require "rubygems"
require "log4r"
include Log4r

@@ACT_TAG = ".txt"
@@POP_TAG = "[p].csv"
@@FR_TAG = "[f].csv"
@@ERR_TAG = "[e].txt"

def setup_log dir, name
  
  time_sig = Time.new.strftime("%y%m%d-%H%M%S")
  file_path = "#{dir}/#{name}_#{time_sig}"
  
  unless File.exists?("#{file_path}")
    $LOG_FILE_BASE = "#{file_path}"
  else
    i = 0
    while File.exists?("#{file_path}(#{i})")
      i += 1
    end
    $LOG_FILE_BASE = "#{file_path}(#{i})"
  end
  
  
  act_log_file = $LOG_FILE_BASE + @@ACT_TAG
  
  log = Logger.new "activity_log"
  console_format = PatternFormatter.new(:pattern => "%l:\t %m")
  log.add Log4r::StdoutOutputter.new("console", :formatter => console_format,
                                      :level => $LOG_CONSOLE_LEVEL)
  
  if $LOG_ACT and not defined?(Ocra)
    file_format = PatternFormatter.new(:pattern => "[ %d ] %l\t %m")
    log.add FileOutputter.new("file", :filename => act_log_file, :trunc => false,
                                :formatter=>file_format, :level => $LOG_FILE_BASE_LEVEL)
  end
  
  pop_log_file = $LOG_FILE_BASE + @@POP_TAG
  
  if $LOG_POP and not defined?(Ocra)
    pop_log = Logger.new "population_log"
    format = PatternFormatter.new(:pattern => "%m")
    pop_log.add FileOutputter.new("pop_output", :filename => pop_log_file, :formatter => format,
                                    :trunc => false)
    $POP_LOG = pop_log
  end
  
  fr_log_file = $LOG_FILE_BASE + @@FR_TAG
  
  if $LOG_FR and not defined?(Ocra)
    fr_log = Logger.new "framerate_log"
    format = PatternFormatter.new(:pattern => "%m")
    fr_log.add FileOutputter.new("fr_output", :filename => fr_log_file, :formatter => format,
                                  :trunc => false)
    $FR_LOG = fr_log
  end
  
  error_log_file = $LOG_FILE_BASE + @@ERR_TAG
  
  if $LOG_ERR
    format = PatternFormatter.new(:pattern => "[ %d ] %l\t %m")
    log.add FileOutputter.new("error_output", :filename => error_log_file, :formatter => format,
                                :trunc => false, :level => 3)
  end
  
  $LOGGER = log
  
  $LOGGER.info "Logger loaded"
  $LOGGER.info "Logging activity in #{act_log_file}" if $LOG_ACT
  $LOGGER.info "Logging population in #{pop_log_file}" if $LOG_POP
  $LOGGER.info "Logging framerate in #{fr_log_file}" if $LOG_FR
  $LOGGER.info "Logging errors in #{error_log_file}" if $LOG_ERR
  
  case $LOG_CONSOLE_LEVEL
  when 0..1
    $LOGGER.info "Outputting to console in Debug Mode"
  when 2
    $LOGGER.info "Outputting to console in Info Mode"
  when 3..6
    $LOGGER.info "Outputting to console in Silent Mode"
  end
end

def consolidate_logs
  if $ERR_LOG_CLEAN
    error_log_file = $LOG_FILE_BASE + @@ERR_TAG
    File.delete(error_log_file) if File.zero?(error_log_file)
  end
end