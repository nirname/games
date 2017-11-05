#!/usr/bin/env ruby -W0

require 'io/console'
require 'set'
system("stty raw -echo")

def clear
  system "clear && printf '\033[3J'"
end

def move_to(position)
  "\033[#{position.y + 1};#{position.x * 2 + 1}H"
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

WALL = '#' # 0x23
PLAYER = '@' # 0x40
PLAYER_ON_GOAL_SQUARE = '+' # 0x2b
BOX = '$'# 0x24
BOX_ON_GOAL_SQUARE = '*' # 0x2a
GOAL_SQUARE = '.' # 0x2e
FLOOR = ' ' # 0x20

Point = Struct.new :x, :y do
  def +(point)
    case point
    when Point
      Point.new(self.x + point.x, self.y + point.y)
    else
      if point.respond_to? :to_p
        self + point.to_p
      else
        raise TypeError, "#{point.class} cannot be coersed into Point"
      end
    end
  end
end

class Symbol
  def to_p
    case self
    when :up then Point.new(0, -1)
    when :down then Point.new(0, 1)
    when :left then Point.new(-1, 0)
    when :right then Point.new(1, 0)
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
    move_to(position) + PLAYER
  end
end

class Field
  attr_accessor :cells
  attr_accessor :boxes
  attr_accessor :player

  def initialize
    self.cells ||= {}
  end

  def load(data)
    data.split("\n").each_with_index do |row, y|
      row.split('').each_with_index do |char, x|
        cells[Point.new(x, y)] = char
      end
    end
  end

  def to_s
    cells.map do |position, char|
      move_to(position) + char
    end.join
  end
end

field = Field.new
field.load(File.read('level1.txt'))

sokoban = Sokoban.new(Point.new(1, 1))

draw = -> do
  print field
  # print sokoban
end

possible = ->(direction) do
  next1, next2 = sokoban.next(direction).position, sokoban.next(direction).next(direction).position
  true
end

clear

loop do
  key = detect_key(read_char)
  case key
  when :up, :right, :down, :left
    direction = key
    if possible.call(direction)
      sokoban.step(direction)
    end
  when :control_c
    quit
  when :space
  end

  draw.call()
end