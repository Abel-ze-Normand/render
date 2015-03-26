module Linedrawer
  require 'chunky_png'

  def self.linedraw(x0, y0, x1, y1, target, color)
    png = target
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
        png[y, x] = color
      else
        png[x, y] = color
      end

      error += derror

      if error > dx
        y += (y1 > y0 ? 1 : -1)
        error -= dx*2
      end
    end
  end
end
