#!/usr/bin/env ruby -W0

# 1. Build an empty room.
# 2. Place goals in the room.
# 3. Find the state farthest from the goal state.

# f - floor
# g - goal
# w - wall
# p - player
# b - box
# e - empty

# blocks.yaml
# YAML magic
# http://yaml-multiline.info/
blocks = File.read('blocks.txt').split(/\n{2,}/).compact
p blocks