require "rubygems"
require "rubygame"

include Rubygame

class Eo
  include Sprites::Sprite
  
  @@count = 0
  
  attr_reader :body,:feeler,:energy,:age,:brain,:dna,:angle,
              :velocity,:velo_magnitude,:mass,:id,:generation
  attr_accessor :pos
  
  def initialize (pond,dna,energy=0,pos_x=0,pos_y=0,angle=0,generation=1)
    
    @id = @@count.to_s(36)
    @@count += 1
    @generation = generation
    
    super()
    
    @dna = dna
    
    @body = Eo_Body.new(self,@dna.shell,@dna.max_speed,@dna.efficiency)
    @feeler = Feeler.new(self,@dna.f_length,@dna.f_strength)
    @brain = Brain.new(self,@dna.b_containers,@dna.b_programs,@dna.birth_program)
    
    @mass = @feeler.mass + @body.mass
    @energy = energy
    set_velocity [0,0]
    @age = 0
    
    @food_triggered = []
    @eo_triggered = []
    
    
    @pond = pond
    @pos = [pos_x,pos_y]
    @angle = angle
    @angle_vect = Vector_Array.from_angle(270-@angle)
    
    @col_rect = Rect.new(0,0,10,10)
    
    set_angle @angle
    set_rects
    
    $LOGGER.info "Eo_#{@id}\tBorn (g#{@generation});\t#{@dna}"
    
    @brain.run_birth_program
  end
  
  def graphic
    return @eo_graphic if @eo_graphic
    
    @eo_graphic = Surface.new([30,30],0)
    @eo_graphic.colorkey = [10,10,10]
    @eo_graphic.fill([10,10,10])
    
    @body.rect.center = [15,15]
    @body.draw(@eo_graphic)
    
    @feeler.rect.center = [15,5]
    @feeler.draw(@eo_graphic)
    
    @eo_graphic = @eo_graphic.to_display
    
    return @eo_graphic
  end
  
  def set_rects
    @rect.center = Array.new(@pos)
    @col_rect.center = @rect.center
  end
  
  def update
    @age += 1
    unless replicate
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
      
      @pos[i] = @pos[i].boundarize(0,@pond.environment.size[i],false,true)
      
    end
  end
  
  def set_velocity velo
    @velocity = Vector_Array.new(velo)
    @velo_magnitude = @velocity.magnitude
  end
  
  def set_angle angle
    
    @angle = angle
    
    @angle += 360 if @angle < 0
    @angle -= 360 if @angle >= 360
    
    @angle_vect = Vector_Array.from_angle(270-@angle)
    
    @image = graphic.rotozoom(@angle,1)
    @image.colorkey = [10,10,10]
    
    @rect = @image.make_rect
  end
  
  def add_angle added_angle
    set_angle @angle+added_angle
  end
  
  def feeler_triggered momentum
    @brain.process(momentum)
  end
  
  def handle_collisions
    handle_eo_collisions
    handle_food_collisions
  end
  
  def handle_eo_collisions
    collisions = @pond.find_possible_eo_collisions self
    if collisions.size > 0
      
      for eo in @eo_triggered
        @eo_triggered.delete eo unless collisions.include? eo
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
              diff = Vector_Array.new(velocity).sub(other.velocity).magnitude+0.1
              unless @eo_triggered.include? other
                feeler_triggered(other.mass*diff)
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
    collisions = @pond.find_possible_food_collisions self
    if collisions.size > 0
      
      for food in @food_triggered
        @food_triggered.delete food unless collisions.include? food
      end
      
      for food in collisions
        
        
        vec = Vector_Array.from_points(food.pos,@pos)
        dist = vec.magnitude
        if dist <= 5
          
          eat(food)
          food.eaten
          
        elsif dist < 7+@feeler.length and not @food_triggered.include? food
          
          feeler_dist = @angle_vect.distance_to_point(food.pos,@pos)
          if (feeler_dist < 3 or feeler_dist < @velo_magnitude*2) and @angle_vect.dot(vec) <= 0 
            feeler_triggered(food.mass*@velo_magnitude+0.1)
            @food_triggered << food
          end
          
          
        end
        
      end
    end
  end
  
  def energy_decay
    @energy *= $HEAL_DRAIN if @body.hp < @body.shell
    @energy -= (@velo_magnitude+0.2)/(@body.efficiency*20+0.1)   ## find out way to un-hardcode
    if @energy < 0
      $LOGGER.info "Eo_#{@id}\tStarved;\ta#{@age}"
      die
    end
  end
  
  def momentum_magnitude
    @velo_magnitude*@mass
  end
  
  def eat food
    ## maybe have food wasted?
    collect_energy food.energy
    #    food.eaten
  end
  
  def collect_energy amount
    @energy += amount
  end
  
  def poked poke_force, poker
    @body.poked poke_force, poker
  end
  
  def mutate new_energy=0
    new_dna = @dna.mutate
    return Eo.new(new_dna, new_energy)
  end
  
  def replicate
    
    if (@energy > $REP_THRESHOLD) & (rand*$REP_RATE < @energy)
      
      $LOGGER.info "Eo_#{@id}\tReplicates;\ta#{@age}, e#{@energy.to_i}"
      
      @energy -= (5-@body.efficiency/2)
      
