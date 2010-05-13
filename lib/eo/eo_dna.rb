## This class handles all the genetic information for an eo, and handles mutation
## procedures as well.

class Eo_DNA
  
  attr_reader :b_containers,:b_programs
  
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
    shell_arr = rand_array(shell)
    max_speed_arr = rand_array(max_speed)
    efficiency_arr = rand_array(efficiency)
    f_length_arr = rand_array(f_length)
    f_strength_arr = rand_array(f_strength)
    f_sensitivity_arr = rand_array(f_sensitivity)
    
    
    return Eo_DNA.new(shell_arr,max_speed_arr,efficiency_arr,
                      f_length_arr,f_strength_arr,f_sensitivity_arr,
                      b_containers,b_programs)
  end
  
  def self.rand_array(scale=1, size=10)
    Array.new(size) { |i| rand*scale }
  end
  
  def sum_vars array
    return array.inject { |sum,n| sum+n }
  end
  
  def shell
    sum_vars @shell
  end
  def max_speed
    sum_vars(@max_speed) / 4
  end
  def efficiency
    sum_vars @efficiency
  end
  def f_length
    sum_vars @f_length
  end
  def f_strength
    sum_vars @f_strength
  end
  def f_sensitivity
    sum_vars @f_sensitivity
  end
  
  def dna_color
    return [(shell+max_speed)*12.8,(efficiency+f_length)*12.8,(f_strength+f_sensitivity)*12.8]
  end
  
  def mutate!
    @shell = mutate_array @shell
    @max_speed = mutate_array @max_speed
    @efficiency = mutate_array @efficiency
    @f_length = mutate_array @f_length
    @f_strength = mutate_array @f_strength
    @f_sensitivity = mutate_array @f_sensitivity
    mutate_b_containers
    mutate_b_programs
    
    return self
  end
  
  def clone
    Eo_DNA.new(Array.new(@shell),Array.new(@max_speed),
    Array.new(@efficiency),Array.new(@f_length),Array.new(@f_strength),
    Array.new(@f_sensitivity),Array.new(@b_containers),clone_b_programs)
  end
  
  def clone_b_programs
    Array.new(@b_programs.size) { |i| @b_programs[i].clone }
  end
  
  def mutate
    new_dna = clone
    new_dna.mutate!
  end
  
  def mutate_array array
    Array.new(array.size) do |i|
      if rand < $MUTATION_FACTOR
        rand
      else
        array[i]
      end
    end
  end
  
  def mutate_b_containers
    
    for c in @b_containers
      if rand < $MUTATION_FACTOR/4
        @b_containers.delete c
        unless rand < $FORGET_FACTOR
          new_c = c + rand*10-5
          if new_c > 80
            if @b_containers.include? 80
              new_c = 80-rand*10
            else
              new_c = 80
            end
          elsif new_c < 0
            if @b_containers.include? 0
              new_c = 0+rand*10
            else
              new_c = 0
            end
          end
          
          @b_containers << new_c
        else
          @b_programs.delete @b_programs.pick_rand
        end
      end
    end
    
    if rand < $MUTATION_FACTOR/5
      
      new_wall_spot = rand*80
      @b_containers << new_wall_spot
      
      
      insert_spot = rand(@b_programs.size+1)
      @b_programs.insert insert_spot, Command_Block.fresh_block   ## should probably be a better way
    end
    
    @b_containers.sort!
    
    
  end
  def mutate_b_programs
    
    for prog in b_programs
      
      prog.mutate!
      
    end
    
  end
  
  def inspect
    return [shell.to_i,(max_speed*4).to_i,efficiency.to_i,f_length.to_i,f_strength.to_i,f_sensitivity.to_i].to_s
  end
  def to_s
    inspect
  end
  
end

module Command_Data
  @@POSSIBLE_COMMANDS = [:move,:wait,:turn,:stop,:emit_energy,:multiply_speed,:set_speed,:if]
  @@COMMAND_WEIGHTS   = { :move           => 1.5,
                          :wait           => 1.0,
                          :turn           => 1.0,
                          :stop           => 0.5,
                          :emit_energy    => 0.5,
                          :multiply_speed => 0.5,
                          :set_speed      => 0.5,
                          :if             => 1.0 }
  @@COMMAND_WEIGHT_SUM= @@COMMAND_WEIGHTS.values.inject { |sum,n| sum+n }
  
  @@COMMAND_RANGES    = { :move           => [[-180,180],[0,1]]       ,
                          :wait           => [[0,300]]                ,
                          :turn           => [[-180,180]]             ,
                          :stop           => []                       ,
                          :emit_energy    => [[0,10],[-180,180],[1,6]],
                          :multiply_speed => [[0,2.5]]                ,
                          :set_speed      => [[0,1]]                   }
  
  @@POSSIBLE_IF_CONDS = [:energy,:age,:velocity,:momentum,:random]
  @@IF_WEIGHTS        = { :energy   => 1  ,
                          :age      => 0.5,
                          :velocity => 0.7,
                          :momentum => 0.5,
                          :random   => 0.2 }
  @@IF_WEIGHT_SUM     = @@IF_WEIGHTS.values.inject { |sum,n| sum+n }
  
  @@IF_RANGES         = { :energy   => [0,50]  ,    ## find ways to indicate tendency
                          :age      => [0,5000],
                          :velocity => [0,4]   ,
                          :momentum => [0,80]  ,
                          :random   => [0,1]    }
  @@IF_COMPS          = [:lt,:gt]
  
  
  for command in @@POSSIBLE_COMMANDS
    @@COMMAND_WEIGHTS[command] /= @@COMMAND_WEIGHT_SUM
  end
  for cond in @@POSSIBLE_IF_CONDS
    @@IF_WEIGHTS[cond] /= @@IF_WEIGHT_SUM
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
        max_min = rand(2)       ## average with either max or min; placeholder function.
                                ## still kinda normative though
        @args = Array.new(args.size) { |i| (@args[i]*2+@@COMMAND_RANGES[@command][i][max_min])/3 }
      else
        if rand(2) == 1
          @args = [@args[0],@@IF_COMPS[rand(2)], @args[2]]
        else
          max_min = rand(2)
          @args = [@args[0],@args[1], (@args[2]*2+@@IF_RANGES[@args[0]][max_min])/3]
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
      return "(#{@command})"
    else
      return "(#{@command} #{@args[0]})"
    end
  end
  def to_s
    inspect
  end
  
end

class Command_Block < Array
  
  def mutate!
    for b in self
      if rand < $FORGET_FACTOR
        self.delete b
      end
      b.mutate!
    end
    
    if rand < $MUTATION_FACTOR
      insert_spot = rand(self.size+1)
      if rand(2) == 0
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
  
  def self.fresh_block
    new_block = Command_Block.new([Eo_Command.new_command])
     (2/$MUTATION_FACTOR).to_i.times do
      new_block.mutate!
    end
    return new_block
  end
  
  def inspect
    str = "["
    for b in self
      str += b.inspect
    end
    str += "]"
  end
  def to_s
    inspect
  end
  
end