require 'timeout'
require 'io/wait'

module Rerun
  class Runner

    # The watcher instance that wait for changes
    attr_reader :watcher

    def self.keep_running(cmd, options)
      runner = new(cmd, options)
      runner.start
      runner.join
      # apparently runner doesn't keep running anymore (as of Listen 2) so we have to sleep forever :-(
      sleep 10000 while true # :-(
    end

    include System
    include ::Timeout

    def initialize(run_command, options = {})
      @run_command, @options = run_command, options
      @run_command = "ruby #{@run_command}" if @run_command.split(' ').first =~ /\.rb$/
      @options[:directory] ||= options.delete(:dir) || '.'
      @options[:ignore] ||= []
    end

    def start_keypress_thread
      return if @options[:background]

      @keypress_thread = Thread.new do
        while true
          if c = key_pressed
            case c.downcase
            when 'c'
              say "Clearing screen"
              clear_screen
            when 'r'
              say "Restarting"
              restart
            when 'f'
              say "Stopping and starting"
              restart(false)
            when 'p'
              toggle_pause
            when 'x', 'q'
              die
              break # the break will stop this thread, in case the 'die' doesn't
            else
              puts "\n#{c.inspect} pressed inside rerun"
              puts [["c", "clear screen"],
                    ["r", "restart"],
                    ["f", "forced restart (stop and start)"],
                    ["p", "toggle pause"],
                    ["x or q", "stop and exit"]
                   ].map {|key, description| "  #{key} -- #{description}"}.join("\n")
              puts
            end
          end
          sleep 1 # todo: use select instead of polling somehow?
        end
      end
      @keypress_thread.run
    end

    def stop_keypress_thread
      @keypress_thread.kill if @keypress_thread
      @keypress_thread = nil
    end

    def restart(with_signal = true)
      @restarting = true
      if @options[:restart] && with_signal
        restart_with_signal(@options[:signal])
      else
        stop
        start
      end
      @restarting = false
    end

    def toggle_pause
      unless @pausing
        say "Pausing.  Press 'p' again to resume."
        @watcher.pause
        @pausing = true
      else
        say "Resuming."
        @watcher.unpause
        @pausing = false
      end
    end

    def unpause
      @watcher.unpause
    end

    def dir
      @options[:directory]
    end

    def pattern
      @options[:pattern]
    end

    def clear?
      @options[:clear]
    end

    def quiet?
      @options[:quiet]
    end

    def verbose?
      @options[:verbose]
    end

    def exit?
      @options[:exit]
    end

    def app_name
      @options[:name]
    end

    def restart_with_signal(restart_signal)
      if @pid && (@pid != 0)
        notify "restarting", "We will be with you shortly."
        send_signal(restart_signal)
      end
    end

    def force_polling
      @options[:force_polling]
    end

    def start
      if @already_running
        taglines = [
          "Here we go again!",
          "Keep on trucking.",
          "Once more unto the breach, dear friends, once more!",
          "The road goes ever on and on, down from the door where it began.",
        ]
        notify "restarted", taglines[rand(taglines.size)]
      else
        taglines = [
          "To infinity... and beyond!",
          "Charge!",
        ]
        notify "launched", taglines[rand(taglines.size)]
        @already_running = true
      end

      clear_screen if clear?
      start_keypress_thread unless @keypress_thread

      begin
        @pid = run @run_command
        say "Rerun (#{$PID}) running #{app_name} (#{@pid})"
      rescue => e
        puts "#{e.class}: #{e.message}"
        exit
      end

      status_thread = Process.detach(@pid) # so if the child exits, it dies

      Signal.trap("INT") do # INT = control-C -- allows user to stop the top-level rerun process
        die
      end

      Signal.trap("TERM") do # TERM is the polite way of terminating a process
        die
      end

      begin
        sleep 2
      rescue Interrupt => e
        # in case someone hits control-C immediately ("oops!")
        die
      end

      if exit?
        status = status_thread.value
        if status.success?
          notify "succeeded", ""
        else
          notify "failed", "Exit status #{status.exitstatus}"
        end
      else
        if !running?
          notify "Launch Failed", "See console for error output"
          @already_running = false
        end
      end

      unless @watcher
        watcher = Watcher.new(@options) do |changes|
          message = change_message(changes)
          say "Change detected: #{message}"
          restart unless @restarting
        end
        watcher.start
        @watcher = watcher
        ignore = @options[:ignore]
        say "Watching #{dir.join(', ')} for #{pattern}" +
              (ignore.empty? ? "" : " (ignoring #{ignore.join(',')})") +
              (watcher.adapter.nil? ? "" : " with #{watcher.adapter_name} adapter")
      end
    end

    def run command
      Kernel.spawn command
    end

    def change_message(changes)
      message = [:modified, :added, :removed].map do |change|
        count = changes[change] ? changes[change].size : 0
        if count > 0
          "#{count} #{change}"
        end
      end.compact.join(", ")

      changed_files = changes.values.flatten
      if changed_files.count > 0
        message += ": "
        message += changes.values.flatten[0..3].map {|path| path.split('/').last}.join(', ')
        if changed_files.count > 3
          message += ", ..."
        end
      end
      message
    end

    def die
      #stop_keypress_thread   # don't do this since we're probably *in* the keypress thread
      stop # stop the child process if it exists
      exit 0 # todo: status code param
    end

    def join
      @watcher.join
    end

    def running?
      send_signal(0)
    end

    # Send the signal to process @pid and wait for it to die.
    # @returns true if the process dies
    # @returns false if either sending the signal fails or the process fails to die
    def signal_and_wait(signal)

      signal_sent = if windows?
                      force_kill = (signal == 'KILL')
                      system("taskkill /T #{'/F' if force_kill} /PID #{@pid}")
                    else
                      send_signal(signal)
                    end

      if signal_sent
        # the signal was successfully sent, so wait for the process to die
        begin
          timeout(@options[:wait]) do
            Process.wait(@pid)
          end
          process_status = $?
          say "Process ended: #{process_status}" if verbose?
          true
        rescue Timeout::Error
          false
        end
      else
        false
      end
    end

    # Send the signal to process @pid.
    # @returns true if the signal is sent
    # @returns false if sending the signal fails
    # If sending the signal fails, the exception will be swallowed
    # (and logged if verbose is true) and this method will return false.
    #
    def send_signal(signal)
      say "Sending signal #{signal} to #{@pid}" unless signal == 0 if verbose?
      Process.kill(signal, @pid)
      true
    rescue => e
      say "Signal #{signal} failed: #{e.class}: #{e.message}" if verbose?
      false
    end

    # todo: test escalation
    def stop
      if @pid && (@pid != 0)
        notify "stopping", "All good things must come to an end." unless @restarting
        @options[:signal].split(',').each do |signal|
          success = signal_and_wait(signal)
          return true if success
        end
      end
    rescue
      false
    end

    def git_head_changed?
      old_git_head = @git_head
      read_git_head
      @git_head and old_git_head and @git_head != old_git_head
    end

    def read_git_head
      git_head_file = File.join(dir, '.git', 'HEAD')
      @git_head = File.exists?(git_head_file) && File.read(git_head_file)
    end

    def notify(title, body, background = true)
      Notification.new(title, body, @options).send(background) if @options[:notify]
      puts
      say "#{app_name} #{title}"
    end

    def say msg
      puts "#{Time.now.strftime("%T")} [rerun] #{msg}" unless quiet?
    end

    def stty(args)
      system "stty #{args}"
    end

    # non-blocking stdin reader.
    # returns a 1-char string if a key was pressed; otherwise nil
    #
    def key_pressed
      return one_char if windows?
      begin
        # this "raw input" nonsense is because unix likes waiting for linefeeds before sending stdin

        # 'raw' means turn raw input on

        # restore proper output newline handling -- see stty.rb and "man stty" and /usr/include/sys/termios.h
        # looks like "raw" flips off the OPOST bit 0x00000001 /* enable following output processing */
        # which disables #define ONLCR		0x00000002	/* map NL to CR-NL (ala CRMOD) */
        # so this sets it back on again since all we care about is raw input, not raw output
        stty "raw opost"
        one_char
      ensure
        stty "-raw" # turn raw input off
      end

      # note: according to 'man tty' the proper way restore the settings is
      # tty_state=`stty -g`
      # ensure
      #   system 'stty "#{tty_state}'
      # end
      # but this way seems fine and less confusing
    end

    def clear_screen
      # see http://ascii-table.com/ansi-escape-sequences-vt-100.php
      $stdout.print "\033[H\033[2J"
    end

    private
    def one_char
      c = nil
      if $stdin.ready?
        c = $stdin.getc
      end
      c.chr if c
    end

  end
end
