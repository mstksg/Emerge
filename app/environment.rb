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
    
  end
  
  def add_eo_still(dna, energy=0, x=0, y=0, rot=0)
    add_eo(dna,energy,x,y,rot,[0,0])
  end
  
  def add_eo(dna, energy=0, x=0, y=0, rot=0, velo=false)
    new_eo = Eo.new(self,dna,energy,x,y,rot)
    
    if velo
      new_eo.velocity = Array.new(velo)  
    else
      new_velo = (rand * 2 - 1)*dna.max_speed
      new_velo_dir = rand*360
      new_eo.velocity = [Math.d_cos(new_velo_dir)*new_velo,Math.d_sin(new_velo_dir)*new_velo]
    end
    @eos << new_eo
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
  
  def eo_collides_sprite sprite
    collisions = @eos.collide_sprite(sprite)
    collisions.delete(sprite)
    return collisions
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
    @eos.undraw(@game.screen,@game.background)
  end
  
  def update
    @eos.update
  end
  
  def draw
    @eos.draw(@game.screen)
  end
  
end