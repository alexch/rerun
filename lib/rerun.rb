

require "lib/filesystemwatcher"

# todo: make this work in non-Mac and non-Unix environments (also Macs without growlnotify) 
class Runner
  
  def app_name
    # todo: make sure this works in non-Mac and non-Unix environments
    File.dirname(File.expand_path(__FILE__)).gsub(/^.*\//, '').capitalize
  end
  
  def growlcmd(title, body)
    "growlnotify -n #{app_name} -m \"#{body}\" \"#{app_name} #{title}\""
  end

  def growl(title, body)
    `#{growlcmd title, body} &`
  end
  
  def restart
    beginning = Time.now
    puts ""
    puts "#{beginning.strftime("%T")} - Restarting #{app_name}..."
    puts ""
    stop
    start
  end

  def start
    if (!@already_running)
      growl "Launching", "To infinity... and beyond!"
      @already_running = true
    else
      growl "Restarting", "Here we go again!"
    end

    @pid = Kernel.fork do
       # Signal.trap("HUP") { puts "Ouch!"; exit }
       exec("ruby app.rb")
    end

    Process.detach(@pid)

    sleep 2
    unless running?
      growl "Launch Failed", "See console for error output"
      @already_running = false
    end
    
    self
  end
  
  def running?
    kill(0)
  end
  
  def kill(signal)
    Process.kill(signal, @pid)
    true
  rescue
    false
  end

  def stop
    kill("KILL") && Process.wait(@pid)
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

  def listen
    begin
      require 'lib/listener'
      listener = Listener.new(%w(rb erb haml)) do |files|
        puts "Changed: #{files.join(', ')}"
        restart
      end.run(".")
    rescue
      watcher = FileSystemWatcher.new()
      watcher.add_directory(".", "**/*.rb")
      watcher.sleepTime = 1
      watcher.start do |status,file|
        if (status == FileSystemWatcher::CREATED)
          puts "Created: #{file}"
        elsif (status == FileSystemWatcher::MODIFIED)
          puts "Modified: #{file}"
        elsif (status == FileSystemWatcher::DELETED)
          puts "Deleted: #{file}"
        else
          puts "something else... ?!?!"
        end
        restart
      end
      watcher.join
    end
  end
end

Runner.new.start.listen
