require "#{File.dirname(__FILE__)}/spec_helper.rb"

require 'watcher'
require 'osxwatcher'

require 'watcher_spec'

if mac?
  module Rerun
    describe OSXWatcher do
      it_should_behave_like "all watchers"
      def create_watcher(&block)
        OSXWatcher.new(&block)
      end
    end
  end
end
