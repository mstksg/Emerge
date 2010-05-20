## This class handles all the genetic information for an eo, and handles mutation
## procedures as well.

require File.dirname(__FILE__)+"/../../lib/emerge/command_data.rb"
require File.dirname(__FILE__)+"/../../lib/utils/mutations.rb"

include Rubygame

class Eo_DNA
  
  @@_DEFAULT_COLORS = ["B22222","228B22","FFA500","87CEFA","0000CD",
                       "FFFF00","800080","00FF7F","D87093","32CD32",
                       "FA8072","FFC0CB","D2691E","A9A9A9","00FFFF",
                       "A52A2A"]
  
  @@DEFAULT_COLORS = @@_DEFAULT_COLORS.collect { |c| Array.new(3) { |n| c[n*2,2].to_i(16) } }
  
  @@COLOR_VAR = $MUTATION_FACTOR*$DNA_COLOR_VAR*100
  
  attr_reader :shell,:efficiency,:f_length,:f_strength,
              :b_containers,:b_programs,:birth_program,:color
  
  def initialize(shell,max_speed,efficiency,f_length,f_strength,
                 b_containers,b_programs,birth_program,color)
    @shell = shell
    @max_speed = max_speed
    @efficiency = efficiency
    @f_length = f_length
    @f_strength = f_strength
    @b_containers = Array.new(b_containers)
    @b_programs = Array.new(b_programs)
    @birth_program = birth_program.clone
    @color = color
  end
  
  def self.generate(shell=1,max_speed=1,efficiency=1,f_length=1,
                    f_strength=1,b_containers=[],b_programs=[Command_Block.fresh_block],
                    birth_program=Command_Block.blank_block)
    
        if @@DEFAULT_COLORS.size > 0
          new_color = @@DEFAULT_COLORS.pick_rand
          @@DEFAULT_COLORS.delete new_color
        else
          new_color = [rand*255,rand*255,rand*255]
        end
        
        return Eo_DNA.new(Mutations.rand_norm_dist(0,10*shell),
        Mutations.rand_norm_dist(0,10*max_speed),
        Mutations.rand_norm_dist(0,10*efficiency),
        Mutations.rand_norm_dist(0,10*f_length),
        Mutations.rand_norm_dist(0,10*f_strength),
        b_containers,b_programs,birth_program,
        new_color)
    
#    return Eo_DNA.new(Mutations.rand_norm_dist(0,10*shell),
#    Mutations.rand_norm_dist(0,10*max_speed),
#    Mutations.rand_norm_dist(0,10*efficiency),
#    Mutations.rand_norm_dist(0,10*f_length),
#    Mutations.rand_norm_dist(0,10*f_strength),
#    b_containers,b_programs,birth_program,
#    [rand*255,rand*255,rand*255])
  end
  
  def max_speed
    @max_speed / 4
  end
  
  def mutate!
    @shell = mutate_value @shell
    @max_speed = mutate_value @max_speed
    @efficiency = mutate_value @efficiency
    @f_length = mutate_value @f_length
    @f_strength = mutate_value @f_strength
    mutate_b_containers
    mutate_b_programs
    @birth_program.mutate!
    @color = Array.new(3) { |i| Mutations.mutate(@color[i],0,255,@@COLOR_VAR,2) }
    
    return self
  end
  
  def clone
    Eo_DNA.new(@shell,@max_speed,@efficiency,
               @f_length,@f_strength,Array.new(@b_containers),
    clone_b_programs,@birth_program.clone,Array.new(color))
  end
  
  def clone_b_programs
    Array.new(@b_programs.size) { |i| @b_programs[i].clone }
  end
  
  def mutate
    new_dna = clone
    new_dna.mutate!
  end
  
  def mutate_value curr
    if rand < $MUTATION_FACTOR
      return Mutations.mutate(curr)
    else
      return curr
    end
  end
  
  def mutate_b_containers
    
    for c in @b_containers
      if rand < $BRAIN_MUTATE_FACTOR/4
        @b_containers.delete c
        unless rand < $FORGET_FACTOR
          @b_containers << Mutations.mutate(c,0,80,7.5,5)
        else
          @b_programs.delete @b_programs.pick_rand
        end
      end
    end
    
    @b_containers.sort!
    
    if @b_containers.size < $CONTAINER_SIZE_LIMIT and rand < $BRAIN_MUTATE_FACTOR/3
      
      new_wall_spot = rand*80
      
      @b_containers << new_wall_spot
      @b_containers.sort!
      
      insert_spot = @b_containers.index(new_wall_spot)
      
      @b_programs.insert insert_spot+1, @b_programs[insert_spot].clone
      
    end
    
    
  end
  def mutate_b_programs
    
    for prog in b_programs
      
      prog.mutate!
      
    end
    
  end
  
  def inspect
    "#{inspect_physical}/#{inspect_color}/#{inspect_programs}"
  end
  def to_s
    inspect
  end
  
  def inspect_color
    "#{@color[0].to_s(16).rjust(2,'0')}#{@color[1].to_s(16).rjust(2,'0')}#{@color[2].to_s(16).rjust(2,'0')}"
  end
  
  def inspect_physical
    "#{@shell.to_i}#{@max_speed.to_i}#{@efficiency.to_i}#{@f_length.to_i}#{@f_strength.to_i}"
  end
  
  
  def inspect_programs
    if @b_containers.size == 0
      return "[b:#{@birth_program},0:#{@b_programs[0]}]"
    else
      inspected = "[b:#{@birth_program},0:"
      for i in 0...@b_containers.size
        inspected += "#{@b_programs[i]},#{@b_containers[i].to_i}:"
      end
      
      inspected += "#{@b_programs[-1]}]"
    end
  end
  
