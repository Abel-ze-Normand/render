module Render
  require 'ply'
  require 'chunky_png'

  class PointVector
    attr_accessor :x, :y, :z
    def initialize x, y, z
      @x = x
      @y = y
      @z = z
    end
  end


  class Model

    attr_accessor :width, :height, :depth, :xshift, :yshift , :path, :mod, :flip, :light_vector

    def initialize path
      @width = @height = @depth = 1000
      @xshift = 0
      @yshift = 0
      @zshift = 0
      @light_vector = PointVector.new(0, 0, 1)
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
      @zbuffer = Array.new(@height)
      @zbuffer.each do |line|
        line = Array.new(@width, -Float::INFINITY)
      end
    end

    def load_config path
      
      config = File.new(path_config)

      #------------CONFIG-------------
        str = config.gets
        @width = str[(str.index("=") + 1)..str.length].to_f

        str = config.gets
        @height = str[(str.index("=") + 1)..str.length].to_f

        str = config.gets
        @depth = str[(str.index("=") + 1)..str.length].to_f
        
        str = config.gets
        @xshift = str[(str.index("=") + 1)..str.length].to_f

        str = config.gets
        @yshift = str[(str.index("=") + 1)..str.length].to_f

        str = config.gets
        @zshift = str[(str.index("=") + 1)..str.length].to_f
        
        str = config.gets
        @flip = str[(str.index("=") + 1)..str.length] != nil

        str = config.gets
        @path = str[(str.index("=") + 1)..str.length]

        str = config.gets
        @mod = str[(str.index("=") + 1)..str.length].to_f
      #-------------END-CONFIG---------
    end

    
    def linedraw x0, y0, x1, y1, color
      
      steep = false
      if ((x0 - x1).abs < (y0 - y1).abs)
          x0, y0 = y0, x0
          x1, y1 = y1, x1
          steep = true
      end

      if (x0 > x1)
          x0, x1 = x1, x0
          y0, y1 = y1, y0
      end

      dx = x1 - x0
      dy = y1 - y0

      derror = dy.abs * 2
      error = 0
      y = y0

      for x in x0..x1 do

        if steep
          @png[y, x] = color 
        else
          @png[x, y] = color
        end

        error += derror

        if error > dx
          y += (y1 > y0 ? 1 : -1)
          error -= dx*2
        end
      end
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
      
          linedraw(x0.to_i, y0.to_i, x1.to_i, y1.to_i, ChunkyPNG::Color.from_hex('#FFFFFF'))
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
        z0 = (@vertices[index_v0]["z"] * @mod + 1) * @depth / 2 + @zshift

        x1 = (@vertices[index_v1]["x"] * @mod + 1) * @width / 2 + @xshift
        y1 = (@vertices[index_v1]["y"] * @mod + 1) * @height / 2 + @yshift
        z1 = (@vertices[index_v1]["z"] * @mod + 1) * @depth / 2 + @zshift

        x2 = (@vertices[index_v2]["x"] * @mod + 1) * @width / 2 + @xshift
        y2 = (@vertices[index_v2]["y"] * @mod + 1) * @height / 2 + @yshift
        z2 = (@vertices[index_v2]["z"] * @mod + 1) * @depth / 2 + @zshift

        #puts "coords - t0:(#{x0}, #{y0}) t1:(#{x1}, #{y1}) t2:(#{x2}, #{y2})"
        #fill_triangle x0.to_i, y0.to_i, x1.to_i, y1.to_i, x2.to_i, y2.to_i, ChunkyPNG::Color.rgb(Random.rand(255), Random.rand(255), Random.rand(255))
        #@png.save('example.png')
        #sleep(4)
        a = PointVector.new(x0.to_i, y0.to_i, z0.to_i)
        b = PointVector.new(x1.to_i, y1.to_i, z1.to_i)
        c = PointVector.new(x2.to_i, y2.to_i, z2.to_i)
        calc_shadow(a, b, c, @light_vector) 
      end

      #@png.rotate_180! if @flip
      @png.save('example.png')
    end

    def fill_line_with_zbuffer lt, rt, y, color
      # нужно продумать с уравнением прямой в пространстве. координаты lt и rt при построчном рендере постоянно изменяются, но и "глубина" этих точек постоянно меняется. нужно как то определять координаты lt.z и rt.z, чтобы zbuffer имел место быть
      if lt.x > rt.x then
        lt.x, rt.x = rt.x, lt.x 
        lt.z, rt.z = rt.z, lt.z
      end

      for x in lt.x..rt.x
        z = (x - lt.x).to_f * (rt.z - lt.z) / (rt.x - lt.x) + lt.z
        z.floor!
        if @zbuffer[i][y] < z 
          @png[x, y] = color
          @zbuffer = z
        end
      end
    end

    def fill_triangle t0, t1, t2, color
      #вырожденный случай
      #return if y0==y1 && y0==y2
      return if t0.y==t1.y && t0.y==t2.y
      #sort vertices by Oy
      if t0.y > t1.y 
        t0.x, t1.x = t1.x, t0.x
        t0.y, t1.y = t1.y, t0.y
        t0.z, t1.z = t1.z, t0.z
      end
      if t0.y > t2.y
        t0.x, t2.x = t2.x, t0.x
        t0.y, t2.y = t2.y, t0.y
        t0.z, t2.z = t2.z, t0.z
      end
      if t1.y > t2.y
        t1.x, t2.x = t2.x, t1.x
        t1.y, t2.y = t2.y, t1.y
        t1.z, t2.z = t2.z, t1.z
      end
      #lower half
      for y in t0.y..t1.y
        if (t2.y - t0.y == 0 || t1.y - t0.y == 0) then next end
        lx = (y - t0.y).to_f * (t2.x - t0.x) / (t2.y - t0.y) + t0.x
        rx = (y - t0.y).to_f * (t1.x - t0.x) / (t1.y - t0.y) + t0.x
        linedraw(lx.floor, y, rx.floor, y, color)
        #lt = Point.new(lx, 1, t0.z)
        #rt = Point.new(rx, 1, t1.z)
        #fill_line_with_zbuffer lt, rt, y, color
      end

      #upper half
      for y in t1.y..t2.y
        if (t1.y - t2.y == 0 || t2.y - t0.y == 0) then next end
        lx = (y - t0.y).to_f * (t2.x - t0.x) / (t2.y - t0.y) + t0.x
        rx = (y - t1.y).to_f * (t2.x - t1.x) / (t2.y - t1.y) + t1.x
        linedraw(lx.floor, y, rx.floor, y, color)
        #lt = Point.new(lx, 1, t1.z)
      end
    end

    def flip
      @png.rotate_180!
      @png.save('example.png')
    end

    def calc_shadow t0, t1, t2, light
      a = PointVector.new(t2.x - t0.x, t2.y - t0.y, t2.z - t0.z)
      b = PointVector.new(t1.x - t0.x, t1.y - t0.y, t1.z - t0.z)

      normal = PointVector.new(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)

      norma_normal = Math::sqrt(normal.x ** 2 + normal.y ** 2 + normal.z ** 2)
      light_norma = Math::sqrt(light.x ** 2 + light.y ** 2 + light.z ** 2)
      
      intensity = (normal.x * light.x + normal.y * light.y + normal.z * light.z) / norma_normal / light_norma
      if (intensity > 0) then 
        color = ChunkyPNG::Color.rgb((intensity * 255).to_i , (intensity * 255).to_i, (intensity * 255).to_i)
        fill_triangle t0, t1, t2, color
      end
    end
  end
end
