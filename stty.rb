# see  /usr/include/sys/termios.h
# see man stty
require "wrong"
include Wrong

def tty
  stty = `stty -g`
  stty.split(':')
end


def tty_setting name
  tty.grep(/^#{name}/).first.split('=').last
end

def oflag
  tty_setting("oflag")
end

normal = tty
`stty raw`
raw = tty
`stty -raw`
post_raw = tty
assert { post_raw == normal }

d { raw - normal }
d { normal - raw }

puts "== normal"
# d { tty }
d{oflag}

def check setting
  `stty gfmt1:#{setting}`
  puts "testing #{setting}:\nline\nline"
end

puts "== raw"
`stty raw`
puts "testing\nraw\nmode"

check "oflag=3"
check "lflag=200005cb"
check "iflag=2b02"
`stty -raw`
