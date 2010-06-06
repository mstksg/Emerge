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
    begin
      r2d( asin(x) )
    rescue Exception
      raise "Error while trying to find arcsin of #{x}"
    end
  end
  def self.d_acos x
    begin
      r2d( acos(x) )
    rescue Exception
      raise "Error while trying to find arccos of #{x}"
    end
  end
  def self.d_atan x
    r2d( atan(x) )
  end
  
end