require "#{File.dirname(__FILE__)}/spec_helper.rb"
require 'tmpdir'
require 'watcher'
require 'osxwatcher'

module Rerun
  shared_examples_for "all watchers" do
    before do
      @dir = Dir.tmpdir + "/#{Time.now.to_i}"
      FileUtils.mkdir_p(@dir)

      @log = []
      @watcher = create_watcher do |status, file|
        @log << [status, file]
      end
      @watcher.add_directory(@dir, "*.txt")
      @watcher.sleep_time = 0.1
      @watcher.start
      
      @test_file = "#{@dir}/test.txt"
      @non_matching_file = "#{@dir}/test.exe"
      sleep(1) # let it spin up
    end

    after do
      begin
        @watcher.stop
      rescue ThreadError => e
      end
    end

    it "watches file changes" do
      rest = 0.5
      @log.clear
      File.open(@test_file, "w") do |f|
        f.puts("test")
      end
      sleep(rest)
      @log.should == [[Watcher::CREATED, @test_file]]

      @log.clear
      File.open(@test_file, "a") do |f|
        f.puts("more more more")
      end
      sleep(rest)
      @log.should == [[Watcher::MODIFIED, @test_file]]

      @log.clear
      File.delete(@test_file)
      sleep(rest)
      @log.should == [[Watcher::DELETED, @test_file]]
    end

    # it "ignores changes to non-matching files" do
    #   rest = 1.0
    #   
    #   @log.clear
    #   File.open(@non_matching_file, "w") do |f|
    #     f.puts("test")
    #   end
    #   sleep(rest)
    #   @log.should == []
    # 
    #   @log.clear
    #   File.open(@non_matching_file, "a") do |f|
    #     f.puts("more more more")
    #   end
    #   sleep(rest)
    #   @log.should == []
    # 
    #   @log.clear
    #   File.delete(@non_matching_file)
    #   sleep(rest)
    #   @log.should == []
    # end
  end
  
end
