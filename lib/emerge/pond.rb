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

class Follower
  
  attr_accessor :environment,:tracked_eo,:original_tracked,:original_generation
  
  def initialize environment, archive, auto_track=false
    @environment = environment
    @auto_track = auto_track
    @archive = archive
    
    @curr_dialog = nil
    @tracked_eo = nil
    @original_tracked = nil
    @original_generation = nil
    @dna_dialog = nil
    @tracked_start_time = nil
    
  end
  
  def tracking_eo
    return true if @tracked_eo
    return false
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
        @tracked_start_time = nil
      end
    else
      
      find_next = false
      
      if @tracked_eo.groups.size == 0
        next_track_id = @archive.first_living_descendant_of @original_tracked
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
    @tracked_start_time = @environment.clock.ticks
    
    $LOGGER.info "TRACK\tNow tracking #{@tracked_eo} and its family line"
    
    @curr_dialog = Bubble_Dialog.new(@tracked_eo.pos,info_text)
    @dna_dialog = Bubble_Dialog.new([0,@environment.height],dna_text,[0,255,255],127)
    @environment.dialog_layer.add_dialog @curr_dialog
    @environment.dialog_layer.add_dialog @dna_dialog
    
  end
  
  def step_up_ancestor
    if @original_generation == 1
      $LOGGER.info "TRACK\tEo_#{@original_tracked} [g#{@original_generation}] has no ancestors."
    else
      new_ancestor = @archive.parent_of @original_tracked
      if new_ancestor
        $LOGGER.info "TRACK\tNow tracking family line of Eo_#{new_ancestor} [g#{@original_generation-1}], parent of Eo_#{@original_tracked} [g#{@original_generation}]."
        @original_generation -= 1
        @original_tracked = new_ancestor
      else
        $LOGGER.info "TRACK\tNo earlier ancestor of Eo_#{@original_tracked} [g#{@original_generation}] found."
      end
    end
  end
  
  def narrow_down
    if @original_generation == @tracked_eo.generation
      $LOGGER.info "TRACK\tEo_#{@original_tracked} [g#{@original_generation}] has no descendants."
    else
      narrow_down_id = @archive.narrow_down @original_tracked
      if narrow_down_id == @original_tracked
        $LOGGER.info "TRACK\tNo narrowed down descendant of Eo_#{@original_tracked} [g#{@original_generation}] found; both children have living descendants."
      else
        narrow_down_gen = @original_generation + @archive.generation_gap(@original_tracked,narrow_down_id)
        $LOGGER.info "TRACK\tNow tracking family line of Eo_#{narrow_down_id} [g#{narrow_down_gen}], narrowed-down ancestor of #{@tracked_eo} descended from Eo_#{@original_tracked} [g#{@original_generation}."
        @original_tracked = narrow_down_id
        @original_generation = narrow_down_gen
      end
    end
  end
  
  def stop_following
    if @tracked_eo
      
      $LOGGER.info "TRACK\tStopped tracking #{@tracked_eo}, of Eo_#{@original_tracked} [g#{@original_generation}] family line."
      
      @curr_dialog.kill
      @dna_dialog.kill
      @original_tracked = nil
      @original_generation = nil
      @curr_dialog = nil
      @dna_dialog = nil
      @tracked_start_time = nil
      
      @tracked_eo.followed = nil if @tracked_eo
      @tracked_eo = nil
      
    end
  end
  
  def track_elapsed_time
    if @tracked_start_time
      return @environment.clock.ticks - @tracked_start_time
    else
      return 0
    end
  end
  
  def track_elapsed_generations
    if @tracked_eo
      return @tracked_eo.generation - @original_generation + 1
    else
      return 0
    end
  end
  
  def info_text
    "#{@tracked_eo}; #{@tracked_eo.dna.inspect_physical}; e:#{@tracked_eo.energy.to_i},h:#{(@tracked_eo.body.hp*10).to_i}/#{(@tracked_eo.body.shell*10).to_i}"
  end
  def dna_text
    "#{@tracked_eo}: #{@tracked_eo.dna.inspect_programs}"
  end
end
  
