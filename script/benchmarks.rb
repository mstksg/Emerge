require 'benchmark'

def b_copy
  n = 100000
  Benchmark.bm do |x|
    x.report('copy') { n.times do ; h = {}; h = h.merge({1 => 2}); end }
    x.report('no copy') { n.times do ; h = {}; h.merge!({1 => 2}); end }
  end
end

def b_square
  n = 1000000
  num = 25
  Benchmark.bm do |x|
    x.report("mult\t") { n.times do ; num*num ; end }
    x.report("square\t") { n.times do ; num**2 ; end }
    x.report("^1.25\t") { n.times do ; num**1.25 ; end }
    x.report("^3\t") { n.times do ; num**3 ; end }
    x.report("ops_m\t") { n.times do ; (num+5)*(num+5) ; end }
    x.report("ops_s\t") { n.times do ; (num+5)**2 ; end }
  end
end

def b_square_root
  n = 1000000
  num = 26
  Benchmark.bm do |x|
    x.report("normal") { n.times do ; num**0.5 ; end }
    x.report("normal f") { n.times do ; num**(1.0/2.0) ; end }
    x.report("math") { n.times do ; Math.sqrt(num) ; end }
    x.report("square") { n.times do ; num**2 ; end }
  end
end

def b_odd_power
  n = 5000000
  num = 26
  Benchmark.bm do |x|
    x.report("normal") { n.times do ; num**1.5 ; end }
    x.report("normal fr") { n.times do ; num**(3/2) ; end }
    x.report("products") { n.times do ; num**(1/2)*num**(1/2)*num**(1/2) ; end }
    x.report("products c1") { n.times do ; srt = num**(1/2) ; srt*srt*srt ; end }
    x.report("products c2") { srt = num**(1/2) ; n.times do ; srt*srt*srt ; end }
    x.report("compare") { n.times do ; num**(1/2) ; end }
  end
end

def b_division
    n = 5000000
  num = 26
  Benchmark.bm do |x|
    x.report("division") { n.times do ; 1/num ; end }
    x.report("inverse") { n.times do ; num**(-1) ; end }
    x.report("sqrt") { n.times do ; num**(1/2) ; end }
    x.report("sqr") { n.times do ; num*num ; end }
  end
end

def b_returns
  def method1
    new_num = rand
    Array.new() << new_num
  end
  def method2
    new_num = rand
    Array.new() << new_num
    return new_num
  end
  n = 5000000
  Benchmark.bm do |x|
    x.report("method1") { n.times do ; method1 ; end }
    x.report("method2") { n.times do ; method2 ; end }
  end
end


#b_copy
#b_square
#b_square_root
#b_odd_power
#b_division
b_returns