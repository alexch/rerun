here = File.expand_path(File.dirname(__FILE__))
$: << here unless $:.include?(here)

require "listen"  # pull in the Listen gem
require "rerun/options"
require "rerun/system"
require "rerun/runner"
require "rerun/watcher"
require "rerun/glob"

module Rerun

  DEFAULT_PATTERN = "**/*.{rb,js,css,scss,sass,erb,html,haml,ru}"

end

