## lib/ruby_graphviz.rb -- graphviz dot generator library
## Author::    Yoichiro Hasebe (mailto: yohasebe@gmail.com)
## Copyright:: Copyright 2009 Yoichiro Hasebe
## License::   GNU GPL version 3

class RubyGraphviz
  
  ## Example: 
  ##
  ##   g = RubyGraphviz.new("newgraph", {:rankdir => "LR", :nodesep => "0.4", :ranksep => "0.2"})
  ##
  def initialize(name, graph_hash = nil)
    @name = name
    @graph_data = graph_hash
    @nodes = []
    @edges = []
    @dot   = ""
    create_graph
  end

  protected

  def create_graph
    @dot << "graph #{@name} {\n  graph"
    index = 0
    if @graph_data
      @dot << " ["
      @graph_data.each do |k, v|
        k = k.to_s
        @dot << "#{k} = \"#{v}\""
        index += 1
        @dot << ", " unless index == @graph_data.size
      end
      @dot << "]"
    end
    @dot << ";\n"    
  end
  
  def finish_graph
    @dot << "}\n"
  end

  def create_edge(edgetype, nid1, nid2, edge_hash = nil)
    temp = "  #{nid1.to_s} #{edgetype} #{nid2.to_s}"
    index = 0
    if edge_hash
      temp << " ["      
      edge_hash.each do |k, v|
        k = k.to_s
        temp << "#{k} = \"#{v}\""
        index += 1
        temp << ", " unless index == edge_hash.size
      end
      temp << "]"      
    end
    return temp
  end
  
  public
  
  ## Add a subgraph to a graph (recursively)
  ##
  ## Example:
  ##
  ##   graph1.subgraph(graph2)
  ##
  def subgraph(graph)
    @dot << graph.to_dot.sub(/\Agraph/, "subgraph")
  end
  
  ## Set default options for nodes
  ##
  ## Example:
  ##
  ##   graph.node_default(:shape => "record", :color => "gray60")
  ##
  def node_default(node_hash = nil)
    @dot << "  node["
    index = 0
    node_hash.each do |k, v|
      k = k.to_s
      @dot << "#{k} = \"#{v}\""
      index += 1
      @dot << ", " unless index == node_hash.size
    end
    @dot << "];\n"
    self
  end

  ## Set default options for edges
  ##
  ## Example:
  ##
  ##   graph.edge_default(:color => "gray60")
  ##
  def edge_default(edge_hash = nil)
    @dot << "  edge["
    index = 0
    edge_hash.each do |k, v|
      k = k.to_s
      @dot << "#{k} = \"#{v}\""
      index += 1
      @dot << ", " unless index == edge_hash.size
    end
    @dot << "];\n"
    self
  end
  
  ## Create a node with its options
  ##
  ## Example:
  ##
  ##   graph.node("node-01", :label => "Node 01", :fillcolor => "pink")
  ##
  def node(node_id, node_hash = nil)
    @dot << "  #{node_id.to_s}"
    index = 0
    if node_hash
      @dot << " ["
      node_hash.each do |k, v|
        k = k.to_s
        @dot << "#{k} = \"#{v}\""
        index += 1
        @dot << ", " unless index == node_hash.size
      end
      @dot << "]"
    end
    @dot << ";\n"
    self
  end

  ## Create a non-directional edge (connection line between nodes) with its options 
  ##
  ## Example:
  ##
  ##   graph.edge("node-01", "node-02", :label => "connecting 1 and 2", :color => "lightblue")
  ## 
  def edge(nid1, nid2, edge_hash = nil)
    @dot << create_edge("--", nid1, nid2, edge_hash) + ";\n"
    self
  end

  ## Create a directional edge (arrow from node to node) with its options 
  ##
  ## Example:
  ##   graph.arrow_edge("node-01", "node-02", :label => "from 1 to 2", :color => "lightblue")
  ##  
  def arrow_edge(nid1, nid2, edge_hash = nil)
    @dot << create_edge("->", nid1, nid2, edge_hash) + ";\n"
    self
  end

  ## Align nodes on the same rank connecting them with non-directional edges
  ##
  def rank(nid1, nid2, edge_hash = nil)
    @dot << "{rank=same " + create_edge("--", nid1, nid2, edge_hash) + "}\n"
    self
  end
  
  ## Convert graph into dot formatted data
  ##
  def to_dot
    finish_graph
    @dot = @dot.gsub(/\"\</m, "<").gsub(/\>\"/m, ">")
    return @dot
  end
end
