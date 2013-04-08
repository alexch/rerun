require 'optparse'

libdir = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}"

$spec = Gem::Specification.load(File.join(libdir, "..", "rerun.gemspec"))

module Rerun
  class Options
    DEFAULT_PATTERN = "**/*.{rb,js,css,scss,sass,erb,html,haml,ru}"

    DEFAULTS = {
        :dir => ["."],
        :pattern => DEFAULT_PATTERN,
        :signal => "TERM",
        :growl => true,
    }

    def self.parse args = ARGV
      options = DEFAULTS.dup
      opts = OptionParser.new("", 24, '  ') do |opts|
        opts.banner = "Usage: rerun [options] [--] cmd"

        opts.separator ""
        opts.separator "Launches an app, and restarts it when the filesystem changes."
        opts.separator "See http://github.com/alexch/rerun for more info."
        opts.separator "Version: #{$spec.version}"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-d dir", "--dir dir", "directory to watch, default = \"#{DEFAULTS[:dir]}\". Separate multiple paths with ','.") do |dir|
          options[:dir] = dir.split(",")
        end

        opts.on("-p pattern", "--pattern pattern", "file glob, default = \"#{DEFAULTS[:pattern]}\"") do |pattern|
          options[:pattern] = pattern
        end

        opts.on("-s", "--signal signal", "terminate process using this signal, default = \"#{DEFAULTS[:signal]}\"") do |signal|
          options[:signal] = signal
        end

        opts.on("-c", "--clear", "clear screen before each run") do
          options[:clear] = true
        end

        opts.on("-x", "--exit", "expect the program to exit. With this option, rerun checks the return value; without it, rerun checks that the process is running.") do |dir|
          options[:exit] = true
        end

        opts.on("-b", "--background", "disable on-the-fly commands, allowing the process to be backgrounded") do
          options[:background] = true
        end

        opts.on("--no-growl", "don't use growl") do
          options[:growl] = false
        end

        opts.on_tail("-h", "--help", "--usage", "show this message") do
          puts opts
          return
        end

        opts.on_tail("--version", "show version") do
          puts $spec.version
          return
        end
      end

      if args.empty?
        puts opts
        nil
      else
        opts.parse! args
        options[:cmd] = args.join(" ")
        options
      end
    end

  end
end
