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
    InvalidDirectoryError = Class.new(RuntimeError)

    #def self.default_ignore
    #  Listen::Silencer.new(Listen::Listener.new).send :_default_ignore_patterns
    #end

    attr_reader :directory, :pattern, :priority, :ignore_dotfiles

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
          :ignore_dotfiles => true,
      }.merge(options)

      @pattern = options[:pattern]
      @directories = options[:directory]
      @directories = sanitize_dirs(@directories)
      @priority = options[:priority]
      @force_polling = options[:force_polling]
      @ignore = [options[:ignore]].flatten.compact
      @ignore_dotfiles = options[:ignore_dotfiles]
      @thread = nil
    end

    def sanitize_dirs(dirs)
      dirs = [*dirs]
      dirs.map do |d|
        d.chomp!("/")
        unless FileTest.exists?(d) && FileTest.readable?(d) && FileTest.directory?(d)
          raise InvalidDirectoryError, "Directory '#{d}' either doesnt exist or isn't readable"
        end
        File.expand_path(d)
      end
    end

    def start
      if @thread then
        raise RuntimeError, "already started"
      end

      @thread = Thread.new do
        @listener = Listen.to(*@directories, only: watching, ignore: ignoring, wait_for_delay: 1, force_polling: @force_polling) do |modified, added, removed|
          count = modified.size + added.size + removed.size
          if count > 0
            @client_callback.call(:modified => modified, :added => added, :removed => removed)
          end
        end
        @listener.start
      end

      @thread.priority = @priority

      sleep 0.1 until @listener

      at_exit { stop } # try really hard to clean up after ourselves
    end

    def watching
      Rerun::Glob.new(@pattern).to_regexp
    end

    def ignoring
      patterns = []
      if ignore_dotfiles
        patterns << /^\.[^.]/ # at beginning of string, a real dot followed by any other character
      end
      patterns + @ignore.map { |x| Rerun::Glob.new(x).to_regexp }
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
    rescue Interrupt
      # don't care
    end

    def pause
      @listener.pause if @listener
    end

    def unpause
      @listener.start if @listener
    end

    def running?
      @listener && @listener.processing?
    end

    def adapter
      @listener &&
          (backend = @listener.instance_variable_get(:@backend)) &&
          backend.instance_variable_get(:@adapter)
    end

    def adapter_name
      adapter && adapter.class.name.split('::').last
    end
  end
end
