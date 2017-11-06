#!/usr/bin/env ruby -W0

require 'io/console'
require 'set'
system("stty raw -echo")

def clear
  system "clear && printf '\033[3J'"
end

def print_at(position)
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
BOX_ON_GOAL_SQUARE = '*' # 0x2a

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

Block = Struct.new :position do
  attr_accessor :cell

  def initialize(position)
    self.cell = FLOOR
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

class EmptyBlock < Block
  def can_be_moved_to(block)
    true
  end
end

class Wall < Block
  def to_s
    print_at(position) + WALL
  end

  def can_be_moved_to(block)
    false
  end
end

class Box < Block
  def to_s
    print_at(position) + (self.on?(GOAL_SQUARE) ? BOX_ON_GOAL_SQUARE : BOX)
  end

  def can_be_moved_to(block)
    case block
    when EmptyBlock
      true
    else
      false
    end
  end
end

class Player < Block
  def to_s
    print_at(position) + (self.on?(GOAL_SQUARE) ? PLAYER_ON_GOAL_SQUARE : PLAYER)
  end

  def can_be_moved_to(block)
    case block
    when EmptyBlock
      true
    when Box
      true
    else
      false
    end
  end
end

class Promise < Proc
  alias :to :call
end

class Field
  attr_accessor :blocks
  attr_accessor :cells
  attr_reader   :player

  def initialize
    @cells = {}
    @blocks = []
  end

  def player
    self.blocks.select{ |block| block.is_a? Player }.first
  end

  def load(data)
    data.split("\n").each_with_index do |line, y|
      line.split('').each_with_index do |char, x|
        case char
        when WALL
          self.blocks << Wall.new(Point.new(x, y))
        when BOX
          self.blocks << Box.new(Point.new(x, y)).on(FLOOR)
          self.cells[Point.new(x, y)] = FLOOR
        when BOX_ON_GOAL_SQUARE
          self.blocks << Box.new(Point.new(x, y)).on(GOAL_SQUARE)
          self.cells[Point.new(x, y)] = GOAL_SQUARE
        when PLAYER
          self.blocks << Player.new(Point.new(x, y)).on(FLOOR)
          self.cells[Point.new(x, y)] = FLOOR
        when PLAYER_ON_GOAL_SQUARE
          self.blocks << Player.new(Point.new(x, y)).on(GOAL_SQUARE)
          self.cells[Point.new(x, y)] = GOAL_SQUARE
        when FLOOR
          self.cells[Point.new(x, y)] = FLOOR
        when GOAL_SQUARE
          self.cells[Point.new(x, y)] = GOAL_SQUARE
        end
      end
    end
  end

  def [](position)
    self.blocks.select{ |block| block.position == position }.first || EmptyBlock.new(position)
  end

  def move(block)
    Promise.new do |position|
      unless block.is_a? EmptyBlock
        self.blocks.delete(block)
        self.blocks << block.class.new(position).on(self.cells[position])
      end
    end
  end

  def to_s
    s = ''
    s += cells.map do |position, char|
      print_at(position) + char
    end.join
    s += blocks.map(&:to_s).join
    s
  end
end

field = Field.new
field.load(File.read('level1.txt'))

draw = -> do
  print field
  sleep 0.02
end

clear

draw.call()

loop do
  key = detect_key(read_char)
  case key
  when :up, :right, :down, :left
    player = field.player
    direction = key
    next_position = player.position.next(direction)
    following_position = next_position.next(direction)
    next_block = field[next_position]
    following_block = field[following_position]

    # puts field.blocks.inspect
    # puts next_position.inspect
    # puts following_position.inspect
    # puts next_block.inspect
    # puts following_block.inspect

    if player.can_be_moved_to(next_block) && next_block.can_be_moved_to(following_block)
      field.move(player).to(next_position)
      field.move(next_block).to(following_position)
      # field.move(player).to(first_position)
      # field.move(box).to(following_position)
    end
  when :control_c
    quit
  when :space
  end

  draw.call() if key
end