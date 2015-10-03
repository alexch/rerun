here = File.expand_path(File.dirname(__FILE__))
require 'tmpdir'

class IncProcess

  attr_reader :dir, :inc_output_file
  attr_reader :dir1, :dir2
  attr_reader :rerun_pid

  def initialize
    @dir = Dir.tmpdir + "/#{Time.now.to_i}"
    FileUtils.mkdir_p(@dir)

    @inc_output_file = "#{@dir}/inc.txt"

    @dir1 = File.join(@dir, "dir1")
    FileUtils.mkdir_p(@dir1)

    @dir2 = File.join(@dir, "dir2")
    FileUtils.mkdir_p(@dir2)

  end

  def kill
    timeout(4) {
      Process.kill("INT", @inc_pid) && Process.wait(@inc_pid) rescue Errno::ESRCH
      Process.kill("INT", @rerun_pid) && Process.wait(@rerun_pid) rescue Errno::ESRCH
    }
  end

  def cmd
    root = File.dirname(__FILE__) + "/.."
    "#{root}/bin/rerun -d '#{@dir1},#{@dir2}' ruby #{root}/inc.rb #{@inc_output_file}"
  end

  def launch
    @rerun_pid = spawn(cmd)
    timeout(10) { sleep 0.5 until File.exist?(@inc_output_file) }
    sleep 4  # let rerun's watcher get going
  end

  def read
    File.open(@inc_output_file, "r") do |f|
      launched_at = f.gets.to_i
      count = f.gets.to_i
      @inc_pid = f.gets.to_i
      result = [launched_at, count, @inc_pid]
      puts "reading #{@inc_output_file}: #{result.join("\t")}"
      result
    end
  end

  def current_count
    launched_at, count = read
    count
  end

  def touch(file = @watched_file1)
    puts "#{Time.now.strftime("%T")} touching #{file}"
    File.open(file, "w") do |f|
      f.puts Time.now
    end
  end

  def type char
    # todo: send a character to stdin of the rerun process
  end

end


