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