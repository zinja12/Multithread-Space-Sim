##########################################################################
### CMSC330 Project 5: Multi-threaded Space Simulation                 ###
### Source code: space.rb                                              ###
### Description: Multi-threaded Ruby program simulating space travel   ###
### Student Name: ??                                                   ###
##########################################################################

require "monitor"

Thread.abort_on_exception = true   # to avoid hiding errors in threads

#------------------------------------
# Global Variables

$headerPorts = "=== Starports ==="
$headerShips = "=== Starships ==="
$headerTraveler = "=== Travelers ==="
$headerOutput = "=== Output ==="

$simOut = []            # simulation output

$starport = []
$starship = []
$traveler = []

#----------------------------------------------------------------
# Starport
#----------------------------------------------------------------

class Starport

  attr_accessor :name, :size, :ships, :travelers

  def initialize (name,size)
    @name = name
    @size = size
    @ships = []
    @travelers = []
  end

  def to_s
    @name
  end

  def size
    @size
  end

  def arrive(person)
    @travelers.push(person)
  end
end

#------------------------------------------------------------------
# find_name(name) - find port based on name

def find_name(arr, name)
  arr.each { |p| return p if (p.to_s == name) }
  puts "Error: find_name cannot find #{name}"
  $stdout.flush
end

#------------------------------------------------------------------
# next_port(c) - find port after current port, wrapping around

def next_port(current_port)
  port_idx = $starport.index(current_port)
  if !port_idx
    puts "Error: next_port missing #{current_port}"
    $stdout.flush
    return  $starport.first
  end
  port_idx += 1
  port_idx = 0 if (port_idx >= $starport.length)
  $starport[port_idx]
end

#------------------------------------------------------------------
# last_port(c) - find the port after current port, wrapping around

def last_port(current_port)
  port_idx = $starport.index(current_port)
  if !port_idx
    puts "Error: next_port missing #{current_port}"
    $stdout.flush
    return $starport.first
  end
  port_idx -= 1
  port_idx = ($starport.size - 1) if (port_idx < 0)
  $starport[port_idx]
end

def sim_complete
  $traveler.each{ |t|
    if $starport.include?(t.most_rec_port)
      if t.most_rec_port != t.itinerary[t.itinerary.length - 1] || t.itinerary_pos != t.itinerary.size - 1
        return false
      end
    end
  }

  return true
end

#----------------------------------------------------------------
# Starship
#----------------------------------------------------------------

class Starship

  attr_accessor :name, :size, :passengers, :at_starport, :most_recent_port

  def initialize (name,size)
    @name = name
    @size = size
    @passengers = []
    @most_recent_port = "first"
  end

  def size
    @size
  end

  def to_s
    @name
  end
end


#----------------------------------------------------------------
# Traveler
#----------------------------------------------------------------

class Traveler

  attr_accessor :name, :itinerary, :most_rec_location, :boarded, :itinerary_pos, :most_rec_port

  def initialize(name, itinerary)
    @name = name
    @itinerary = itinerary
    @most_rec_location = nil
    @most_rec_port = itinerary[0]
    @idx_port = 0
    @itinerary_pos = 0
    @boarded = false
  end

  def to_s
    @name
  end

  def itinerary
    @itinerary
  end
end

#------------------------------------------------------------------
# read command line and decide on display(), verify() or simulate()

def readParams(fname)
  begin
    f = File.open(fname)
  rescue Exception => e
    puts e
    $stdout.flush
    exit(1)
  end

  section = nil
  f.each_line{|line|

    line.chomp!
    line.strip!
    if line == "" || line =~ /^%/
      # skip blank lines & lines beginning with %

    elsif line == $headerPorts || line == $headerShips ||
      line == $headerTraveler || line == $headerOutput
      section = line

    elsif section == $headerPorts
      parts = line.split(' ')
      name = parts[0]
      size = parts[1].to_i
      $starport.push(Starport.new(name,size))

    elsif section == $headerShips
      parts = line.split(' ')
      name = parts[0]
      size = parts[1].to_i
      $starship.push(Starship.new(name,size))

    elsif section == $headerTraveler
      parts = line.split(' ')
      name = parts.shift
      itinerary = []
      parts.each { |p| itinerary.push(find_name($starport,p)) }
      person = Traveler.new(name,itinerary)
      $traveler.push(person)
      find_name($starport,parts.first).arrive(person)

    elsif section == $headerOutput
      $simOut.push(line)

    else
      puts "ERROR: simFile format error at #{line}"
      $stdout.flush
      exit(1)
    end
  }
