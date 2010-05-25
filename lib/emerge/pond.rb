require "rubygems"
require "rubygame"

include Rubygame

class Pond
  
  attr_reader :environment, :eos, :foods, :zone_rects, :archive # for debug
  
  def initialize environment
    @environment = environment
    
    @eos = Sprites::Group.new
    @eos.extend(Sprites::UpdateGroup)
    @archive = Eo_Archive.new(@eos)
    @eo_follower = Follower.new(@environment,@archive,$AUTO_TRACKING)
    
    @foods = Sprites::Group.new
    @foods.extend(Sprites::UpdateGroup)
    
    @packets = Sprites::Group.new
    @packets.extend(Sprites::UpdateGroup)
    
    @spikes = Sprites::Group.new
    @spikes.extend(Sprites::UpdateGroup)
    
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
  
  def add_eo(dna, energy=10, x=0, y=0, rot=0, generation=1, direction=false, speed_frac=false)
    
    x %= @environment.width
    y %= @environment.height
    
    new_eo = Eo.new(self,dna,energy,x,y,rot,generation)
    
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
  
  def sprinkle_food(amount=1,max_energy=20,min_energy=5)
    for i in 0...amount
      add_food(Mutations.rand_norm_dist(min_energy,max_energy,2),rand*@environment.width,rand*@environment.height)
    end
  end
  
  def sprinkle_eo(amount=1,energy=10)
    for i in 0...amount
      add_eo(Eo_DNA.generate,energy,rand*@environment.width,rand*@environment.height,rand*360)
    end
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
    
    if rand*$POND_FOOD_RATE < 1
      sprinkle_food
    end
    @packets.update
    
    set_zone_count
    update_zones
    
    @spikes.update
    @eos.update
    
    #    for eo in @eos
    #      if eo.pos[0].nan?
    #        puts "#{eo}"
    #        puts "#{eo.velocity},#{eo.energy}"
    #        for prog in eo.dna.b_programs
    #          puts "#{prog}"
    #        end
    #      end
    #    end
    
    @eo_follower.update_follow
    
    if @eos.size == 0
      $LOGGER.warn "Repopulating empty pool..."
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
            $LOGGER.info "SPAWN\tManually spawned Eo_#{spawned.id} (dna:#{spawned.dna.inspect}})"
          else
            add_food(Mutations.rand_norm_dist(5,20,2),pos[0],pos[1])
          end
        end
        
      end
    end
  end
  
  def select_random
    @eo_follower.start_following @eos.pick_rand if @eos.size > 0
  end
  
end

class Follower
  
  attr_accessor :environment
  
  def initialize environment, archive, auto_track=false
    @environment = environment
    @auto_track = auto_track
    @archive = archive
    
    @curr_dialog = nil
    @tracked_eo = nil
    @original_tracked = nil
    @original_generation = nil
    @dna_dialog = nil
    
  end
  
  
  def update_follow
    
    if @tracked_eo == nil
      if @curr_dialog
        @curr_dialog.kill
        @curr_dialog = nil
        @original_tracked = nil
        @original_generation = nil
        @dna_dialog.kill
        @dna_dialog = nil
      end
    else
      
      find_next = false
      
      if @tracked_eo.groups.size == 0
        next_track_id = @archive.find_first_living_descendant(@original_tracked)
        next_track = @environment.pond.eos.find { |eo| eo.id == next_track_id }
        if @archive.has_descendants @tracked_eo.id
          $LOGGER.info "TRACK\tNow tracking #{next_track} (child of Eo_#{@tracked_eo.id}), of Eo_#{@original_tracked} [g#{@original_generation}] family line"
          @tracked_eo.followed = nil
          @tracked_eo = next_track
          @tracked_eo.followed = true
        else
          if next_track
            $LOGGER.info "TRACK\t#{@tracked_eo} has died (#{@tracked_eo.death_cause}, a#{@tracked_eo.age})"
            $LOGGER.info "TRACK\tNow tracking closest relative (#{next_track}), of Eo_#{@original_tracked} [g#{@original_generation}] family line"
            @tracked_eo = next_track
            @tracked_eo.followed = true
          else
            $LOGGER.info "TRACK\tFamily line of Eo_#{@original_tracked} [g#{@original_generation}] ended with death of #{@tracked_eo} (#{@tracked_eo.death_cause}, a#{@tracked_eo.age})"
            @tracked_eo.followed = nil
            @tracked_eo = nil
            update_follow
            
            @environment.pond.select_random if @auto_track
          end
        end
      end
      
      if @tracked_eo
        @curr_dialog.change_message(info_text,@tracked_eo.pos)
        @dna_dialog.change_message(dna_text)
      end
      
    end
  end
  
  def start_following eo
    
    stop_following if @tracked_eo
    
    @original_tracked = eo.id
    @original_generation = eo.generation
    @tracked_eo = eo
    @tracked_eo.followed = true
    
    $LOGGER.info "TRACK\tNow tracking #{@tracked_eo} and its family line"
    
    @curr_dialog = Bubble_Dialog.new(@tracked_eo.pos,info_text)
    @dna_dialog = Bubble_Dialog.new([0,@environment.height],dna_text,[0,255,255],127)
    @environment.dialog_layer.add_dialog @curr_dialog
    @environment.dialog_layer.add_dialog @dna_dialog
  end
  
  def stop_following
    
    if @tracked_eo
      
      @curr_dialog.kill
      @dna_dialog.kill
      @original_tracked = nil
      @original_generation = nil
      @curr_dialog = nil
      @dna_dialog = nil
      
      $LOGGER.info "TRACK\tStopped tracking #{@tracked_eo}, of Eo_#{@original_tracked} [g#{@original_generation}] family line."
      
      @tracked_eo.followed = nil if @tracked_eo
      @tracked_eo = nil
      
    end
  end
  
  def info_text
    "#{@tracked_eo}; #{@tracked_eo.dna.inspect_physical}; e:#{@tracked_eo.energy.to_i},h:#{(@tracked_eo.body.hp*10).to_i}/#{(@tracked_eo.body.shell*10).to_i}"
  end
  def dna_text
    "#{@tracked_eo}: #{@tracked_eo.dna.inspect_programs}"
  end
  
end