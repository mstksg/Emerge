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
    
    @food_triggered = []
    @eo_triggered = []
    
    
    @environment = environment
    @pos = [pos_x,pos_y]
    @angle = angle
    @angle_vect = Vector_Array.from_angle(270-@angle)
    
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
      
      @brain.read_program
      
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
    
    @angle_vect = Vector_Array.from_angle(270-@angle)
    
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
      
      for eo in @eo_triggered
        unless collisions.include? eo
          @eo_triggered.delete eo
        end
      end
      
      for other in collisions
        next if other == self
        
        
        ## Feeler collision testing
        ##    Later on, arrange these in order of least intense to most intense
        
        vec = Vector_Array.from_points(other.pos,@pos)
        if vec.magnitude <= @feeler.max_dist
          
          feeler_dist = @angle_vect.distance_to_point(other.pos,@pos)
          if feeler_dist <= 5
            
            if @angle_vect.dot(vec) <= 0
              diff = Vector_Array.new(velocity).sub(other.velocity).magnitude
              unless @eo_triggered.include? other
                @feeler.trigger other.mass*diff  ## maybe make directional somehow
              end
              @feeler.poke other
              @eo_triggered << other
            end
            
          end
          
        end
        
        
      end
    end
  end
  
  def handle_food_collisions
    collisions = @environment.food_in_rect(@col_rect)
    if collisions.size > 0
      
      for food in @food_triggered
        unless collisions.include? food
          @food_triggered.delete food
        end
      end
      
      for food in collisions
        
        
        vec = Vector_Array.from_points(food.pos,@pos)
        dist = vec.magnitude
        if dist <= 5
          
          eat(food)
          
        elsif dist < 7+@feeler.length and not @food_triggered.include? food
          
          feeler_dist = @angle_vect.distance_to_point(food.pos,@pos)
          if (feeler_dist < 3 or feeler_dist < velo_magnitude*2) and @angle_vect.dot(vec) <= 0 
            #            puts "bloop #{vec}, #{feeler_dist}, #{velo_magnitude}"
            @feeler.trigger food.mass*velo_magnitude
            @food_triggered << food
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
  
  def move angle,velocity_fraction
    move_angle = 270 - (@angle+angle)
    new_velo = velocity_fraction*@body.max_speed
    @velocity = [Math.d_cos(move_angle)*new_velo,Math.d_sin(move_angle)*new_velo]
  end
  
  def multiply_speed factor
    new_speed = velo_magnitude*factor
    if new_speed >= @body.max_speed
      set_speed 1
    else
      set_speed(new_speed/@body.max_speed)
    end
  end
  
  def set_speed velocity_fraction
    new_speed = @body.max_speed*velocity_fraction
    speed_frac = new_speed/velo_magnitude
    
    @velocity = Array.new(2) { |i| @velocity[i]*speed_frac }
  end
  
  def turn(angle)
    @angle += angle
    update_rot
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
  
  def emit_energy amount, angle, speed
    velo_vect = Vector_Array.new(@velocity)
    packet_angle_vect = Vector_Array.from_angle(270-(@angle+angle))
    packet_final_vect = packet_angle_vect.mult(speed).add(velo_vect)
    
    new_x = @pos[0] + packet_angle_vect[0]*7
    new_y = @pos[1] + packet_angle_vect[1]*7
    
    @environment.add_packet amount, new_x, new_y, packet_final_vect.magnitude, packet_final_vect.angle 
    
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
    return @mass if @mass
    @mass = @body.mass + @feeler.mass
  end
  
end

class Eo_Body
  include Sprites::Sprite
  
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