class Pond_Key_Handler

  @@DISASTERS = [:plague,:'a divine wind',:flooding,:'gamma radiation',:'poisoned water',
                  :'global warming',:'the ice age',:'a zombie apocalypse',:'an asteroid impact',
                  :'you meddling kids',:'an earthquake',:'a hurricane',:'an alien invasion',
                  :'a volcanic eruption',:'an oil spill']                                       # symbols might be overkill
  
  def initialize pond, eos, foods, packets, follower, archive
    @pond = pond
    @eos = eos
    @foods = foods
    @packets = packets
    @follower = follower
    @archive = archive
  end
  
  def process key,mods
    case key
    when K_SPACE
      if @follower.tracking_eo
        @follower.tracked_eo.report
      end
    when K_Z
      if @follower.tracking_eo
        @follower.step_up_ancestor
      end
    when K_N
      if @follower.tracking_eo
        @follower.narrow_down
      end
    when K_D
      disaster
    when K_I
      infuse_energy
    when K_O
      mass_reproduction
    when K_M
      mass_mutation
    when K_F
      vanish_food
    when K_P
      drought
    when K_R
      report
    when K_H
      hall_of_fame
    when K_S
      # maybe implement shift = x5
      spawned = sprinkle_eo
      $LOGGER.info "SPAWN\tManually spawned Eo_#{spawned[0].id} (#{spawned[0].dna.inspect_physical})"
    end
  end
  
  def disaster
    cause = @@DISASTERS.pick_rand
    $LOGGER.info "POND\tA terrible disaster caused by #{cause.to_s} brings destruction across the pond."
    @eos.clone.each do |eo|
      eo.strike(Mutations.rand_norm_dist(0,$POND_DISASTER,2),cause)
    end
  end
  
  def infuse_energy
    $LOGGER.info "POND\tAll of a sudden, a surge of energy has been infused in the pond's creatures."
    @eos.each do |eo|
      energy_infusion = Mutations.mutate($POND_ENERGY_INFUSION,0,1/0.0,$POND_ENERGY_INFUSION/10.0,10)
      eo.collect_energy energy_infusion
      eo.log_message "Eo_#{eo.id}\tinfused with #{energy_infusion} energy.",false
    end
  end
  
  def mass_reproduction
    @eos.clone.each do |eo|
      eo.replicate true
    end
    $LOGGER.info "POND\tBy some divide circumstance, every Eo has been forced to reproduce."
  end
  
  def mass_mutation
    $LOGGER.info "POND\tA nearby solar flare has caused every Eo to radically mutate."
    @eos.each do |eo|
      eo.mutate! $DNA_INITIAL_VARIANCE/2
    end
  end
  
  def vanish_food
    cause = @@DISASTERS.pick_rand
    (@foods | @packets).each do |food|
      food.kill
    end
    $LOGGER.info "POND\t#{cause.to_s.capitalize} has caused all food in the pond to vanish."
  end
  
  def report
    $C_LOG.info "REPORT:\t~~ Pond (Age: #{@pond.environment.clock.ticks}) ~~"
    
    ## Living, Ages
    ages = @eos.map { |e| e.age }
    $C_LOG.info "\t- Currently #{@eos.size} Eos alive; Average age: #{(ages.mean+0.5).to_i} (min: #{ages.min}, max: #{ages.max}, s^2: #{ages.standard_deviation.to_s[0,5]})"
    
    ## Average Generation
    gens = @eos.map { |e| e.generation }
    $C_LOG.info "\t   (Average generation: [g#{(gens.mean+0.5).to_i}]; min: [g#{gens.min}]; max: [g#{gens.max}]; s^2: #{gens.standard_deviation.to_s[0,5]})"
    
    ## Common Ancestors
    ids = @eos.map { |e| e.id }
    lca = @archive.LCA_of_group ids
    if lca == nil
      $C_LOG.info "\t- No most recent common ancestor exists."
    else
      lca_gen = @eos[0].generation - @archive.generation_gap(@eos[0].id,lca)
      $C_LOG.info "\t- Most recent common ancestor: Eo_#{lca} [g#{lca_gen}]"
    end
    
    ## Roots
    $C_LOG.info "\t- Surviving original family lines:"
    if lca
      $C_LOG.info "\t\t\tEo_#{@archive.ultimate_ancestor_of lca} [g1]\t(#{@eos.size} surviving)"
    else
      roots = @archive.group_roots ids
      roots.each do |root|
        $C_LOG.info "\t\t\tEo_#{root} [g1]\t(#{@archive.count_living_descendants_of root} surviving)"
      end
    end
    
    ## Ancestor Groups
    ga = @archive.group_ancestors ids
    ga_gens = Hash.new
    for ancestor in ga
      curr_desc_id = @archive.first_living_descendant_of ancestor
      curr_desc_gen = @pond.eos.find { |eo| eo.id == curr_desc_id }.generation
      ga_gens[ancestor] = curr_desc_gen - @archive.generation_gap(curr_desc_id,ancestor)
    end
    $C_LOG.info "\t- Largest families alive include:"
    ga.each do |anc|
      unless lca
        anc_root = ", of Eo_#{@archive.ultimate_ancestor_of anc} [g1]"
      end
      $C_LOG.info "\t\t\tEo_#{anc} [g#{ga_gens[anc]}]#{anc_root}\t(#{@archive.count_living_descendants_of anc} surviving)"
    end
    
    ## Tracking Stats
    if @follower.tracking_eo
      tracker_offspring = @archive.count_living_descendants_of @follower.original_tracked
      member_plural = tracker_offspring > 1 ? "s" : ""
      $C_LOG.info "\t- Current tracked family line Eo_#{@follower.original_tracked} [g#{@follower.original_generation}] has #{tracker_offspring} living member#{member_plural}."
      $C_LOG.info "\t   (Tracking current family line for #{@follower.track_elapsed_time} ticks and #{@follower.track_elapsed_generations} generations)"
    end
    
  end
  
  def hall_of_fame
    
    $C_LOG.info "REPORT:\t~~ HALL OF FAME ~~"
    
    if @pond.hall.empty?
      $C_LOG.info "\t(Hall of fame is currently empty)"
    else
      for record in @pond.hall.categories
        if @pond.hall.record_exists? record
          $C_LOG.info "\t#{@pond.hall.record_name record}:\t#{@pond.hall.record_to_s record}"
        end
      end
    end
    
  end
  
end