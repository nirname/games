#!/usr/bin/env ruby -W0

def clear
  system "clear && printf '\033[3J'"
end

def move_to(x, y)
  # puts the cursor at line L and column C.
  "\033[#{y + 1};#{x * 2 + 1}H"
end

Field = Struct.new :height, :length do
  def to_s
    (length + 2).times.map do |y|
      (height + 2).times.map  do |x|
        if x == 0 or x == length + 2 - 1
          '#'
        elsif y == 0 or y == height + 2 - 1
          '#'
        else
          ' '
        end
      end.join(' ')
    end.join("\n")
  end
end

Snake = Struct.new :body do
  def to_s
    s = []
    body[0..0].each do |(x, y)|
      s << move_to(x + 1, y + 1) + '@'
    end
    body[1..-1].each do |(x, y)|
      s << move_to(x + 1, y + 1) + 'o'
    end
    s.join
  end

  def step
    body.pop
    new_head = head.dup
    case dir
    when :right
      new_head[0] += 1
    when :left
      new_head[0] -= 1
    when :up
      new_head[1] += 1
    when :down
      new_head[1] -= 1
    end
    body.unshift new_head
  end

  def head
    body.first
  end

  def dir
    :right
  end
end

field = Field.new 10, 10
snake = Snake.new [[2, 0], [1, 0], [0, 0]]

loop do
  t1 = Time.now
  snake.step

  clear
  puts field
  puts snake

  puts move_to 0, 30
  p snake.body

  t2 = Time.now
  sleep 1.0 / 1.0 - (t2 - t1)
end