end

#------------------------------------------------------------------
#

def printParams()

  puts $headerPorts
  $starport.each { |s| puts "#{s} #{s.size}" }

  puts $headerShips
  $starship.each { |s| puts "#{s} #{s.size}" }

  puts $headerTraveler
  $traveler.each { |p| print "#{p} "
  p.itinerary.each { |s| print "#{s} " }
  puts }

  puts $headerOutput
  $stdout.flush
end

#----------------------------------------------------------------
# Simulation Display
#----------------------------------------------------------------

def array_to_s(arr)
  out = []
  arr.each { |p| out.push(p.to_s) }
  out.sort!
  str = ""
  out.each { |p| str = str << p << " " }
  str
end

def pad_s_to_n(s, n)
  str = "" << s
  (n - str.length).times { str = str << " " }
  str
end

def ship_to_s(ship)
  str = pad_s_to_n(ship.to_s,12) << " " << array_to_s(ship.passengers)
  str
end

def display_state()
  puts "----------------------------------------"
  $starport.each { |port|
    puts "#{pad_s_to_n(port.to_s,13)} #{array_to_s(port.travelers)}"
    out = []
    port.ships.each { |ship| out.push("  " + (ship_to_s(ship))) }
    out.sort.each { |line| puts line }
  }
  puts "----------------------------------------"
end


#------------------------------------------------------------------
# display - print state of space simulation

def display()
  display_state()
  $simOut.each {|o|
    puts o
    if o =~ /(\w+) (docking at|departing from) (\w+)/
      ship = find_name($starship,$1);
      action = $2;
      port = find_name($starport,$3);
      if (action == "docking at")
        #Ship is now at the port
        port.ships << ship
        ship.at_starport = true
        ship.most_recent_port = port
      else
        #Ship leaves the port
        port.ships.delete(ship)
        ship.at_starport = false
      end

    elsif o =~ /(\w+) (board|depart)ing (\w+) at (\w+)/
      person = find_name($traveler,$1);
      action = $2;
      ship = find_name($starship,$3);
      port = find_name($starport,$4);

      if (action == "board")
        #Traveler leaves the port
        port.travelers.delete(person)
        #Traveler boards the ship
        ship.passengers << person
        person.most_rec_location = ship
        person.boarded = true
      else
        #Passenger disembarks the ship
        ship.passengers.delete(person)
        #Traveler enters the star port
        port.travelers << person
        person.most_rec_port = port
        person.boarded = false
      end
    else
      puts "% ERROR Illegal output #{o}"
    end
    display_state()
  }
end

#------------------------------------------------------------------
# verify - check legality of simulation output

def verify
  validSim = true
  $simOut.each {|o|
    if o =~ /(\w+) (docking at|departing from) (\w+)/
      ship = find_name($starship,$1);
      action = $2;
      port = find_name($starport,$3);
=begin
      if (!$starports.include?(port) || !(0...($starports.length - 1)).include?($starports.index(port)))
        validSim = false
      end
=end
      if (action == "docking at")
        #Need to check for valid sim

        #Check for the wrong port
        if ship.most_recent_port != "first"
          if (port != next_port(ship.most_recent_port))
            validSim = false
          end
        end

        if port.ships.size >= port.size
          validSim = false
        end

        if ship.at_starport
          validSim = false
        end

        #Ship is now at the port
        port.ships << ship
        ship.at_starport = true
        ship.most_recent_port = port
      else
        #Need to check for valid sim

        if ship.most_recent_port != "first" && port != ship.most_recent_port
          validSim = false
        end

        if !port.ships.include?(ship)
          validSim = false
        end

        if !ship.at_starport
          validSim = false
        end

        #Ship leaves the port
        port.ships.delete(ship)
        ship.at_starport = false
      end
    elsif o =~ /(\w+) (board|depart)ing (\w+) at (\w+)/
      person = find_name($traveler,$1);
      action = $2;
      ship = find_name($starship,$3);
      port = find_name($starport,$4);

      if !port.ships.include?(ship)
        validSim = false
      end

      if (action == "board")
        #Need to check for valid sim

        #Check if the ship is at the gate
        if !port.ships.include?(ship)
          validSim = false
        end

        #Check if the ship should and is at the port
        if !ship.at_starport
          validSim = false
        end

        #Check if ship is filled
        if ship.passengers.size >= ship.size
          validSim = false
        end

        #Check if the person is already on the ship
        #Should not be already on the ship
        if person.boarded
          validSim = false
        end

        #Traveler leaves the port
        port.travelers.delete(person)
        #Traveler boards the ship
        ship.passengers << person
        person.boarded = true
        person.most_rec_location = ship
      else
        #Need to check for valid sim

        #Check if the ship should and is at the port
        if !ship.at_starport
          validSim = false
        end

        #Check if the ship is at the gate
        if !port.ships.include?(ship)
          validSim = false
        end

        if $starport.include?(person.most_rec_location)
          tmp_port = next_port(person.most_rec_location)
          tmp_idx = $starports.index(tmp_port)

          if port != person.itinerary[tmp_idx]
            validSim = false
          end
        end

        if !person.itinerary.include?(port)
          validSim = false
        end

        #Passenger disembarks the ship
        ship.passengers.delete(person)
        #Traveler enters the star port
        port.travelers << person
        person.most_rec_port = port
        person.boarded = false
        person.itinerary_pos += 1
      end
    else
      puts "% ERROR Illegal output #{o}"
    end
  }

  if !sim_complete
    validSim = false
  end

  return validSim
