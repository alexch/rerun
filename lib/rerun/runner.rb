module Rerun
  class Runner

    include System

    def initialize(run_command, options = {})
      @run_command, @options = run_command, options
      @run_command = "ruby #{@run_command}" if @run_command.split(' ').first =~ /\.rb$/
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

      print "\033[H\033[2J" if clear?  # see http://ascii-table.com/ansi-escape-sequences-vt-100.php

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

      Signal.trap("INT") do  # INT = control-C
        stop # first stop the child
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
        notify "stopped", "All good things must come to an end." unless @restarting
        signal("KILL") && Process.wait(@pid)
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

  end
end
