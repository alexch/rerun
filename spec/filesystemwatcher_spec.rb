require "#{File.dirname(__FILE__)}/spec_helper.rb"
require 'tmpdir'
require 'filesystemwatcher'

describe FileSystemWatcher do
  before do
    @dir = Dir.tmpdir + "/#{Time.now.to_i}"
    FileUtils.mkdir_p(@dir)

    @log = []
    @watcher = FileSystemWatcher.new(@dir, "*.txt")
    @watcher.sleep_time = 0.1
    @watcher.start do |status, file|
      @log << [status, file]
    end
    @test_file = "#{@dir}/test.txt"
    @non_matching_file = "#{@dir}/test.exe"
    sleep(0.1) # let it spin up
  end

  after do
    begin
      @watcher.stop
    rescue ThreadError => e
    end
  end

  it "watches file changes" do
    @log.clear
    File.open(@test_file, "w") do |f|
      f.puts("test")
    end
    sleep(0.5)
    @log.should == [[FileSystemWatcher::CREATED, @test_file]]

    @log.clear
    File.open(@test_file, "a") do |f|
      f.puts("more more more")
    end
    sleep(0.5)
    @log.should == [[FileSystemWatcher::MODIFIED, @test_file]]

    @log.clear
    File.delete(@test_file)
    sleep(0.5)
    @log.should == [[FileSystemWatcher::DELETED, @test_file]]
  end

  it "ignores changes to non-matching files" do
    @log.clear
    File.open(@non_matching_file, "w") do |f|
      f.puts("test")
    end
    sleep(0.5)
    @log.should == []

    @log.clear
    File.open(@non_matching_file, "a") do |f|
      f.puts("more more more")
    end
    sleep(0.5)
    @log.should == []

    @log.clear
    File.delete(@non_matching_file)
    sleep(0.5)
    @log.should == []
  end
end
