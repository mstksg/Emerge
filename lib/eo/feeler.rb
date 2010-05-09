class Feeler
  
  POKE_FORCE_FACTOR = 1.0/2.0
  
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
  
  def poke target
    # should be poking an Eo
    poke_force = @strength*(@owner.velo_magnitude+1)*POKE_FORCE_FACTOR
    target.poked(poke_force)
  end
  
end