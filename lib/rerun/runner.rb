require 'timeout'
require 'io/wait'

module Rerun
  class Runner

    def self.keep_running(cmd, options)
      runner = new(cmd, options)
      runner.start
      runner.join
      # apparently runner doesn't keep running anymore (as of Listen 2) so we have to sleep forever :-(
      sleep 10000 while true  # :-(
    end

    include System

    def initialize(run_command, options = {})
      @run_command, @options = run_command, options
      @run_command = "ruby #{@run_command}" if @run_command.split(' ').first =~ /\.rb$/
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
            when 'p'
              toggle_pause if watcher_running?
            when 'x', 'q'
              die
              break  # the break will stop this thread, in case the 'die' doesn't
            else
              puts "\n#{c.inspect} pressed inside rerun"
              puts [["c", "clear screen"],
               ["r", "restart"],
               ["p", "toggle pause"],
               ["x or q", "stop and exit"]
              ].map{|key, description| "  #{key} -- #{description}"}.join("\n")
              puts
            end
          end
          sleep 1  # todo: use select instead of polling somehow?
        end
      end
      @keypress_thread.run
    end

    def stop_keypress_thread
      @keypress_thread.kill if @keypress_thread
      @keypress_thread = nil
    end

    def restart
      @restarting = true
      stop
      start
      @restarting = false
    end

    def watcher_running?
      @watcher && @watcher.running?
    end

    def toggle_pause
      unless @pausing
        say "Pausing.  Press 'p' again to resume."
        @watcher.pause
        @pausing = true
      else
        say "Resuming"
        @watcher.unpause
        @pausing = false
      end
    end

    def unpause
      @watcher.unpause
    end

    def dir
      @options[:dir]
    end

    def dirs
      @options[:dir] || "."
    end

    def pattern
      @options[:pattern]
    end

    def ignore
      @options[:ignore] || []
    end

    def clear?
      @options[:clear]
    end

    def exit?
      @options[:exit]
    end

    def app_name
      @options[:name]
    end

    def start
      if windows?
        raise "Sorry, Rerun does not work on Windows."
      end

      if (!@already_running)
        taglines = [
          "To infinity... and beyond!",
          "Charge!",
        ]
        notify "launched", taglines[rand(taglines.size)]
        @already_running = true
      else
        taglines = [
          "Here we go again!",
          "Keep on trucking.",
          "Once more unto the breach, dear friends, once more!",
          "The road goes ever on and on, down from the door where it began.",
        ]
        notify "restarted", taglines[rand(taglines.size)]
      end

      clear_screen if clear?
      start_keypress_thread unless @keypress_thread

      @pid = Kernel.fork do
        begin
          exec(@run_command)
        rescue => e
          puts "#{e.class}: #{e.message}"
          exit
        end
      end
      status_thread = Process.detach(@pid) # so if the child exits, it dies

      Signal.trap("INT") do # INT = control-C -- allows user to stop the top-level rerun process
        die
      end

      Signal.trap("TERM") do  # TERM is the polite way of terminating a process
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

        watcher = Watcher.new(:directory => dirs, :pattern => pattern, :ignore => ignore) do |changes|

          message = [:modified, :added, :removed].map do |change|
            count = changes[change].size
            if count and count > 0
              "#{count} #{change}"
            end
          end.compact.join(", ")
          say "Change detected: #{message}"
          restart unless @restarting
        end
        watcher.start
        @watcher = watcher
        say "Watching #{dir.join(', ')} for #{pattern}" +
                (ignore.empty? ? "" : " (ignoring #{ignore.join(',')})") +
                " using #{watcher.adapter.class.name.split('::').last} adapter"
      end
    end

    def die
      #stop_keypress_thread   # don't do this since we're probably *in* the keypress thread
      stop # stop the child process if it exists
      exit 0  # todo: status code param
    end

    def join
      @watcher.join
    end

    def running?
      signal(0)
    end

    def signal(signal)
      say "Sending signal #{signal} to #{@pid}" unless signal == 0
      Process.kill(signal, @pid)
      true
    rescue
      false
    end

    # todo: test escalation
    def stop
      default_signal = @options[:signal] || "TERM"
      if @pid && (@pid != 0)
        notify "stopping", "All good things must come to an end." unless @restarting
        begin
          timeout(5) do  # todo: escalation timeout setting
            # start with a polite SIGTERM
            signal(default_signal) && Process.wait(@pid)
          end
        rescue Timeout::Error
          begin
            timeout(5) do
              # escalate to SIGINT aka control-C since some foolish process may be ignoring SIGTERM
              signal("INT") && Process.wait(@pid)
            end
          rescue Timeout::Error
            # escalate to SIGKILL aka "kill -9" which cannot be ignored
            signal("KILL") && Process.wait(@pid)
          end
        end
      end
    rescue => e
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

    def notify(title, body)
      growl title, body if @options[:growl]
      puts
      say "#{app_name} #{title}"
    end

    def say msg
      puts "#{Time.now.strftime("%T")} [rerun] #{msg}"
    end

    # non-blocking stdin reader.
    # returns a 1-char string if a key was pressed; otherwise nil
    #
    def key_pressed
      begin
        # this "raw input" nonsense is because unix likes waiting for linefeeds before sending stdin

        # 'raw' means turn raw input on

        # restore proper output newline handling -- see stty.rb and "man stty" and /usr/include/sys/termios.h
        # looks like "raw" flips off the OPOST bit 0x00000001 /* enable following output processing */
        # which disables #define ONLCR		0x00000002	/* map NL to CR-NL (ala CRMOD) */
        # so this sets it back on again since all we care about is raw input, not raw output
        system("stty raw opost")

        c = nil
        if $stdin.ready?
          c = $stdin.getc
        end
        c.chr if c
      ensure
        system "stty -raw" # turn raw input off
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

  end
end
