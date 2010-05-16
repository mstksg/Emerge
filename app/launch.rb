Dir.require_all("lib/emerge/")
require File.dirname(__FILE__)+"/environment.rb"

$LOGGER.debug "Reproduction Rate:\t1/#{$REP_RATE}"
$LOGGER.debug "Mutation Rate:\t\t #{$MUTATION_FACTOR}"
$LOGGER.debug "Mutation Variance:\t #{$MUTATION_VARIANCE}"

environment = Environment.new

begin
  environment.run
rescue SystemExit
  
rescue Exception => err
  $LOGGER.error err.class.name+": "+err.message
  for i in err.backtrace
    $LOGGER.error i
  end
end

$LOGGER.info "Quitting..."
Rubygame.quit
$LOGGER.info "Closed."