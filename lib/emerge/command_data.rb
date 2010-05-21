module Command_Data
  @@POSSIBLE_COMMANDS = [:move,:wait,:turn,:stop,:emit_energy,:multiply_speed,
                          :set_speed,:shoot_spike,:if]
  @@COMMAND_WEIGHTS   = { :move           => 1.5 ,
                          :wait           => 1.0 ,
                          :turn           => 1.0 ,
                          :stop           => 0.15,
                          :emit_energy    => 0.2 ,
                          :multiply_speed => 0.5 ,
                          :set_speed      => 0.5 ,
                          :shoot_spike    => 0.25,
                          :if             => 1.0  }
  @@COMMAND_WEIGHT_SUM= @@COMMAND_WEIGHTS.values.inject { |sum,n| sum+n }
  @@COMMAND_RANGES    = { :move           => [[-180,180],[0.05,1]]   ,
                          :wait           => [[0,40]]                ,
                          :turn           => [[-180,180]]            ,
                          :stop           => []                      ,
                          :emit_energy    => [[0,7.5],[15,345],[1,6]],
                          :multiply_speed => [[0,2.5]]               ,
                          :set_speed      => [[0,1]]                 ,
                          :shoot_spike    => [[1,6],[-180,180],[1,6]] }
  
  
  
  @@POSSIBLE_IF_CONDS = [:energy,:age,:velocity,:momentum,:random]
  @@IF_WEIGHTS        = { :energy   => 1  ,
                          :age      => 0.5,
                          :velocity => 0.7,
                          :momentum => 0.5,
                          :random   => 0.2 }
  @@IF_WEIGHT_SUM     = @@IF_WEIGHTS.values.inject { |sum,n| sum+n }
  
  @@IF_RANGES         = { :energy   => [0,50]  ,    ## find ways to indicate tendency
                          :age      => [0,2500],
                          :velocity => [0,4]   ,
                          :momentum => [0,80]  ,
                          :random   => [0,1]    }
  @@IF_COMPS          = [:lt,:gt]
  
  
  for command in @@POSSIBLE_COMMANDS
    @@COMMAND_WEIGHTS[command] /= @@COMMAND_WEIGHT_SUM
  end
  for cond in @@POSSIBLE_IF_CONDS
    @@IF_WEIGHTS[cond] /= @@IF_WEIGHT_SUM
  end
  
  @@ALIASES           = { :move           => "m" ,
                          :wait           => "w" ,
                          :turn           => "t" ,
                          :stop           => "s" ,
                          :emit_energy    => "e" ,
                          :multiply_speed => "x" ,
                          :set_speed      => "v" ,
                          :shoot_spike    => "p" ,
                          :if             => "f" ,
                          
                          :energy         => "E" ,
                          :age            => "A" ,
                          :velocity       => "V" ,
                          :momentum       => "M" ,
                          :random         => "R"  }
  
end