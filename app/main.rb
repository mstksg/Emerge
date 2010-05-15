require "rubygems"
require "rubygame"
Dir.require_all("lib/eo/")
Dir.require_all("app/")

include Rubygame

class Main
  
  attr_reader :screen, :background, :width, :height, :size, :clock, :environment
  
  def initialize
    
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
    
    @environment = Environment.new(self)
    
    $LOGGER.info "Populating pool..."
    
    @environment.sprinkle_eo($ENV_INIT_EO)
    
    @environment.sprinkle_food($ENV_INIT_FOOD)
    
    @environment.draw
    
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
    @environment.update
    screen.title = @clock.framerate.to_s
  end
  
  def undraw
    @environment.undraw
  end
  
  def draw
    @environment.draw
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