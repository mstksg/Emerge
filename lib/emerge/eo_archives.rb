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
        @reached_limit = true if @archive_limit < 1000
      end
      
    end
  end
  
  def clean_up count=1
    c = 0
    for n in @database.keys.sort!
      next if @database[n] == nil
      
      c += 1
      break if c >= count
      
      next if _has_living_descendants? n
      
      @database.delete n
      @stored_count -= 1
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
  
  @@Proxy_Methods = [:descendants_of,:parent_of,:nth_ancestor_of,:ultimate_ancestor_of,:has_living_descendants?,
                     :count_living_descendants_of,:first_living_descendant_of,:narrow_down,
                     :distance_to_closest_relative_of,:closest_relative_of,:lowest_common_ancestor_of,
                     :LCA_of_group,:group_roots,:group_ancestors]
  
  # @@Proxy_Methods.each do |method|
    # proxy_method = "def #{method.to_s}\n" +
                     # "result = _#{method.to_s} "
  # end
  
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
  
  def has_living_descendants? id
    return _has_living_descendants?(id.to_i(36))
  end
  
  def count_living_descendants_of id
    return _count_living_descendants_of(id.to_i(36))
  end
  
  def first_living_descendant_of id
    fld = _first_living_descendant_of id.to_i(36)
    return nil if fld == nil
    return fld.to_s(36)
  end
  
  def narrow_down id
    nd = _narrow_down id.to_i(36)
    return nil if nd == nil
    return nd.to_s(36)
  end
  
  def distance_to_closest_relative_of id
    _distance_to_closest_relative_of id.to_i(36)
  end
  
  def closest_relative_of id
    c_rel = _closest_relative_of id.to_i(36)
    return nil if c_rel == nil
    return c_rel.to_s(36)
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
  
  def group_ancestors ids,groups=4
    ga = _group_ancestors ids.map { |n| n.to_i(36) },groups
    return ga.map! { |n| n.to_s(36) }
  end
  
  ## Internal methods
  
  def _descendants_of id
    @database[id]
  end
  
  def _parent_of id
    keys = @database.keys.sort!
    
    n = keys.index(id)
    
    if n == nil
      
      for m in keys
        return nil if m >= id
        return m if @database[m].any? { |j| j == id }
      end
      
    else
    
      while n >= 0
        return keys[n] if @database[keys[n]].any? { |m| m == id }
        n -= 1
      end
    
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
  
  def _has_living_descendants? id
    
    curr_check = @database[id]
    
    if curr_check == nil
      if is_alive? id
        return true
      else
        return false
      end
    else
      return _descendants_of(id).any? { |n| _has_living_descendants? n }
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
  
  def _living_descendants_of id
    curr_check = @database[id]
    
    if curr_check == nil
      if is_alive? id
        return Set.new.add(id)
      else
        return Set.new                            # this has a danger of blowing up, memory-wise
      end
    else
      return _descendants_of(id).inject(Set.new) { |total,n| total | _living_descendants_of(n) }
    end
  end
  
  def _narrow_down id
    while true
      children = _descendants_of id
      return id if children == nil
      
      children_counts = children.map { |n| _count_living_descendants_of n }
      
      return id unless children_counts.any? { |n| n < 1 }
      
      if children_counts[0] == 0
        id = children[1]
      else
        id = children[0]
      end
      
    end
  end
  
  def _distance_to_closest_relative_of id
    dist = 1
    parent_check = _parent_of(id)
    while parent_check != nil
      
      if _living_descendants_of(parent_check).size > 1
        return dist
      end
      
      dist += 1
      parent_check = _parent_of(parent_check)
    end
    return nil
  end
  
  def _closest_relative_of id
    parent_check = _parent_of(id)
    while parent_check != nil
      descs = _living_descendants_of(parent_check).delete(id)
      
      if descs.size > 0
        return descs.to_a[0]
      end
      
      parent_check = _parent_of(parent_check)
    end
    return nil
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
  
  # def _split_group_by_LCA ids
    # LCAs = Set.new
    # (ids.size-1) do |n|
      # curr_lca = _lowest_common_ancestor_of(ids[n],ids[n+1])
    # end
    # return LCAs
  # end
  
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
  
  def _group_ancestors ids,groups=4
    
    roots = _group_roots ids
    
    ancestors = Hash.new
    
    for root in roots
      desc_count = _count_living_descendants_of root
      ancestors[_narrow_down(root)] = desc_count
    end
    
    return ancestors.keys if roots.size >= groups
    
    while ancestors.size < groups
      
      if ancestors.values.max < 2
        return ancestors.keys.map! { |n| _narrow_down n }
      end
      
      smallest = ancestors.max {|a,b| a[1] <=> b[1]}[0]
      descs = _descendants_of smallest
      ancestors.delete smallest
      
      for desc in descs
        desc_ancs = _count_living_descendants_of desc
        if desc_ancs > 0
          ancestors[_narrow_down(desc)] = desc_ancs
        end
      end
      
    end
    
    return ancestors.keys
    
  end
  
end

class Eo_HoF
  
  @@CATEGORIES = [:kill_count,:age,:energy,:energy_col]
  @@CATEGORIES_DEFAULTS = { :kill_count => 0,
                            :age        => 0,
                            :energy     => 0,
                            :energy_col => 0 }
  @@CATEGORIES_NAMES =    { :kill_count => "Highest kill count  ",
                            :age        => "Longest living      ",
                            :energy     => "Highest energy      ",
                            :energy_col => "Most energy gathered" }
  
  def initialize
    @records = Hash.new
    @hall = Hash.new
    
    for category in @@CATEGORIES
      @records[category] = @@CATEGORIES_DEFAULTS[category]
      @hall[category] = nil
    end
  end
  
  def submit eo
    
    admitted = Set.new
    
    if eo.kill_count > curr_record(:kill_count)
      set_record :kill_count,eo,eo.kill_count
      admitted.add :kill_count
    end
    
    if eo.age > curr_record(:age)
      set_record :age,eo,eo.age
      admitted.add :age
    end
    
    if eo.energy_record > curr_record(:energy)
      set_record :energy,eo,eo.energy_record
      admitted.add :energy
    end
    
    if eo.collected_energy > curr_record(:energy_col)
      set_record :energy_col,eo,eo.collected_energy
      admitted.add :energy_col
    end
    
    if admitted.size > 0
      eo.log_message "#{eo.to_s} inducted in the hall of fame for #{ admitted.map { |r| record_name(r,true) }.join(", ") }."
    end
    
  end
  
  def set_record record_name,holder,record
    @hall[record_name] = holder.inspect
    @records[record_name] = record
  end
  
  def curr_record record,to_s=false
    return @records[record] unless to_s
    
    rec = @records[record]
    return rec.to_s[0,6] if rec.class == Float
    return rec.to_s
  end
  
  def curr_holder record
    @hall[record]
  end
  
  def record_exists? record
    return @hall[record] != nil
  end
  
  def record_name record,strip=false
    return @@CATEGORIES_NAMES[record].strip if strip
    return @@CATEGORIES_NAMES[record]
  end
  
  def record_to_s record
    if record_exists? record
      return "#{curr_record(record,true)}\t(#{curr_holder record})"
    else
      return "No record yet set for #{record.to_s}"
    end
  end
  
  def empty?
    for category in @@CATEGORIES
      return false if record_exists? category
    end
    return true
  end
  
  def categories
    return @@CATEGORIES.clone
  end
  
end