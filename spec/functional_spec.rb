here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"
require "#{here}/inc_process.rb"

describe "the rerun command" do
  before do
    STDOUT.sync = true

    @inc = IncProcess.new
    @dir = @inc.dir
    @dir1 = @inc.dir1
    @dir2 = @inc.dir2

    # one file that exists in dir1
    @watched_file1 = File.join(@dir1, "foo.rb")
    touch @watched_file1

    # one file that doesn't yet exist in dir1
    @watched_file2 = File.join(@dir1, "bar.rb")

    # one file that exists in dir2
    @watched_file3 = File.join(@dir2, "baz.rb")

    @inc.launch
  end

  after do
    @inc.kill
  end


  def read
    @inc.read
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

  it "increments a test file at least once per second" do
    sleep 1
    x = current_count
    sleep 1
    y = current_count
    y.should be > x
  end

  it "restarts its target when an app file is modified" do
    first_launched_at, count = read
    touch @watched_file1
    sleep 4
    second_launched_at, count = read

    second_launched_at.should be > first_launched_at
  end

  it "restarts its target when an app file is created" do
    first_launched_at, count = read
    touch @watched_file2
    sleep 4
    second_launched_at, count = read

    second_launched_at.should be > first_launched_at
  end

  it "restarts its target when an app file is created in the second dir" do
    first_launched_at, count = read
    touch @watched_file3
    sleep 4
    second_launched_at, count = read

    second_launched_at.should be > first_launched_at
  end

  #it "sends its child process a SIGINT to restart"

  it "dies when sent a control-C (SIGINT)" do
    Process.kill("INT", @inc.rerun_pid)
    timeout(6) {
      Process.wait(@inc.rerun_pid) rescue Errno::ESRCH
    }
  end

  #it "accepts a key press"
end


