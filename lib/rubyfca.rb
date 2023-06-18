# frozen_string_literal: true

## lib/rubyfca.rb -- Formal Concept Analysis tool in Ruby
## Author::    Yoichiro Hasebe (mailto: yohasebe@gmail.com)
##             Kow Kuroda (mailto: kuroda@nict.go.jp)
## Copyright:: Copyright 2009-2023 Yoichiro Hasebe and Kow Kuroda
## License::   GNU GPL version 3

require "csv"
require "optimist"
require "roo"

require_relative "./rubyfca/ruby_graphviz"
require_relative "./rubyfca/version"

private

## Take two arrays each consisting of 0s and 1s and create their logical disjunction
def create_and_ary(a, b)
  return false if (s = a.size) != b.size

  (0..(s - 1)).to_a.map { |i| a[i].to_i & b[i].to_i }
end

## Take two arrays each consisting of 0s and 1s and create their logical conjunction
def create_or_ary(a, b)
  return false if (s = a.size) != b.size

  (0..(s - 1)).to_a.map { |i| a[i].to_i | b[i].to_i }
end

public

## Take care of errors
def showerror(sentence, severity)
  if severity.zero?
    puts "Warning: #{sentence} The output may not be meaningful."
  elsif severity == 1
    puts "Error: #{sentence} No output generated."
    exit
  end
end

