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
GOAL_SQUARE = '.' # 0x2e
FLOOR = ' ' # 0x20
PLAYER = '@' # 0x40
PLAYER_ON_GOAL_SQUARE = '+' # 0x2b
BOX = '$'# 0x24
BOX_ON_GOAL_SQUARE = '.' # 0x2a

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

  def next(direction)
    self + direction
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

Block = Struct.new :position, :cell do
  def initialize(position, cell = FLOOR)
    super
  end

  def on(cell)
    block = self.dup
    block.cell = cell
    block
  end

  def on?(cell)
    self.cell == cell
  end
end

class Wall < Block
  def to_s
    move_to(position) + WALL
  end
end

class Box < Block
  def to_s
    move_to(position) + (self.on?(GOAL_SQUARE) ? BOX_ON_GOAL_SQUARE : BOX)
  end
end

class Player < Block
  def to_s
    move_to(position) + (self.on?(GOAL_SQUARE) ? PLAYER_ON_GOAL_SQUARE : PLAYER)
  end
end

class Field
  attr_accessor :blocks
  attr_accessor :cells
  attr_reader   :player

  def initialize
    @cells = {}
    @blocks = {}
  end

  def player
    self.blocks.values.select{ |block| block.is_a? Player }.first
  end

  def load(data)
    data.split("\n").each_with_index do |line, y|
      line.split('').each_with_index do |char, x|
        case char
        when WALL
          self.blocks[Point.new(x, y)] = Wall.new(Point.new(x, y))
        when BOX
          self.blocks[Point.new(x, y)] = Box.new(Point.new(x, y)).on(FLOOR)
          self.cells[Point.new(x, y)] = FLOOR
        when BOX_ON_GOAL_SQUARE
          self.blocks[Point.new(x, y)] = Box.new(Point.new(x, y)).on(GOAL_SQUARE)
          self.cells[Point.new(x, y)] = GOAL_SQUARE
        when PLAYER
          self.blocks[Point.new(x, y)] = Player.new(Point.new(x, y)).on(FLOOR)
          self.cells[Point.new(x, y)] = FLOOR
        when PLAYER_ON_GOAL_SQUARE
          self.blocks[Point.new(x, y)] = Player.new(Point.new(x, y)).on(GOAL_SQUARE)
          self.cells[Point.new(x, y)] = GOAL_SQUARE
        end
      end
    end
  end

  def [](position)
    self.blocks[position]
  end

  def to_s
    s = ''
    s += cells.map do |position, char|
      move_to(position) + char
    end.join
    s += blocks.map do |position, block|
      move_to(position) + block.to_s
    end.join
    s
  end
end

field = Field.new
field.load(File.read('level1.txt'))
player = field.player

draw = -> do
  print field
  sleep 0.02
end

clear

loop do
  key = detect_key(read_char)
  case key
  when :up, :right, :down, :left
    direction = key
    first_position = player.position.next(direction)
    second_position = first_position.next(direction)
    # if player.can_be_moved_to(field[first_position])
    #   move(player).to(first_position)
    # end
  when :control_c
    quit
  when :space
  end

  draw.call()
end