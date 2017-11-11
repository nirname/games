#!/usr/bin/env ruby -W0

# 2. Place goals in the room.
# 3. Find the state farthest from the goal state.

# f - floor
# g - goal
# w - wall
# p - player
# b - box
# e - empty

class Block < Array
  # clock-wise
  def rotate(n = 1)
    i = n % 4
    chunk = self
    i.times {
      chunk = Block.new chunk.reverse.transpose
    }
    chunk
  end

  def to_s
    self.map(&:join).join("\n")
  end
end

chunks = File.read('blocks.txt').split(/\n{2,}/).compact

blocks = chunks.map do |chunk|
  Block.new chunk.split('/n').map{ |line| line.split('') }
end

# puts blocks.map(&:to_s).join("\n\n")

# 1. Build an empty room.


