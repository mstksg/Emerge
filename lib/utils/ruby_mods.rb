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
    r2d( acos(x) )
  end
  def self.d_atan x
    r2d( atan(x) )
  end
  
end

module Boundarizer
  
  def boundarize min=0,max=1,allow_min=true,allow_max=false 
    
    raise "Improper boundaries" if min >= max
    
    min_test = case allow_min
    when true then lambda { |num| num < min  }
    when false then lambda { |num| num <= min }
    end
    max_test = case allow_max
    when true then lambda { |num| num > max  }
    when false then lambda { |num| num >= max }
    end
    
    new_num = self
    
    while min_test.call(new_num)
      new_num += max
    end
    while max_test.call(new_num)
      new_num -= max
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