here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"

require "rerun/glob"

module Rerun
  describe Glob do
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
        Glob.new(glob_string).to_regexp_string.should == regexp_string
      end
    end

    it "excludes files beginning with dots"

    describe "#to_regexp" do
      it "makes a regexp" do
        Glob.new("foo*").to_regexp.should == /foo.*/
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

