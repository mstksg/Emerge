require "rubygems"
require "rubygame"

include Rubygame

class Pond
  
  @@total_zones = $POND_ZONES**2
  
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
    
    make_zones
    
  end
  
  def make_zones
    @zone_width = @environment.width/$POND_ZONES
    @zone_height = @environment.height/$POND_ZONES
    @zone_rects = Array.new()
    for i in 0...$POND_ZONES
      for j in 0...$POND_ZONES
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
      @eo_zones[row*$POND_ZONES+col] << new_eo unless @eo_zones[row*$POND_ZONES+col].include? new_eo
      
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
    @eo_zones = Array.new(@@total_zones) { |i| Array.new(eo_in_rect(@zone_rects[i])) }
    @food_zones = Array.new(@@total_zones) { |i| Array.new(food_in_rect(@zone_rects[i])) }
  end
  
  def eo_in_rect rect, group=@eos
    coll_indxs = rect.collide_array_all(group)
    Array.new(coll_indxs.size) { |i| group[coll_indxs[i]] }
  end
  
  def find_possible_eo_collisions eo
    checks = Array.new
    for i in 0...16
      if @eo_zones[i].include? eo
        checks |= @eo_zones[i]
      end
    end
    return eo_in_rect(eo.rect,checks)
  end
  
  def find_possible_food_collisions eo
    checks = Array.new
    for i in 0...16
      if @eo_zones[i].include? eo
        checks |= @food_zones[i]
      end
    end
    return food_in_zone_rect(eo.rect,checks)
  end
  
  def food_in_rect rect, group=@foods
    coll_indxs = rect.collide_array_all(@foods)
    foods = Array.new(coll_indxs.size) { |i| @foods[coll_indxs[i]] }
    if @packets.size > 1
      coll_indxs = rect.collide_array_all(@packets)
      foods += Array.new(coll_indxs.size) { |i| @packets[coll_indxs[i]] }
    end
    return foods
  end
  
  def food_in_zone_rect rect,zone
    coll_indxs = rect.collide_array_all(zone)
    Array.new(coll_indxs.size) { |i| zone[coll_indxs[i]] }
  end
  
  ## An unfortunate case of premature optimization; will work on later
  #  def find_collisions
  #    temp_group = @eos.clone
  #    while temp_group.size > 0
  #      curr_eo = temp_group.pop
  #      
  #      collisions = temp_group.collide_sprite(curr_eo)
  #      
  #      for i in collisions
  #        curr_eo.add_coll_queue i
  #        i.add_coll_queue curr_eo
  #        for j in collisions
  #          i.add_coll_queue j if i != j
  #        end
  #      end
  #      
  #    end
  #  end
  
  def undraw
    @foods.undraw(@environment.screen,@environment.background)
    @packets.undraw(@environment.screen,@environment.background)
    @eos.undraw(@environment.screen,@environment.background)
  end
  
  def update
    @fr = @environment.clock.framerate
    if @fr != 0 and @fr < 0.05
      raise "Computational overload; Framerate = #{@environment.clock.framerate}"
    end
    
    if rand*$POND_FOOD_RATE < 1
      sprinkle_food
    end
    
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