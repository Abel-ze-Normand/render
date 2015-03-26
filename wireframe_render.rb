module Render
  require 'ply'
  require 'chunky_png'
  require './linedrawer.rb'

  class Model

    attr_writer :width, :height, :xshift, :yshift , :path, :mod, :flip

    def initialize path
      @width = @height = 1000
      @xshift = 0
      @yshift = 0
      @path = path
      @mod = 1.0
      @flip = false 
      @png = nil
      @png = ChunkyPNG::Image.from_file('example.png')
      @target = Ply::PlyFile.new "#{@path}"
      dummy = ChunkyPNG::Image.new(@width, @height, ChunkyPNG::Color.from_hex('#000000'))
      dummy.save('example.png', :interlace => true)
      @png = ChunkyPNG::Image.from_file('example.png')
      @faces = @target.data["face"]
      @vertices = @target.data["vertex"]
    end

    def load_config path
      
      config = File.new(path_config)

      #------------CONFIG-------------
        str = config.gets
        @width = str[(str.index("=") + 1)..str.length].to_f

        str = config.gets
        @height = str[(str.index("=") + 1)..str.length].to_f

        str = config.gets
        @xshift = str[(str.index("=") + 1)..str.length].to_f

        str = config.gets
        @yshift = str[(str.index("=") + 1)..str.length].to_f

        str = config.gets
        @flip = str[(str.index("=") + 1)..str.length] != nil

        str = config.gets
        @path = str[(str.index("=") + 1)..str.length]

        str = config.gets
        @mod = str[(str.index("=") + 1)..str.length].to_f
      #-------------END-CONFIG---------
    end

    def render_wireframe 
      
      @png = ChunkyPNG::Image.from_file('example.png')
      
      
      @faces.each do |polygon|
       
        for i in 0..2 do
          index_v0 = polygon["vertex_indices"][i]
          index_v1 = polygon["vertex_indices"][(i + 1) % 3]
      
          x0 = (@vertices[index_v0]["x"] * @mod + 1) * @width / 2 + @xshift
          y0 = (@vertices[index_v0]["y"] * @mod + 1) * @height / 2 + @yshift
          x1 = (@vertices[index_v1]["x"] * @mod + 1) * @width / 2 + @xshift
          y1 = (@vertices[index_v1]["y"] * @mod + 1) * @height / 2 + @yshift
      
          Linedrawer::linedraw(x0.to_i, y0.to_i, x1.to_i, y1.to_i, @png, ChunkyPNG::Color.from_hex('#FFFFFF'))
        end
      end
      #rotate if need
      @png.rotate_180! if @flip

      @png.save('example.png')
    end

    def rasterize
      #@png.rotate_180! if @flip
      #faces = @target.data["face"] 
      #vertices = @target.data["vertex"]
      
      @faces = @target.data["face"]
      @vertices = @target.data["vertex"]
      
      @faces.each do |polygon|
        index_v0 = polygon["vertex_indices"][0]
        index_v1 = polygon["vertex_indices"][1]
        index_v2 = polygon["vertex_indices"][2]
        x0 = (@vertices[index_v0]["x"] * @mod + 1) * @width / 2 + @xshift
        y0 = (@vertices[index_v0]["y"] * @mod + 1) * @height / 2 + @yshift
        x1 = (@vertices[index_v1]["x"] * @mod + 1) * @width / 2 + @xshift
        y1 = (@vertices[index_v1]["y"] * @mod + 1) * @height / 2 + @yshift
        x2 = (@vertices[index_v2]["x"] * @mod + 1) * @width / 2 + @xshift
        y2 = (@vertices[index_v2]["y"] * @mod + 1) * @height / 2 + @yshift

        #puts "coords - t0:(#{x0}, #{y0}) t1:(#{x1}, #{y1}) t2:(#{x2}, #{y2})"
        fill_triangle x0.to_i, y0.to_i, x1.to_i, y1.to_i, x2.to_i, y2.to_i, ChunkyPNG::Color.rgb(Random.rand(255), Random.rand(255), Random.rand(255))
        #@png.save('example.png')
        #sleep(4)
      end

      #@png.rotate_180! if @flip
      @png.save('example.png')
    end

    def fill_triangle x0, y0, x1, y1, x2, y2, color
      #вырожденный случай
      return if y0==y1 && y0==y2
      #sort vertices by Oy
      if y0 > y1 
        x0, x1 = x1, x0
        y0, y1 = y1, y0
      end
      if y0 > y2
        x0, x2 = x2, x0
        y0, y2 = y2, y0
      end
      if y1 > y2
        x1, x2 = x2, x1
        y1, y2 = y2, y1
      end
      #lower half
      for y in y0..y1
        if (y2 - y0 == 0 || y1 - y0 == 0) then next end
        lx = (y - y0).to_f * (x2 - x0) / (y2 - y0) + x0
        rx = (y - y0).to_f * (x1 - x0) / (y1 - y0) + x0
        Linedrawer::linedraw(lx.floor, y, rx.floor, y, @png, color)
      end

      #upper half
      for y in y1..y2
        if (y1 - y2 == 0 || y2 - y0 == 0) then next end
        lx = (y - y0).to_f * (x2 - x0) / (y2 - y0) + x0
        rx = (y - y1).to_f * (x2 - x1) / (y2 - y1) + x1
        Linedrawer::linedraw(lx.floor, y, rx.floor, y, @png, color)
      end
    end

    def flip
      @png.rotate_180!
      @png.save('example.png')
    end
  end
end
