require "rubygems"
require "rspec"
#require "rspec/autorun"

require "wrong/adapters/rspec"
include Wrong::D

here = File.expand_path(File.dirname(__FILE__))
$: << File.expand_path("#{here}/../lib")

require "rerun"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = %i[expect should] }
end
