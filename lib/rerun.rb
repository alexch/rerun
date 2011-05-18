here = File.expand_path(File.dirname(__FILE__))
$: << here unless $:.include?(here)

require "rerun/system"
require "rerun/runner"
require "rerun/watcher"
require "rerun/osxwatcher"
require "rerun/fswatcher"

# todo: make sure this works in non-Mac environments (also Macs without growlnotify)
module Rerun
  
  DEFAULT_PATTERN = "**/*.{rb,js,css,scss,sass,erb,html,haml,ru}"

end  

