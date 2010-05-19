require "rubygems"
require "rubygame"

include Rubygame

class Dialog_Layer
  
  attr_reader :environment,:boxes
  
  def initialize environment
    @environment = environment
    
    @dialogs = Sprites::Group.new
    @dialogs.extend(Sprites::UpdateGroup)
  end
  
  def add_dialog to_add
    @dialogs << to_add
  end
  
  def remove_dialog
    @dialogs.delete(to_add)
  end
  
  def update
    
  end
  
  def undraw
    @dialogs.undraw(@environment.screen,@environment.background)
  end
  
  def draw
    @dialogs.draw(@environment.screen)
  end
  
end

class Dialog
  include Sprites::Sprite
  @@DIALOG_FONT = TTF.new("#{File.dirname(__FILE__)}/../data/fonts/#{$FONT_FILE}",12)
  
  #  def draw(destination)
  #    self.image.blit(destination, self.rect)
  #  end
  
end

class Bubble_Dialog < Dialog
  
  # top, right, left, bottom
  # 0 = none, 1 = horizontal flip, 2 = vertical flip, 3 = both
  @@ANCHOR_CORNERS = [ [0,1,2,3], [1,0,3,2], [2,3,0,1], [3,2,1,0] ]
  # none, horizontal, vertical, both
  
  attr_reader :pos,:message,:color,:alpha
  attr_accessor :anchor,:margin
  
  def initialize pos,message,color=[255,255,255],alpha=85,anchor=2,margin=5,boundaries=[$ENV_WIDTH,$ENV_HEIGHT]
    
    super()
    
    @pos = pos.clone
    @message = message
    @color = color
    @alpha = alpha
    @anchor = anchor
    @margin = margin
    @boundaries = boundaries
    @corners_profile = @@ANCHOR_CORNERS[@anchor]
    
    reset_image
  end
  
  def graphic redraw = false
    
    ## TODO account for string truncation
    
    return @dialog_image if @dialog_image and not redraw
    
    text = @@DIALOG_FONT.render(@message, true, [0,0,0])
    text_rect = text.make_rect
    text.clip = text_rect
    
    if text_rect.width > @boundaries[0]-2*@margin-10
      text_rect.width = @boundaries[0]-2*@margin-10
    end
    
    @dialog_image = Surface.new([text_rect.width+10,text_rect.height+6])
    @dialog_image.fill([0,0,0])
    @dialog_image.draw_box_s([1,1],[text_rect.width+8,text_rect.height+4],@color)
    @dialog_image.alpha = @alpha
    
    text.blit(@dialog_image,[5,3])
    
    @dialog_image.to_display
    return @dialog_image
  end
  
  def reset_image redraw = false
    @image = graphic redraw
    @rect = @image.make_rect
    
    if @anchor == 4
      @rect.center = [@pos[0],@pos[1]]
    else
      
      test_rect = @image.make_rect 
      
      case @anchor
      when 0
        test_rect.topleft = [@pos[0]+@margin,@pos[1]+@margin]
      when 1
        test_rect.topright = [@pos[0]-@margin,@pos[1]+@margin]
      when 2
        test_rect.bottomleft = [@pos[0]+@margin,@pos[1]-@margin]
      when 3
        test_rect.bottomright = [@pos[0]-@margin,@pos[1]-@margin]
      end
      
      flip_factor = 0
      
      flip_factor |= 2 if not is_in_bounds? test_rect.top,1
      flip_factor |= 1 if not is_in_bounds? test_rect.left,0
      flip_factor |= 2 if not is_in_bounds? test_rect.bottom,1
      flip_factor |= 1 if not is_in_bounds? test_rect.right,0
      
      if flip_factor == 0
        @rect=test_rect
      else
        
        adjusted_anchor = @corners_profile[flip_factor]
        
        case adjusted_anchor
        when 0
          @rect.topleft = [@pos[0]+@margin,@pos[1]+@margin]
        when 1
          @rect.topright = [@pos[0]-@margin,@pos[1]+@margin]
        when 2
          @rect.bottomleft = [@pos[0]+@margin,@pos[1]-@margin]
        when 3
          @rect.bottomright = [@pos[0]-@margin,@pos[1]-@margin]
        end
        
      end
    end
  end
  
  def is_in_bounds? line,axis    # 0 = x, 1 = y
    return false if line < 0
    return false if line > @boundaries[axis]
    return true
  end
  
  def move_to new_pos
    @pos = new_pos.clone
    reset_image
  end
  
  def change_message new_message, move_to=false
    @pos = move_to.clone if move_to
    if @message == new_message
      reset = false
    else
      reset = true
      @message = new_message
    end
    reset_image reset
  end
  
end