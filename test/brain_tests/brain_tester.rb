require File.dirname(__FILE__)+"/brain1.rb"
require File.dirname(__FILE__)+"/brain2.rb"
require File.dirname(__FILE__)+"/brain3.rb"

class Brain_Tester
  
  attr_reader :velo_magnitude, :age, :energy
  
  def initialize brain_type, command_block
    @brain = case brain_type
    when :brain_1 then Brain_1.new(self,[],[command_block.clone],[])
    when :brain_2 then Brain_2.new(self,[],[command_block.clone],[])
    when :brain_3 then Brain_3.new(self,[],[command_block.clone],[])
    end
    
    @velo_magnitude = 4
    @age = 100
    @energy = 23
    
  end
  
  def run_through
    @brain.process 1
    while @brain.has_commands?
      puts "." if $VERBOSE
      @brain.read_program
    end
  end
  
  def move a,v
    puts "moving #{a}@#{v}" if $VERBOSE
  end
  def wait t
    puts "waiting #{t}" if $VERBOSE
  end
  def turn a
    puts "turning #{a}"  if $VERBOSE
  end
  def stop
    puts "stopped!"  if $VERBOSE
  end
  def emit_energy e,a,v
    puts "emitting energy #{e}@#{a}@#{v}" if $VERBOSE
  end
  def multiply_speed f
    puts "multiplying speed by #{f}" if $VERBOSE
  end
  def set_speed s
    puts "setting speed to #{s}" if $VERBOSE
  end
  
end