#      ortho = @velocity.ortho_2D.mult(0.5)
#      
#      left_disp = @velocity.sub(ortho).normalize.mult(10).add(@pos)
#      right_disp = @velocity.add(ortho).normalize.mult(10).add(@pos)
#      
#      #      curr_dir = Math.d_atan(@velocity[1]/@velocity[0])
#      #      angle_disp = curr_dir+@angle-270    # curr_dir - (270 - @angle)
#      
#      speed_frac = @velo_magnitude/@body.max_speed
#      
#      velo_unit = @velocity.unit_vector
#      angle_disp = Math.d_acos(@angle_vect.dot(velo_unit))
#      
#      move_angle = 270 - (@angle+angle_disp)
#      test_velo = Vector_Array.new([Math.d_cos(move_angle)*@velo_magnitude,
#                                    Math.d_sin(move_angle)*@velo_magnitude])
#      
#      $LOGGER.info angle_disp
#      $LOGGER.info test_velo
#      $LOGGER.info velo_unit
#      if test_velo != velo_unit
#        angle_disp *= -1
#      end
#      
#      @pond.add_eo(@dna.mutate,@energy/2,left_disp[0],left_disp[1],
#                   @angle+30,@generation+1,-angle_disp,speed_frac)
#      @pond.add_eo(@dna.mutate,@energy/2,right_disp[0],right_disp[1],
#                   @angle-30,@generation+1,angle_disp,speed_frac)
#      die
      
            @pond.add_eo(@dna.mutate,@energy/2,@pos[0]+5,@pos[1]+5,rand*360,@generation+1)
            @pond.add_eo(@dna.mutate,@energy/2,@pos[0]-5,@pos[1]-5,rand*360,@generation+1)
            die
      
      return true
    end
    
    return false
  end
  
  def move angle,velocity_fraction
    move_angle = 270 - (@angle+angle)
    new_velo = velocity_fraction*@body.max_speed
    set_velocity [Math.d_cos(move_angle)*new_velo,Math.d_sin(move_angle)*new_velo]
  end
  
  def multiply_speed factor
    unless @velo_magnitude == 0
      new_speed = @velo_magnitude*factor
      if new_speed >= @body.max_speed
        set_speed 1
      else
        set_speed(new_speed/@body.max_speed)
      end
    end
  end
  
  def set_speed velocity_fraction
    if @velo_magnitude == 0
      move(0,velocity_fraction)
    else
      new_speed = @body.max_speed*velocity_fraction
      speed_frac = new_speed/@velo_magnitude
      
      set_velocity = Array.new(2) { |i| @velocity[i]*speed_frac }
    end
  end
  
  def turn(angle)
    add_angle angle
  end
  
  def stop
    move(0,0)
  end
  
  def emit_energy amount, angle, speed
    velo_vect = Vector_Array.new(@velocity)
    packet_angle_vect = Vector_Array.from_angle(270-(@angle+angle))
    packet_final_vect = packet_angle_vect.mult(speed).add(velo_vect)
    
    new_x = @pos[0] + packet_angle_vect[0]*7
    new_y = @pos[1] + packet_angle_vect[1]*7
    
    @pond.add_packet amount, new_x, new_y, packet_final_vect.magnitude, packet_final_vect.angle 
    
    @energy -= amount
  end
  
  def eaten
    @energy = 0
    die
  end
  
  def die
    @pond.remove_eo(self)
    kill
  end
  
  def inspect
    to_s
  end
  def to_s
    "Eo_#{@id}"
  end
  
