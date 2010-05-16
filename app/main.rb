require "rubygems"
require "rubygame"
Dir.require_all("lib/emerge/")

include Rubygame

class Main
  
  attr_reader :screen, :background, :width, :height, :size, :clock, :pond
  
  def initialize
    
    @size = [$POND_WIDTH,$POND_HEIGHT]
    
    @width = size[0]
    @height = size[1]
    
    @screen = Rubygame::Screen.new @size, 0,
                [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF]
    @screen.title = "Emerge"
    
    @queue = Rubygame::EventQueue.new
    @clock = Rubygame::Clock.new
    @clock.target_framerate = $POND_FRAMERATE
    
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

main = Main.new
begin
  main.run
rescue SystemExit
  
rescue Exception => err
  $LOGGER.error err.class.name+": "+err.message
  for i in err.backtrace
    $LOGGER.error i
  end
end

$LOGGER.info "Quitting..."
Rubygame.quit
$LOGGER.info "Closed."