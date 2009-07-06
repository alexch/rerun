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

    def icon
      libdir = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}/lib"
      $LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

      rails_sig_file = File.expand_path(".")+"/config/boot.rb" 
      puts rails_sig_file
      return "#{libdir}/../icons/rails_red_sml.png" if File.exists? rails_sig_file
      return nil
    end

    def growl(title, body, background = true)
      if growl?
        icon ? icon_str = "--image \"#{icon}\"" : icon_str = ""
        s = "#{growlcmd} -H localhost -n \"#{app_name}\" -m \"#{body}\" \"#{app_name} #{title}\" #{icon_str}"
        s += " &" if background
        `#{s}`
      end
    end
    
  end
end
