# todo: unit tests

module Rerun
  class Notification
    include System

    attr_reader :title, :body, :options

    def initialize(title, body, options = Options::DEFAULTS.dup)
      @title = title
      @body = body
      @options = options
    end

    def command
      return unless mac?

      # todo: strategy or subclass

      s = nil

      if options[:notify] == true or options[:notify] == "growl"
        if (cmd = command_named("growlnotify"))
          # todo: check version of growlnotify and warn if it's too old
          icon_str = ("--image \"#{icon}\"" if icon)
          s = "#{cmd} -n \"#{app_name}\" -m \"#{body}\" \"#{app_name} #{title}\" #{icon_str}"
        end
      end

      if s.nil? and options[:notify] == true or options[:notify] == "osx"
        if (cmd = command_named("terminal-notifier"))
          icon_str = ("-appIcon \"#{icon}\"" if icon)
          s = "#{cmd} -title \"#{app_name}\" -message \"#{body}\" \"#{app_name} #{title}\" #{icon_str}"
        end
      end

      s
    end

    def command_named(name)
      path = `which #{name}`.chomp
      path.empty? ? nil : path
    end

    def send(background = true)
      return unless command
      `#{command}#{" &" if background}`
    end

    def app_name
      options[:name]
    end

    def icon
      "#{icon_dir}/rails_red_sml.png" if rails?
    end

    def icon_dir
      here = File.expand_path(File.dirname(__FILE__))
      File.expand_path("#{here}/../../icons")
    end

  end
end
