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
    @age += 1
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
          if feeler_dist <= 5
            
            feel_vect = Vector_Array.from_angle(@angle+90)
            if feel_vect.dot(vec) < 1
              diff = Vector_Array.new(velocity).sub(other.velocity).magnitude
              @feeler.trigger other.mass*diff  ## maybe make directional somehow
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
        dist = vec.magnitude
        if dist <= 5
          
          eat(food)
          
        elsif dist <= 6+@feeler.length
          
          feeler_dist = @angle_vect.distance_to_point(food.pos,@pos)
          if feeler_dist < 1.5
            @feeler.trigger food.mass*velo_magnitude
          end
          
          
        end
        
      end
    end
  end
  
  def energy_decay
    ## Placeholder energy decay algorithm
    @energy *= $HEAL_DRAIN if @body.hp < @body.shell
    @energy -= (velo_magnitude+0.2)/(@body.efficiency*20+0.1)   ## find out way to un-hardcode
    if @energy < 0
      puts "#{@age}; drain"
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
    ## maybe have food wasted?
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
    
    if (@energy > $REP_THRESHOLD) & (rand*$REP_RATE < @energy)
      
      puts "#{@dna}, #{@energy}, #{@age}"
      
      @energy -= (5-@body.efficiency/2)
      
      @environment.add_eo(@dna.mutate,@energy/2,@pos[0]+5,@pos[1]+5,rand*360)
      @environment.add_eo(@dna.mutate,@energy/2,@pos[0]-5,@pos[1]-5,rand*360)
      die
      
      return true
    end
    
    return false
  end
  
  def eaten
    puts "#{@age}; eaten (#{@energy})"
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
  
  DAMAGE_CONSTANT = 1.0/5.0
  
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
    @mass = $B_MASS
    
    @hp = @shell
    
    @image = graphic
    @rect = @image.make_rect
  end
  
  def recover_hp
    if @hp < @shell
      @hp += @shell*$B_RECOVERY
      if @hp > @shell
        @hp = @shell
      end
      
    end
  end
  
  def poked poke_force, poker
    @hp -= poke_force*$B_DAMAGE
    if @hp < 0
      poker.eat @owner
    end
  end
  
end