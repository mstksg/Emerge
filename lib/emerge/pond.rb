require "rubygems"
require "rubygame"

include Rubygame

class Pond
  
  attr_reader :environment, :eos, :foods, :zone_rects, :archive, :hall
  
  def initialize environment
    @environment = environment
    
    @eos = Sprites::Group.new
    @eos.extend(Sprites::UpdateGroup)
    @archive = Eo_Archive.new(@eos)
    @eo_follower = Follower.new(@environment,@archive,$AUTO_TRACKING)
    @hall = Eo_HoF.new
    
    @foods = Sprites::Group.new
    @foods.extend(Sprites::UpdateGroup)
    
    @packets = Sprites::Group.new
    @packets.extend(Sprites::UpdateGroup)
    
    @spikes = Sprites::Group.new
    @spikes.extend(Sprites::UpdateGroup)
    
    @key_handler = Pond_Key_Handler.new(self,@eos,@foods,@packets,@eo_follower,@archive)
    
    @food_rate = $POND_FOOD_RATE
    @drought = false
    
    @zone_count = determine_zone_count
    @total_zones = @zone_count*@zone_count
    
    $LOGGER.debug "Pond zoning grid set to #{@zone_count}x#{@zone_count}"
    
    make_zones
    
  end
  
  def determine_zone_count eo_count=$POND_INIT_EO
    ## Point when z is worse than z+1 => z^2(1+z^2)
    ## This is because, for z zones and t eos, there are
    ##  z^2 t + (t/z)^2 rect checks (approximately)
    ## Surprisingly, if you add a variable accounting
    ## for food collision checks, z^2 f + (f t)/z^2,
    ## the boundary points stay exactly the same
    return 1 if eo_count < 4
    return 2 if eo_count < 36
    return 3 if eo_count < 144
    return 4 if eo_count < 400
    return 5 if eo_count < 900
    return 6 if eo_count < 1764
    return 7 if eo_count < 3038
    return 8 if eo_count < 5184
    return 9 if eo_count < 8100
    return 10 if eo_count < 12100       # Hey, I can dream, can't I?
    return 11
  end
  
  def set_zone_count
    unless @zone_count == determine_zone_count(@eos.size)
      @zone_count = determine_zone_count(@eos.size)
      @total_zones = @zone_count*@zone_count
      
      make_zones
      
      $LOGGER.debug "Pond zoning grid changed to #{@zone_count}x#{@zone_count}"
    end
  end
  
  def make_zones
    @zone_width = @environment.width/@zone_count.to_f
    @zone_height = @environment.height/@zone_count.to_f
    @zone_rects = Array.new()
    for i in 0...@zone_count
      for j in 0...@zone_count
        @zone_rects << Rect.new(@zone_width*j,@zone_height*i,@zone_width,@zone_height)
      end
    end
    
    update_zones
  end
  
  def add_eo_still(dna, energy=0, x=0, y=0, rot=0, generation=1)
    add_eo(dna,energy,x,y,rot,generation,[0,0])
  end
  
  def add_eo(dna, energy=10, x=0, y=0, rot=0, generation=1, direction=false, speed_frac=false, hp_percent=1)
    
    x %= @environment.width
    y %= @environment.height
    
    new_eo = Eo.new(self,dna,energy,x,y,rot,generation,hp_percent)
    
    if direction and speed_frac
      new_eo.move(direction,speed_frac)
    else
      new_eo.move(rand*360,rand)
    end
    @eos << new_eo
    
    put_in_zones new_eo
    
    ## does this impact performance? a little...but too much?  this is to track descendants
    return new_eo
    
  end
  
  def put_in_zones new_eo
    
    for corner in new_eo.rect.corners
      
      col = ((corner[0] % @environment.width)/@zone_width).to_i
      row = ((corner[1] % @environment.height)/@zone_height).to_i
      @eo_zones[row*@zone_count+col] << new_eo unless @eo_zones[row*@zone_count+col].include? new_eo
      
    end
    
  end
  
  def point_in_zone point
    col = ((point[0] % @environment.width)/@zone_width).to_i
    row = ((point[1] % @environment.height)/@zone_height).to_i
    return row*@zone_count+col
  end
  
  def add_food(energy=10,x=0,y=0)
    x %= @environment.width
    y %= @environment.height
    
    @foods << Pond_Bits::Food.new(energy,x,y)
  end
  
  def add_packet(energy,x=0,y=0,speed=0,angle=0)
    
    x %= @environment.width
    y %= @environment.height
    
    @packets << Pond_Bits::Packet.new(self,energy,x,y,speed,angle)
  end
  
  def add_spike(mass,owner=nil,x=0,y=0,speed=0,angle=0)
    
    x %= @environment.width
    y %= @environment.height
    
    @spikes << Pond_Bits::Spike.new(self,mass,owner,x,y,speed,angle)
  end
  
  def sprinkle_food(amount=1,max_energy=20,min_energy=7.5)
    for i in 0...amount
      add_food(Mutations.rand_norm_dist(min_energy,max_energy,2),rand*@environment.width,rand*@environment.height)
    end
  end
  
  def sprinkle_eo(amount=1,energy=$EO_STARTING_ENERGY)
    sprinkled = Array.new
    amount.times do
      sprinkled << add_eo(Eo_DNA.generate,energy,rand*@environment.width,rand*@environment.height,rand*360)
    end
    return sprinkled
  end
  
  def remove_eo(to_remove)
    @eos.delete(to_remove)
  end
  
  def update_zones
    @eo_zones = Array.new(@total_zones) { |i| Array.new(eo_in_rect(@zone_rects[i])) }
    @food_zones = Array.new(@total_zones) { |i| Array.new(food_in_rect(@zone_rects[i])) }
  end
  
  def eo_in_rect rect, group=@eos
    coll_indxs = rect.collide_array_all(group)
    Array.new(coll_indxs.size) { |i| group[coll_indxs[i]] }
  end
  
  def find_possible_eo_collisions eo
    
    checks = Array.new
    
    for corner in eo.rect.corners
      
      col = ((corner[0] % @environment.width)/@zone_width).to_i
      row = ((corner[1] % @environment.height)/@zone_height).to_i
      
      checks |= @eo_zones[row*@zone_count+col]
      
    end
    
    return eo_in_rect(eo.rect,checks)
    
  end
  
  def find_possible_food_collisions eo
    checks = Array.new
    
    for corner in eo.rect.corners
      
      col = ((corner[0] % @environment.width)/@zone_width).to_i
      row = ((corner[1] % @environment.height)/@zone_height).to_i
      
      checks |= @food_zones[row*@zone_count+col]
      
    end
    
    return food_in_zone_rect(eo.rect,checks)
  end
  
  def food_in_rect rect
    coll_indxs = rect.collide_array_all(@foods)
    foods = Array.new(coll_indxs.size) { |i| @foods[coll_indxs[i]] }
    if @packets.size > 0
      coll_indxs = rect.collide_array_all(@packets)
      foods |= Array.new(coll_indxs.size) { |i| @packets[coll_indxs[i]] }
    end
    return foods
  end
  
  def food_in_zone_rect rect,zone
    coll_indxs = rect.collide_array_all(zone)
    Array.new(coll_indxs.size) { |i| zone[coll_indxs[i]] }
  end
  
  def undraw
    @foods.undraw(@environment.screen,@environment.background)
    @packets.undraw(@environment.screen,@environment.background)
    @eos.undraw(@environment.screen,@environment.background)
    @spikes.undraw(@environment.screen,@environment.background)
  end
  
  def update
    
    if rand*@food_rate < 1
      sprinkle_food
    end
    @packets.update
    
    set_zone_count
    update_zones
    
    @spikes.update
    @eos.update
    
    @eo_follower.update_follow
    
    if @eos.size == 0
      $LOGGER.warn "POND\tRepopulating empty pool..."
      sprinkle_eo($POND_REPOP_COUNT)
      select_random if $AUTO_TRACKING
    end
    
  end
  
  def draw
    @foods.draw(@environment.screen)
    @packets.draw(@environment.screen)
    @eos.draw(@environment.screen)
    @spikes.draw(@environment.screen)
  end
  
  def drought
    unless @drought
      $LOGGER.info "POND\tA horrible drought has befallen the pond."
      @food_rate *= 100.0
      @drought = true
    else
      $LOGGER.info "POND\tThe drought that has plagued the pond has been lifted!"
      @food_rate /= 100.0
      @drought = false
    end
  end
  
  def clicked pos, button
    if button > 0 or button < 4
      
      col = (pos[0]/@zone_width).to_i
      row = (pos[1]/@zone_height).to_i
      checks = @eo_zones[row*@zone_count+col]
      click_rect = Rect.new(pos[0]-1,pos[1]-1,3,3)
      collisions = eo_in_rect click_rect,checks
      
      if button == 1
        
        if collisions.size > 0
          @eo_follower.start_following collisions[0]
        else
          @eo_follower.stop_following
        end
        
      else
        
        if collisions.size > 0
          clicked = collisions[0]
          if button == 3
            clicked.die :divine,true
            $LOGGER.info "KILL\tManually killed Eo_#{clicked.id}"
          else
            clicked.replicate true
            $LOGGER.info "REPRODUCE\tManually forced Eo_#{clicked.id} to reproduce"
          end
        else
          if button == 3
            spawned = add_eo(Eo_DNA.generate,10,pos[0],pos[1],rand*360)
            $LOGGER.info "SPAWN\tManually spawned Eo_#{spawned.id} (#{spawned.dna.inspect_physical})"
          else
            add_food(Mutations.rand_norm_dist(5,20,2),pos[0],pos[1])
          end
        end
        
      end
    end
  end
  
  def keyed key,mods
    @key_handler.process key,mods
  end
  
  def select_random
    @eo_follower.start_following @eos.pick_rand if @eos.size > 0
  end
  
end