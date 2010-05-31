require "rubygems"
require "rubygame"

include Rubygame

module Sprites
  module Sprite
    def collide_rect? rect
      col_rect.collide_rect? rect
    end
  end
  
  class Group
    
    def get_sprites
      Array.new(self)
    end
    
  end
  
  class Group_Set < Set
    
  end
  
end

class Rect
  
  def corners
    [topleft.clone,topright.clone,bottomleft.clone,bottomright.clone]
  end
  
end