end

#------------------------------------------------------------------
# simulate - perform multithreaded space simulation

=begin
$port_locks = []
$port_conditions = []
$print_lock = nil

def dock (port, ship)
  port_idx = $starport.index(port)

  $port_locks[port_idx].synchronize{
    $port_conditions[port_idx].wait_while{
      port.ships.size >= port.size
    }
    port.ships << ship
    $print_lock.synchronize{
      print "#{ship.to_s} docking at #{port.to_s}\n"
      $stdout.flush
    }
    $port_conditions[port_idx].broadcast
  }
end

def depart (port, ship)
  port_indx = $starport.index(port)

  $port_locks[port_indx].synchronize{
    port.ships.delete(ship)
    $print_lock.synchronize{
      print "#{ship.to_s} departing from #{port.to_s}\n"
      $stdout.flush
    }
    $port_conditions[port_indx].broadcast
  }
end

def boarding (passenger, port)
  port_index = $starport.index(port)

  while !passenger.boarded
    $port_locks[port_index].synchronize{
      $port_conditions[port_index].wait_while{
        port.ships.size == 0
      }
      for w in 0...(port.ships.size)
        if port.ships[w].at_starport == true && port.ships[w].passengers.size < port.ships[w].size
          port.ships[w].passengers << passenger
          passenger.boarded = true
          passenger.most_rec_location = port.ships[w]
          $print_lock.synchronize{
            print "#{passenger.to_s} boarding #{port.ships[w].to_s} at #{port.to_s}\n"
            $stdout.flush
          }
        end
      end
      $port_conditions[port_index].broadcast
    }
  end
end

def disembark (passenger, port)
  port_ix = $starport.index(port)
  tmp_ship = passenger.most_rec_location

  $port_locks[port_ix].synchronize{
    $port_conditions[port_ix].wait_while{
      !port.ships.include?(tmp_ship)
    }
    tmp_ship.passengers.delete(passenger)
    passenger.boarded = false
    passenger.most_rec_port = port
    $print_lock.synchronize{
      print "#{passenger.to_s} departing #{tmp_ship.to_s} at #{port.to_s}\n"
      $stdout.flush
    }
    $port_conditions[port_ix].broadcast
  }
end

def simulate()
    create_port_locks($port_locks)
    create_port_conditions($port_locks, $port_conditions)
    $print_lock = Monitor.new

    ship_threads = []
    traveler_threads = []

    for u in 0...($starship.size)
      ship_threads << Thread.new{
        cur_port = $starport[$starport.length - 1]
        while(true)
          cur_port = next_port(cur_port)

          #Dock
          dock(cur_port, $starship[u])
          #Sleep
          sleep 0.001
          #Depart
          depart(cur_port, $starship[u])
        end
      }
    end

    for k in 0...($traveler.size)
      traveler_threads << Thread.new{
        if ($traveler[k].most_rec_port == $traveler[k].itinerary[$traveler[k].itinerary.size - 1])
          Thread.exit
        else
          curr_itinerary_pos = 0
          while($traveler[k].most_rec_port != $traveler[k].itinerary[$traveler[k].itinerary.size - 1])
            curr_port = $traveler[k].itinerary[curr_itinerary_pos]
            boarding($traveler[k], curr_port)
            curr_itinerary_pos += 1
            curr_port = $traveler[k].itinerary[curr_itinerary_pos]
            disembark($traveler, curr_port)
            sleep 0.001
          end
        end
        Thread.exit
      }
    end

    traveler_threads.each{ |tt|
      tt.join
    }
