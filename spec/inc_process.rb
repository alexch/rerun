here = File.expand_path(File.dirname(__FILE__))
require 'tmpdir'
require_relative('../lib/rerun/system')
class IncProcess

  include Rerun::System

  attr_reader :dir, :inc_output_file
  attr_reader :dir1, :dir2
  attr_reader :rerun_pid, :inc_parent_pid

  def initialize
    @dir = Dir.tmpdir + "/#{Time.now.to_i}"
    FileUtils.mkdir_p(@dir)

    @inc_output_file = "#{@dir}/inc.txt"

    @dir1 = File.join(@dir, "dir1")
    FileUtils.mkdir_p(@dir1)

    @dir2 = File.join(@dir, "dir2")
    FileUtils.mkdir_p(@dir2)

  end

  # don't call this until you're sure it's running
  def kill
    begin
      pids = ([@inc_pid, @inc_parent_pid, @rerun_pid] - [Process.pid]).uniq
      ::Timeout.timeout(5) do
        pids.each do |pid|
          if windows?
            system("taskkill /F /T /PID #{pid}")
          else
            # puts "Killing #{pid} gracefully"
            Process.kill("INT", pid) rescue Errno::ESRCH
          end
        end
        pids.each do |pid|
          # puts "waiting for #{pid}"
          Process.wait(pid) rescue Errno::ECHILD
        end
      end
    rescue Timeout::Error
      pids.each do |pid|
        # puts "Killing #{pid} forcefully"
        Process.kill("KILL", pid) rescue Errno::ESRCH
      end
    end

  end

  def rerun_cmd
    root = File.dirname(__FILE__) + "/.."
    "#{root}/bin/rerun -d '#{@dir1},#{@dir2}' ruby #{root}/inc.rb #{@inc_output_file}"
  end

  def launch
    @rerun_pid = spawn(rerun_cmd)
    Timeout.timeout(10) { sleep 0.5 until File.exist?(@inc_output_file) }
    sleep 3 # let rerun's watcher get going
    read
  end

  def read
    File.open(@inc_output_file, "r") do |f|
      result = {
          launched_at: f.gets.to_i,
          count: f.gets.to_i,
          inc_pid: f.gets.to_i,
          inc_parent_pid: f.gets.to_i,
      }
      @inc_pid = result[:inc_pid]
      @inc_parent_pid = result[:inc_parent_pid]
      puts "reading #{@inc_output_file}: #{result.inspect}"
      result
    end
  end

  def current_count
    read[:count]
  end

  def touch(file = @existing_file)
    puts "#{Time.now.strftime("%T")} touching #{file}"
    File.open(file, "w") do |f|
      f.puts Time.now
    end
  end

  def type char
    # todo: send a character to stdin of the rerun process
  end

end


