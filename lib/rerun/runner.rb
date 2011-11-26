require 'timeout'
require 'io/wait'

module Rerun
  class Runner

    def self.keep_running(cmd, options)
      runner = new(cmd, options)
      runner.start_keypress_thread
      runner.start
      runner.join
    end

    include System

    def initialize(run_command, options = {})
      @run_command, @options = run_command, options
      @run_command = "ruby #{@run_command}" if @run_command.split(' ').first =~ /\.rb$/
    end

    def start_keypress_thread
      @keypress_thread = Thread.new do
        while true
          if c = key_pressed
            case c.downcase
            when 'c'
              puts "clearing screen"
              clear_screen
            when 'r'
              restart
              break
            else
              puts "#{c.inspect} pressed -- try 'c' or 'r'"
            end
          end
          sleep 1  # todo: use select instead of polling somehow?
        end
      end
      @keypress_thread.run
    end

    def kill_keypress_thread
      @keypress_thread.kill if @keypress_thread
      @keypress_thread = nil
    end

    def restart
      @restarting = true
      stop
      start
      @restarting = false
    end

    def dir
      @options[:dir] || "."
    end

    def pattern
      @options[:pattern] || DEFAULT_PATTERN
    end

    def clear?
      @options[:clear]
    end

    def exit?
      @options[:exit]
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

      @pid = Kernel.fork do
        begin
          # Signal.trap("INT") { exit }
          exec(@run_command)
        rescue => e
          puts e
          exit
        end
      end
      status_thread = Process.detach(@pid) # so if the child exits, it dies

      Signal.trap("INT") do # INT = control-C -- allows user to stop the top-level rerun process
        stop # stop the child process
        exit
      end

      Signal.trap("TERM") do  # TERM is the polite way of terminating a process
        stop # stop the child process
        exit
      end

      begin
        sleep 2
      rescue Interrupt => e
        # in case someone hits control-C immediately
        stop
        exit
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
        watcher_class = osx_foundation? ? OSXWatcher : FSWatcher
        # watcher_class = FSWatcher

        watcher = watcher_class.new do
          restart unless @restarting
        end
        say "Watching #{dir}/#{pattern}"
        watcher.add_directory(dir, pattern)
        watcher.sleep_time = 1
        watcher.start
        @watcher = watcher
      end

      start_keypress_thread
    end

    def join
      @watcher.join
    end

    def running?
      signal(0)
    end

    def signal(signal)
      Process.kill(signal, @pid)
      true
    rescue
      false
    end

    def stop
      if @pid && (@pid != 0)
        notify "stopping", "All good things must come to an end." unless @restarting

        begin
          timeout(2) do
            # start with a polite SIGTERM
            signal("TERM") && Process.wait(@pid)
          end
        rescue Timeout::Error
          begin
            timeout(2) do
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
      growl title, body
      puts
      say "#{app_name} #{title}"
    end

    def say msg
      puts "#{Time.now.strftime("%T")} - #{msg}"
    end

    def key_pressed
      begin
        system("stty raw -echo") # turn raw input on
        c = nil
        if $stdin.ready?
          c = $stdin.getc
        end
        c.chr if c
      ensure
        system "stty -raw echo" # turn raw input off
      end
    end

    def clear_screen
      # see http://ascii-table.com/ansi-escape-sequences-vt-100.php
      $stdout.print "\033[H\033[2J"
    end

  end
end
