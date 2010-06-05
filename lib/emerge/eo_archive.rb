class Eo_Archive
  
  def initialize eo_group
    
    @database = Array.new()
    @eo_group = eo_group
    @stored_count = 0
    
    @archive_limit = $ARCHIVE_LIMIT
    @archive_limit = 1.0/0 if @archive_limit == 0
    @reached_limit = false
    
  end
  
  def store_eo id, descendant_1_id, descendant_2_id                       # possibly also store dna, age?
    descendant_array = [descendant_1_id.to_i(36),descendant_2_id.to_i(36)]
    descendant_array.freeze
    @database[id.to_i(36)] = descendant_array
    @stored_count += 1
    if @stored_count > @archive_limit
      clean_up $ARCHIVE_CLEANUP
      
      unless @reached_limit
        $LOGGER.debug "Reached archive limit of #{$ARCHIVE_LIMIT}"
        @reached_limit = true
      end
      
    end
  end
  
  def find_descendants id
    Array.new(@database[id.to_i(36)])
  end
  
  def find_parent id
    @database.size.times do |n|
      if @database[n].contains? id
        return n.to_s(36)
      end
    end
  end
  
  def is_eo_alive? id
    id = id.to_s(36) if id.class != String
    @eo_group.any? { |eo| eo.id == id }
  end
  
  def find_first_living_descendant id
    if id.class == String
      id_num = id.to_i(36)
    else
      id_num = id
      id = id.to_s(36)
    end
    
    curr_check = @database[id_num]
    
    if curr_check == nil
      if @eo_group.any? { |eo| eo.id == id }
        return id
      else
        return nil
      end
    end
    
    2.times do |n|
      branch = find_first_living_descendant(curr_check[n])
      return branch if branch
    end
    
    return nil
  end
  
  def has_descendants id
    id = id.to_i(36) if id.class == String
    return @database[id] != nil
  end
  
  def clean_up count=1
    c = 0
    for n in @database
      next if n == nil
      @database.delete n
      @stored_count -= 1
      c += 1
      break if c >= count
    end
  end
  
end