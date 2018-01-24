here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"

require "rerun/options"

module Rerun
  describe Options do
    it "has good defaults" do
      defaults = Options.parse ["foo"]
      assert { defaults[:cmd] = "foo" }

      assert { defaults[:dir] == ["."] }
      assert { defaults[:pattern] == Options::DEFAULT_PATTERN }
      assert { defaults[:signal] == "TERM,INT,KILL" }
      assert { defaults[:notify] == true }
      assert { defaults[:quiet] == false }
      assert { defaults[:verbose] == false }
      assert { defaults[:name] == 'Rerun' }
      assert { defaults[:force_polling] == false }

      assert { defaults[:clear].nil? }
      assert { defaults[:exit].nil? }
      assert { defaults[:background].nil? }
    end

    ["--help", "-h", "--usage", "--version"].each do |arg|
      describe "when passed #{arg}" do
        it "returns nil" do
          capturing do
            Options.parse([arg]).should be_nil
          end
        end
      end
    end

    it "accepts --quiet" do
      options = Options.parse ["--quiet", "foo"]
      assert { options[:quiet] == true }
    end

    it "accepts --verbose" do
      options = Options.parse ["--verbose", "foo"]
      assert { options[:verbose] == true }
    end

    it "splits directories" do
      options = Options.parse ["--dir", "a,b", "foo"]
      assert { options[:dir] == ["a", "b"] }
    end

    it "adds directories specified individually with --dir" do
      options = Options.parse ["--dir", "a", "--dir", "b"]
      assert { options[:dir] == ["a", "b"] }
    end

    it "adds directories specified individually with -d" do
      options = Options.parse ["-d", "a", "-d", "b"]
      assert { options[:dir] == ["a", "b"] }
    end

    it "adds directories specified individually using mixed -d and --dir" do
      options = Options.parse ["-d", "a", "--dir", "b"]
      assert { options[:dir] == ["a", "b"] }
    end

    it "adds individual directories and splits comma-separated ones" do
      options = Options.parse ["--dir", "a", "--dir", "b", "--dir", "foo,other"]
      assert { options[:dir] == ["a", "b", "foo", "other"] }
    end

    it "accepts --name for a custom application name" do
      options = Options.parse ["--name", "scheduler"]
      assert { options[:name] == "scheduler" }
    end

    it "accepts --force-polling to force listener polling" do
      options = Options.parse ["--force-polling"]
      assert { options[:force_polling] == true }
    end

    it "accepts --ignore" do
      options = Options.parse ["--ignore", "log/*"]
      assert { options[:ignore] == ["log/*"] }
    end

    it "accepts --ignore multiple times" do
      options = Options.parse ["--ignore", "log/*", "--ignore", "*.tmp"]
      assert { options[:ignore] == ["log/*", "*.tmp"] }
    end

    it "accepts --restart which allows the process to restart itself, defaulting to HUP" do
      options = Options.parse ["--restart"]
      assert { options[:restart] }
      assert { options[:signal] == "HUP" }
    end

    it "allows user to override HUP signal when --restart is specified" do
      options = Options.parse %w[--restart --signal INT]
      assert { options[:restart] }
      assert { options[:signal] == "INT" }
    end

    # notifications

    it "rejects --no-growl" do
      options = nil
      err = capturing(:stderr) do
        options = Options.parse %w[--no-growl echo foo]
      end

      assert { options == nil }
      assert { err.include? "use --no-notify" }
    end

    it "defaults to --notify true (meaning 'use what works')" do
      options = Options.parse %w[echo foo]
      assert { options[:notify] == true }
    end

    it "accepts bare --notify" do
      options = Options.parse %w[--notify -- echo foo]
      assert { options[:notify] == true }
    end

    %w[growl osx].each do |notifier|
      it "accepts --notify #{notifier}" do
        options = Options.parse ["--notify", notifier, "echo foo"]
        assert { options[:notify] == notifier }
      end
    end

    it "accepts --no-notify" do
      options = Options.parse %w[--no-notify echo foo]
      assert { options[:notify] == false }
    end

  end
end
