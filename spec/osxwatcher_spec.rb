here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper.rb"
require 'watcher'
require 'osxwatcher'
require 'watcher_examples'

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
