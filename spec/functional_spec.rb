here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"
require "#{here}/inc_process.rb"


describe "the rerun command" do
  before do
    STDOUT.sync = true

    @inc = IncProcess.new

    # one file that exists in dir1
    @existing_file = File.join(@inc.dir1, "foo.rb")
    touch @existing_file

    # one file that doesn't yet exist in dir1
    @soon_to_exist_file = File.join(@inc.dir1, "bar.rb")

    # one file that exists in dir2
    @other_existing_file = File.join(@inc.dir2, "baz.rb")

    @inc.launch
  end

  after do
    @inc.kill
  end

  def read
    @inc.read
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

  describe IncProcess do
    it "increments a test file at least once per second" do
      sleep 1
      x = @inc.current_count
      sleep 1
      y = @inc.current_count
      y.should be > x
    end
  end

  it "restarts its target when an app file is modified" do
    first_launched_at = read[:launched_at]
    touch @existing_file
    sleep 4
    second_launched_at = read[:launched_at]

    second_launched_at.should be > first_launched_at
  end

  it "restarts its target when an app file is created" do
    first_launched_at = read[:launched_at]
    touch @soon_to_exist_file
    sleep 4
    second_launched_at = read[:launched_at]

    second_launched_at.should be > first_launched_at
  end

  it "restarts its target when an app file is created in the second dir" do
    first_launched_at = read[:launched_at]
    touch @other_existing_file
    sleep 4
    second_launched_at = read[:launched_at]

    second_launched_at.should be > first_launched_at
  end

  #it "sends its child process a SIGINT to restart"

  it "dies when sent a control-C (SIGINT)" do
    pid = @inc.inc_parent_pid
    # puts "test sending INT to #{pid}"
    Process.kill("INT", pid)
    timeout(6) {
      # puts "test waiting for #{pid}"
      Process.wait(@inc.rerun_pid) rescue Errno::ESRCH
    }
  end

  #it "accepts a key press"
end
