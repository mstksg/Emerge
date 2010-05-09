class Eo
  
  attr_reader :body,:feeler,:energy,:velocity,:age,:brain,:dna
  
  def initialize dna,energy=0
    @dna = dna
    
    @body = Eo_Body.new(self,@dna.shell,@dna.max_speed,@dna.efficiency)
    @feeler = Feeler.new(self,@dna.f_length,@dna.f_strength,@dna.f_sensitivity)
    @brain = Brain.new(self,@dna.b_containers,@dna.b_programs)
    
    @energy = energy
    @velocity = [0,0]
    @age = 0
  end
  
  def update
    @body.recover_hp
    energy_decay
  end
  
  def feeler_triggered momentum
    @brain.process(momentum)
  end
  
  def energy_decay
    ## Placeholder energy decay algorithm
   @energy *= 0.95 if @hp < @shell
    @energy -= velo_magnitude/efficiency
  end 
  
  def velo_magnitude
    Math.sqrt(velocity[0]**2 + velocity[1]**2)
  end
  
  def momentum_magnitude
    velo_magnitude*(body.mass + feeler.mass)
  end
  
  def move(angle,velocity)
    
  end
  
  def turn(angle)
    
  end
  
  def stop
    move(0,0)
  end
  
  def emit_energy
    
  end
  
  def poked poke_force
    @body.poked poke_force
  end
  
  def mutate new_energy = 0
    new_dna = @dna.mutate
    return Eo.new(new_dna, new_energy)
  end
  
end

class Eo_Body
  
  BODY_MASS = 10
  RECOVERY_CONSTANT = 1.0/50.0
  DAMAGE_CONSTANT = 1.0/10.0
  
  attr_reader :owner,:hp,:shell,:max_speed,:efficiency,:mass
  
  def initialize owner, shell, max_speed, efficiency
    @owner = owner
    
    @shell = shell
    @max_speed = max_speed
    @efficiency = efficiency
    @mass = BODY_MASS
    
    @hp = @shell
  end
  
  def recover_hp
    if @hp < @shell
      @hp += @shell*RECOVERY_CONSTANT
      if @hp > @shell
        @hp = @shell
      end
    end
  end
  
  def poked poke_force
    @hp -= poke_force*DAMAGE_CONSTANT
  end
  
end