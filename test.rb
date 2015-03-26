$LOAD_PATH << '.'

require 'linedrawer.rb'
require 'wireframe_render.rb'


def fill_triangle x0, y0, x1, y1, x2, y2, color, png
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
    lx = (y - y0).to_f * (x2 - x0) / (y2 - y0) + x0
    rx = (y - y0).to_f * (x1 - x0) / (y1 - y0) + x0
    Linedrawer::linedraw(lx.floor, y, rx.floor, y, png,ChunkyPNG::Color.html_color('yellow'))
  end

  #upper half
  for y in y1..y2
    lx = (y - y0).to_f * (x2 - x0) / (y2 - y0) + x0
    rx = (y - y1).to_f * (x2 - x1) / (y2 - y1) + x1
    Linedrawer::linedraw(lx.floor, y, rx.floor, y, png,ChunkyPNG::Color.html_color('yellow'))
  end
end

x0 = Random.rand(999)
y0 = Random.rand(999)
x1 = Random.rand(999)
y1 = Random.rand(999)
x2 = Random.rand(999)
y2 = Random.rand(999)

#x0 = 967.086.to_i 
#y0 = 678.411.to_i
#x1 = 967.086.to_i
#y1 = 321.589.to_i
#x2 = 788.675.to_i
#y2 = 211.325.to_i

dummy = ChunkyPNG::Image.new(1000, 1000, ChunkyPNG::Color.from_hex('#000000'))
dummy.save('test.png', :interlace => true)
png = ChunkyPNG::Image.from_file('test.png')
puts "coords - t0:(#{x0}, #{y0}) t1:(#{x1}, #{y1}) t2:(#{x2}, #{y2})"
Linedrawer::linedraw(x0, y0, x1, y1, png, ChunkyPNG::Color.html_color('yellow'))
Linedrawer::linedraw(x1, y1, x2, y2, png, ChunkyPNG::Color.html_color('yellow'))
Linedrawer::linedraw(x2, y2, x0, y0, png, ChunkyPNG::Color.html_color('yellow'))
fill_triangle(x0, y0, x1, y1, x2, y2, ChunkyPNG::Color.from_hex('#2F0F0F'), png)
png.save('test.png')

