#! /usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/goldy_lox"

runner = GoldyLox::Runner.new

print "GoldyLox REPL ready\n"
print "> "
while (line = gets)
  runner.run(line) unless line.strip.empty?
  print "> "
end
print "\n🖖\n"
