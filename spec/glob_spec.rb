here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"

require "rerun/glob"

module Rerun
  describe Glob do

    describe "#to_regexp" do
      it "makes a regexp" do
        Glob.new("foo*").to_regexp.should == /#{Glob::START_OF_FILENAME}foo.*#{Glob::END_OF_STRING}/
      end

    end

    describe "#to_regexp_string" do
      {
        "x" => "x",

        "*" => ".*",
        "foo*" => "foo.*",
        "*foo" => ".*foo",
        "*foo*" => ".*foo.*",

        "?" => ".",

        "." => "\\.",

        "{foo,bar,baz}" => "(foo|bar|baz)",
        "{.txt,.md}" => '(\.txt|\.md)',

        # pass through slash-escapes verbatim
        "\\x" => "\\x",
        "\\." => "\\.",
        "\\*" => "\\*",
        "\\\\" => "\\\\",

        "**/*.txt" => "([^/]+/)*.*\\.txt",

      }.each_pair do |glob_string, regexp_string|
        specify glob_string do
          Glob.new(glob_string).to_regexp_string.should ==
              Glob::START_OF_FILENAME + regexp_string + Glob::END_OF_STRING
        end
      end
    end

    describe "specifically" do
      {
        "*.txt" => {
          :hits=> [
              "foo.txt",
              "foo/bar.txt",
              "/foo/bar.txt",
              "bar.baz.txt",
              "/foo/bar.baz.txt",
          ],
          :misses => [
              "foo.txt.html",
              "tmp/foo.txt.html",
              "/tmp/foo.txt.html",
              #"tmp/.foo.txt",
          ]
        },
        "tmp/foo.*" => {
          :hits => [
            "tmp/foo.txt",
          ],
          :misses => [
            "stmp/foo.txt",
            "tmp/foofoo.txt",
          ]
        }
      }.each_pair do |glob, paths|
        paths[:hits].each do |path|
          specify "#{glob} matches #{path}" do
            Glob.new(glob).to_regexp.should =~ path
          end
        end
        paths[:misses].each do |path|
          specify "#{glob} doesn't match #{path}" do
            Glob.new(glob).to_regexp.should_not =~ path
          end
        end
      end
    end

    describe "#smoosh" do

      def check_smoosh string, array
        glob = Glob.new("")
        glob.smoosh(string.split('')).should == array
      end

      it "ignores non-stars" do
        check_smoosh "", []
        check_smoosh "abc", ["a", "b", "c"]
      end

      it "passes solitary stars" do
        check_smoosh "*", ["*"]
        check_smoosh "a*b", ["a", "*", "b"]
      end

      it "smooshes two stars in a row into a single '**' string" do
        check_smoosh "**", ["**"]
        check_smoosh "a**b", ["a", "**", "b"]
        check_smoosh "**b", ["**", "b"]
        check_smoosh "a**", ["a", "**"]
      end

      it "treats **/ like **" do
        check_smoosh "**/", ["**"]
        check_smoosh "a**/b", ["a", "**", "b"]
      end
    end

  end
end

