require "rubygems"
require "rubygame"

include Rubygame

class Environment
  
  attr_reader :screen, :background, :width, :height, :size, :clock, :pond, :dialog_layer
  
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
    
    @dialog_layer = Dialog_Layer.new(self)
    
    @fr_dialog = Bubble_Dialog.new([0,0],"#{$ENV_FRAMERATE}/#{$ENV_FRAMERATE}",[2,255,255],63,3)
    @dialog_layer.add_dialog @fr_dialog
    
    @pond = Pond.new(self)
    
    $LOGGER.info "Populating pool..."
    
    @pond.sprinkle_eo($POND_INIT_EO)
    @pond.sprinkle_food($POND_INIT_FOOD)
    
    @pond.select_random if $AUTO_TRACKING
    
    @pond.draw
    @dialog_layer.draw
    
    @screen.flip()
    
  end
  
  def run
    loop do
      
      @fr = @clock.framerate
      if @fr != 0 and @fr < $FRAMERATE_LIMIT
        raise "Computational overload; Framerate = #{@fr}"
      end
      
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
      when Rubygame::MouseUpEvent
        @pond.clicked(ev.pos,ev.button)
      when Rubygame::KeyUpEvent
        @pond.keyed(ev.key,ev.mods)
      end
    end
    @pond.update
    
    if $LOG_FR
      if @clock.ticks % $LOG_FR_FREQ == 0
        $FR_LOG.info "#{@clock.ticks},#{@fr}"
      end
    end
    if $LOG_POP
      if @clock.ticks % $LOG_POP_FREQ == 0
        $POP_LOG.info "#{@clock.ticks},#{@pond.eos.size},#{@pond.foods.size}"
      end
    end
    
    #    @dialog.upate
    
    @fr_dialog.change_message "#{@clock.framerate}/#{$ENV_FRAMERATE}" if @clock.ticks % $ENV_FRAMERATE == 0
  end
  
  def undraw
    @pond.undraw
    @dialog_layer.undraw
  end
  
  def draw
    @pond.draw
    @dialog_layer.draw
    @screen.flip()
  end
end