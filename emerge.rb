require "lib/utils/ruby_mods.rb"
Dir.require_all("lib/utils/")

i=0
while File.exists?("log#{i}.txt")
  i += 1
end
$log = "log#{i}.txt"

require "app/load_config.rb"
require "app/main.rb"