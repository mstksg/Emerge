class Eo_Archive
  
  def initialize eo_group
    
    @database = Hash.new()
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
  
  def clean_up count=1
    c = 0
    for n in @database.keys.sort!
      next if @database[n] == nil
      @database.delete n
      @stored_count -= 1
      c += 1
      break if c >= count
    end
  end
  
  def is_alive? id
    id = id.to_s(36) if id.class != String
    @eo_group.any? { |eo| eo.id == id }
  end
  
  def has_descendants id
    id = id.to_i(36) if id.class == String
    return @database[id] != nil
  end
  
  def generation_gap id_1,id_2
    id_1 = id_1.to_i(36) if id_1.class == String
    id_2 = id_2.to_i(36) if id_2.class == String
    
    if id_1 > id_2
      child = id_1
      parent = id_2
    else
      child = id_2
      parent = id_1
    end
    
    count = 0
    while true
      return count if child == parent
      child = _parent_of child
      return nil if child == nil
      count += 1
    end
  end
  
  ## Proxy methods
  ## (replace with meta-programming)
  
  def descendants_of id
    descs = _descendants_of id.to_i(36)
    return nil if descs == nil
    return descs.map! { |n| n.to_s(36) }
  end
  
  def parent_of id
    parent = _parent_of id.to_i(36)
    return nil if parent == nil
    return parent.to_s(36)
  end
  
  def nth_ancestor_of id,num
    na = _nth_ancestor_of id.to_i(36),num
    return nil if na == nil
    return na.to_s(36)
  end
  
  def ultimate_ancestor_of id
    ua = _ultimate_ancestor_of id.to_i(36)
    return nil if ua == nil
    return ua.to_s(36)
  end
  
  def count_living_descendants_of id
    return _count_living_descendants_of(id.to_i(36))
  end
  
  def first_living_descendant_of id
    fld = _first_living_descendant_of id.to_i(36)
    return nil if fld == nil
    return fld.to_s(36)
  end
  
  def lowest_common_ancestor_of id_1,id_2
    lca = _lowest_common_ancestor_of id_1.to_i(36),id_2.to_i(36)
    return nil if lca == nil
    return lca.to_s(36)
  end
  
  def LCA_of_group ids
    lca = _LCA_of_group ids.map { |n| n.to_i(36) }
    return nil if lca == nil
    return lca.to_s(36)
  end
  
  def group_roots ids,levels=0
    gr = _group_roots ids.map { |n| n.to_i(36) },levels
    return gr.map! { |n| n.to_s(36) }
  end
  
  ## Internal methods
  
  def _descendants_of id
    Array.new(@database[id])
  end
  
  def _parent_of id
    for n in @database.keys.sort!
      
      return nil if n >= id
      return n if @database[n].any? { |m| m == id }
      
    end
    
    return nil
  end
  
  def _nth_ancestor_of id,num
    num.times do |n|
      id = _parent_of id
      return nil if id == nil
    end
    return id
  end
  
  def _ultimate_ancestor_of id
    while true
      parent = _parent_of id
      if parent == nil
        return id
      else
        id = parent
      end
    end
  end
  
  def _count_living_descendants_of id
    curr_check = @database[id]
    
    if curr_check == nil
      if is_alive? id
        return 1
      else
        return 0
      end
    else
      return _descendants_of(id).inject(0) { |sum,n| sum + _count_living_descendants_of(n) }
    end
    
  end
  
  def _first_living_descendant_of id
    
    curr_check = @database[id]
    
    if curr_check == nil
      if is_alive? id
        return id
      else
        return nil
      end
    else
      2.times do |n|
        branch = _first_living_descendant_of curr_check[n]
        return branch if branch
      end
      
      return nil
    end
  end
  
  def _lowest_common_ancestor_of id_1,id_2
    while true
      
      if id_1 == nil or id_2 == nil
        return nil
      end
      if id_1 == id_2
        return id_1
      end
      
      if id_1 > id_2
        id_1 = _parent_of(id_1) 
      else
        id_2 = _parent_of(id_2)
      end
      
    end
  end
  
  def _LCA_of_group ids
    ids.inject(ids[0]) { |curr,new| _lowest_common_ancestor_of(curr,new) }
  end
  
  def _group_roots ids,levels=0
    roots = Set.new
    for id in ids
      if levels == 0
        roots << _ultimate_ancestor_of(id)
      else
        na = _nth_ancestor_of id,levels
        if na == nil
          roots << _ultimate_ancestor_of(id)
        else
          roots << na
        end
      end
    end
    return roots
  end
  
end