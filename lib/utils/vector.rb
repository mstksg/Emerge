class Vector_Array < Array
  
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
    (unit_vector.dot(r)).abs
  end
  
end