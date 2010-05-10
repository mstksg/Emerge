require "rubygems"
require "rubygame"
Dir.require_all("lib/eo/")
Dir.require_all("app/")

include Rubygame
 
class Main
  
  attr_reader :screen, :background
  
  def initialize
    @screen = Rubygame::Screen.new [640,480], 0, [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF]
    @screen.title = "Emerge"
 
    @queue = Rubygame::EventQueue.new
    @clock = Rubygame::Clock.new
    @clock.target_framerate = 50
    
    @background = Surface.new( @screen.size )
    @background.fill( Color::ColorRGB.new([0.1, 0.2, 0.35]) )
    
    @background.blit(@screen,[0,0])
    
    @test_dna = Eo_DNA.new(1,2,3,8,5,6,[1,2],[2,3,4])
    @test_env = Environment.new()
    
    @test_eo = Eo.new(@test_env,@test_dna,10)
    
    @test_eo.rect.center = [100,100]
    @test_eo.draw(@screen)
    
    @screen.update()
    
  end
 
  def run
    loop do
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
  end
 
  def draw
    @screen.update()
  end
end

main = Main.new
main.run

Rubygame.quit