class Vector_Array < Array
  
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
    if self.size != other.size
      raise "Can only dot two similar-sized vectors"
    end
    
    Array.new(self.size) { |i| self[i]*other[i] }.inject { |sum,n| sum+n }
    
  end
  
  def mult scalar
    Vector_Array.new(self.size) { |i| self[i]*scalar }
  end
  
  def add other
    if self.size != other.size
      raise "Can only add two similar-sized vectors"
    end
    
    Vector_Array.new(self.size) { |i| self[i] + other[i] }
  end
  
  def sub other
    if self.size != other.size
      raise "Can only subtract two similar-sized vectors"
    end
    
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
    return Math.d_atan(self[1]/self[0]) if deg
    Math.atan(self[1]/self[0])
  end
  
  def to_s
    "[#{self.join(",")}]"
  end
  
  def angle_to other, deg=true
    return Math.d_acos(self.unit_vector.dot(other.unit_vector)) if deg
    Math.acos(self.unit_vector.dot(other.unit_vector))
  end
  
  alias :normalize :unit_vector
end