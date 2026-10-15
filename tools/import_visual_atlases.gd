extends SceneTree

# Production slicing only: original image-generation masters are preserved.
const HEROES = ["varek", "varek_hammer", "maela", "maela_focus", "neris", "neris_daggers"]
const HERO_EDGES = [[0,190,369,552,735,909,1086],[0,190,369,552,735,909,1086],[0,190,369,552,735,909,1086],[0,190,369,552,735,909,1086],[0,185,369,552,733,909,1086],[0,190,369,552,735,909,1086],[0,190,369,552,735,909,1086],[0,183,369,552,734,909,1086]]
const ENEMY_EDGES = [[0,157,318,455,611,775,932,1074,1254],[0,157,318,455,611,773,932,1077,1254],[0,157,318,455,611,775,933,1076,1254],[0,157,318,455,611,775,932,1076,1254],[0,153,302,448,609,768,916,1078,1254],[0,157,318,455,611,775,932,1078,1254],[0,157,318,455,611,775,932,1077,1254],[0,157,310,455,611,775,937,1077,1254]]
const ENEMIES = ["knight", "archer", "brute", "garron", "sereia", "rei", "colosso", "severan"]

func _initialize() -> void:
	var worlds = Image.load_from_file("res://art_sources/environments_atlas.png")
	# Actual panel boundaries were inspected in the generated production master.
	var edges = [0, 357, 748, worlds.get_height()]
	for index in range(6):
		var row = int(index / 2)
		var x = int(index % 2) * 682
		var tile = worlds.get_region(Rect2i(x, edges[row], 682, edges[row + 1] - edges[row]))
		tile.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
		assert(tile.save_webp("res://assets/painted_worlds/world_%d.webp" % index, false, .92) == OK)
	var camp = Image.load_from_file("res://art_sources/hub_camp_v1.png")
	camp.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	assert(camp.save_webp("res://assets/painted_worlds/hub_camp.webp", false, .92) == OK)
	slice_actors("res://art_sources/heroes_atlas.png", HEROES, HERO_EDGES)
	slice_actors("res://art_sources/enemies_atlas.png", ENEMIES, ENEMY_EDGES)
	print("VISUAL ATLAS IMPORT: 6 worlds + forest campsite, 14 animated characters, 112 authored frames")
	quit()

func slice_actors(path: String, names: Array, edges: Array) -> void:
	var source = Image.load_from_file(path)
	for row in range(names.size()):
		var row_height = 0
		for edge in edges:row_height = maxi(row_height, edge[row+1]-edge[row])
		var ratio = minf(176.0 / ceilf(source.get_width()/8.0), 176.0 / row_height)
		var atlas = Image.create(192 * 8, 192, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for column in range(8):
			var x0 = roundi(column * source.get_width() / 8.0)
			var x1 = roundi((column + 1) * source.get_width() / 8.0)
			var y0 = int(edges[column][row])
			var y1 = int(edges[column][row + 1])
			var frame = source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
			# Irregular authored rows: preserve proportions and align feet to the cell baseline.
			var used = frame.get_used_rect()
			frame = frame.get_region(used)
			frame.resize(roundi(frame.get_width() * ratio), roundi(frame.get_height() * ratio), Image.INTERPOLATE_LANCZOS)
			var canvas = Image.create(176, 176, false, Image.FORMAT_RGBA8)
			canvas.fill(Color.TRANSPARENT)
			canvas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i((176-frame.get_width())/2,176-frame.get_height()))
			frame = canvas
			atlas.blit_rect(frame, Rect2i(0, 0, 176, 176), Vector2i(column * 192 + 8, 4))
			if column == 0:
				assert(frame.save_png("res://assets/portraits/%s.png" % names[row]) == OK)
		assert(atlas.save_png("res://assets/%s.png" % names[row]) == OK)