## Basic structure of the code is the same as Fcastone written in Perl by Uta Priss
class FormalContext
  ## Converte cxt data to three basic structures of objects, attributes, and matrix
  def initialize(input, mode, label_contraction: false)
    showerror("File is empty", 1) if input.empty?
    input = input.gsub(" ", "&nbsp;")
    begin
      case mode
      when /cxt\z/
        read_cxt(input)
      when /csv\z/
        read_csv(input)
      when /xlsx\z/
        read_xlsx(input)
      end
    rescue StandardError => e
      pp e.message
      pp e.backtrace
      showerror("Input data contains a syntactic problem.", 1)
    end
    @label_contraction = label_contraction
  end

  ## process cxt data
  def read_cxt(input)
    lines = input.split
    t1 = 3
    if (lines[0] !~ /B/i || (2 * lines[1].to_i + lines[2].to_i + t1) != lines.size)
      showerror("Wrong cxt format!", 1)
    end
    @objects = lines[t1..(lines[1].to_i + t1 - 1)]
    @attributes = lines[(lines[1].to_i + t1)..(lines[1].to_i + lines[2].to_i + t1 - 1)]
    lines = lines[(lines[1].to_i + lines[2].to_i + t1)..lines.size]
    @matrix = changecrosssymbol("X", "\\.", lines)
  end

  # process csv data using the standard csv library
  def read_csv(input)
    input = remove_blank(input)
    data = CSV.parse(input)
    @objects = trim_ary(data.transpose.first[1..])
    @attributes = trim_ary(data.first[1..])
    @matrix = []
    data[1..].each do |line|
      @matrix << line[1..].collect { |cell| /x/i =~ cell ? 1 : 0 }
    end
  end

  # process xlsx data using the roo gem
  def read_xlsx(file_path)
    xlsx = Roo::Spreadsheet.open(file_path, extension: :xlsx)
    @objects = xlsx.sheet(0).column(1)[1..]
    @attributes = xlsx.sheet(0).row(1)[1..]
    @matrix = []
    (2..xlsx.sheet(0).last_row).each do |row|
      matrix_row = []
      (2..xlsx.sheet(0).last_column).each do |col|
        matrix_row << (xlsx.sheet(0).cell(row, col) =~ /x/i ? 1 : 0)
      end
      @matrix << matrix_row
    end
  end

  def remove_blank(input)
    blank_removed = +""
    input.split("\n").each do |line|
      line = line.strip
      unless /\A\s*\z/ =~ line
        blank_removed << line + "\n"
      end
    end
    blank_removed
  end

  def trim_ary(ary)
    ary.map(&:strip)
  end

  ## Apply a formal concept analysis on the matrix
  def calcurate
    @concepts, @extM, @intM = ganter_alg(@matrix)
    @relM, @reltrans, @rank = create_rel(@intM)
    @gammaM, @muM = gammaMu(@extM, @intM, @matrix)
  end

  ## This is an implementation of an algorithm described by Bernhard Ganter
  ## in "Two basic algorithms in concept analysis." Technische Hochschule
  ## Darmstadt, FB4-Preprint, 831, 1984.
  def ganter_alg(matrix)
    m = matrix

    ## all arrays except @idx are arrays of arrays of 0's and 1's
    idx = []
    extension = []
    intension = []
    ext_A = []
    int_B = []
    endkey = []
    temp = []

    ## the level in the lattice from the top
    lvl = 0
    ## is lower than the index of leftmost attr
    idx[lvl] = -1
    ## number of attr. and objs
    anzM = m.size
    ## only needed for initialization
    anzG = m[0].size
    ## initialize extA[0] = [1,...,1]
    anzG.times do
      unless ext_A[0]
        ext_A[0] = []
      end
      ext_A[0] << 1
    end
    ## initialize extB[0] = [0,...,0]
    anzM.times do
      unless int_B[0]
        int_B[0] = []
      end
      int_B[0] << 0
    end
    anzCpt = 0
    extension[0] = ext_A[0]
    intension[0] = int_B[0]
    anzM.times do
      endkey << 1
    end

    ## start of algorithm
    while int_B[lvl] != endkey
      (anzM - 1).downto(0) do |i|
        breakkey = false
        if (int_B[lvl][i] != 1)
          lvl -= 1 while (i < idx[lvl])
          idx[lvl + 1] = i
          ext_A[lvl + 1] = create_and_ary(ext_A[lvl], m[i])
          0.upto(i - 1) do |j|
            if (!breakkey && int_B[lvl][j] != 1)
              temp = create_and_ary(ext_A[lvl + 1], m[j])
              if temp == ext_A[lvl + 1]
                breakkey = true
              end
            end
          end
          unless breakkey
            int_B[lvl + 1] = int_B[lvl].dup
            int_B[lvl + 1][i] = 1
            (i + 1).upto(anzM - 1) do |k|
              if int_B[lvl + 1][k] != 1
                temp = create_and_ary(ext_A[lvl + 1], m[k])
                if temp == ext_A[lvl + 1]
                  int_B[lvl + 1][k] = 1
                end
              end
            end
            lvl += 1
            anzCpt += 1
            extension[anzCpt] = ext_A[lvl]
            intension[anzCpt] = int_B[lvl]
            break
          end
        end
      end
    end

    a1 = extension[0].join("")
    a2 = extension[1].join("")
    if a1 == a2
      extension.shift
      intension.shift
      anzCpt -= 1
    end

    c = []
    0.upto(anzCpt) do |i|
      c[i] = i
    end

    [c, intension, extension]
  end

  ## Output arrayconsists of the following:
  ## r (subconcept superconcept relation)
  ## rt (trans. closure of r)
  ## s (ranked concepts)
  def create_rel(intensions)
    anzCpt = intensions.size
    rank = []
    sup_con = []
    r = []
    rt = []
    s = []

    0.upto(anzCpt - 1) do |i|
      0.upto(anzCpt - 1) do |j|
        unless r[i]
          r[i] = []
        end
        r[i][j] = 0
        unless rt[i]
          rt[i] = []
        end
        rt[i][j] = 0
      end
    end

    1.upto(anzCpt - 1) do |i|
      rank[i] = 1
      (i - 1).downto(0) do |j|
        temp = create_and_ary(intensions[j], intensions[i])
        if temp == intensions[i]
          unless sup_con[i]
            sup_con[i] = []
          end
          sup_con[i] << j
          r[i][j] = 1
          rt[i][j] = 1
          sup_con[i].each do |elem|
            if r[elem][j] == 1
              r[i][j] = 0
              if rank[elem] >= rank [i]
                rank[i] = rank[elem] + 1
              end
              break
            end
          end
        end
      end
      unless s[rank[i]]
        s[rank[i]] = []
      end
      s[rank[i]] << i
    end
    s = s.collect do |i|
      i || [0]
    end

    [r, rt, s]
  end

  def gammaMu(extent, intent, cxt)
    gamma = []
    mu = []
    invcxt = []
    0.upto(cxt[0].size - 1) do |i|
      0.upto(cxt.size - 1) do |k|
        invcxt[i] = [] unless invcxt[i]
        invcxt[i][k] = cxt[k][i]
      end
    end

    0.upto(intent.size - 1) do |j|
      0.upto(cxt.size - 1) do |i|
        gamma[i] = [] unless gamma[i]
        gamma[i][j] = if cxt[i] == intent[j]
                        2
                      elsif (!@label_contraction && create_or_ary(cxt[i], intent[j]) == cxt[i])
                        1
                      else
                        0
                      end
      end

      0.upto(invcxt.size - 1) do |i|
        # next unless invcxt[i]
        mu[i] = [] unless mu[i]
        mu[i][j] = if invcxt[i] == extent[j]
                     2
                   elsif (!@label_contraction && create_or_ary(invcxt[i], extent[j]) == invcxt[i])
                     1
                   else
                     0
                   end
      end
    end

    [gamma, mu]
  end

  def changecrosssymbol(char1, char2, lns)
    rel = []
    lns.each do |ln|
      ary = []
      elems = ln.split(//)
      elems.each do |elem|
        if /#{char1}/i =~ elem
          ary << 1
        elsif /#{char2}/i =~ elem
          ary << 0
        end
      end
      rel << ary
    end
    rel
  end

  ## Generate Graphviz dot data (not creating a file)
  ## For options, see 'rubyfca'
  def generate_dot(opts)
    # index_max_width = @concepts.size.to_s.split(//).size
    nodesep = opts[:nodesep] ? opts[:nodesep].to_s : "0.4"
    ranksep = opts[:ranksep] ? opts[:ranksep].to_s : "0.2"
    clattice = RubyGraphviz.new("clattice", rankdir: "", nodesep: nodesep, ranksep: ranksep)

    if opts[:circle] && opts[:legend]
      legend = RubyGraphviz.new("legend", rankdir: "TB", lebelloc: "t", centered: "false")
      legend.node_default(shape: "plaintext")
      legend.edge_default(color: "gray60") if opts[:coloring]
      legends = []
    end

    if opts[:circle]
      clattice.node_default(shape: "circle", style: "filled")
      clattice.edge_default(dir: "none", minlen: "2")
      clattice.edge_default(color: "gray60") if opts[:coloring]
    else
      clattice.node_default(shape: "record", margin: "0.2,0.055")
      clattice.edge_default(dir: "none")
      clattice.edge_default(color: "gray60") if opts[:coloring]
    end

    0.upto(@concepts.size - 1) do |i|
      objfull = []
      attrfull = []
      0.upto(@gammaM.size - 1) do |j|
        if @gammaM[j][i] == 2
          # pointing finger does not appear correctly in eps...
          # obj = opts[:full] ? @objects[j] + " " + [0x261C].pack("U") : @objects[j]
          obj = opts[:full] ? @objects[j].to_s + "*" : @objects[j].to_s
          objfull << obj
        elsif @gammaM[j][i] == 1
          objfull << @objects[j]
        end
      end
      0.upto(@muM.size - 1) do |k|
        if @muM[k][i] == 2
          # pointing finger does not appear correctly in eps...
          # att = opts[:full] ? @attributes[k] + " " + [0x261C].pack("U") : @attributes[k]
          att = opts[:full] ? @attributes[k].to_s + "*" : @attributes[k].to_s
          attrfull << att
        elsif @muM[k][i] == 1
          attrfull << @attributes[k]
        end
      end

      concept_id = i + 1

      attr_str = attrfull.join("<br />")
      attr_str = attr_str == "" ? "     " : attr_str

      if opts[:coloring].zero? || /\A\s+\z/ =~ attr_str
        attr_color = "white"
      elsif opts[:coloring] == 1
        attr_color = "lightblue"
      elsif opts[:coloring] == 2
        attr_color = "gray87"
      end

      obj_str = objfull.join("<br />")
      obj_str = obj_str == "" ? "     " : obj_str

      if opts[:coloring].zero? || /\A\s+\z/ =~ obj_str
        obj_color = "white"
      elsif opts[:coloring] == 1
        obj_color = "pink"
      elsif opts[:coloring] == 2
        obj_color = "gray92"
      end

      label = "<<table border=\"0\" cellborder=\"1\" cellspacing=\"0\">" \
        "<tr><td balign=\"left\" align=\"left\" bgcolor=\"#{attr_color}\">#{attr_str}</td></tr>" \
        "<tr><td balign=\"left\" align=\"left\"  bgcolor=\"#{obj_color}\">#{obj_str}</td></tr>" \
        "</table>>"

      if opts[:circle] && opts[:legend]

        leg = "<<table border=\"0\" cellborder=\"1\" cellspacing=\"0\">" \
          "<tr><td rowspan=\"2\">#{concept_id}</td><td balign=\"left\" align=\"left\" bgcolor=\"#{attr_color}\">#{attr_str}</td></tr>" \
          "<tr><td balign=\"left\" align=\"left\" bgcolor=\"#{obj_color}\">#{obj_str}</td></tr>" \
          "</table>>"

        if !attrfull.empty? || !objfull.empty?
          legend.node("cl#{concept_id}k", label: concept_id, style: "invis")
          legend.node("cl#{concept_id}v", label: leg, fillcolor: "white")
          legend.rank("cl#{concept_id}k", "cl#{concept_id}v", style: "invis", length: "0.0")
          if legends[-1]
            legend.edge("cl#{legends[-1]}k", "cl#{concept_id}k", style: "invis", length: "0.0")
          end
          legends << concept_id
        end
      end

      if opts[:circle]
        clattice.node("c#{i}", width: "0.5", fontsize: "14.0", label: concept_id)
      else
        clattice.node("c#{i}", label: label, shape: "plaintext", height: "0.0", width: "0.0", margin: "0.0")
      end
    end

    0.upto(@relM.size - 1) do |i|
      0.upto(@relM.size - 1) do |j|
        if @relM[i][j] == 1
          clattice.edge("c#{i}", "c#{j}")
        end
      end
    end

    clattice.subgraph(legend) if opts[:circle] && opts[:legend]
    clattice.to_dot
  end

  ## Generate an actual graphic file (Graphviz dot needs to be installed properly)
  def generate_img(outfile, image_type, opts)
    dot = generate_dot(opts)
    isthere_dot = `dot -V 2>&1`
    if isthere_dot !~ /dot.*version/i
      showerror("Graphviz's dot program cannot be found.", 1)
    else
      cmd = if opts[:straight]
              "dot | neato -n -T#{image_type} -o#{outfile} 2>rubyfca.log"
            else
              "dot -T#{image_type} -o#{outfile} 2>rubyfca.log"
            end
      IO.popen(cmd, "r+") do |io|
        io.puts dot
      end
    end
  end
end
