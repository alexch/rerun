require 'listen'

Thread.abort_on_exception = true

# This class will watch a directory and alert you of
# new files, modified files, deleted files.
#
# Author: Paul Horman, http://paulhorman.com/filesystemwatcher/
# Author: Alex Chaffee
module Rerun
  class Watcher
    CREATED = 0
    MODIFIED = 1
    DELETED = 2

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
      @directory = options[:directory]
      if FileTest.exists?(directory) && FileTest.readable?(directory) then
        @directory = Directory.new(directory, @pattern)
      else
        raise InvalidDirectoryError, "Dir '#{directory}' either doesnt exist or isnt readable"
      end
      @priority = options[:priority]

      @found = nil
      @first_time = true
      @thread = nil
    end

    def prime
      @first_time = true
      @found = {}
      examine
      @first_time = false
    end

    def start
      if @thread then
        raise RuntimeError, "already started"
      end

      prime

      @thread = Thread.new do
        # todo: multiple dirs

        regexp = Glob.new(@pattern).to_regexp
        @listener = Listen::Listener.new(@directory.dir, :filter => regexp) do |modified, added, removed|
          #d { modified }
          #d { added }
          #d { removed }
          examine
        end
        @listener.start
      end

      @thread.priority = @priority

      at_exit { stop } # try really hard to clean up after ourselves
    end

    def adapter
      timeout(4) do
        sleep 1 until adapter = @listener.instance_variable_get(:@adapter)
        adapter
      end
    end

    # kill the filewatcher thread
    def stop
      begin
        @thread.wakeup
      rescue ThreadError => e
        # ignore
      end
      begin
        @thread.kill
      rescue ThreadError => e
        # ignore
      end
    end

    # wait for the filewatcher to finish
    def join
      @thread.join() if @thread
    rescue Interrupt => e
      # don't care
    end

    private

    def examine

      already_examined = Hash.new()

      examine_files(@directory.files, already_examined)

      # now diff the found files and the examined files to see if
      # something has been deleted
      all_found_files = @found.keys()
      all_examined_files = already_examined.keys()
      intersection = all_found_files - all_examined_files

      intersection.each do |file_name|
        @client_callback.call(DELETED, file_name)
        @found.delete(file_name)
      end

    end

    # loops over the file list check for new or modified files
    def examine_files(files, already_examined)
      files.each do |file_name|
        # expand the file name to the fully qual path
        full_file_name = File.expand_path(file_name)

        # we cant do much if the file isnt readable anyway
        if File.readable?(full_file_name) then
          already_examined[full_file_name] = true
          stat = File.stat(full_file_name)
          mod_time = stat.mtime
          size = stat.size

          # on the first iteration just load all of the files into the foundList
          if @first_time then
            @found[full_file_name] = FoundFile.new(full_file_name, mod_time, size)
          else
            # see if we have found this file already
            found_file = @found[full_file_name]
            @found[full_file_name] = FoundFile.new(full_file_name, mod_time, size)

            if found_file
              if mod_time > found_file.mod_time || size != found_file.size then
                @client_callback.call(MODIFIED, full_file_name)
              end
            else
              @client_callback.call(CREATED, full_file_name)
            end
          end
        end
      end
    end

    class Directory
      attr_reader :dir, :expression

      def initialize(dir, expression)
        @dir, @expression = dir, expression
        @dir.chop! if @dir =~ %r{/$}
      end

      def files
        return Dir["#{@dir}/#{@expression}"]
      end
    end

    class FoundFile
      attr_reader :status, :file_name, :mod_time, :size

      def initialize(file_name, mod_time, size)
        @file_name, @mod_time, @size = file_name, mod_time, size
      end

      def modified(mod_time)
        @mod_time = mod_time
      end

      def to_s
        "FoundFile[file_name=#{file_name}, mod_time=#{mod_time.to_i}, size=#{size}]"
      end
    end

    # if the directory you want to watch doesnt exist or isn't readable this is thrown
    class InvalidDirectoryError < StandardError;
    end

    # if the file you want to watch doesnt exist or isn't readable this is thrown
    class InvalidFileError < StandardError;
    end
  end
end
