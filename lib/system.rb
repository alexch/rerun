def mac?
  RUBY_PLATFORM =~ /darwin/i && !$osx_foundation_failed_to_load
end

def windows?
   RUBY_PLATFORM =~ /mswin/i
end

def linux?
   RUBY_PLATFORM =~ /linux/i
end

if mac?
  begin
    require 'osx/foundation'
    OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
  rescue
    $osx_foundation_failed_to_load = true
  end
end

module Rerun
  module System

    # do we have growl or not?
    def growl?
      mac? && (growlcmd != "")
    end

    def growlcmd
      `which growlnotify`.chomp
    end
    
    def app_name
      # todo: make sure this works in non-Mac and non-Unix environments
      File.expand_path(".").gsub(/^.*\//, '').capitalize
    end

    def growl(title, body, background = true)
      if growl?
        s = "#{growlcmd} -n \"#{app_name}\" -m \"#{body}\" \"#{app_name} #{title}\""
        s += " &" if background
        `#{s}`
      end
    end
    
  end
end
