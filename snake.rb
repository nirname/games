#!/usr/bin/env ruby -W0

require 'io/console'
require 'set'
system("stty raw -echo")

def clear
  system "clear && printf '\033[3J'"
end

def move_to(x, y)
  "\033[#{y + 1};#{x * 2 + 1}H"
end

def read_char
  char = STDIN.read_nonblock(3) rescue nil
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
SKULL = 'X'

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

Field = Struct.new :width, :height, :cells do
  def initialize(width, height, cells = {})
    super
  end

  def to_s
    blank_field =
      width.times.map do |x|
        height.times.map do |y|
          move_to(x, y) + ' '
        end
      end.join
    walls =
      cells.map do |(x, y), e|
        move_to(x, y) + e
      end.join
    blank_field + walls
  end
end

class Symbol
  def same?(symbol)
    self == symbol
  end

  def opposite?(symbol)
    return true if self == :right && symbol == :left
    return true if self == :left && symbol == :right
    return true if self == :up && symbol == :down
    return true if self == :down && symbol == :up
    false
  end
end

Snake = Struct.new :body, :direction, :state do
  def initialize(body, direction = :right, state = :asleep)
    super
  end

  def to_s
    s = []
    body[0..0].map do |(x, y)|
      s << move_to(x, y) + (dead? ? SKULL : HEAD)
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

  def length
    body.length
  end

  def sleep
    self.state = :asleep if alive? && !dead?
  end

  def asleep?
    self.state == :asleep
  end

  def wake
    self.state = :alive if asleep? && !dead?
  end

  def alive?
    self.state == :alive
  end

  def die
    self.state = :dead
  end

  def dead?
    self.state == :dead
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

  def turn(new_direction)
    return if direction.opposite?(new_direction)
    return if direction.same?(new_direction)

    self.direction = new_direction
  end
end

def fetch_cell(place, field, snake)
  cell = field.cells[place]
  cell ||= snake.head.include?(place) ? HEAD : nil
  cell ||= snake.body.include?(place) ? SEGMENT : nil
  cell
end

def grow_food(field, snake)
  loop do
    place = [rand(0 ... field.width), rand(0 ... field.height)]
    if !fetch_cell(place, field, snake)
      field.cells[place] = FOOD
      return
    end
  end
end

field = Field.new(12, 12)
12.times do |n|
  field.cells[[n, 0]] = WALL
  field.cells[[n, 11]] = WALL
  field.cells[[0, n]] = WALL
  field.cells[[11, n]] = WALL
end
snake = Snake.new [[3, 1], [2, 1], [1, 1]]

grow_food(field, snake)

draw = -> do
  print field
  print snake
  print move_to(0, field.height + 1)
  puts "Use arrow keys to play\r"
  puts "Press Control + c to exit\r"
end

debug = -> do
  print move_to 0, 14
  print "body: #{snake.body}"
end

def quit
  clear
  system("stty -raw echo")
  exit 0
end

MAX_TIME = 0.5
MIN_TIME = 0.1

begin
  time = 0.5

  previous = Time.now
  lag = 0

  clear

  loop do
    current = Time.now
    elapsed = current - previous
    lag += elapsed
    previous = current

    key = detect_key(read_char)

    snake.wake if key && snake.asleep?

    case key
    when :up, :right, :down, :left
      if snake.turn(key)
        lag = time
      end
    when :control_c
      quit
    else
    end

    while (lag >= time)
      lag -= time

      case fetch_cell(snake.next, field, snake)
      when wall?
        snake.die
      when segment?
        snake.die
      when food?
        time = MAX_TIME - 0.001 * (snake.length ** 2)
        time = MIN_TIME if time < MIN_TIME

        field.cells.delete(snake.next)
        snake.eat
        grow_food(field, snake)
      else
        snake.move if snake.alive?
      end
    end

    draw.call()
    sleep 0.02
  end
ensure
  system("stty -raw echo")
end
