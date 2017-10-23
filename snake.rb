#!/usr/bin/env ruby -W0

require 'io/console'
require 'set'

def clear
  system "clear && printf '\033[3J'"
end

def move_to(x, y)
  "\033[#{y + 1};#{x * 2 + 1}H"
end

def read_char
  system("stty raw -echo")
  char = STDIN.read_nonblock(3) rescue nil
  system("stty -raw echo")
  char
end

def detect_key(c)
  case c
  when " "
    :space
  when "\e"
    :escape
  when "\e[A"
    :up
  when "\e[B"
    :down
  when "\e[C"
    :right
  when "\e[D"
    :left
  when "\u0003"
    :control_c
  end
end

FOOD = '*'
SEGMENT = 'o'
WALL = '#'
HEAD = '@'

def wall?
  lambda do |e|
    e.eql? WALL
  end
end

def segment?
  lambda do |e|
    e.eql? SEGMENT
  end
end

def food?
  lambda do |e|
    e.eql? FOOD
  end
end

Field = Struct.new :cells do
  def initialize(cells = {})
    super
  end

  def to_s
    cells.map do |(x, y), e|
      move_to(x, y) + e
    end.join
  end
end

Snake = Struct.new :body do
  def to_s
    s = []
    body[0..0].map do |(x, y)|
      s << move_to(x, y) + HEAD
    end
    body[1..-1].map do |(x, y)|
      s << move_to(x, y) + SEGMENT
    end
    s.join
  end

  def move
    return if dead?
    body.pop
    body.unshift self.next
  end

  def eat
    return if dead?
    body.unshift self.next
  end

  def die
    @dead = true
  end

  def dead?
    @dead
  end

  def next
    _next = head.dup
    case direction
    when :right
      _next[0] += 1
    when :left
      _next[0] -= 1
    when :up
      _next[1] -= 1
    when :down
      _next[1] += 1
    end
    _next
  end

  def head
    body.first
  end

  def direction
    @direction || :right
  end

  def turn(direction)
    return if [@direction, direction].to_set == [:left, :right].to_set
    return if [@direction, direction].to_set == [:up, :down].to_set
    @direction = direction
  end
end

field = Field.new
12.times do |n|
  field.cells[[n, 0]] = WALL
  field.cells[[n, 11]] = WALL
  field.cells[[0, n]] = WALL
  field.cells[[11, n]] = WALL
end
snake = Snake.new [[3, 1], [2, 1], [1, 1]]

draw = -> do
  clear
  print field
  print snake
end

debug = -> do
  print move_to 0, 14
  print "body: #{snake.body}"
end

def within(time)
  t1 = Time.now
  yield
  t2 = Time.now
  sleep time - (t2 - t1)
end

time = 0.5

t0 = Time.now
lag = 0
loop do

  t1 = Time.now()
  lag += t1 - t0
  t0 = t1

  # double current = getCurrentTime();
  # double elapsed = current - previous;
  # lag += elapsed;
  # previous = current;

  t1 = Time.now
  # puts 'loop'
  key = detect_key(read_char)
  # puts key if key

  case key
  when :up, :right, :down, :left
    snake.turn(key)
    snake.move
    lag = 0
  when :control_c
    exit 0
  else
  end

  while (lag >= time)
    # draw.call()
    # debug.call()

    # update
    snake.move

    lag -= time
  end

  draw.call()
  sleep 0.02
end

# within time do
#   draw.call()
#   debug.call()
# end

# loop do
#   within time do
#     # key = detect_char(read_char)
#     # case key
#     # when :up, :right, :down, :left
#     #   snake.turn(key)
#     # else
#     #   puts key
#     # end

#     case snake.next
#     when wall?
#       snake.die
#     when segment?
#       snake.die
#     when food?
#       snake.eat
#     else
#       snake.move
#     end

#     draw.call()
#     debug.call()
#   end
# end
