here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"
require 'rerun/watcher'
require 'rerun/osxwatcher'
require "#{here}/watcher_examples"

module Rerun
  extend Rerun::System
  if osx_foundation?
    describe OSXWatcher do
      it_should_behave_like "all watchers"
      def create_watcher(&block)
        OSXWatcher.new(&block)
      end
    end
  end
end
