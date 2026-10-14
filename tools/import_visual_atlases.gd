extends SceneTree

# Production slicing only: original image-generation masters are preserved.
const HEROES = ["varek", "varek_hammer", "maela", "maela_focus", "neris", "neris_daggers"]
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
	slice_actors("res://art_sources/heroes_atlas.png", HEROES)
	slice_actors("res://art_sources/enemies_atlas.png", ENEMIES)
	print("VISUAL ATLAS IMPORT: 6 worlds, 14 animated characters, 112 authored frames")
	quit()

func slice_actors(path: String, names: Array) -> void:
	var source = Image.load_from_file(path)
	for row in range(names.size()):
		var atlas = Image.create(192 * 8, 192, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for column in range(8):
			var x0 = roundi(column * source.get_width() / 8.0)
			var x1 = roundi((column + 1) * source.get_width() / 8.0)
			var y0 = roundi(row * source.get_height() / float(names.size()))
			var y1 = roundi((row + 1) * source.get_height() / float(names.size()))
			var frame = source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
			frame.resize(176, 176, Image.INTERPOLATE_LANCZOS)
			atlas.blit_rect(frame, Rect2i(0, 0, 176, 176), Vector2i(column * 192 + 8, 4))
			if column == 0:
				assert(frame.save_png("res://assets/portraits/%s.png" % names[row]) == OK)
		assert(atlas.save_png("res://assets/%s.png" % names[row]) == OK)
