require "system"
require "watcher"
require "osxwatcher"
require "fswatcher"

# todo: make this work in non-Mac and non-Unix environments (also Macs without growlnotify) 
module Rerun
  class Runner

    include System

    def initialize(run_command, options = {})
      @run_command, @options = run_command, options
    end
    
    def restart
      stop
      start
    end

    def start
      if (!@already_running)
        taglines = [
          "To infinity... and beyond!",
          "Charge!",
          ]
        notify "Launching", taglines[rand(taglines.size)]
        @already_running = true
      else
        taglines = [
          "Here we go again!",
          "Once more unto the breach, dear friends, once more!", 
        ]
        notify "Restarting", taglines[rand(taglines.size)]
      end

      @pid = Kernel.fork do
        Signal.trap("HUP") { stop; exit }
        exec(@run_command)
      end

      Process.detach(@pid)

      begin
        sleep 2
      rescue Interrupt => e
        # in case someone hits control-C immediately
        stop
        exit
      end

      unless running?
        notify "Launch Failed", "See console for error output"
        @already_running = false
      end

      watcher_class = osx? ? OSXWatcher : FSWatcher
      # watcher_class = FSWatcher
      
      watcher = watcher_class.new do
        restart
      end
      watcher.add_directory(".", "**/*.rb")
      watcher.sleep_time = 1
      watcher.start
      watcher.join

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
      if @pid && @pid != 0
        notify "Stopping"
        signal("KILL") && Process.wait(@pid)
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

    def notify(title, body)
      growl title, body if has_growl?
      puts
      puts "#{Time.now.strftime("%T")} - #{app_name} #{title}: #{body}"
      puts
    end
    
  end

end  

