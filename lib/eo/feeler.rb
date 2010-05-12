require "rubygems"
require "rubygame"

include Rubygame

class Feeler
  include Sprites::Sprite
  
  POKE_FORCE_FACTOR = 1.0/4.0
  
  attr_reader :owner, :length, :strength, :sensitivity, :mass
  
  def graphic
    return @f_graphic if @f_graphic
    
    pen_thickness = (@strength/2).to_i
    pen = Surface.new([pen_thickness,pen_thickness],0)
    pen.fill([100,100,100])
    
    
#    pen.draw_circle_s([pen_thickness/2,pen_thickness/2],pen_thickness/2,[100,100,100])
    
    @f_graphic = Surface.new([10,10],0)
    @f_graphic.fill([0,0,0])
    
    @f_graphic.colorkey = [0,0,0]
    
    y_pos = 10
    
    while y_pos > 10-length
      pen.blit(@f_graphic,[5-pen_thickness/2,y_pos])
      y_pos -= 0.25
    end
    
    return @f_graphic
  end
  
  def initialize owner, length, strength, sensitivity
    
    super()
    
    @owner = owner
    
    raise "Maximum length is 10" if length > 10
    
    @length = length
    @strength = strength
    @sensitivity = sensitivity
    @mass = length*strength/10    # define this more later on
    
    @image = graphic
    @rect = @image.make_rect
  end
  
  def max_dist
    return @max_dist if @max_dist
    @max_dist = (100+(@length+5)**2)**0.5
  end
  
  def trigger momentum
    ## should add some fuzzying of momentum due to sensitivity here
    @owner.feeler_triggered(momentum)
  end
  
  def poke target
    # should be poking an Eo
    poke_force = @strength*(@owner.velo_magnitude+1)*POKE_FORCE_FACTOR
    target.poked(poke_force,@owner)
  end
  
end