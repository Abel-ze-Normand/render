$LOAD_PATH << '.'

require 'wireframe_render.rb'

render = Render::Model.new 'dodecahedron.ply'

#render.render_wireframe

render.rasterize
