#!/usr/bin/env ruby -W0

def clear
  system "clear && printf '\033[3J'"
end

def move_to(x, y)
  "\033[#{y};#{x * 2}H"
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

  def move
    return if dead?
    body.pop
    body.unshift self.next
  end

  def eat
    return if dead?
    body.unshift self.next
  end

  def die
    @dead = true
  end

  def dead?
    @dead
  end

  def next
    _next = head.dup
    case direction
    when :right
      _next[0] += 1
    when :left
      _next[0] -= 1
    when :up
      _next[1] += 1
    when :down
      _next[1] -= 1
    end
    _next
  end

  def head
    body.first
  end

  def direction
    :right
  end

  def turn(direction)
    self.direction = direction
  end
end

field = Field.new 10, 10
snake = Snake.new [[3, 1], [2, 1], [1, 1]]
snake = Snake.new [[3, 1], [2, 1], [1, 1]]

draw = -> do
  clear
  print field
  print snake
end

debug = -> do
  print move_to 0, 14
  print "body: #{snake.body}"
end

def within(time)
  t1 = Time.now
  yield
  t2 = Time.now
  sleep time - (t2 - t1)
end

time = 0.5

within time do
  draw.call()
  debug.call()
end

def wall?
  lambda do |e|
    false
  end
end

def segment?
  lambda do |e|
    false
  end
end

def food?
  lambda do |e|
    false
  end
end

loop do
  within time do
    case snake.next
    when wall?
      snake.die
    when segment?
      snake.die
    when food?
      snake.eat
    else
      snake.move
    end

    draw.call()
    debug.call()
  end
end