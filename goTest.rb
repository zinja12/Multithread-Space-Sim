#!/usr/bin/env ruby

for t in 1..6 do
	cmd = "ruby space.rb display public#{t}.in > public#{t}_display.log"
        puts "TESTING: #{cmd}"
        system(cmd)
end

for t in 1..7 do
	cmd = "ruby space.rb verify public#{t}.in > public#{t}_verify.log"
        puts "TESTING: #{cmd}"
        system(cmd)
end

for t in 1..6 do
	cmd = "ruby space.rb simulate public#{t}.in > public#{t}_simulate.log"
        puts "TESTING: #{cmd}"
        system(cmd)
end

