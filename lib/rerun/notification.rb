# todo: unit tests
# todo: deprecate "--growl", use "--notify" or "--notify growl" or "--notify osx" or "--no-notify"

module Rerun
  class Notification
    include System

    attr_reader :title, :body, :options

    def initialize(title:, body:, options: Options::DEFAULTS.dup)
      @title = title
      @body = body
      @options = options
    end

    def command
      if mac?
        # todo: strategy object or subclass

        if (cmd = command_named("growlnotify"))
          puts "growl"
          # todo: check version of growlnotify and warn if it's too old

          icon_str = ("--image \"#{icon}\"" if icon)

          "#{cmd} -n \"#{app_name}\" -m \"#{body}\" \"#{app_name} #{title}\" #{icon_str}"

        elsif (cmd = command_named("terminal-notifier"))
          puts "term"

          icon_str = ("-appIcon \"#{icon}\"" if icon)

          "#{cmd} -title \"#{app_name}\" -message \"#{body}\" \"#{app_name} #{title}\" #{icon_str}"

        end
      end
    end

    def app_name
      options[:name]
    end

    def command_named(name)
      path = `which #{name}`.chomp
      path.empty? ? nil : path
    end

    def send(background = true)
      `#{command}#{" &" if background}`
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