end

class Eo_Body
  include Sprites::Sprite
  
  attr_reader :owner,:hp,:shell,:max_speed,:efficiency,:mass
  
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
  
  def graphic
    return @body_graphic if @body_graphic
    
    @body_graphic = Surface.new([10,10],0)
    @body_graphic.draw_circle_s([5,5],4.5,@owner.dna.color)
    
    new_thick = 4.5-(@shell*0.45)
    #    new_thick = 0 if new_thick < 0
    
    @body_graphic.draw_circle_s([5,5],new_thick,[0,0,0])
    
    @body_graphic.colorkey = [0,0,0]
    
    @body_graphic = @body_graphic.to_display
    
    return @body_graphic
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
      @owner.eaten
      $LOGGER.info "Eo_#{@owner.id}\tEaten by Eo_#{poker.id};\ta#{@owner.age}, e#{@owner.energy.to_i}"
    end
  end
  
  def inspect
    to_s
  end
  def to_s
    "Body of #{@owner.to_s}; #{@shell.to_i}#{@max_speed.to_i}#{@efficiency.to_i}"
  end
  
end

class Feeler
  include Sprites::Sprite
  
  attr_reader :owner, :length, :strength, :mass
  
  def initialize owner, length, strength
    
    super()
    
    @owner = owner
    
    raise "Maximum length is 10 (given #{length})" if length > 10
    
    @length = length
    @strength = strength
    @mass = length*strength*$F_MASS    # define this more later on
    
    @image = graphic
    @rect = @image.make_rect
  end
  
  def graphic
    return @f_graphic if @f_graphic
    
    pen_thickness = (@strength/2).to_i
    pen = Surface.new([pen_thickness,pen_thickness],0)
    pen.fill([100,100,100])
    
    
    #    pen.draw_circle_s([pen_thickness/2,pen_thickness/2],pen_thickness/2,[100,100,100])
    
    @f_graphic = Surface.new([10,10],0)
    @f_graphic.fill([0,0,0])
    
    @f_graphic.colorkey = [0,0,0]
    
    y_pos = 10
    
    while y_pos > 10-length
      pen.blit(@f_graphic,[5-pen_thickness/2,y_pos])
      y_pos -= 0.25
    end
    
    @f_graphic = @f_graphic.to_display
    
    return @f_graphic
  end
  
  def max_dist
    return @max_dist if @max_dist
    @max_dist = (100+(@length+5)*(@length+5))**0.5
  end
  
  def trigger momentum
    @owner.feeler_triggered(felt_momentum)
  end
  
  def poke target
    # should be poking an Eo
    diff = Vector_Array.new(@owner.velocity).sub(target.velocity).magnitude
    poke_force = @strength*(diff+0.2)*$F_POKE
    target.poked(poke_force,@owner)
  end
  
  def inspect
    to_s
  end
  def to_s
    "Feeler of #{@owner.to_s}; #{@f_length.to_i}#{@f_strength.to_i}"
  end
  
end