class Brain
  
  attr_reader :owner
  
  def initialize (owner, container_walls, programs, birth_program)
    
    if programs.size() != container_walls.size() + 1
      raise "Improper brain settings; #{programs.size} programs for #{container_walls.size} walls"
    end
    
    @owner = owner
    @container_walls = container_walls
    @programs = programs
    @birth_program = birth_program
    
    @program_queue = []
    @momentum_trigger = 0
    @waiting = 0
  end
  
  def process momentum
    
    @momentum_trigger = momentum
    
    if @container_walls.size() == 0
      run_program @programs[0]
    else
      count = 0
      while count < @container_walls.size and @container_walls[count] < momentum
        count += 1
      end
      run_program @programs[count]
    end
    
  end
  
  def run_birth_program
    run_program @birth_program
  end
  
  def run_program program
    @program_queue = [program.clone]
    @waiting = 0
  end
  
  def pull_next_command
    
    ## Turns out that the old one was more or less completely
    ## broken; this one is accurate, but much slower(?) about 2x as slow
    
    if @program_queue.size > 0
      
      if @program_queue[0].size == 0
        @program_queue.shift
        return pull_next_command
      else
        
        curr_command = @program_queue[0].shift
        
        if curr_command.class == Command_Block
          @program_queue.unshift curr_command
          return pull_next_command
        else # curr_command.class == Eo_Command
          
          if curr_command.command == :if
            if @program_queue[0].size == 0
              return pull_next_command
            else
              eval_true = eval_if curr_command
              
              if eval_true
                return pull_next_command
              else
                while curr_command.class == Eo_Command and curr_command.command == :if
                  if @program_queue[0].size == 0
                    return pull_next_command
                  end
                  curr_command = @program_queue[0].shift
                end
                
                return pull_next_command
                
              end
            end
            
          else
            return curr_command
          end
        end
      end
    else
      return false
    end
  end
  
  def eval_if if_command
    cond = case if_command.args[0]
    when :energy then @owner.energy
    when :age then @owner.age
    when :velocity then @owner.velo_magnitude
    when :momentum then @momentum_trigger
    when :random then rand()
    else raise "Bad 'if' condition #{if_command.args[0]}"
    end   ## maybe add more conditions later
    
    if if_command.args[1] == :lt
      return cond < if_command.args[2]
    else
      return cond > if_command.args[2]
    end
  end
  
  def read_program
    
    if @waiting <= 0
      
      curr_command = pull_next_command
      
      if curr_command
        
        case curr_command.command
        when :move
          if curr_command.args[1] > 1
            raise "Bad velocity for 'move': #{curr_command.args[1]}"
          end
          @owner.move(curr_command.args[0],curr_command.args[1])
        when :wait
          @waiting = curr_command.args[0].to_i
        when :turn
          @owner.turn(curr_command.args[0])
        when :stop
          @owner.stop
        when :emit_energy
          @owner.emit_energy(curr_command.args[0],curr_command.args[1],curr_command.args[2])
        when :multiply_speed
          @owner.multiply_speed(curr_command.args[0])
        when :set_speed
          if curr_command.args[0] > 1
            raise "Bad velocity for 'set speed': #{curr_command.args[0]}"
          end
          @owner.set_speed(curr_command.args[0])
        else
          raise "Bad command #{curr_command.command}"
        end
      end
      
      
    else
      @waiting -= 1
    end
    
  end
  
end