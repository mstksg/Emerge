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
  
  attr_reader :pos,:message,:color,:alpha
  attr_accessor :anchor,:margin
  
  def initialize pos,message,color=[255,255,255],alpha=127,anchor=2, margin=4
    
    super()
    
    @pos = pos.clone
    @message = message
    @color = color
    @alpha = alpha
    @anchor = anchor
    @margin = margin
    
    reset_image
  end
  
  def graphic redraw = false
    return @dialog_image if @dialog_image and not redraw
    
    text = @@DIALOG_FONT.render(@message, true, [0,0,0])
    text_rect = text.make_rect
    
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
    
    case @anchor
    when 0
      @rect.topleft = [@pos[0]+@margin,@pos[1]+@margin]
    when 1
      @rect.topright = [@pos[0]-@margin,@pos[1]+@margin]
    when 2
      @rect.bottomleft = [@pos[0]+@margin,@pos[1]-@margin]
    when 3
      @rect.bottomright = [@pos[0]-@margin,@pos[1]-@margin]
    when 4
      @rect.center = [@pos[0],@pos[1]]
    end
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