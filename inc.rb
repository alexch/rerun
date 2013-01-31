def say msg
  puts "#{Time.now.strftime("%T")} #{$$} #{msg}"
end

STDOUT.sync = true

Signal.trap("TERM") do
  say "caught TERM"
  exit
end

launched = Time.now.to_i
say "launching"
file = ARGV[0] || "./inc.txt"
i = 0
while i < 10
  say "writing #{launched}/#{i}"
  File.open(file, "w") do |f|
    f.puts(launched)
    f.puts(i)
  end
  sleep 0.5
  i+=1
end
