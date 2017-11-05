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

Sokoban = Struct.new :position do
  def up
    self.position += Point.new(0, -1)
  end

  def down
    self.position += Point.new(0, 1)
  end

  def left
    self.position += Point.new(-1, 0)
  end

  def right
    self.position += Point.new(1, 0)
  end

  def to_s
    move_to(position.x, position.y) + MAN
  end
end

sokoban = Sokoban.new(Point.new(1, 1))

draw = -> do
  print sokoban
end

clear

loop do
  key = detect_key(read_char)
  case key
  when :up
    sokoban.up
  when :right
    sokoban.right
  when :down
    sokoban.down
  when :left
    sokoban.left
  when :control_c
    quit
  when :space
  end

  draw.call()
end