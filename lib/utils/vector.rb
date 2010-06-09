class Vector_Array < Array
  
  @@deg_mod = 360
  @@rad_mod = Math::PI*2
  
  def initialize array
    super(array)
    self.freeze
  end
  
  def self.from_array array
    Vector_Array.new(Array.new(array))
  end
  
  def self.from_points point1, point2
    Vector_Array.new([point2[0]-point1[0],point2[1]-point1[1]])
  end
  
  def self.from_angle angle, deg=true
    return Vector_Array.new([Math.d_cos(angle),Math.d_sin(angle)]) if deg
    return Vector_Array.new([Math.cos(angle),Math.sin(angle)])
  end
  
  def dot other
    # if self.size != other.size
      # raise "Can only dot two similar-sized vectors"
    # end
    
    Array.new(self.size) { |i| self[i]*other[i] }.inject(0) { |sum,n| sum+n }
    
  end
  
  def mult scalar
    Vector_Array.new(self.size) { |i| self[i]*scalar }
  end
  
  def add other
    # if self.size != other.size
      # raise "Can only add two similar-sized vectors"
    # end
    
    Vector_Array.new(self.size) { |i| self[i] + other[i] }
  end
  
  def sub other
    # if self.size != other.size
      # raise "Can only subtract two similar-sized vectors"
    # end
    
    Vector_Array.new(self.size) { |i| self[i] - other[i] }
  end
  
  def unit_vector
    mag = magnitude
    Vector_Array.new(self.size) { |i| self[i]/mag }
  end
  
  def magnitude
    sums = Array.new(self.size) { |i| self[i]*self[i] }.inject{ |sum,n| sum+n }
    sums**0.5
  end
  
  def distance_to_point(point,starting)
    r = Vector_Array.from_points point, starting
    (unit_vector.ortho_2D.dot(r)).abs
  end
  
  def ortho_2D    ## counter clockwise
    Vector_Array.new([-self[1],self[0]])
  end
  
  def angle deg=true
    if self[0] == 0
      return 0 if self[1] == 0
      if self[1] > 0
        return 90 if deg
        return Math::PI/2
      else
        return 270 if deg
        return 3*Math::PI/2
      end
    end
    if deg
      base_angle = Math.d_atan(self[1].to_f/self[0])
      mod = @@deg_mod
    else
      base_angle = Math.atan(self[1].to_f/self[0])
      mod = @@rad_mod
    end
    
    if self[0] > 0
      return (base_angle)%mod
    else
      return (base_angle+180)%mod
    end
  end
  
  def to_s
    "[#{self.join(",")}]"
  end
  
  def angle_between other, deg=true
    dotted = self.unit_vector.dot(other.unit_vector)
    
    return 0 if dotted.nan?         ## either return 0, or return dotted; not sure what to define here
    
    dotted = 1 if dotted > 1
    dotted = -1 if dotted < -1
    
    return Math.d_acos(dotted) if deg
    Math.acos(dotted)
  end
  
  def angle_to other, deg=true
    return (other.angle-angle)%360 if deg
    return (other.angle(deg)-angle(deg))%@@rad_mod
  end
  
  alias :normalize :unit_vector
end