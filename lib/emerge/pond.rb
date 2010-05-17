require "rubygems"
require "rubygame"

include Rubygame

class Pond
  
  attr_reader :environment, :eos, :foods # for debug
  
  def initialize environment
    @environment = environment
    
    @eos = Sprites::Group.new
    #    @eos.extend(Sprites::DepthSortGroup)
    @eos.extend(Sprites::UpdateGroup)
    
    @foods = Sprites::Group.new
    #    @foods.extend(Sprites::DepthSortGroup)
    @foods.extend(Sprites::UpdateGroup)
    
    @packets = Sprites::Group.new
    #    @packets.extend(Sprites::DepthSortGroup)
    @packets.extend(Sprites::UpdateGroup)
    
    @zone_count = determine_zone_count
    @total_zones = @zone_count*@zone_count
    
    $LOGGER.debug "Pond zoning grid set to #{@zone_count}x#{@zone_count}"
    
    make_zones
    
  end
  
  def determine_zone_count eo_count=$POND_INIT_EO
    ## Point when z is worse than z+1 = z^2(1+z^2)
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
    
    x = x.boundarize(0,@environment.width,false,true)
    y = y.boundarize(0,@environment.height,false,true)
    
    new_eo = Eo.new(self,dna,energy,x,y,rot,generation)
    
    if direction and speed_frac
      new_eo.move(direction,speed)  
    else
      new_eo.move(rand*360,rand)
    end
    @eos << new_eo
    
    put_in_zones new_eo
    
  end
  
  def put_in_zones new_eo
    
    for corner in new_eo.rect.corners
      
      col = (corner[0].boundarize(0,@environment.width,true,false)/@zone_width).to_i
      row = (corner[1].boundarize(0,@environment.height,true,false)/@zone_height).to_i
      @eo_zones[row*@zone_count+col] << new_eo unless @eo_zones[row*@zone_count+col].include? new_eo
      
    end
    
  end
  
  def add_food(energy=10,x=0,y=0)
    x = x.boundarize(0,@environment.width,false,true)
    y = y.boundarize(0,@environment.height,false,true)
    
    new_food = Food.new(energy,x,y)
    @foods << new_food
  end
  
  def add_packet(energy,x=0,y=0,speed=0,angle=0)
    
    x = x.boundarize(0,@environment.width,false,true)
    y = y.boundarize(0,@environment.height,false,true)
    
    new_packet = Packet.new(self,energy,x,y,speed,angle)
    @packets << new_packet
  end
  
  def sprinkle_food(amount=1,max_energy=20,min_energy=5)
    for i in 0...amount
      add_food(rand*(max_energy-min_energy)+min_energy,rand*@environment.width,rand*@environment.height)
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
      
      col = (corner[0].boundarize(0,@environment.width,true,false)/@zone_width).to_i
      row = (corner[1].boundarize(0,@environment.height,true,false)/@zone_height).to_i
      
      checks |= @eo_zones[row*@zone_count+col]
      
    end
    
    return eo_in_rect(eo.rect,checks)
    
  end
  
  def find_possible_food_collisions eo
    checks = Array.new
    
    for corner in eo.rect.corners
      
      col = (corner[0].boundarize(0,@environment.width,true,false)/@zone_width).to_i
      row = (corner[1].boundarize(0,@environment.height,true,false)/@zone_height).to_i
      
      checks |= @food_zones[row*@zone_count+col]
      
    end
    
    return food_in_zone_rect(eo.rect,checks)
  end
  
  def food_in_rect rect
    coll_indxs = rect.collide_array_all(@foods)
    foods = Array.new(coll_indxs.size) { |i| @foods[coll_indxs[i]] }
    if @packets.size > 1
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
  end
  
  def update
    @fr = @environment.clock.framerate
    if @fr != 0 and @fr < 0.05
      raise "Computational overload; Framerate = #{@fr}"
    end
    
    if rand*$POND_FOOD_RATE < 1
      sprinkle_food
    end
    
    set_zone_count
    update_zones
    
    @eos.update
    @packets.update
    
    #    for eo in @eos
    #      if eo.pos[0].nan?
    #        puts "#{eo}"
    #        puts "#{eo.velocity},#{eo.energy}"
    #        for prog in eo.dna.b_programs
    #          puts "#{prog}"
    #        end
    #      end
    #    end
    
    if @eos.size == 0
      sprinkle_eo($POND_REPOP_COUNT)
      @logger.warn "Repopulating empty pool..."
    end
    
  end
  
  def draw
    @foods.draw(@environment.screen)
    @packets.draw(@environment.screen)
    @eos.draw(@environment.screen)
  end
  
end