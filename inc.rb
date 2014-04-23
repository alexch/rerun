STDOUT.sync = true

Signal.trap("TERM") do
  say "exiting"
  exit
end

def say msg
  puts "\t[inc] #{Time.now.strftime("%T")} #{$$} #{msg}"
end

class Inc
  def initialize file
    @file = file
  end

  def run
    launched = Time.now.to_i
    say "launching"
    i = 0
    while i < 100
      say "writing #{launched}/#{i} to #{@file}"
      File.open(@file, "w") do |f|
        f.puts(launched)
        f.puts(i)
      end
      sleep 0.5
      i+=1
    end

  end
end

Inc.new(ARGV[0] || "./inc.txt").run
