require "rubygems"
require "rubygame"

Dir.require_all("lib/eo/")

include Rubygame

class Environment
  
  attr_reader :game
  
  def initialize game
    @game = game
    
    @eos = Sprites::Group.new
    @eos.extend(Sprites::DepthSortGroup)
    @eos.extend(Sprites::UpdateGroup)
    
    @foods = Sprites::Group.new
    @foods.extend(Sprites::DepthSortGroup)
    @foods.extend(Sprites::UpdateGroup)
    
  end
  
  def add_eo_still(dna, energy=0, x=0, y=0, rot=0)
    add_eo(dna,energy,x,y,rot,[0,0])
  end
  
  def add_eo(dna, energy=10, x=0, y=0, rot=0, velo=false)
    new_eo = Eo.new(self,dna,energy,x,y,rot)
    
    if velo
      new_eo.velocity = Array.new(velo)  
    else
      new_velo = (rand * 2 - 1)*dna.max_speed
      new_velo_dir = rand*360
      new_eo.velocity = [Math.d_cos(new_velo_dir)*new_velo,Math.d_sin(new_velo_dir)*new_velo]
    end
    @eos << new_eo
    
#    @eos << Food.new(self,rand*20,rand*200,rand*200)
  end
  
  def add_food(energy=10,x=0,y=0)
    new_food = Food.new(self,energy,x,y)
    @foods << new_food
  end
  
  def sprinkle_food(amount=1,max_energy=20,min_energy=5)
    for i in 0...amount
      add_food(rand*(max_energy-min_energy)+min_energy,rand*@game.width,rand*@game.height)
    end
  end
  
  def sprinkle_eo(amount=1,energy=10)
    for i in 0...amount
      add_eo(Eo_DNA.generate,energy,rand*@game.width,rand*@game.height,rand*360)
    end
  end
  
  def remove_eo(to_remove)
    @eos.delete(to_remove)
  end
  
  def update_zones
    
  end
  
  def eo_in_rect rect
    coll_indxs = rect.collide_array_all(@eos)
    Array.new(coll_indxs.size) { |i| @eos[coll_indxs[i]] }
  end
  
  def food_in_rect rect
    coll_indxs = rect.collide_array_all(@foods)
    Array.new(coll_indxs.size) { |i| @foods[coll_indxs[i]] }
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
    @foods.undraw(@game.screen,@game.background)
    @eos.undraw(@game.screen,@game.background)
  end
  
  def update
    
    if @eos.size == 0
      sprinkle_eo(5)
      puts "~REPOPULATE~"
    end
    
    if rand*$ENV_FOOD_RATE < 1
      sprinkle_food
    end
    
#    if rand*200 < 1
#      sprinkle_eo
#    end
    
    @eos.update
    
    File.open($log, 'a') {|f| f.write("#{@game.clock.ticks},#{@eos.size},#{@foods.size}\n") } if @game.clock.ticks % 20 == 0
    
#    @foods.update
  end
  
  def draw
    @foods.draw(@game.screen)
    @eos.draw(@game.screen)
  end
  
end