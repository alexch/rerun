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

        #"**/*.txt" => "([^/]*/)*.*\\.txt"

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

  end
end

