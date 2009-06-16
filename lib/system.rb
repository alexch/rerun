
# are we on OSX or not?
begin
  require 'osx/foundation'
  OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
  $osx = true
rescue MissingSourceFile
  # this is to not fail when running on a non-Mac
end

module Rerun
  module System
    def osx?
      $osx
    end
    
    # do we have growl or not?
    def has_growl?
      growlcmd != ""
    end

    def growlcmd
      `which growlnotify`.chomp
    end
    
    def app_name
      # todo: make sure this works in non-Mac and non-Unix environments
      File.expand_path(".").gsub(/^.*\//, '').capitalize
    end

    def growl(title, body, background = true)
      s = "#{growlcmd} -n \"#{app_name}\" -m \"#{body}\" \"#{app_name} #{title}\""
      s += " &" if background
      `#{s}`
    end
    
  end
end
