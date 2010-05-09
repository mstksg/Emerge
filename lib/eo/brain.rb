class Brain
  
  attr_reader :owner
  
  def initialize owner, container_walls, programs
    
    if programs.size() != container_walls.size() + 1
      raise "Improper brain settings"
    end
    
    @owner = owner
    @container_walls = container_walls
    @programs = programs
  end
  
  def process momentum
    
    if @container_walls.size() == 0
      run_program @programs[0]
    else
      count = 0
      while @container_walls[count] < momentum
        count += 1
      end
      run_program @programs[count]
    end
    
  end
  
  def run_program program
    ## executing program
  end
  
end