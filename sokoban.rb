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

def quit
  clear
  system("stty -raw echo")
  exit 0
end

WALL = '#'
MAN = '@'

Point = Struct.new :x, :y do
  def +(point)
    Point.new(self.x + point.x, self.y + point.y)
  end
end

Field = Struct.new :width, :height do
end

UP = Point.new(0, -1)
DOWN = Point.new(0, 1)
LEFT = Point.new(-1, 0)
RIGHT = Point.new(1, 0)

class Symbol
  def to_direction
    case self
    when :up then UP
    when :down then DOWN
    when :left then LEFT
    when :right then RIGHT
    end
  end
end

Sokoban = Struct.new :position do
  def step(direction)
    self.position += direction
  end

  def next(direction)
    Sokoban.new(self.position + direction)
  end

  def to_s
    move_to(position.x, position.y) + MAN
  end
end

sokoban = Sokoban.new(Point.new(1, 1))

draw = -> do
  print sokoban
end

possible = ->(direction) do
  # sokoban.next(direction)
  true
end

clear

loop do
  key = detect_key(read_char)
  case key
  when :up, :right, :down, :left
    direction = key.to_direction
    if possible.call(direction)
      sokoban.step(direction)
    end
  when :control_c
    quit
  when :space
  end

  draw.call()
end