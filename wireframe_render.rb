module WireRender
  require 'ply'
  require 'chunky_png'
  require './linedrawer.rb'

  class WireFrameModel

    attr_writer :width, :height, :xshift, :yshift , :path, :mod, :flip

    def initialize path
      @width = @height = 1000
      @xshift = 0
      @yshift = 0
      @path = path
      @mod = 1.0
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

    def render 
      target = Ply::PlyFile.new "#{@path}"

      dummy = ChunkyPNG::Image.new(@width, @height, ChunkyPNG::Color.from_hex('#000000'))
      dummy.save('example.png', :interlace => true)
      
      png = ChunkyPNG::Image.from_file('example.png')
      
      faces = target.data["face"]
      vertices = target.data["vertex"]
      
      faces.each do |polygon|
       
        for i in 0..2 do
          index_v0 = polygon["vertex_indices"][i]
          index_v1 = polygon["vertex_indices"][(i + 1) % 3]
      
          x0 = (vertices[index_v0]["x"] * @mod + 1) * @width / 2 + @xshift
          y0 = (vertices[index_v0]["y"] * @mod + 1) * @height / 2 + @yshift
          x1 = (vertices[index_v1]["x"] * @mod + 1) * @width / 2 + @xshift
          y1 = (vertices[index_v1]["y"] * @mod + 1) * @height / 2 + @yshift
      
          Linedrawer::linedraw(x0.to_i, y0.to_i, x1.to_i, y1.to_i, png)
        end
      end
      png.rotate_180!
      
      png.save('example.png')
    end

  end
end
