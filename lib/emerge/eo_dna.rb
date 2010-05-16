## This class handles all the genetic information for an eo, and handles mutation
## procedures as well.

class Eo_DNA
  
  attr_reader :shell,:efficiency,:f_length,:f_strength,:f_sensitivity,
              :b_containers,:b_programs
  
  def initialize(shell,max_speed,efficiency,f_length,f_strength,
                 f_sensitivity,b_containers,b_programs)
    @shell = shell
    @max_speed = max_speed
    @efficiency = efficiency
    @f_length = f_length
    @f_strength = f_strength
    @f_sensitivity = f_sensitivity
    @b_containers = Array.new(b_containers)
    @b_programs = Array.new(b_programs)
  end
  
  ## Maybe the genes average method is not the best. too centrally normative.
  def self.generate(shell=1,max_speed=1,efficiency=1,f_length=1,
                    f_strength=1,f_sensitivity=1,b_containers=[],b_programs=[Command_Block.fresh_block])
    return Eo_DNA.new(Mutations.rand_norm_dist(0,10*shell),
    Mutations.rand_norm_dist(0,10*max_speed),
    Mutations.rand_norm_dist(0,10*efficiency),
    Mutations.rand_norm_dist(0,10*f_length),
    Mutations.rand_norm_dist(0,10*f_strength),
    Mutations.rand_norm_dist(0,10*f_sensitivity),
    b_containers,b_programs)
  end
  
  def max_speed
    @max_speed / 4
  end
  
  def dna_color
    return [(@shell+@max_speed)*12.8,(@efficiency+@f_length)*12.8,(@f_strength+@f_sensitivity)*12.8]
  end
  
  def mutate!
    @shell = mutate_value @shell
    @max_speed = mutate_value @max_speed
    @efficiency = mutate_value @efficiency
    @f_length = mutate_value @f_length
    @f_strength = mutate_value @f_strength
    @f_sensitivity = mutate_value @f_sensitivity
    mutate_b_containers
    mutate_b_programs
    
    return self
  end
  
  def clone
    Eo_DNA.new(@shell,@max_speed,@efficiency,
               @f_length,@f_strength,@f_sensitivity,
               Array.new(@b_containers),clone_b_programs)
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
      if rand < $MUTATION_FACTOR/4
        @b_containers.delete c
        unless rand < $FORGET_FACTOR
          @b_containers << Mutations.mutate(c,0,80,7.5)
        else
          @b_programs.delete @b_programs.pick_rand
        end
      end
    end
    
    if rand < $MUTATION_FACTOR/3
      
      new_wall_spot = rand*80
      @b_containers << new_wall_spot
      
      
      insert_spot = rand(@b_programs.size+1)
      @b_programs.insert insert_spot, @b_programs.pick_rand.clone
    end
    
    @b_containers.sort!
    
    
  end
  def mutate_b_programs
    
    for prog in b_programs
      
      prog.mutate!
      
    end
    
  end
  
  def inspect
    "#{inspect_physical}/#{inspect_programs}"
  end
  def to_s
    inspect
  end
  
  def inspect_physical
    "#{@shell.to_i}#{@max_speed.to_i}#{@efficiency.to_i}#{@f_length.to_i}#{@f_strength.to_i}#{@f_sensitivity.to_i}"
  end
  
  
  def inspect_programs
    if @b_containers.size == 0
      return "[0:#{@b_programs[0]}]"
    else
      inspected = "[0:"
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
  
  def mutate!
    if rand < $MUTATION_FACTOR
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
  
end

class Command_Block < Array
  
  def make_top
    @top = true
  end
  
  def mutate!
    for b in self
      if rand < $FORGET_FACTOR
        self.delete b
        next
      end
      
      b.mutate!
      
      if b.class == Command_Block and b.size == 0
        self.delete b
      end
    end
    
    
    if rand < $MUTATION_FACTOR
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
  
  def clone
    Command_Block.new(self.size) { |i| self[i].clone }
  end
  
  def self.fresh_block iterations=2
    new_block = Command_Block.new([Eo_Command.new_command])
     (iterations/$MUTATION_FACTOR).to_i.times do
      new_block.mutate!
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
  
end