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
  
end