end
=end

def create_port_locks(array)
  for i in 0...($starport.size)
    array[i] = Monitor.new
  end
end

def create_port_conditions(locks, conditions)
  for i in 0...($starport.size)
    conditions[i] = locks[i].new_cond()
  end
end

Thread.abort_on_exception = true

def simulate()

  port_locks = []
  port_conditions = []
  print_lock = Monitor.new

  create_port_locks(port_locks)
  create_port_conditions(port_locks, port_conditions)

  ship_threads = []
  traveler_threads = []

  $starship.each{ |y|
    ship_threads << Thread.new{
      cur_location = $starport[$starport.length - 1]
      while(true)
        n_port = next_port(cur_location)
        cur_location = n_port

        port_idx = $starport.index(cur_location)

        #Dock
        port_locks[port_idx].synchronize{
          port_conditions[port_idx].wait_until{
            $starport[port_idx].ships.size < $starport[port_idx].size
          }
          $starport[port_idx].ships << y
          y.at_starport = true
          y.most_recent_port = $starport[port_idx]
          print_lock.synchronize{
            print "#{y.to_s} docking at #{$starport[port_idx].to_s}\n"
            $stdout.flush
          }
          port_conditions[port_idx].broadcast
        }

        #sleep
        sleep 0.001

        #Depart
        port_locks[port_idx].synchronize{
          $starport[port_idx].ships.delete(y)
          y.at_starport = false
          print_lock.synchronize{
            print "#{y.to_s} departing from #{$starport[port_idx].to_s}\n"
            $stdout.flush
          }
          port_conditions[port_idx].broadcast
        }
      end
    }
  }

=begin
  for i in 0...($starship.size)
    ship_threads << Thread.new{
      cur_location = $starport[$starport.length - 1]
      while(true)
        n_port = next_port(cur_location)
        cur_location = n_port

        port_idx = $starport.index(cur_location)

        #Dock
        port_locks[port_idx].synchronize{
          port_conditions[port_idx].wait_while{
            $starport[port_idx].ships.size == $starport[port_idx].size
          }
          $starport[port_idx].ships << $starship[i]
          $starship[i].at_starport = true
          $starship[i].most_recent_port = $starport[port_idx]
          print_lock.synchronize{
            print "#{$starship[i].to_s} docking at #{$starport[port_idx].to_s}\n"
            $stdout.flush
          }
          port_conditions[port_idx].broadcast
        }

        #sleep
        sleep 0.001

        #Depart
        port_locks[port_idx].synchronize{
          $starport[port_idx].ships.delete($starship[i])
          $starship[i].at_starport = false
          print_lock.synchronize{
            print "#{$starship[i].to_s} departing from #{$starport[port_idx].to_s}\n"
            $stdout.flush
          }
          port_conditions[port_idx].broadcast
        }
      end
    }
  end
=end

  $traveler.each{ |x|
      traveler_threads << Thread.new{
        if (x.itinerary_pos == x.itinerary.size - 1)
          Thread.exit
        end

        while (x.itinerary_pos != (x.itinerary.size - 1))
          curr_port = x.most_rec_port
          port_indx = $starport.index(curr_port)

          #Board
          if !x.boarded
            port_locks[port_indx].synchronize{
              port_conditions[port_indx].wait_while{
                $starport[port_indx].ships.size == 0
              }
              for o in 0...($starport[port_indx].ships.size)
                if $starport[port_indx].ships[o].at_starport && $starport[port_indx].ships[o].passengers.size < $starport[port_indx].ships[o].size
                  $starport[port_indx].ships[o].passengers << x
                  x.boarded = true
                  x.most_rec_location = $starport[port_indx].ships[o]
                  if $starport[port_indx].travelers.include?(x)
                    $starport[port_indx].travelers.delete(x)
                  end
                  print_lock.synchronize{
                    print "#{x.to_s} boarding #{$starport[port_indx].ships[o].to_s} at #{$starport[port_indx].to_s}\n"
                    $stdout.flush
                  }
                  break
                end
              end
              port_conditions[port_indx].broadcast
            }
          end

          #sleep
          sleep 0.001

          #Disembark
          if x.boarded
            nex_port = next_port(curr_port)
            next_port_idx = $starport.index(nex_port)

            #while !x.itinerary.include?($starport[next_port_idx])
            #  nex_port = next_port(nex_port)
            #  next_port_idx = $starport.index(nex_port)
            #end

            while nex_port != x.itinerary[x.itinerary_pos + 1]
              nex_port = next_port(nex_port)
              next_port_idx = $starport.index(nex_port)
            end

            port_locks[next_port_idx].synchronize{
              port_conditions[next_port_idx].wait_until{
                $starport[next_port_idx].ships.include?(x.most_rec_location)
              }
              x.most_rec_location.passengers.delete(x)
              x.most_rec_port = $starport[next_port_idx]
              x.boarded = false
              x.itinerary_pos += 1
              if !$starport[port_indx].travelers.include?(x)
                $starport[port_indx].travelers << x
              end
              print_lock.synchronize{
                print "#{x.to_s} departing #{x.most_rec_location.to_s} at #{$starport[next_port_idx].to_s}\n"
                $stdout.flush
              }
              port_conditions[next_port_idx].broadcast
            }
          end
        end
      }
  }
