require "lib/utils/ruby_mods.rb"
Dir.require_all("lib/utils/")

require "app/setup/load_config.rb"
require "app/setup/setup_log.rb"

setup_log "logs", "log"

require "app/main.rb"