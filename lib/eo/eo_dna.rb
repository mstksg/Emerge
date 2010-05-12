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
      f_strength=1,f_sensitivity=1,b_containers=[],b_programs=[""])
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
      Array.new(@f_sensitivity),Array.new(@b_containers),Array.new(@b_programs))
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
    
  end
  def mutate_b_programs
    
  end
  
  def to_s
    return [shell.to_i,(max_speed*4).to_i,efficiency.to_i,f_length.to_i,f_strength.to_i,f_sensitivity.to_i].to_s
  end
  
end