end

class Eo_Command
  include Command_Data
  
  
  attr_reader :command, :args
  
  def initialize command, args
    @command = command
    @args = args
  end
  
  def rand_params
    unless @command == :if
      return Array.new(args.size) { |i| pick_rand @@COMMAND_RANGES[@command][i] }
    else
      return [@args[0],@@IF_COMPS[rand(2)], pick_rand(@@IF_RANGES[@args[0]])]
    end
  end
  
  def mutate! total_size=nil
    if rand < $BRAIN_MUTATE_FACTOR
      unless @command == :if
        @args = Array.new(args.size) { |i|
          Mutations.mutate_percent(@args[i],
                                   @@COMMAND_RANGES[@command][i][0],
                                   @@COMMAND_RANGES[@command][i][1]) }
      else
        if rand(2) == 1
          @args = [@args[0],@@IF_COMPS[rand(2)], @args[2]]
        else
          @args = [@args[0],@args[1],
          Mutations.mutate_percent(@args[2],
                                   @@IF_RANGES[@args[0]][0]       ,
                                   @@IF_RANGES[@args[0]][1])       ]
        end
      end
    end
  end
  
  def randomize_params
    @args = rand_params
    return self
  end
  
  def pick_rand new_range
    return rand*(new_range[1]-new_range[0])+new_range[0]
  end
  
  def self.new_command
    pick = rand
    for command in @@POSSIBLE_COMMANDS
      if @@COMMAND_WEIGHTS[command] > pick
        unless command == :if
          new_command = Eo_Command.new command, Array.new(@@COMMAND_RANGES[command].size)
          return new_command.randomize_params
        else
          pick2 = rand
          for cond in @@POSSIBLE_IF_CONDS
            if @@IF_WEIGHTS[cond] > pick2
              new_command = Eo_Command.new command, [cond,nil,nil]
              return new_command.randomize_params
            else
              pick2 -= @@IF_WEIGHTS[cond]
            end
          end  
        end
      else
        pick -= @@COMMAND_WEIGHTS[command]
      end
    end
    raise "Some horrible error making a new command"
  end
  
  def clone
    Eo_Command.new(@command,Array.new(@args))
  end
  
  def inspect
    #    "(#{@command}:#{args.join(",")})"
    unless @command == :if
      return "#{@@ALIASES[@command]}"
    else
      return "f#{@@ALIASES[@args[0]]}"
    end
  end
  def to_s
    inspect
  end
  
  def command_length
    return 0.5 if @command == :if
    return 1
  end
  
end

class Command_Block < Array
  
  def make_top
    @top = true
  end
  
  def mutate! total_size=nil
    
    total_size = command_length unless total_size
    
    mutate_scale = 1
    forget_scale = 1
    
    if total_size
      if total_size < 3
        mutate_scale = 20/(total_size+1)
      elsif total_size > $PROGRAM_SIZE_LIMIT
        mutate_scale = $PROGRAM_SIZE_LIMIT/(total_size*2)
        forget_scale = total_size
      end
    end
    
    for b in self
      if rand < $FORGET_FACTOR*forget_scale
        self.delete b
        next
      end
      
      b.mutate! total_size
      
      if b.class == Command_Block and b.size == 0
        self.delete b
      end
    end
    
    if rand < $BRAIN_MUTATE_FACTOR*mutate_scale
      insert_spot = rand(self.size+1)
      if rand < 0.4
        self.insert insert_spot, Command_Block.new_block
      else
        self.insert insert_spot, Eo_Command.new_command
      end
      
    end
    
    
  end
  
  def self.new_block
    Command_Block.new([Eo_Command.new_command])
  end
  
  def self.blank_block
    Command_Block.new()
  end
  
  def clone
    Command_Block.new(self.size) { |i| self[i].clone }
  end
  
  def self.fresh_block iterations=$DNA_INITIAL_VARIANCE
    new_block = Command_Block.new([Eo_Command.new_command])
     (iterations/$BRAIN_MUTATE_FACTOR).to_i.times do
      new_block.mutate! 10
    end
    return new_block
  end
  
  def inspect
    str = "("
    for b in self
      str += b.inspect
    end
    str += ")"
  end
  def to_s
    inspect
  end
  
  def command_length
    count = 0
    for b in self
      count += b.command_length
    end
    return count
  end
  
end