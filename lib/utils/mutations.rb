module Mutations
  
  def self.rand_norm_dist min=0,max=10,curve=5
    Array.new(curve) { |i| rand*(max-min)+min }.inject { |sum,n| sum+n }/curve
  end
  
  def self.mutate curr,min=0,max=10,variance=$MUTATION_VARIANCE,curve=$DNA_MUTATION_CURVE,wrap=false
    
    # raise "Bad min/max #{min}/#{max}" if min >= max
    
    new_num = curr + rand_norm_dist(-variance,variance,curve)
    
    if wrap
      return (new_num-min) % (max-min) + min if new_num >= max or new_num <= min
    else
      return (curr*curve+max)/(curve+1) if new_num >= max
      return (curr*curve+min)/(curve+1) if new_num <= min
    end
    
    return new_num
  end
  
  def self.mutate_percent curr,min=0,max=10,variance_percent=$MUTATION_VARIANCE/10,curve=3,wrap=false
    mutate(curr,min,max,(max-min)*variance_percent,curve,wrap)
  end
  
end