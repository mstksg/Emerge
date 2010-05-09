class Feeler
  
  attr_reader :owner, :length, :strength, :sensitivity, :mass
  
  def initialize owner, length, strength, sensitivity
    @owner = owner
    
    @length = length
    @strength = strength
    @sensitivity = sensitivity
    @mass = length*strength/10    # define this more later on
  end
  
  def trigger momentum
    ## should add some fuzzying of momentum due to sensitivity here
    @owner.feeler_triggered(momentum)
  end
  
end