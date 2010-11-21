here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"
require 'rerun'

module Rerun
  describe Runner do
    class Runner
      attr_reader :run_command
    end
    
    it "accepts a command" do
      runner = Runner.new("foo")
      runner.run_command.should == "foo"
    end

    it "If the command is a .rb file, then run it with ruby" do
      runner = Runner.new("foo.rb")
      runner.run_command.should == "ruby foo.rb"
    end

    it "If the command starts with a .rb file, then run it with ruby" do
      runner = Runner.new("foo.rb --param bar baz.txt")
      runner.run_command.should == "ruby foo.rb --param bar baz.txt"
    end

  end
end
