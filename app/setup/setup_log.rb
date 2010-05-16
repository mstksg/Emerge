require "rubygems"
require "log4r"
include Log4r

def setup_log dir, name
  
  time_sig = Time.new.strftime("%y%m%d-%H%M%S")
  file_path = "#{dir}/#{name}_#{time_sig}"
  
  unless File.exists?("#{file_path}.txt")
    logfile = "#{file_path}.txt"
  else
    i = 0
    while File.exists?("#{file_path}(#{i}).txt")
      i += 1
    end
    logfile = "#{file_path}(#{i}).txt"
  end
  
  log = Logger.new "activity_log"
  console_format = PatternFormatter.new(:pattern => "%l:\t %m")
  log.add Log4r::StdoutOutputter.new("console", :formatter => console_format,
                                      :level => $LOG_CONSOLE_LEVEL)
  
  if $LOG_ACT
    file_format = PatternFormatter.new(:pattern => "[ %d ] %l\t %m")
    log.add FileOutputter.new("file", :filename => logfile, :trunc => false,
                                :formatter=>file_format, :level => $LOG_FILE_LEVEL)
  end
  
  pop_log_file = logfile.sub(".txt","[p].csv")
  
  if $LOG_POP
    pop_log = Logger.new "population_log"
    format = PatternFormatter.new(:pattern => "%m")
    pop_log.add FileOutputter.new("pop_output", :filename => pop_log_file, :formatter => format)
    $POP_LOG = pop_log
  end
  
  $LOGGER = log
  
  $LOGGER.info "Logger loaded"
  $LOGGER.info "Logging in activity in #{logfile}" if $LOG_ACT
  $LOGGER.info "Logging in population in #{pop_log_file}" if $LOG_POP
end