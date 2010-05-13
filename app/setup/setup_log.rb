def setup_log dir, name
  
  time_sig = Time.new.strftime("%y%m%d-%H%M%S")
  file_path = "#{dir}/#{name}_#{time_sig}"
  
  unless File.exists?("#{file_path}.txt")
    $log = "#{file_path}.txt"
  else
    i = 0
    while File.exists?("#{file_path}(#{i}).txt")
      i += 1
    end
    $log = "#{file_path}(#{i}).txt"
  end
  
  puts "Logging in #{$log}"
end