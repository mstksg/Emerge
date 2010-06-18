class Graph_Builder
  
  attr_reader :root_node,:middle_nodes,:end_nodes,:straight_nodes
  
  @@drop_char = Hash.new do |h,k|
                           if k == 1
                             h[k] = "`"
                           else
                             h[k] = "\\"
                           end
                         end
  @@fill_char = Hash.new do |h,k|
                           if k == "`"
                             h[k] = "-"
                           else
                             h[k] = k
                           end
                         end
  
  def initialize root_value
    @root_node = Graph_Node.new(0,root_value)
    @middle_nodes = []
    @straight_nodes = []
    @end_nodes = [@root_node]
  end
  
  def relevant_nodes
    @middle_nodes | @end_nodes
  end
  
  def nodes
    @middle_nodes | @end_nodes | @straight_nodes
  end
  
  def relevant_depths
    rel_depths = @middle_nodes.map { |n| n.depth } |  @end_nodes.map { |n| n.depth }
    return rel_depths.sort!
  end
  
  def all_depths
    a_depths = relevant_depths | @striaght_nodes.map { |n| n.depth }
    return a_depths.sort!
  end
  
  def add_node parent_value,depth,value
    parent = nodes.find { |n| n.value == parent_value }
    
    raise "Invalid parent" if @middle_nodes.include? parent
    
    child = Graph_Node.new(depth,value,parent)
    parent.add_child child
    @end_nodes << child
    
    if @end_nodes.include? parent
      @end_nodes.delete(parent)
      @straight_nodes << parent
    end
    
    if @straight_nodes.include? parent and parent.descendants_count == 2
      @straight_nodes.delete parent
      @middle_nodes << parent
    end
    
  end
  
  def add_node_pair parent_value,depth_1,value_1,depth_2,value_2
    parent = nodes.find { |n| n.value == parent_value }
    
    raise "Invalid parent" if parent.has_children?
    
    if @straight_nodes.include? parent
      @straight_nodes.delete(parent)
    elsif @end_nodes.include? parent
      @end_nodes.delete(parent)
    end
    
    @middle_nodes << parent
    
    child1 = Graph_Node.new(depth_1,value_1,parent)
    child2 = Graph_Node.new(depth_2,value_2,parent)
    
    parent.set_right child1
    parent.set_left child2
    
    @end_nodes << child1
    @end_nodes << child2
    
  end
  
  def render_horizontal leading_dash=false
    
    grid = populate_grid
    height = grid.size
    width = grid[0].size
    
    text_grid = grid.map { |row| row.map { |column| column.to_s } }
    
    max_lengths = Array.new(width) { |column| Array.new(height) { |row| text_grid[row][column].length }.max }
    
    ## initial population
    height.times do |row|
      
      after_first = false
      before_last = true
      width.times do |column|
        if text_grid[row][column] == ""
          text_fill = (after_first and before_last) ? "-" : " "
          text_grid[row][column] = text_fill * (max_lengths[column]+2)
        else
          curr_node = grid[row][column]
          node_val = curr_node.value
          adds = 0
          start_add = leading_dash ? "-" : @root_node == grid[row][column] ? " " : "-"
          after_first = true
          if not curr_node.has_children?
            before_last = false
          end
          end_add = before_last ? "-" : " "
          
          until node_val.length >= max_lengths[column]+2
            if adds % 2 == 0
              node_val = start_add + node_val
            else
              node_val = node_val + end_add
            end
            adds += 1
          end
          
          text_grid[row][column] = node_val
        end
      end
      
    end
    
    ## Drop lines
    width.times do |column|
      drop_length = 0
      incr = 0
      height.times do |row|
        if drop_length > 0
          text_grid[row][column] = text_grid[row][column].chop + " " * incr + @@drop_char[drop_length] + " " * (drop_length-1)
          drop_length -= 1
          incr += 1
        elsif grid[row][column] and grid[row][column].has_children?
          drop_length = grid[row][column].right.ultimate_descendants_count
          incr = 0
        end
      end
    end
    
    ## Fill in horizontal lines
    height.times do |row|
      found_branch = false
      before_first = true
      width.times do |column|
        if found_branch
          if before_first
            if grid[row][column]
              before_first = false
            else
              text_grid[row][column] = "-"
            end
          end
        elsif text_grid[row][column].include? @@drop_char[1]
          found_branch = true
        end
      end
    end
    
    
    ## normalize lengths
    width.times do |column|
      max_length = Array.new(height) { |row| text_grid[row][column].length }.max
      height.times do |row|
        until text_grid[row][column].length >= max_length
          text_grid[row][column] += @@fill_char[text_grid[row][column][-1..-1]]
        end
      end
    end
    
    if block_given?
      text_grid.each do |row|
        yield row.join("")
      end
    end
    
    return text_grid.map { |row| row.join("") }.join("\n")
  end
  
  def first_significant_parent node
    rel_nodes = relevant_nodes
    parent = node.parent
    return nil if parent.nil?
    until rel_nodes.include? parent
      parent = parent.parent
      return nil if parent.nil?
    end
    return parent
  end
  
  def populate_grid
    
    depths = relevant_depths
    
    grid = Array.new(@end_nodes.size) { Array.new(depths.size) }
    
    relevant_nodes.each do |node|
      row_count = 0
      parent = first_significant_parent node
      while parent
        unless parent.right.all_descendants.include? node
          row_count += parent.right.ultimate_descendants_count
        end
        parent = first_significant_parent parent
      end
      
      grid[row_count][depths.index(node.depth)] = node
    end
    
    return grid
    
  end
  
end

class Graph_Node
  
  attr_reader :depth,:parent,:value,:left,:right
  
  def initialize depth,value,parent=nil,left=nil,right=nil
    @depth = depth
    @value = value
    @parent = parent
    @left = left
    @right = right
  end
  
  def set_parent node
    @parent = node
  end
  
  def set_left node
    raise "put right in first" unless @right
    @left = node
  end
  
  def set_right node
    @right = node
  end
  
  def add_child node
    if @right
      set_left node
    else
      set_right node
    end
  end
  
  def has_children?
    @right or @left
  end
  
  def inspect
    @value.to_s
  end
  def to_s
    @value.to_s
  end
  
  def ultimate_descendants_count
    if has_children?
      count = 0
      count += @right.ultimate_descendants_count if @right
      count += @left.ultimate_descendants_count if @left
      return count
    else
      return 1
    end
  end
  
  def descendants_count
    total = 0
    total += 1 if @right
    total += 1 if @left
    return total
  end
  
  def all_descendants
    total = [self]
    total |= @right.all_descendants if @right
    total |= @left.all_descendants if @left
    return total
  end
  
end

# gb = Graph_Builder.new "[a0]"
# gb.add_node_pair "[a0]",3,"[b3]",1,"[g1]"
# gb.add_node "[b3]",4,"[ghost]"
# gb.add_node "[b3]",4,"[boo]"
# gb.add_node "[ghost]",5,"[c5]"
# gb.add_node "[boo]",5,"[f5]"
# gb.add_node_pair "[c5]",8,"[d8]",9,"[e9]"
# gb.add_node_pair "[g1]",4,"[h4]",3,"[k3]"
# gb.add_node_pair "[h4]",6,"[i6]",10,"[j10]"
# gb.render_horizontal { |n| puts n }