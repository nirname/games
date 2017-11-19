#!/usr/bin/env ruby -W0

# 2. Place goals in the room.
# 3. Find the state farthest from the goal state.

# f - floor
# w - wall
# b - blank

seed = ARGV[0]
RANDOM = seed ? Random.new(seed.to_i) : Random.new
seed = RANDOM.seed
STDERR.puts "seed: #{seed}\n"

class Cell < String
  def overlaps?(other)
    [self, other].any?{ |cell| cell == 'b' }
  end

  def to_notation
    case self
    when 'f'
      ' '
    when 'w'
      '#'
    when 'b'
      '?'
    end
  end
end

class Border < Array
  def opposite
    map do |row|
      row.reverse
    end.reverse
  end

  def overlaps?(border)
    self.flatten.zip(border.flatten).all?{ |x, y| x.overlaps? y }
  end
end

class Block < Array
  # clock-wise
  def reverse
    Block.new super
  end

  def transpose
    Block.new super
  end

  def rotate(n = 1)
    i = n % 4
    block = self
    i.times {
      block = block.reverse.transpose
    }
    block
  end

  def flip(n = 1)
    i = n % 2
    block = self
    i.times {
      block = block.reverse
    }
    block
  end

  def top
    rotate 0
  end

  def right
    rotate 1
  end

  def bottom
    rotate 2
  end

  def left
    rotate 3
  end

  def border(n)
    Border.new first(n)
  end

  # random rotate or flip
  # central symmetry is the same as 180 degrees rotate is
  def randomize
    self.rotate(RANDOM.rand(4)).flip(RANDOM.rand(2))
  end

  def to_s
    self.map(&:join).join("\n")
  end

  def to_notation
    self.map do |row|
      row.map do |cell|
        cell.to_notation
      end.join
    end.join("\n")
  end

  def body
    Block.new self[1 ... -1].map{ |row| row[1 ... -1] }
  end
end

chunks = File.read('blocks.txt').split(/\n{2,}/).compact

blocks = chunks.map do |chunk|
  Block.new chunk.split("\n").map{ |line| line.split('').map{ |char| Cell.new char } }
end

BLANK_BLOCK = Block.new Array.new(5){ Array.new(5){ 'b' } }

b = Block.new ('a'..'z').to_a.first(25).each_slice(5).to_a

# puts b.to_s
# puts '---'
# puts b.rotate(2).to_s

# puts blocks.map(&:to_s).join("\n\n")

Field = Struct.new :width, :height do
  attr_accessor :blocks

  def initialize(width, height)
    self.blocks = Hash.new(BLANK_BLOCK)
    super
  end

  def fill
    field = self.dup
    height.times do |y|
      width.times do |x|
        field.blocks[[y, x]] = yield(y, x)
      end
    end
  end

  def accept?(block, y, x)
    right_block = blocks[[y, x + 1]]
    left_block = blocks[[y, x - 1]]
    bottom_block = blocks[[y + 1, x]]
    top_block = blocks[[y - 1, x]]

    block.right.border(2).overlaps?(right_block.left.border(2).opposite) &&
    block.top.border(2).overlaps?(top_block.bottom.border(2).opposite) &&
    block.bottom.border(2).overlaps?(bottom_block.top.border(2).opposite) &&
    block.left.border(2).overlaps?(right_block.right.border(2).opposite)
  end

  def to_block
    result = []

    blocks.each do |(y, x), block|
      block.body.each_with_index do |row, row_number|
        row.each_with_index do |cell, col_number|
          y_pos = y * 3 + row_number
          x_pos = x * 3 + col_number
          result[y_pos] ||= []
          result[y_pos][x_pos] = cell
        end
      end
    end

    Block.new result
  end

  def to_s
    to_block.to_s
  end

  def to_notation
    to_block.to_notation
  end
end

# 1. Build an empty room.

f = Field.new 2, 2

f.fill do |y, x|
  block = nil
  100.times do
    block = blocks.sample(random: RANDOM).randomize
    if f.accept?(block, y, x)
      break
    else
      block = nil
    end
  end
  if block
    block
  else
    STDERR.puts "Failed to generate level with seed #{seed}"
    exit 1
  end
end

puts f.to_notation