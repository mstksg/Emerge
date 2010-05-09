## This class handles all the genetic information for an eo, and handles mutation
## procedures as well.

class Eo_DNA
  
  attr_reader :shell,:max_speed,:efficiency,:f_length,:f_strength,:f_sensitivity,:b_containers,:b_programs
  
  def initialize(shell,max_speed,efficiency,f_length,f_strength,f_sensitivity,b_containers,b_programs)
    @shell = shell
    @max_speed = max_speed
    @efficiency = efficiency
    @f_length = f_length
    @f_strength = f_strength
    @f_sensitivity = f_sensitivity
    @b_containers = b_containers
    @b_programs = b_programs
  end
  
  def dna_color
    return [0,0,0]
  end
  
  def mutate!
    mutate_shell
    mutate_speed
    mutate_efficiency
    mutate_f_length
    mutate_f_strength
    mutate_f_sensitivity
    mutate_b_containers
    mutate_b_programs
    
    return self
  end
  
  def mutate
    new_dna = self.clone()
    new_dna.mutate!
  end
  
  
  ## individual procedures for mutating each parameter
  def mutate_shell
    
  end
  def mutate_speed
    @max_speed *= 3
  end
  def mutate_efficiency
    
  end
  def mutate_f_length
    
  end
  def mutate_f_strength
    
  end
  def mutate_f_sensitivity
    
  end
  def mutate_b_containers
    
  end
  def mutate_b_programs
    
  end
  
end