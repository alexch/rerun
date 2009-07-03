launched = Time.now.to_i
# puts "Launching at #{launched}"
file = ARGV[0] || "./inc.txt"
i = 0
while i < 10
#  puts "Writing #{launched}/#{i}"
  File.open(file, "w") do |f|
    f.puts(launched)
    f.puts(i)
  end
  sleep 0.5
  i+=1
end