=begin
  for q in 0...($traveler.size)
    traveler_threads << Thread.new{
      if ($traveler[q].most_rec_port == $traveler[q].itinerary[$traveler[q].itinerary.size - 1])
        Thread.exit
      end

      while($traveler[q].most_rec_port != $traveler[q].itinerary[$traveler[q].itinerary.size - 1])
        curr_port = $traveler[q].most_rec_port
        port_indx = $starport.index(curr_port)

        #Board
        print "Current TRAVELER: #{$traveler[q].to_s}, Boarded: #{$traveler[q].boarded}\n"
        $stdout.flush
        if (!$traveler[q].boarded)
          port_locks[port_indx].synchronize{
            port_conditions[port_indx].wait_while{
              $starport[port_indx].ships.size == 0
            }
            for j in 0...($starport[port_indx].ships.size)
              if ($starport[port_indx].ships[j].passengers.size <
                $starport[port_indx].ships[j].size &&
                  $starport[port_indx].ships[j].at_starport)
                $starport[port_indx].ships[j].passengers << $traveler[q]
                $traveler[q].boarded = true
                $traveler[q].most_rec_location = $starport[port_indx].ships[j]
                print_lock.synchronize{
                  print "#{$traveler[q].to_s} boarding #{$starport[port_indx].ships[j].to_s} at #{$starport[port_indx].to_s}\n"
                  $stdout.flush
                }
              end
            end
            port_conditions[port_indx].broadcast
          }
        end

        #sleep
        sleep 0.001

        #Disembark

        if ($traveler[q].boarded)
          nex_port = next_port(curr_port)
          next_port_idx = $starport.index(nex_port)

          #ship_idx = $starship.index($traveler[q].most_rec_location)

          port_locks[next_port_idx].synchronize{
            port_conditions[next_port_idx].wait_while{
              #The most recent location is the ship that the traveler is on
              #Will not unlock until they get to a port to disembark
              !$starport[next_port_idx].ships.include?($traveler[q].most_rec_location)
            }
            $traveler[q].most_rec_location.passengers.delete($traveler[q])
            $traveler[q].boarded = false
            #$traveler[q].most_rec_location = $starport[next_port_idx]
            $traveler[q].most_rec_port = $starport[next_port_idx]
            print_lock.synchronize{
              print "#{$traveler[q].to_s} departing #{$traveler[q].most_rec_location.to_s} at #{$starport[next_port_idx].to_s}\n"
              $stdout.flush
            }
            port_conditions[next_port_idx].broadcast
          }
        end
      end
    }
  end
=end
  traveler_threads.each{ |tt|
    tt.join
  }

  #for r in 0...($traveler.size)
  #  print "#{$traveler[r].to_s}, #{$traveler[r].most_rec_port}\n"
  #end

end
#------------------------------------------------------------------
# main - simulation driver

def main
  if ARGV.length != 2
    puts "Usage: ruby space.rb [simulate|verify|display] <simFileName>"
    exit(1)
  end

  # list command line parameters
  cmd = "% ruby space.rb "
  ARGV.each { |a| cmd << a << " " }
  puts cmd

  readParams(ARGV[1])

  if ARGV[0] == "verify"
    result = verify()
    if result
      puts "VALID"
    else
      puts "INVALID"
    end

  elsif ARGV[0] == "simulate"
    printParams()
    simulate()

  elsif ARGV[0] == "display"
    display()

  else
    puts "Usage: space [simulate|verify|display] <simFileName>"
    exit(1)
  end
  exit(0)
end

main
