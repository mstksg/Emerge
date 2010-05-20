$LOG_CONSOLE_LEVEL = 1 if $DEBUG

check_log = false

unless $*.size == 0 or $*.find_all { |a| a =~ /-D/ }.size > 0
  
  $LOG_POP = false
  $LOG_ACT = false
  $LOG_FR = false
  $AUTO_TRACKING = false
  
  $*.each do |a|
    if check_log
      $LOG_POP = true if a =~ /p/
      $LOG_ACT = true if a =~ /a/
      $LOG_FR = true if a =~ /f/
      check_log = false
    else
      case a
      when /-t/
        $AUTO_TRACKER = true
      when /-i/
        $LOG_CONSOLE_LEVEL = 2
      when /-s/
        $LOG_CONSOLE_LEVEL = 3
      when /-d/
        $LOG_CONSOLE_LEVEL = 1
      when /-l/
        $LOG_POP = false if $LOG_POP == nil
        $LOG_ACT = false if $LOG_ACT == nil
        $LOG_FR = false if $LOG_ACT == nil
        check_log = true
      else
        $env_choice = a
      end
    end
  end
  
end