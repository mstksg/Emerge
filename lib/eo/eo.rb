require "rubygems"
require "rubygame"

include Rubygame

class Eo
  include Sprites::Sprite
  
  attr_reader :body,:feeler,:energy,:age,:brain,:dna
  attr_accessor :pos,:velocity,:angle
  
  def graphic
    return @eo_graphic if @eo_graphic
    
    @eo_graphic = Surface.new([30,30],0)
    @eo_graphic.colorkey = [10,10,10]
    @eo_graphic.fill([10,10,10])
    
    @body.rect.center = [15,15]
    @body.draw(@eo_graphic)
    
    @feeler.rect.center = [15,5]
    @feeler.draw(@eo_graphic)
    
    return @eo_graphic
  end
  
  def initialize (environment,dna,energy=0,pos_x=0,pos_y=0,angle=0)
    
    super()
    
    @dna = dna
    
    @body = Eo_Body.new(self,@dna.shell,@dna.max_speed,@dna.efficiency)
    @feeler = Feeler.new(self,@dna.f_length,@dna.f_strength,@dna.f_sensitivity)
    @brain = Brain.new(self,@dna.b_containers,@dna.b_programs)
    
    @energy = energy
    @velocity = [0,0]
    @age = 0
    
    #    @facing_angle = 0
    @environment = environment
    @pos = [pos_x,pos_y]
    @angle = angle
    @angle_vect = Vector_Array.from_angle @angle
    
    @col_rect = Rect.new(0,0,10,10)
    
    update_rot
    set_rects
  end
  
  def set_rects
    @rect.center = Array.new(@pos)
    @col_rect.center = @rect.center
  end
  
  def update
    unless reproduce
      @body.recover_hp
      energy_decay
      update_pos
      set_rects
      
      handle_collisions
    end
  end
  
  def update_pos
    @pos = Array.new(2) { |i| @pos[i] + @velocity[i] }
    
    for i in 0..1
      
      if @pos[i] <= 0
        @pos[i] += @environment.game.size[i]
      elsif @pos[i] > @environment.game.size[i]
        @pos[i] -= @environment.game.size[i]
      end
      
    end
  end
  
  def update_rot
    
    @angle += 360 if @angle < 0
    @angle -= 360 if @angle >= 360
    
    @angle_vect = Vector_Array.from_angle @angle
    
    @image = graphic.rotozoom(@angle,1)
    @image.colorkey = [10,10,10]
    
    @rect = @image.make_rect
  end
  
  def feeler_triggered momentum
    @brain.process(momentum)
  end
  
  def handle_collisions
    handle_eo_collisions
    handle_food_collisions
  end
  
  def handle_eo_collisions
    collisions = @environment.eo_in_rect(@rect)
    if collisions.size > 0
      for other in collisions
        next if other == self
        
        
        ## Feeler collision testing
        ##    Later on, arrange these in order of least intense to most intense
        
        vec = Vector_Array.from_points(other.pos,@pos)
        if vec.magnitude <= @feeler.max_dist
          
          feeler_dist = @angle_vect.distance_to_point(other.pos,@pos)
          if feeler_dist < 10
            
            x_diff = other.pos[0] - @pos[0]
            if (x_diff > 0)&(@angle > 180)
              possible_collide = true
            elsif (x_diff < 0)&(@angle < 180)
              possible_collide = true
            else
              y_diff = other.pos[1]-@pos[1]
              if (y_diff > 0)&(@angle > 90)&(@angle < 270)
                possible_collide = true
              else
                possible_collide = (y_diff < 0)& ((@angle < 90) || (@angle > 270))
              end
            end
            
            if possible_collide
              @feeler.trigger momentum_magnitude ## maybe make directional somehow
              @feeler.poke other
            end
            
          end
          
        end
        
        
      end
    end
  end
  
  def handle_food_collisions
    collisions = @environment.food_in_rect(@col_rect)
    if collisions.size > 0
      for food in collisions
        
        vec = Vector_Array.from_points(food.pos,@pos)
        if vec.magnitude <= 5
          
          eat(food)
          
        end
        
      end
    end
  end
  
  def energy_decay
    ## Placeholder energy decay algorithm
    @energy *= 0.975 if @body.hp < @body.shell
    @energy -= (velo_magnitude+0.25)/(@body.efficiency*10+0.0001)
    if @energy < 0
      die
    end
  end
  
  def velo_magnitude
    Math.sqrt(@velocity[0]**2 + @velocity[1]**2)
  end
  
  def momentum_magnitude
    velo_magnitude*(@body.mass + @feeler.mass)
  end
  
  def move(angle,velocity)
    
  end
  
  def turn(angle)
    
  end
  
  def stop
    move(0,0)
  end
  
  def eat food
    collect_energy food.energy
    food.eaten
  end
  
  def collect_energy amount
    @energy += amount
  end
  
  def emit_energy amount, angle
    @energy -= amount
  end
  
  def poked poke_force, poker
    @body.poked poke_force, poker
  end
  
  def mutate new_energy=0
    new_dna = @dna.mutate
    return Eo.new(new_dna, new_energy)
  end
  
  def reproduce
    
    if (@energy > 15) & (rand*5000 < @energy)
      
      puts @energy
      puts @dna
      
      @energy -= (10-@body.efficiency)
      
      @environment.add_eo(@dna.mutate,@energy/2,@pos[0]+5,@pos[1]+5,rand*360)
      @environment.add_eo(@dna.mutate,@energy/2,@pos[0]-5,@pos[1]-5,rand*360)
      die
      
      return true
    end
    
    return false
  end
  
  def eaten
    @energy = 0
    die
  end
  
  def die
#    puts "alas! i am spent; (#{@energy},#{@body.hp})"
    @environment.remove_eo(self)
    kill
    ## more stuff later
  end
  
  def mass
    @body.mass + @feeler.mass
  end
  
end

class Eo_Body
  include Sprites::Sprite
  
  BODY_MASS = 10
  RECOVERY_CONSTANT = 0.01
  DAMAGE_CONSTANT = 1.0/4.0
  
  attr_reader :owner,:hp,:shell,:max_speed,:efficiency,:mass
  
  def graphic
    return @body_graphic if @body_graphic
    
    @body_graphic = Surface.new([10,10],0)
    @body_graphic.draw_circle_s([5,5],4.5,@owner.dna.dna_color)
    
    new_thick = 4.5-(@shell*0.45)
    #    new_thick = 0 if new_thick < 0
    
    @body_graphic.draw_circle_s([5,5],new_thick,[0,0,0])
    
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
  
  def poked poke_force, poker
    @hp -= poke_force*DAMAGE_CONSTANT
    if @hp < 0
      poker.eat @owner
    end
  end
  
end