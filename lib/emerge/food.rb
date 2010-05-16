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
  
  def initialize energy,x=0,y=0
    super()
    
    @energy = energy
    @pos = [x,y]
    
    @image = graphic
    @rect = @image.make_rect
    @rect.center = @pos
  end
  
  def mass
    return @energy*$POND_FOOD_MASS
  end
  
  def eaten
    kill
  end
  
end

class Packet < Food
  
  def initialize pond,energy,x=0,y=0,speed=0,angle=0
    super(energy,x,y)
    
    @pond = pond
    
    move_angle = 270-angle
    @velocity = Vector_Array.new([Math.d_cos(move_angle)*speed,Math.d_sin(move_angle)*speed])
  end
  
  def update
    update_velo
    update_pos
    
    if @velocity == [0,0]
      turn_into_food
    else
      @rect.center = @pos
    end
  end
  
  def update_velo
    if @velocity.magnitude < $POND_DRAG
      @velocity = [0,0]
    else
      @velocity = @velocity.sub(@velocity.unit_vector.mult($POND_DRAG))
    end
  end
  
  def update_pos
    @pos = Array.new(2) { |i| @pos[i] + @velocity[i] }
    
    for i in 0..1
      
      @pos[i] = @pos[i].boundarize(0,@pond.environment.size[i],false,true)
      
    end
  end
  
  def turn_into_food
    kill
    @pond.add_food(@energy,@pos[0],@pos[1])
  end
  
end