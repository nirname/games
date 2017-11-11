#!/usr/bin/env ruby -W0

# 2. Place goals in the room.
# 3. Find the state farthest from the goal state.

# f - floor
# g - goal
# w - wall
# p - player
# b - box
# e - empty

BLOCK_SIZE = 3

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

  # random rotate or flip
  # central symmetry is the same as 180 degrees rotate is
  def randomize
    self.rotate(rand(4)).flip(rand(2))
  end

  def to_s
    self.map(&:join).join("\n")
  end
end

chunks = File.read('blocks.txt').split(/\n{2,}/).compact

blocks = chunks.map do |chunk|
  Block.new chunk.split("\n").map{ |line| line.split('') }
end

b = Block.new ('a'..'z').to_a.first(25).each_slice(5).to_a
# puts b.to_s
# puts '---'
# puts b.rotate(2).to_s

# puts blocks.map(&:to_s).join("\n\n")

Field = Struct.new :width, :height, :blocks do
  def initialize(width, height, blocks = [])
    super
  end

  def fill
    field = self.dup
    height.times do |y|
      field.blocks[y] ||= []
      width.times do |x|
        field.blocks[y][x] = yield(x, y)
      end
    end
  end

  def to_s
    height.times.map do |y|
      BLOCK_SIZE.times.map do |l|
        width.times.map do |x|
          blocks[y][x][l][1 .. BLOCK_SIZE].join
        end.join
      end.join("\n")
    end.join("\n")
  end
end

# 1. Build an empty room.

f = Field.new 3, 3

# 2. Fill in
f.fill do |x, y|
  blocks.sample.randomize
end
puts f.to_s