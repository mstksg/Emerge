class Dir
  def self.require_all(directory)
    self.entries($EMERGE_DIRECTORY+"/"+directory).each do |file|
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

class Set
  def pick_rand
    self.to_a.pick_rand
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