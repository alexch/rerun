require "system"
require "watcher"

begin
  require 'osx/foundation'
  OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
rescue MissingSourceFile
  # this is to not fail when running on a non-Mac
end

# stolen from RSpactor, http://github.com/mislav/rspactor
# based on http://rails.aizatto.com/2007/11/28/taming-the-autotest-beast-with-fsevents/

#TODO: make it notice deleted files
require "watcher"
module Rerun
  class OSXWatcher < Rerun::Watcher
    attr_reader :last_check, :valid_extensions
    attr_reader :stream
    
    def start
      prime
      timestamp_checked

      dirs = Array(directories.map{|d| d.dir})
      
      mac_callback = lambda do |stream, ctx, num_events, paths, marks, event_ids|
        examine
        # changed_files = extract_changed_files_from_paths(split_paths(paths, num_events))
        # timestamp_checked
        # puts "changed files:"
        # p changed_files
        # yield changed_files unless changed_files.empty?
      end

      @stream = OSX::FSEventStreamCreate(OSX::KCFAllocatorDefault, mac_callback, nil, dirs, OSX::KFSEventStreamEventIdSinceNow, @sleep_time, 0)
      raise "Failed to create stream" unless stream

      OSX::FSEventStreamScheduleWithRunLoop(stream, OSX::CFRunLoopGetCurrent(), OSX::KCFRunLoopDefaultMode)
      unless OSX::FSEventStreamStart(stream)
        raise "Failed to start stream"
      end

      @thread = Thread.new do
        begin
          OSX::CFRunLoopRun()
        rescue Interrupt
          OSX::FSEventStreamStop(stream)
          OSX::FSEventStreamInvalidate(stream)
          OSX::FSEventStreamRelease(stream)
          @stream = nil
        end
      end

      @thread.priority = @priority
    end

    def stop
      @thread.kill
    end

    def timestamp_checked
      @last_check = Time.now
    end

    def split_paths(paths, num_events)
      paths.regard_as('*')
      rpaths = []
      num_events.times { |i| rpaths << paths[i] }
      rpaths
    end

    def extract_changed_files_from_paths(paths)
      changed_files = []
      paths.each do |path|
        next if ignore_path?(path)
        Dir.glob(path + "*").each do |file|
          next if ignore_file?(file)
          changed_files << file if file_changed?(file)
        end
      end
      changed_files
    end

    def file_changed?(file)
      File.stat(file).mtime > last_check
    end

    def ignore_path?(path)
      path =~ /(?:^|\/)\.(git|svn)/
    end

    def ignore_file?(file)
      File.basename(file).index('.') == 0 or not valid_extension?(file)
    end

    def file_extension(file)
      file =~ /\.(\w+)$/ and $1
    end

    def valid_extension?(file)
      valid_extensions.nil? or valid_extensions.include?(file_extension(file))
    end
  end
end
