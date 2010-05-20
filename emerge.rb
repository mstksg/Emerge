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

require "lib/utils/ruby_mods.rb"
Dir.require_all("lib/utils/")

require "app/setup/load_args.rb"
require "app/setup/load_config.rb"
require "app/setup/setup_log.rb"

setup_log "logs", "log"

require "app/launch.rb"