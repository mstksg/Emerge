require "rubygems"
require "rubygame"

include Rubygame

module Pond_Bits
  class Food
    include Sprites::Sprite
    
    attr_reader :energy, :pos, :velocity
    
    def initialize energy,x=0,y=0
      super()
      
      @energy = energy
      @pos = [x,y]
      
      @image = graphic
      @rect = @image.make_rect
      @rect.center = @pos
    end
    
    def graphic
      return @f_graphic if @f_graphic
      
      brightness = 100+@energy*7.8
      brightness = 255 if brightness > 255
      
      @f_graphic = Surface.new([2,2],0)
      @f_graphic.fill([brightness,brightness,0])
      
      return @f_graphic
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
  
  class Spike
    include Sprites::Sprite
    
    attr_reader :mass, :owner, :velocity
    
    def initialize pond,mass,owner=nil,x=0,y=0,speed=0,angle=0
      super()
      
      @owner = owner
      @mass = mass
      @drag_factor = $POND_DRAG*@mass/2
      
      @pos = [x,y]
      
      @image = graphic
      @rect = @image.make_rect
      @rect.center = @pos
      
      @pond = pond
      
      move_angle = 270-angle
      @velocity = Vector_Array.new([Math.d_cos(move_angle)*speed,Math.d_sin(move_angle)*speed])
      
      @decaying = false
    end
    
    def graphic
      return @s_graphic if @s_graphic
      
      shade = 100-@mass*15
      shade = 0 if shade < 0
      size = (2+@mass/2).to_i
      
      @s_graphic = Surface.new([size,size],0)
      @s_graphic.fill([shade,shade,shade])
      
      return @s_graphic
    end
    
    def update
      
      unless handle_collisions
        
        if @decaying
          if rand*$POND_SPIKE_DECAY < 1
            turn_into_food
          end
        else
          update_velo
          update_pos
          
          if @velocity == [0,0]
            @decaying = true
          else
            @rect.center = @pos
          end
        end
      end
    end
    
    def handle_collisions
      possibles = @pond.eo_in_rect(@pond.zone_rects[@pond.point_in_zone(@pos)])
      for eo in possibles
        vec = Vector_Array.from_points(eo.pos,@pos)
        dist = vec.magnitude
        if dist <= 5
          eo.body.spiked(self)
          kill
          return true
        end
      end
      return false
    end
    
    def update_velo
      if @velocity.magnitude < @drag_factor
        @velocity = [0,0]
      else
        @velocity = @velocity.sub(@velocity.unit_vector.mult(@drag_factor))
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
      @pond.add_food(@mass*2,@pos[0],@pos[1])
    end
    
  end
  
end