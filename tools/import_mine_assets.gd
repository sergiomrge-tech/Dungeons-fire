extends SceneTree
func _initialize():
	for name in ["rails","store","rest","rusk"]:
		var img=Image.load_from_file("res://art_sources/mine_v050/%s.png"%name)
		img.resize(1280,720,Image.INTERPOLATE_LANCZOS)
		assert(img.save_webp("res://assets/painted_worlds/mine_%s.webp"%name,false,.92)==OK)
	var source=Image.load_from_file("res://art_sources/mine_v050/props.png")
	var atlas=Image.create(1024,512,false,Image.FORMAT_RGBA8)
	for i in range(8):
		var cell=source.get_region(Rect2i(i%4*source.get_width()/4,i/4*source.get_height()/2,source.get_width()/4,source.get_height()/2))
		cell.resize(256,256,Image.INTERPOLATE_LANCZOS)
		atlas.blit_rect(cell,Rect2i(0,0,256,256),Vector2i(i%4*256,i/4*256))
	assert(atlas.save_png("res://assets/mine_props.png")==OK)
	quit()
