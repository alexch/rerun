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
minus_raw = tty
assert { minus_raw == normal }

`stty raw opost`
raw_opost = tty

d { raw - normal }
d { normal - raw }
d { normal - raw_opost }

puts "== normal"
# d { tty }
d{oflag}

def check setting
  `stty #{setting}`
  puts "testing #{setting}:\nline\nline"
  print "\r\n"
end

check "raw"

check "-raw"

check "raw opost"

check "-raw"

check "raw gfmt1:oflag=3"

# check "oflag=3"
# check "lflag=200005cb"
# check "iflag=2b02"
`stty -raw`
