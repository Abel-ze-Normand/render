$LOAD_PATH << '.'

require 'wireframe_render.rb'

render = WireRender::WireFrameModel.new 'dodecahedron.ply'

render.render
