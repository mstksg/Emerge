class Eo_Archive
  
  def initialize eo_group
    
    @database = Array.new()
    @eo_group = eo_group
    
  end
  
  def store_eo id, descendant_1_id, descendant_2_id                       # possibly also store dna, age?
    descendant_array = [descendant_1_id.to_i(36),descendant_2_id.to_i(36)]
    descendant_array.freeze
    @database[id.to_i(36)] = descendant_array
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
    end
    
    curr_check = @database[id_num]
    
    if curr_check == nil
      return @eo_group.any? { |eo| eo.id == id }
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
  
end