require "rubygems"
require "rubygame"

include Rubygame

class Food
  include Sprites::Sprite
  
  attr_reader :energy, :pos, :velocity
  
  def graphic
    return @f_graphic if @f_graphic
    
    brightness = 100+@energy*7.8
    brightness = 255 if brightness > 255
    
    @f_graphic = Surface.new([2,2],0)
    @f_graphic.fill([brightness,brightness,0])
    
    return @f_graphic
  end
  
  def initialize environment,energy,x=0,y=0
    super()
    @environment = environment
    @energy = energy
    @pos = [x,y]
    
    @image = graphic
    @rect = @image.make_rect
    @rect.center = @pos
    
#    @velocity = [1,1]
  end

  def mass
    return @amount/5
  end
  
  def eaten
#    @environment.remove_eo(self)
    kill
  end
  
#  def update
#    update_pos
#    @rect.center = @pos
#  end
  
#  def update_pos
#    @pos = Array.new(2) { |i| @pos[i] + @velocity[i] }
#    
#    for i in 0..1
#      
#      if @pos[i] <= 0
#        @pos[i] += @environment.game.size[i]
#      elsif @pos[i] > @environment.game.size[i]
#        @pos[i] -= @environment.game.size[i]
#      end
#      
#    end
#  end
end