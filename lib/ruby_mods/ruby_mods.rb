PROJ_DIR = File.dirname(__FILE__)+"/../../"

class Dir
  def self.require_all(directory)
    self.entries(PROJ_DIR+directory).each do |file|
      if file =~ /\.rb/
        require directory + file
      end
    end
  end
end