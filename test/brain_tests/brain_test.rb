require File.dirname(__FILE__)+"/../../app/setup/load_config.rb"
require File.dirname(__FILE__)+"/../../lib/emerge/eo_dna.rb"
require File.dirname(__FILE__)+"/brain_tester.rb"
require 'benchmark'

$VERBOSE = false

@testblock = Command_Block.fresh_block 15
puts @testblock.to_s

brain_tester1 = Brain_Tester.new(:brain_1,@testblock)
brain_tester2 = Brain_Tester.new(:brain_2,@testblock)
brain_tester3 = Brain_Tester.new(:brain_3,@testblock)

#brain_tester1.run_through
#puts "---"
#brain_tester2.run_through
#puts "---"
#brain_tester3.run_through

def bench_brain
  n = 20000
  Benchmark.bm do |x|
    x.report("brain1") { n.times do ; Brain_Tester.new(:brain_1,@testblock).run_through ; end }
    x.report("brain2") { n.times do ; Brain_Tester.new(:brain_2,@testblock).run_through ; end }
    x.report("brain3") { n.times do ; Brain_Tester.new(:brain_3,@testblock).run_through ; end }
  end
end

def bench_brain_warm
  n = 20000
  Benchmark.bm do |x|
    x.report("brain1") { brain = Brain_Tester.new(:brain_1,@testblock) ; n.times do ; brain.run_through ; end }
    x.report("brain1") { brain = Brain_Tester.new(:brain_2,@testblock) ; n.times do ; brain.run_through ; end }
    x.report("brain1") { brain = Brain_Tester.new(:brain_3,@testblock) ; n.times do ; brain.run_through ; end }
  end
end

def bench_brain_random
  n = 1000
  Benchmark.bm do |x|
    x.report("brain1") { n.times do ; Brain_Tester.new(:brain_1,Command_Block.fresh_block(15)).run_through ; end }
    x.report("brain2") { n.times do ; Brain_Tester.new(:brain_2,Command_Block.fresh_block(15)).run_through ; end }
    x.report("brain3") { n.times do ; Brain_Tester.new(:brain_3,Command_Block.fresh_block(15)).run_through ; end }
  end
end


bench_brain
bench_brain_warm
bench_brain_random