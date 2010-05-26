require "yaml"
config = YAML::load(File.open("../config/config.yaml"))
## Add support for parsing comments
puts config.inspect
File.open("preloaded_config.txt", "w") { |f| f.write(config.inspect) }