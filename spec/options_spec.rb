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
      assert { defaults[:signal] == "TERM" }
      assert { defaults[:growl] == true }
      assert { defaults[:name] == 'Rerun' }

      assert { defaults[:clear].nil? }
      assert { defaults[:exit].nil? }
      assert { defaults[:background].nil? }
    end

    ["--help", "-h", "--usage", "--version", "-v"].each do |arg|
      describe "when passed #{arg}" do
        it "returns nil" do
          capturing do
            Options.parse([arg]).should be_nil
          end
        end
      end
    end

    it "accepts --no-growl" do
      options = Options.parse ["--no-growl", "foo"]
      assert { options[:growl] == false }
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

  end
end
