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
      $C_LOG.info "TRACK\tEo_#{@original_tracked} [g#{@original_generation}] has no ancestors."
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
    if @tracked_eo
      if @original_generation == @tracked_eo.generation
        $C_LOG.info "TRACK\tEo_#{@original_tracked} [g#{@original_generation}] has no descendants."
      else
        narrow_down_id = @archive.narrow_down @original_tracked
        if narrow_down_id == @original_tracked
          $LOGGER.info "TRACK\tNo narrowed down descendant of Eo_#{@original_tracked} [g#{@original_generation}] found; both children have living descendants."
        else
          narrow_down_gen = @original_generation + @archive.generation_gap(@original_tracked,narrow_down_id)
          $LOGGER.info "TRACK\tNow tracking family line of Eo_#{narrow_down_id} [g#{narrow_down_gen}], narrowed-down ancestor of #{@tracked_eo} descended from Eo_#{@original_tracked} [g#{@original_generation}]."
          @original_tracked = narrow_down_id
          @original_generation = narrow_down_gen
        end
      end
    else
      $C_LOG.info "TRACK\tNot following any family line."
    end
  end
  
  def report
    if @tracked_eo
      $C_LOG.info "REPORT\tFamily line of Eo_#{@original_tracked} [g#{@original_generation}] (Time: #{track_elapsed_time}, #{track_elapsed_generations} generations)"
      
      offsprings = @archive.all_living_descendants_of @original_tracked
      $C_LOG.info "\t- Currently #{offsprings.size} living descendants alive."
      
      ## Average Generation
      gens = offsprings.map { |e| @environment.pond.eos.find { |eo| eo.id == e }.generation - @original_generation }
      $C_LOG.info "\t   (Average generation: [+#{(gens.mean+0.5).to_i}]; min: [+#{gens.min}]; max: [+#{gens.max}]; s^2: #{gens.standard_deviation.to_s[0,5]})"
      
      lca = @archive.narrow_down @original_tracked
      lca_gen = @original_generation  + ( lca == @orignal_tracked ? 0 : @archive.generation_gap(@original_tracked,lca) )
      if lca != @original_tracked
        $C_LOG.info "\t- Family line can be narrowed down to Eo_#{lca} [g#{lca_gen}]."
      end
      
      
      if offsprings.size > 1
        
        $C_LOG.info "\t- Graphing major surviving sub-families..."
        
        ga = @archive.group_descendants(lca,10)
        
        g_builder = Graph_Builder.new "Eo_#{lca} [g#{lca_gen}]"
        to_expand = [[lca,0]]
        while to_expand.size > 0
          curr_parent,curr_gen = to_expand.shift
          expanded = @archive.descendants_with_living_descendants_of curr_parent
          expanded.each do |eo|
            g_builder.add_node("Eo_#{curr_parent} [g#{lca_gen+curr_gen}]",curr_gen+1,"Eo_#{eo} [g#{lca_gen+curr_gen+1}]")
            to_expand.push [eo,curr_gen+1] unless ga.include? eo
          end
        end
        
        g_builder.render_horizontal(lca != @original_tracked) do |n|
          last_eo = n.scan(Eo.eo_regex)[-1][0]
          survivors = @archive.count_living_descendants_of last_eo
          
          if survivors == 1
            appender = last_eo == @tracked_eo.id ? "**" : "*"
          else
            appender = "->(#{survivors})"
            appender += "**" if @archive.is_living_descendant_of(last_eo,@tracked_eo.id)
          end
          
          $C_LOG.info "\t#{n.rstrip}#{appender}"
        end
        
      end
      
    else
      $C_LOG.info "\tNot following any family line"
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
      @pond.drought
    when K_R
      report
    when K_T
      @follower.report
    when K_H
      @pond.hall.log_HoF $C_LOG
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
    
    if @eos.size == 0
      $C_LOG.info "\t- A silent pond, with no life of which to speak..."
      return
    end
    
    ## Living, Ages
    ages = @eos.map { |e| e.age }
    $C_LOG.info "\t- Currently #{@eos.size} Eos alive; Average age: #{(ages.mean+0.5).to_i} (min: #{ages.min}, max: #{ages.max}, s^2: #{ages.standard_deviation.to_s[0,5]})"
    
    ## Average Generation
    gens = @eos.map { |e| e.generation }
    $C_LOG.info "\t   (Average generation: [g#{(gens.mean+0.5).to_i}]; min: [g#{gens.min}]; max: [g#{gens.max}]; s^2: #{gens.standard_deviation.to_s[0,5]})"
    
    ## Common Ancestors
    ids = @eos.map { |e| e.id }
    lca = @archive.LCA_of_group ids
    if lca.nil?
      $C_LOG.info "\t- No most recent common ancestor exists."
    else
      lca_gen = @eos[0].generation - @archive.generation_gap(@eos[0].id,lca)
      if @eos.size > 1
        $C_LOG.info "\t- Most recent common ancestor: Eo_#{lca} [g#{lca_gen}]"
      else
        $C_LOG.info "\t- Lone Surviving Eo: #{@eos[0].inspect}"
      end
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
    if @eos.size > 1
      ga = lca ? @archive.group_descendants(lca,10) : @archive.group_ancestors(ids,4)
      ga_gens = Hash.new do |h,k|
        curr_desc_id = @archive.first_living_descendant_of k
        curr_desc_gen = @pond.eos.find { |eo| eo.id == curr_desc_id }.generation
        h[k] = curr_desc_gen - @archive.generation_gap(curr_desc_id,k)
      end
      
      if not lca
        $C_LOG.info "\t- Largest families alive include:"
        ga.each do |anc|
          if lca
            ascend = ga_gens[anc] - lca_gen - 1
            ascend = 1 if ascend < 1
            anc_root = ", of Eo_#{@archive.nth_ancestor_of anc,ascend} [g#{ga_gens[anc]-ascend}]"
          else
            anc_root = ", of Eo_#{@archive.ultimate_ancestor_of anc} [g1]"
          end
          $C_LOG.info "\t\t\tEo_#{anc} [g#{ga_gens[anc]}]#{anc_root}\t(#{@archive.count_living_descendants_of anc} surviving)"
        end
        
      else
      
        $C_LOG.info "\t- Graphing major surviving families..."
        
        g_builder = Graph_Builder.new "Eo_#{lca} [g#{lca_gen}]"
        to_expand = [[lca,0]]
        while to_expand.size > 0
          curr_parent,curr_gen = to_expand.shift
          expanded = @archive.descendants_with_living_descendants_of curr_parent
          expanded.each do |eo|
            g_builder.add_node("Eo_#{curr_parent} [g#{lca_gen+curr_gen}]",curr_gen+1,"Eo_#{eo} [g#{lca_gen+curr_gen+1}]")
            to_expand.push [eo,curr_gen+1] unless ga.include? eo
          end
        end
        
        g_builder.render_horizontal(lca_gen != 1) do |n|
          last_eo = n.scan(Eo.eo_regex)[-1][0]
          survivors = @archive.count_living_descendants_of last_eo
          
          if survivors == 1
            if @follower.tracking_eo
              appender = last_eo == @follower.tracked_eo.id ? "**" : "*"
            else
              appender = "*"
            end
          else
            appender = "->(#{survivors})"
            appender += "**" if @follower.tracking_eo and @archive.is_living_descendant_of(last_eo,@follower.tracked_eo.id)
          end
          
          $C_LOG.info "\t#{n.rstrip}#{appender}"
        end
        
      end
    end
  end
  
end