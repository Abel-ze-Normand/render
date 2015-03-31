$LOAD_PATH << '.'

require 'wireframe_render.rb'

render = Render::Model.new 'cow.ply'
render.mod = 0.3
render.yshift = -250
#render.render_wireframe

render.rasterize
render.flip


#############
#TODO make loading settings for each model from config file (method is exists, but need more declare it)
