require "rubygems"
require "rubygame"

include Rubygame

class Environment
  
  attr_reader :screen, :background, :width, :height, :size, :clock, :pond
  
  def initialize
    
    $LOGGER.debug "Initializing #{$ENV_WIDTH}x#{$ENV_HEIGHT} environment..."
    
    @size = [$ENV_WIDTH,$ENV_HEIGHT]
    
    @width = size[0]
    @height = size[1]
    
    @screen = Rubygame::Screen.new @size, 0,
                [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF]
    @screen.title = "Emerge"
    
    @queue = Rubygame::EventQueue.new
    @clock = Rubygame::Clock.new
    @clock.target_framerate = $ENV_FRAMERATE
    
    @background = Surface.new( @screen.size )
    @background.fill( Color::ColorRGB.new([0.1, 0.2, 0.35]) )
    
    @background.blit(@screen,[0,0])
    
    @pond = Pond.new(self)
    
    $LOGGER.info "Populating pool..."
    
    @pond.sprinkle_eo($POND_INIT_EO)
    @pond.sprinkle_food($POND_INIT_FOOD)
    
    @pond.draw
    
    @screen.flip()
    
  end
  
  def run
    loop do
      undraw
      update
      draw
      @clock.tick
    end
  end
  
  def update
    @queue.each do |ev|
      case ev
      when Rubygame::QuitEvent
        Rubygame.quit
        exit
      end
    end
    @pond.update
    
    if $LOG_POP
      if @clock.ticks % $POND_POP_LOG_FREQ == 0
        $POP_LOG.info "#{@clock.ticks},#{@pond.eos.size},#{@pond.foods.size}"
      end
    end
    
    screen.title = @clock.framerate.to_s
  end
  
  def undraw
    @pond.undraw
  end
  
  def draw
    @pond.draw
    @screen.flip()
  end
end