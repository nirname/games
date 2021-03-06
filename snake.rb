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
  def initialize(body, direction = :right, state = :alive)
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

@game_paused = true

info = -> do
  _info = []

  _info << move_to(0, field.height)
  _info << "Snake length: #{snake.length}"
  _info << ""
  if @game_paused
    _info << "Game paused"
  else
    _info << "Press Space to pause"
  end
  _info << "Use arrow keys to play"
  _info << "Press Control + c to exit"
  _info.map!{ |msg| msg.ljust(80)}
  _info.join("\n\r")
end

draw = -> do
  print field
  print snake
  print info.call()
end

debug = -> do
  move_to(0, 14) + "body: #{snake.body}"
end

def quit
  clear
  system("stty -raw echo")
  exit 0
end

speed = 2 # ticks per sec

time_per_update = -> do
  1.0 / speed
end

# x - progress between 0 and 1
def ease_out(x, n = 1)
  1.0 - (1.0 - x) ** n
end

begin
  previous = Time.now
  lag = 0

  clear

  draw.call()

  loop do
    key = detect_key(read_char)

    case key
    when :space
      @game_paused = !@game_paused
    when :control_c
      quit
    when :up, :right, :down, :left
      @game_paused = false
    end

    next if @game_paused

    current = Time.now
    elapsed = current - previous
    previous = current

    lag += elapsed

    case key
    when :up, :right, :down, :left
      if snake.turn(key)
        lag = time_per_update.call()
      end
    end

    while (lag >= time_per_update.call())
      lag -= time_per_update.call()

      case fetch_cell(snake.next, field, snake)
      when wall?
        snake.die
      when segment?
        snake.die
      when food?
        progress = ([snake.length, 100].min / 100.0)
        speed = 2 + 8 * ease_out(progress, 2)
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
