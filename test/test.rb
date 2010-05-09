## Dir[File.dirname(__FILE__)+"/../lib/eo/"].each {|file| require file }

require File.dirname(__FILE__)+"/../lib/eo/eo.rb"
require File.dirname(__FILE__)+"/../lib/eo/eo_dna.rb"
require File.dirname(__FILE__)+"/../lib/eo/brain.rb"
require File.dirname(__FILE__)+"/../lib/eo/feeler.rb"
require "test/unit"

class TestEo < Test::Unit::TestCase
  def test_simple
    test_dna = Eo_DNA.new(1,2,3,4,5,6,[1,2],[2,3,4])
    
    assert test_dna.shell == 1
    assert_equal([1,2], test_dna.b_containers)
    assert_equal([2,3,4], test_dna.b_programs)
    
    test_eo = Eo.new(test_dna,10)
    
    assert_equal(10,test_eo.energy)
    assert_equal(1,test_eo.body.shell)
    
    assert_equal(4,test_eo.feeler.length)
    
    new_eo = test_eo.mutate 8
    
    assert_equal(8,new_eo.energy)
    assert_equal(1,new_eo.body.shell)
    assert_equal(6,new_eo.body.max_speed)
    
    assert_equal(4,new_eo.feeler.length)
    
    assert_equal(10,test_eo.energy)
    
    assert_equal(1,test_eo.body.hp)
    new_eo.feeler.poke(test_eo)
    puts test_eo.body.hp
  end
end