here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"
require 'tmpdir'
require 'rerun/watcher'

module Rerun
  COOL_OFF_TIME = 2
  describe Watcher do

    before do
      @dir = Dir.tmpdir + "/#{Time.now.to_i}-#{(rand*100000).to_i}"
      # fix goofy MacOS /tmp path ambiguity
      @dir.sub!(/^\/var/, "/private/var")
      FileUtils.mkdir_p(@dir)

      @log = nil
      @watcher = Watcher.new(:directory => @dir, :pattern => "*.txt") do |hash|
        @log = hash
      end
      @watcher.start
      sleep(COOL_OFF_TIME) # let it spin up
    end

    let(:rest) { 1.0 }

    after do
      begin
        @watcher.stop
      rescue ThreadError => e
      end
    end

    def create test_file, sleep = true
      File.open(test_file, "w") do |f|
        f.puts("test")
      end
      sleep(rest) if sleep
    end

    def modify test_file
      File.open(test_file, "a") do |f|
        f.puts("more more more")
      end
      sleep(rest)
    end

    def remove test_file
      File.delete(test_file)
      sleep(rest)
    end

    it "watches file changes" do
      test_file = "#{@dir}/test.txt"

      create test_file
      @log[:added].should == [test_file]

      modify test_file
      @log[:modified].should == [test_file]

      remove test_file
      @log[:removed].should == [test_file]
    end

    it "ignores changes to non-matching files" do
      non_matching_file = "#{@dir}/test.exe"

      create non_matching_file
      @log.should be_nil

      modify non_matching_file
      @log.should be_nil

      remove non_matching_file
      @log.should be_nil
    end

    it "ignores changes to dot-files" do
      dot_file = "#{@dir}/.ignoreme.txt"

      create dot_file
      @log.should be_nil

      modify dot_file
      @log.should be_nil

      remove dot_file
      @log.should be_nil
    end

    ignored_directories = Listen::Silencer::DEFAULT_IGNORED_DIRECTORIES
    it "ignores directories named #{ignored_directories}" do
      ignored_directories.each do |ignored_dir|
        FileUtils.mkdir_p "#{@dir}/#{ignored_dir}"
        create [@dir, ignored_dir, "foo.txt"].join('/'), false
      end
      sleep(rest)
      @log.should be_nil
    end

    it "ignores files named `.DS_Store`." do
      create "#{@dir}/.DS_Store"
      @log.should be_nil
    end

    it "ignores files ending with `.tmp`." do
      create "#{@dir}/foo.tmp"
      @log.should be_nil
    end

    it "disables watcher when paused" do
      @watcher.pause
      create "#{@dir}/pause_test.txt"
      @log.should be_nil
    end

    it "pauses and resumes watcher" do
      @watcher.pause
      create "#{@dir}/pause_test.txt"
      @log.should be_nil
      @watcher.unpause
      test_file = "#{@dir}/pause_test2.txt"
      create test_file
      @log[:added].should == [test_file]
    end

  end

end
