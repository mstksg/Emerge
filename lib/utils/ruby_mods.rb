PROJ_DIR = File.dirname(__FILE__)+"/../../"

class Dir
  def self.require_all(directory)
    self.entries(PROJ_DIR+directory).each do |file|
      if file =~ /\.rb/
        require directory + file
      end
    end
  end
end

class Array
  def pick_rand
    self[Kernel.rand(length)]
  end
end

module Math
  
  def self.d2r d
    d * Math::PI / 180
  end
  def self.r2d r
    r * 180 / Math::PI
  end
  
  def self.d_sin x
    sin d2r(x)
  end
  def self.d_cos x
    cos d2r(x)
  end
  def self.d_tan x
    tan d2r(x)
  end
  
  def self.d_asin x
    r2d( asin(x) )
  end
  def self.d_acos x
    begin
      r2d( acos(x) )
    rescue Exception
      raise "Improper acosine; attempted to arccos #{x}"
    end
  end
  def self.d_atan x
    r2d( atan(x) )
  end
  
end

module Boundarizer
  
  def boundarize min=0,max=1,allow_min=true,allow_max=false 
    
    raise "Improper boundaries #{min}/#{max}" if min >= max
    
    new_num = self
    
    if allow_min
      while new_num < min
        new_num += max
      end
    else
      while new_num <= min
        new_num += max
      end
    end
    
    if allow_max
      while new_num > max
        new_num -= max
      end
    else
      while new_num >= max
        new_num -= max
      end
    end
    
    return new_num
    
  end
  
end

class Float
  include Boundarizer
end
class Integer
  include Boundarizer
end