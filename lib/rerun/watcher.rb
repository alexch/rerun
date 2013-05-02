require 'listen'

Thread.abort_on_exception = true

# This class will watch a directory and alert you of
# new files, modified files, deleted files.
#
# Now uses the Listen gem, but spawns its own thread on top.
# We should probably be accessing the Listen thread directly.
#
# Author: Alex Chaffee
#
module Rerun
  class Watcher
    attr_reader :directory, :pattern, :priority

    # Create a file system watcher. Start it by calling #start.
    #
    # @param options[:directory] the directory to watch (default ".")
    # @param options[:pattern] the glob pattern to search under the watched directory (default "**/*")
    # @param options[:priority] the priority of the watcher thread (default 0)
    #
    def initialize(options = {}, &client_callback)
      @client_callback = client_callback

      options = {
          :directory => ".",
          :pattern => "**/*",
          :priority => 0,
      }.merge(options)

      @pattern = options[:pattern]
      @directories = options[:directory]
      @directories = sanitize_dirs(@directories)
      @priority = options[:priority]
      @thread = nil
    end

    def sanitize_dirs(dirs)
      dirs = [*dirs]
      dirs.map do |d|
        d.chomp!("/")
        unless FileTest.exists?(d) && FileTest.readable?(d) && FileTest.directory?(d)
          raise InvalidDirectoryError, "Directory '#{d}' either doesnt exist or isnt readable"
        end
        File.expand_path(d)
      end
    end

    def start
      if @thread then
        raise RuntimeError, "already started"
      end

      @thread = Thread.new do
        regexp = Rerun::Glob.new(@pattern).to_regexp
        dirs = @directories
        params = dirs << { :filter => regexp, :relative_paths => false }
        @listener = Listen::Listener.new(*params) do |modified, added, removed|
          @client_callback.call(:modified => modified, :added => added, :removed => removed)
        end
        @listener.start!
      end

      @thread.priority = @priority

      sleep 0.1 until @listener

      at_exit { stop } # try really hard to clean up after ourselves
    end

    def adapter
      timeout(4) do
        sleep 1 until adapter = @listener.instance_variable_get(:@adapter)
        adapter
      end
    end

    # kill the file watcher thread
    def stop
      @thread.wakeup rescue ThreadError
      begin
        @listener.stop
      rescue Exception => e
        puts "#{e.class}: #{e.message} stopping listener"
      end
      @thread.kill rescue ThreadError
    end

    # wait for the file watcher to finish
    def join
      @thread.join if @thread
    rescue Interrupt => e
      # don't care
    end
  end
end
