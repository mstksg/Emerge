require "rubygems"
require "rubygame"

include Rubygame

class Eo
  include Sprites::Sprite
  
  attr_reader :body,:feeler,:energy,:velocity,:age,:brain,:dna
  attr_accessor :pos,:angle
  
  def graphic
    return @eo_graphic if @eographic
    
    @eo_graphic = Surface.new([30,30],0)
    @eo_graphic.fill([10,10,10])
    
    @body.rect.center = [15,15]
    @body.draw(@eo_graphic)
    
    @feeler.rect.center = [15,5]
    @feeler.draw(@eo_graphic)
    
    @eo_graphic.colorkey = [10,10,10]
    
    return @eo_graphic
  end
  
  def initialize environment,dna,energy=0,pos_x=0,pos_y=0,angle=0
    @dna = dna
    
    @body = Eo_Body.new(self,@dna.shell,@dna.max_speed,@dna.efficiency)
    @feeler = Feeler.new(self,@dna.f_length,@dna.f_strength,@dna.f_sensitivity)
    @brain = Brain.new(self,@dna.b_containers,@dna.b_programs)
    
    @energy = energy
    @velocity = [0,0]
    @age = 0
    
    @facing_angle = 0
    @environment = environment
    @pos = [pos_x,pos_y]
    @angle = angle
    
    @image = graphic
    @rect = @image.make_rect
  end
  
  def update
    @body.recover_hp
    energy_decay
    @pos = Array.new(2) { |i| ar1[i] + ar2[i] }
#    draw
  end
  
#  def draw
#    @image.undraw(@environment.screen,@environment.background)
#    @rect.bottomright = Array.new(2) { |i| @pos[i] + 5}
#    @image.blit(@environment.screen,@rect)
#  end
  
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
  
  def collect_energy amount
    @energy += amount
  end
  
  def emit_energy amount, angle
    @energy -= amount
  end
  
  def poked poke_force
    @body.poked poke_force
  end
  
  def mutate new_energy=0
    new_dna = @dna.mutate
    return Eo.new(new_dna, new_energy)
  end
  
end

class Eo_Body
  include Sprites::Sprite
  
  BODY_MASS = 10
  RECOVERY_CONSTANT = 1.0/50.0
  DAMAGE_CONSTANT = 1.0/10.0
  
  attr_reader :owner,:hp,:shell,:max_speed,:efficiency,:mass
  
  def graphic
    return @body_graphic if @body_graphic
    
    @body_graphic = Surface.new([10,10],0)
    @body_graphic.draw_circle([5,5],4,[200,200,200])
    
    new_thick = 4-(@shell*0.5)
    new_thick = 0 if new_thick < 0
    
    @body_graphic.draw_circle([5,5],new_thick,[200,200,200])
    
    @body_graphic.colorkey = [0,0,0]
    
    return @body_graphic
  end
  
  def initialize owner, shell, max_speed, efficiency
    @owner = owner
    
    @shell = shell
    @max_speed = max_speed
    @efficiency = efficiency
    @mass = BODY_MASS
    
    @hp = @shell
    
    @image = graphic
    @rect = @image.make_rect
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