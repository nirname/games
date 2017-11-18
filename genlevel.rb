#!/usr/bin/env ruby -W0

# 2. Place goals in the room.
# 3. Find the state farthest from the goal state.

# f - floor
# g - goal
# w - wall
# p - player
# b - box
# e - empty

seed = ARGV[0]
RANDOM = seed ? Random.new(seed.to_i) : Random.new
seed = RANDOM.seed
STDERR.puts "seed: #{seed}\n"

# Block size without border
BLOCK_SIZE = 3

class Border < Array
  def opposite
    map do |row|
      row.reverse
    end.reverse
  end

  def overlaps?(border)
    border
    true
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
end

chunks = File.read('blocks.txt').split(/\n{2,}/).compact

blocks = chunks.map do |chunk|
  Block.new chunk.split("\n").map{ |line| line.split('') }
end

EMPTY_BLOCK = Block.new Array.new(5){ Array.new(5){ 'e' } }

b = Block.new ('a'..'z').to_a.first(25).each_slice(5).to_a

# puts b.to_s
# puts '---'
# puts b.rotate(2).to_s

# puts blocks.map(&:to_s).join("\n\n")

Field = Struct.new :width, :height do
  attr_accessor :blocks

  def initialize(width, height)
    self.blocks = Hash.new(EMPTY_BLOCK)
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

  def to_s
    height.times.map do |y|
      BLOCK_SIZE.times.map do |l|
        width.times.map do |x|
          self.blocks[[y, x]][l][1 .. BLOCK_SIZE].join
        end.join
      end.join("\n")
    end.join("\n")
  end
end

# 1. Build an empty room.

f = Field.new 3, 3

# 2. Fill in

f.fill do |y, x|
  block = blocks.sample(random: RANDOM).randomize
  while(!f.accept?(block, y, x)) do
    block = blocks.sample(random: RANDOM).randomize
  end
  block
end

puts f.to_s