here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"
require 'tmpdir'
require 'rerun/watcher'

module Rerun
  describe Watcher do

    before do
      @dir = Dir.tmpdir + "/#{Time.now.to_i}"
      FileUtils.mkdir_p(@dir)

      @log = nil
      @watcher = Watcher.new(:directory => @dir, :pattern => "*.txt") do |hash|
        #d { hash }

        # fix goofy MacOS /tmp path ambiguity
        [hash[:added], hash[:modified], hash[:removed]].compact.flatten.each do |s|
          s.sub!("/private/var", "/var")
        end

        @log = hash
      end
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
      rest = 1.0
      File.open(@test_file, "w") do |f|
        f.puts("test")
      end
      sleep(rest)
      @log[:added].should == [@test_file]

      File.open(@test_file, "a") do |f|
        f.puts("more more more")
      end
      sleep(rest)
      @log[:modified].should == [@test_file]

      File.delete(@test_file)
      sleep(rest)
      @log[:removed].should == [@test_file]
    end

    it "ignores changes to non-matching files" do
       rest = 1.0

       File.open(@non_matching_file, "w") do |f|
         f.puts("test")
       end
       sleep(rest)
       @log.should be_nil

       File.open(@non_matching_file, "a") do |f|
         f.puts("more more more")
       end
       sleep(rest)
       @log.should be_nil

       File.delete(@non_matching_file)
       sleep(rest)
       @log.should be_nil
    end
  end

end
