## ARGUMENTS
##
## -D           : use default settings as defined in ./config/config.yaml
## -l a         :\
## -l p         : ]- enable activity, population, or frequency logging
## -l f         :/    (can be combined)
## -d           :\
## -s           : ]- set console mode (debug, silent, info) (default: info)
## -i           :/
## -t           : turn on auto-tracking
## a string     : loads settings specified by string in ./config/config.yaml
##                  (by default includes: small, regular, large, huge)
##
## Later arguments will overwrite the ones before them (except for --D,
##    which escapes argument processing)

require "rubygems"

$EMERGE_DIRECTORY = File.dirname(File.expand_path($0))
$LOAD_PATH.unshift File.dirname($EMERGE_DIRECTORY)
SDL_PATHS = [ $EMERGE_DIRECTORY+"/lib/SDL",$EMERGE_DIRECTORY+"/lib/SDL/" ]

if ENV['OCRA_EXECUTABLE']                               # if being run as an OCRA executable
  $LOADING_PATH = File.dirname(ENV['OCRA_EXECUTABLE'])
  SDL_PATHS << $LOADING_PATH+"/lib/SDL"
  SDL_PATHS << $LOADING_PATH+"/lib/SDL/"
else
  $LOADING_PATH = $EMERGE_DIRECTORY
end

puts "Loading Emerge library scripts ..."
require $EMERGE_DIRECTORY+"/lib/utils/ruby_mods"
Dir.require_all("lib/utils/")

require $EMERGE_DIRECTORY+"/app/setup/load_args"

puts "Loading config settings from /config/config.yaml ..."
require $EMERGE_DIRECTORY+"/app/setup/load_config"

require $EMERGE_DIRECTORY+"/app/setup/setup_log"

if defined?(Ocra)
  setup_log $EMERGE_DIRECTORY+"/logs", "log"
else
  setup_log "logs", "log"
end

require $EMERGE_DIRECTORY+"/app/launch"