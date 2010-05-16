module Mutations
  
  def self.rand_norm_dist min=0,max=10,curve=5
    Array.new(curve) { |i| rand*(max-min)+min }.inject { |sum,n| sum+n }/curve
  end
  
  def self.mutate curr,min=0,max=10,variance=$MUTATION_VARIANCE,curve=3
    
    raise "Bad min/max" if min >= max
    
    new_num = curr + rand_norm_dist(-variance,variance,curve)
    
    if new_num >= max
      #      $LOGGER.debug "Over-Mutate, Too High\t(#{curr},#{min},#{max},#{variance},#{curve},#{new_num})"
      return mutate(curr,min,max,(max-curr),curve)
    end
    if new_num <= min
      #      $LOGGER.debug "Over-Mutate, Too Low\t(#{curr},#{min},#{max},#{variance},#{curve},#{new_num})"      
      return mutate(curr,min,max,(curr-min),curve)
    end
    
    return new_num
    
  end
  
  def self.mutate_percent curr,min=0,max=10,variance_percent=$MUTATION_VARIANCE/10,curve=3
    mutate(curr,min,max,(max-min)*variance_percent,curve)
  end
  
end