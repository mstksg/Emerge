$LOGGER.debug "Initializing..."

require "set"

require "rubygems"
require "rubygame"
Rubygame::TTF.setup()

Dir.require_all("lib/emerge/")
require $EMERGE_DIRECTORY+"/app/dialog.rb"
require $EMERGE_DIRECTORY+"/app/environment.rb"

unless defined?(Ocra)             ## if being compiled

  $LOGGER.debug "Settings:\tReproduction Rate:\t1/#{$REP_RATE}"
  $LOGGER.debug "Settings:\tMutation Rate:\t\t#{$MUTATION_FACTOR}"
  $LOGGER.debug "Settings:\tBrain Mutation Rate:\t\t#{$BRAIN_MUTATE_FACTOR}/#{$FORGET_FACTOR}"
  $LOGGER.debug "Settings:\tMutation Variance:\t#{$MUTATION_VARIANCE}"

  environment = Environment.new
  
  begin
    environment.run
  rescue SystemExit
    
  rescue Exception => err
    $LOGGER.fatal err.class.name+": "+err.message
    for i in err.backtrace
      $LOGGER.error i
    end
  end
  
  $LOGGER.info "Quitting..."
  Rubygame.quit
  $LOGGER.info "Closed."
else
  
  $LOGGER.info "Quitting..."
  $LOGGER.info "Closed."
  
end