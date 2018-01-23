here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"
require 'rerun'

module Rerun
  describe Runner do
    class Runner
      attr_reader :run_command
    end

    describe "initialization and configuration" do
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

      it "clears the screen" do
        runner = Runner.new("foo.rb", {:clear => true})
        runner.clear?.should be_truthy
      end

      it "is quiet" do
        runner = Runner.new("foo.rb", {:quiet => true})
        runner.quiet?.should == true
      end

      # TODO: test that quiet actually suppresses output
    end

    describe "running" do
      it "sends its child process a SIGINT when restarting"

      it "dies when sent a control-C (SIGINT)"

      it "accepts a key press"

      it "restarts with HUP"

      it "restarts with a different signal"
    end

    describe 'change_message' do
      subject { Runner.new("").change_message(changes) }
      [:modified, :added, :removed].each do |change_type|
        context "one #{change_type}" do
          let(:changes) { {change_type => ["foo.rb"]} }
          it 'says how many of each type of change' do
            expect(subject == "1 modified: foo.rb")
          end
        end
      end

      context "two changes" do
        let(:changes) { {modified: ["foo.rb", "bar.rb"]} }
        it 'uses a comma' do
          expect(subject == "2 modified: foo.rb, bar.rb")
        end
      end

      context "three changes" do
        let(:changes) { {modified: ["foo.rb", "bar.rb", "baz.rb"]} }
        it 'elides after the third' do
          expect(subject == "3 modified: foo.rb, bar.rb, baz.rb")
        end
      end

      context "more than three changes" do
        let(:changes) { {modified: ["foo.rb", "bar.rb", "baz.rb", "baf.rb"]} }
        it 'elides after the third' do
          expect(subject == "4 modified: foo.rb, bar.rb, baz.rb, ...")
        end
      end

      context "with a path" do
        let(:changes) { {modified: ["baz/bar/foo.rb"]} }
        it 'strips the path' do
          expect(subject == "1 modified: foo.rb")
        end
      end
    end

  end

end
