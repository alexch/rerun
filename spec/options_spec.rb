here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"

require "rerun/options"

module Rerun
  describe Options do
    it "has good defaults" do
      defaults = Options.parse ["foo"]
      assert { defaults[:cmd] = "foo" }

      assert { defaults[:dir] == "." }
      assert { defaults[:pattern] == Options::DEFAULT_PATTERN }
      assert { defaults[:signal] == "TERM" }

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
  end
end
