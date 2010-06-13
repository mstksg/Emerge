require "rubygems"
require "rubygame"

include Rubygame

class Eo
  include Sprites::Sprite
  
  @@HEAL_DRAIN_OFFSET = ($HEAL_DRAIN_MAX-$HEAL_DRAIN_MIN)/10
  
  @@count = 0
  
  attr_reader :body,:feeler,:energy,:age,:brain,:dna,:angle,
              :velocity,:velo_magnitude,:mass,:id,:generation,
              :death_cause,:angle_vect
  attr_accessor :pos,:followed
  
  def initialize (pond,dna,energy=0,pos_x=0,pos_y=0,angle=0,generation=1)
    
    @id = @@count.to_s(36)
    @@count += 1
    @generation = generation
    
    super()
    
    @dna = dna
    
    @body = Eo_Body.new(self,@dna.shell,@dna.max_speed,@dna.efficiency)
    @feeler = Feeler.new(self,@dna.f_length,@dna.f_strength)
    @brain = Brain.new(self,@dna.b_containers,@dna.b_programs,@dna.birth_program,@dna.c_program)
    
    @mass = @feeler.mass + @body.mass
    @energy = energy
    set_velocity [0,0]
    @age = 0
    
    @food_triggered = []
    @eo_triggered = []
    
    @total_heal_drain = $HEAL_DRAIN_MIN+@body.efficiency*@@HEAL_DRAIN_OFFSET
    @total_rep_rate = ($REP_RATE*((1-$REP_VARIANCE/2)+$REP_VARIANCE*@dna.efficiency/10))**$REP_RATE_DEGREE
    @total_rep_threshold = ($REP_MAXIMUM-$REP_MINIMUM)*@dna.efficiency/10 + $REP_MINIMUM
    @total_mass_drag = @mass * $MASS_DRAG/(5*$B_MASS_FACTOR+5*$F_MASS) / (@body.efficiency*$BASE_DRAG_REDUCTOR+0.1)
    
    
    @pond = pond
    @pos = [pos_x,pos_y]
    @angle = angle
    @angle_vect = Vector_Array.from_angle(270-@angle)
    
    @col_rect = Rect.new(0,0,10,10)
    
    set_angle @angle
    set_rects
    
    log_message "Eo_#{@id}\tBorn (g#{@generation});\t#{@dna}"
    
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
    @pos = Array.new(2) { |i| (@pos[i] + @velocity[i])%@pond.environment.size[i] }
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
  
  def movement_angle
    return (270-@velocity.angle-@angle)%360
  end
  
  def add_angle added_angle
    set_angle @angle+added_angle
  end
  
  # def feeler_triggered momentum
    # @brain.process_feeler(momentum)
  # end
  
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
        dist = vec.magnitude
        if dist <= @feeler.max_dist
          
          feeler_dist = @angle_vect.distance_to_point(other.pos,@pos)
          if feeler_dist <= 5
            
            if @angle_vect.dot(vec) <= 0
              diff = Vector_Array.new(velocity).sub(other.velocity).magnitude+0.1
              unless @eo_triggered.include? other
                # feeler_triggered(other.mass*diff)
                @brain.process_feeler(other.mass*diff)
              end
              @feeler.poke other
              @eo_triggered << other
            end
            
          end
          
        end
        
        if dist <= 8
          self_displace = determine_newtonian_collision other
          other_displace = other.determine_newtonian_collision self
          
          execute_newtonian_collision self_displace
          other.execute_newtonian_collision other_displace
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
            # feeler_triggered(food.mass*@velo_magnitude+0.1)
            @brain.process_feeler(food.mass*@velo_magnitude+0.1)
            @food_triggered << food
          end
          
          
        end
        
      end
    end
  end
  
  def determine_newtonian_collision other
    unless @velo_magnitude == 0
      
      diff = Vector_Array.from_points(other.pos,@pos)
      normal = diff.unit_vector.ortho_2D
      new_velo = normal.mult(2*(@velocity.dot(normal))).sub(@velocity)
      
      new_velo = new_velo.mult(-1) if (new_velo.dot diff) < 0
      
      @brain.process_collision(diff.mult(-1).angle_to(@angle_vect))
      
      set_velocity(new_velo)
      
      return new_velo.unit_vector.mult((10-diff.magnitude)/2) ## initial displacement
                                                              ## only 1/2, because both are displaced equally
    else
      return Vector_Array.from_array([0,0])
    end
  end
  
  def execute_newtonian_collision displace_vector
    @pos = Array.new(2) { |i| (@pos[i] + displace_vector[i])%@pond.environment.size[i] }
    set_rects
  end
  
  def energy_decay
    if @body.hp < @body.shell
      @energy *= (@total_heal_drain) if @body.hp < @body.shell
    end
    @energy -= (@velo_magnitude+$REST_ENERGY_DECAY)*@total_mass_drag
    if @energy < 0
      log_message "Eo_#{@id}\tStarved;\ta#{@age}"
      die :starvation
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
  
  def mutate new_energy=0
    new_dna = @dna.mutate
    return Eo.new(new_dna, new_energy)
  end
  
  def replicate force=false
    
    if @energy >= $ENERGY_CAP
      reproduce_now = true
      $LOGGER.warn "Eo_#{@id} has been forced to reproduce by breaking energy cap of #{$ENERGY_CAP}, with a#{@age}/e#{@energy.to_i}"
    end
    
    if reproduce_now or force or ((@energy > @total_rep_threshold) and (rand*@total_rep_rate < @energy))
      
      log_message "Eo_#{@id}\tReplicates;\ta#{@age}, e#{@energy.to_i}"
      
      die :reproduction
      
      @energy -= (5-@body.efficiency/2)       # I really do hate to introduce more config constants, but should un-hardcode this
      
      if @velo_magnitude == 0
        
        axis = rand*180
        move(axis,1)
        
      end
      
      ortho = @velocity.ortho_2D.mult(0.5)
      
      left_disp = @velocity.ortho_2D.normalize.mult(-5).add(@pos)
      right_disp = @velocity.ortho_2D.normalize.mult(5).add(@pos)
      
      speed_frac = @velo_magnitude/@body.max_speed
      
      velo_unit = @velocity.unit_vector
      
      dotted = @angle_vect.dot(velo_unit)
      dotted = 1 if dotted >= 1
      dotted = -1 if dotted <= -1
      
      angle_disp = Math.d_acos(dotted)
      
      move_angle = 270 - (@angle+angle_disp)
      test_velo = Vector_Array.new([Math.d_cos(move_angle)*@velo_magnitude,
      Math.d_sin(move_angle)*@velo_magnitude])
      if test_velo != velo_unit
        angle_disp *= -1
      end
      
      ## Consider making this a bit simpler
      
      descendant1 = @pond.add_eo(@dna.mutate,@energy/2,left_disp[0],left_disp[1],
                                 @angle+90,@generation+1,angle_disp,speed_frac)
      descendant2 = @pond.add_eo(@dna.mutate,@energy/2,right_disp[0],right_disp[1],
                                 @angle-90,@generation+1,angle_disp,speed_frac)
      
      @pond.archive.store_eo(id,descendant1.id,descendant2.id)
      
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
    packet_angle_vect = Vector_Array.from_angle(270-(@angle+angle))
    packet_final_vect = packet_angle_vect.mult(speed).add(@velocity)
    
    new_x = @pos[0] + packet_angle_vect[0]*(6+@velo_magnitude)
    new_y = @pos[1] + packet_angle_vect[1]*(6+@velo_magnitude)
    
    @pond.add_packet amount, new_x, new_y, packet_final_vect.magnitude, packet_final_vect.angle 
    
    @energy -= amount
  end
  
  def shoot_spike mass, angle, speed
    spike_angle_vect = Vector_Array.from_angle(270-(@angle+angle))
    spike_final_vect = spike_angle_vect.mult(speed).add(@velocity)
    
    new_x = @pos[0] + spike_angle_vect[0]*(6+@velo_magnitude)
    new_y = @pos[1] + spike_angle_vect[1]*(6+@velo_magnitude)
    
    @pond.add_spike mass, self, new_x, new_y, spike_final_vect.magnitude, spike_final_vect.angle 
    
    @energy -= (mass*speed)/(@body.efficiency+3)
  end
  
  def eaten
    @energy = 0
    die :eaten
  end
  
  def turn_into_food
  @energy *= $B_DECAY
    while @energy > 0
      drop = rand*15+5
      max_dist = Math.log(@energy+1)*2.5
      dist = rand*max_dist*2-max_dist
      displace = Vector_Array.from_angle(rand*360).mult(dist)
      x = @pos[0]+displace[0]
      y = @pos[1]+displace[1]
      if @energy > drop
        @pond.add_food(drop,x,y)
        @energy -= drop
      else
        @pond.add_food(@energy,x,y)
        @energy = 0
      end
    end
  end
  
  def die reason=:unknown,log=false
    @death_cause = reason
    if log
      case reason
      when :divine
        log_message "Eo_#{@id}\tDies by divine hand\ta#{@age}, e#{@energy.to_i}"
      else
        log_message "Eo_#{@id}\tDies;\t\ta#{@age}, e#{@energy.to_i}\t(Cause: #{reason})"
      end
    end
    @pond.remove_eo(self)
    kill
    if reason != :reproduction and reason != :eaten and @energy > 0
      turn_into_food
    end
    
    @rect = Rect.new([-10,-10,0,0])
    @col_rect = @rect
  end
  
  def strike force,source=:unknown
    @body.strike force,source
  end
  
  def inspect
    to_s
  end
  def to_s
    "Eo_#{@id} [g#{@generation}]"
  end
  
  def log_message message,post_anyway=true
    if @followed
      $LOGGER.info message
      return true
    else
      $LOGGER.debug message if post_anyway
      return false
    end
  end
  
  def is_dead
    return @groups.size > 0
  end
  
  def report
    $LOGGER.info "Age: #{@age}"
    $LOGGER.info "Ultimate Ancestor: Eo_#{@pond.archive.ultimate_ancestor_of id} [g1]"
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
    @mass = (@shell+0.5)*$B_MASS_FACTOR
    
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
      message = "Eo_#{@owner.id}\tEaten by Eo_#{poker.id};\ta#{@owner.age}, e#{@owner.energy.to_i}"
      unless @owner.log_message message,false
        poker.log_message message
      end
      @owner.eaten
    end
  end
  
  def lose_hp amount
    @hp -= amount
  end
  
  def strike force,source=:unknown
    @hp -= force*(1-0.05*@shell)
    @owner.log_message "Eo_#{@owner.id}\tstruck with a force of #{(force*10).to_i} for #{(force*(1-0.05*@shell)*10).to_i} damage by #{source.to_s}.",false
    if @hp < 0
      @owner.log_message "Eo_#{@owner.id}\tdied from being struck by #{source.to_s};\ta#{@owner.age}, e#{@owner.energy.to_i}"
      @owner.die source
    end
  end
  
  def spiked spiker, direct=true
    diff = Vector_Array.new(@owner.velocity).sub(spiker.velocity).magnitude
    damage = (spiker.mass+spiker.energy_content)*(diff+0.5)*$SPIKE_DAMAGE*$B_DAMAGE/2
    if direct
      @hp -= damage
    else
      @hp -= damage/2
    end
    if @hp < 0
      if spiker.owner
        message = "Eo_#{@owner.id}\tKilled by spike from Eo_#{spiker.owner.id};\ta#{@owner.age}, e#{@owner.energy.to_i}"
        unless @owner.log_message message,false
          spiker.owner.log_message message
        end
      else
        message = "Eo_#{@owner.id}\tKilled by spike from unknown Eo;\ta#{@owner.age}, e#{@owner.energy.to_i}"
        @owner.log_message message
      end
      
      @owner.die :spiked
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
    @mass = ((length*$F_L_S_RATIO+strength)/($F_L_S_RATIO+1)) * $F_MASS
    
    @image = graphic
    @rect = @image.make_rect
  end
  
  def graphic
    return @f_graphic if @f_graphic
    
    pen_thickness = (@strength/2).to_i
    pen_thickness = 1 if pen_thickness < 1
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
    target.body.poked(poke_force,@owner)
  end
  
  def inspect
    to_s
  end
  def to_s
    "Feeler of #{@owner.to_s}; #{@f_length.to_i}#{@f_strength.to_i}"
  end
  
end