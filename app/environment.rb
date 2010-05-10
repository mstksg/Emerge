require "rubygems"
require "rubygame"

Dir.require_all("lib/eo/")

include Rubygame

class Environment
  
  def initialize game
    @game = game
    
    @eos = Sprites::Group.new
    @eos.extend(Sprites::DepthSortGroup)
    @eos.extend(Sprites::UpdateGroup)
    
  end
  
  def add_eo(dna, energy=0, x=0, y=0, rot=0)
    @eos << Eo.new(self,dna,x,y,rot)
  end
  
end