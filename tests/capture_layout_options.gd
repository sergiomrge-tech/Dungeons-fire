extends SceneTree

# Isolated design review. The shipping hub remains unchanged until a layout is chosen.
var game
var output_dir = "/tmp/dungeons-layout-options"
var ink = Color("f4e4bd")
var edge = Color("b3975b")
var surface = Color("38291f")
var style_id = 0

class Symbol extends Control:
	var kind = "bag"
	var color = Color("ead49d")
	func _draw() -> void:
		var s = size.x / 32.0
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE*s)
		match kind:
			"bag":
				draw_style_box(_box(),Rect2(5,10,22,18))
				draw_arc(Vector2(16,11),7,PI,TAU,16,color,2,true)
				draw_line(Vector2(7,18),Vector2(25,18),color,2,true)
			"sword":
				draw_colored_polygon(PackedVector2Array([Vector2(9,23),Vector2(11,17),Vector2(25,3),Vector2(28,3),Vector2(28,6),Vector2(15,21)]),color)
				draw_line(Vector2(6,17),Vector2(17,28),color,3,true)
				draw_line(Vector2(11,22),Vector2(4,29),color,3,true)
			"forge":
				draw_colored_polygon(PackedVector2Array([Vector2(3,13),Vector2(29,13),Vector2(24,19),Vector2(19,19),Vector2(19,24),Vector2(25,27),Vector2(7,27),Vector2(13,24),Vector2(13,19),Vector2(7,19)]),color)
				draw_line(Vector2(17,3),Vector2(11,11),color,3,true)
				draw_line(Vector2(13,2),Vector2(21,8),color,5,true)
			"hero":
				draw_circle(Vector2(16,9),6,color,true,-1,true)
				draw_arc(Vector2(16,29),12,PI,TAU,24,color,4,true)
			"talent":
				for i in range(3):
					var p = Vector2(6+i*10,25)
					draw_line(Vector2(16,8),p,color,1.7,true)
					draw_circle(p,3,color,true,-1,true)
				draw_circle(Vector2(16,7),5,color,true,-1,true)
			"book":
				draw_polyline(PackedVector2Array([Vector2(3,5),Vector2(11,5),Vector2(16,9),Vector2(21,5),Vector2(29,5),Vector2(29,26),Vector2(21,26),Vector2(16,29),Vector2(11,26),Vector2(3,26),Vector2(3,5)]),color,2,true)
				draw_line(Vector2(16,9),Vector2(16,29),color,2,true)
			"map":
				draw_polyline(PackedVector2Array([Vector2(3,8),Vector2(11,4),Vector2(21,8),Vector2(29,4),Vector2(29,25),Vector2(21,29),Vector2(11,25),Vector2(3,29),Vector2(3,8)]),color,2,true)
				draw_line(Vector2(11,4),Vector2(11,25),color,1.5,true)
				draw_line(Vector2(21,8),Vector2(21,29),color,1.5,true)
			"fire":
				draw_colored_polygon(PackedVector2Array([Vector2(16,2),Vector2(21,12),Vector2(25,8),Vector2(29,23),Vector2(23,29),Vector2(10,29),Vector2(4,23),Vector2(10,12),Vector2(12,18)]),color)
			"coin":
				draw_circle(Vector2(16,16),11,color,false,2,true)
				draw_circle(Vector2(16,16),7,color,false,1,true)
				draw_line(Vector2(16,10),Vector2(16,22),color,2,true)
			"ore":
				draw_colored_polygon(PackedVector2Array([Vector2(5,24),Vector2(9,10),Vector2(18,4),Vector2(27,14),Vector2(24,27),Vector2(10,28)]),color)
			"menu":
				for y in [8,16,24]:draw_line(Vector2(5,y),Vector2(27,y),color,2,true)
			_:
				draw_circle(Vector2(16,16),11,color,false,2,true)
				draw_circle(Vector2(16,16),3,color,true,-1,true)
	func _box() -> StyleBoxFlat:
		var b=StyleBoxFlat.new();b.bg_color=Color.TRANSPARENT;b.border_color=color;b.set_border_width_all(2);b.set_corner_radius_all(3);return b

class Trim extends Control:
	var color = Color("c8aa68")
	var wood = false
	func _draw() -> void:
		if wood:
			for i in range(6):
				var y=7.0+i*size.y/7.0
				draw_line(Vector2(5,y),Vector2(size.x-5,y+sin(i)*2),Color(1,.8,.4,.035),1,true)
		for p in [Vector2(7,7),Vector2(size.x-7,7),Vector2(7,size.y-7),size-Vector2(7,7)]:
			draw_circle(p,1.8,color,true,-1,true)
		draw_line(Vector2(14,4),Vector2(size.x-14,4),Color(color,.35),1,true)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):output_dir=arg.trim_prefix("--capture-dir=")
	call_deferred("run")

func box_style(bg: Color, border: Color, radius: int = 7) -> StyleBoxFlat:
	var s=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(2);s.set_corner_radius_all(radius)
	s.shadow_color=Color(0,0,0,.30);s.shadow_size=5;s.shadow_offset=Vector2(0,3)
	return s

func panel_at(pos: Vector2, dimensions: Vector2, bg: Color, border: Color, ornate: bool = false) -> Panel:
	var p=Panel.new();p.position=pos;p.size=dimensions;p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel",box_style(bg,border,7 if style_id==0 else 14));game.ui.add_child(p)
	if ornate:
		var trim=Trim.new();trim.size=dimensions;trim.color=border;trim.wood=style_id==0;trim.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(trim)
	return p

func txt(words: String, pos: Vector2, dimensions: Vector2, font_size: int = 19, color: Color = Color("f4e4bd"), center: bool = false) -> Label:
	var l=game.label(words,pos,dimensions,font_size,color)
	if center:l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	return l

func icon_at(kind: String, pos: Vector2, diameter: float = 30, parent: Node = null) -> Control:
	var icon=Symbol.new();icon.kind=kind;icon.color=edge;icon.position=pos;icon.size=Vector2.ONE*diameter;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if parent==null:game.ui.add_child(icon)
	else:parent.add_child(icon)
	return icon

func action(words: String, kind: String, pos: Vector2, dimensions: Vector2, callback: Callable, primary: bool = false, vertical: bool = false) -> Button:
	var b=Button.new();b.position=pos;b.size=dimensions;b.text=words
	var fill=Color("86522c") if primary and style_id==0 else (Color("1a6471") if primary else surface)
	b.add_theme_stylebox_override("normal",box_style(fill,edge,8 if style_id==0 else 14))
	b.add_theme_stylebox_override("hover",box_style(fill.lightened(.12),ink,8 if style_id==0 else 14))
	b.add_theme_stylebox_override("pressed",box_style(fill.darkened(.15),edge,8 if style_id==0 else 14))
	b.add_theme_color_override("font_color",ink);b.add_theme_color_override("font_hover_color",ink);b.add_theme_color_override("font_pressed_color",ink)
	b.add_theme_font_size_override("font_size",19 if primary else 17)
	if vertical:
		b.text=""
		var caption=Label.new();caption.text=words;caption.position=Vector2(3,dimensions.y-29);caption.size=Vector2(dimensions.x-6,25)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color",ink);caption.add_theme_font_size_override("font_size",19 if primary else 17)
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(caption)
		icon_at(kind,Vector2((dimensions.x-26)/2,7),26,b)
	else:
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		for state in ["normal","hover","pressed"]:
			var s=b.get_theme_stylebox(state).duplicate();s.content_margin_left=48;s.content_margin_right=12;b.add_theme_stylebox_override(state,s)
		icon_at(kind,Vector2(12,(dimensions.y-26)/2),26,b)
	b.pressed.connect(callback);game.ui.add_child(b)
	return b

func portrait_panel(pos: Vector2, dimensions: Vector2) -> void:
	panel_at(pos,dimensions,surface,edge,style_id==0)
	game.portrait("varek",pos+Vector2(5,5),Vector2(68,76))
	txt("Varek",pos+Vector2(84,10),Vector2(125,26),23,ink)
	txt("Guardião • Nv. 1",pos+Vector2(84,40),Vector2(170,24),15,ink.darkened(.15))
	var bar=game.meter(pos+Vector2(85,73),Vector2(dimensions.x-102,5),edge);bar.value=36

func resources_at(pos: Vector2, dark: bool = false) -> void:
	panel_at(pos,Vector2(284,66),surface,edge,style_id==0)
	for i in range(3):
		icon_at(["coin","ore","fire"][i],pos+Vector2(14+i*92,12),22)
		txt(["160","12","0"][i],pos+Vector2(41+i*92,10),Vector2(43,25),19,ink)
		txt(["OURO","MINÉRIO","CINZA"][i],pos+Vector2(10+i*92,37),Vector2(80,20),10,ink.darkened(.16),true)

func nameplates() -> void:
	for entry in [["Doran",Vector2(219,484)],["Iria",Vector2(929,499)]]:
		var l=txt(entry[0],entry[1],Vector2(140,28),17,ink,true)
		l.add_theme_color_override("font_outline_color",Color("18241b"));l.add_theme_constant_override("outline_size",5)

func inventory() -> void:game.previous_screen="hub";game.show_inventory()
func lore() -> void:game.show_lore(true)
func map() -> void:game.show_map(0)

func classic() -> void:
	style_id=0;ink=Color("f7e8c5");edge=Color("c6a56b");surface=Color("35281f")
	portrait_panel(Vector2(24,22),Vector2(280,94))
	panel_at(Vector2(341,25),Vector2(598,57),surface,edge,true)
	txt("ACAMPAMENTO DA ÚLTIMA CHAMA",Vector2(354,34),Vector2(572,37),23,ink,true)
	resources_at(Vector2(972,24))
	nameplates()
	panel_at(Vector2(24,608),Vector2(1232,92),Color("241e18"),edge,true)
	var labels=["Mochila","Equipar","Forja","EXPLORAR","Heróis","Talentos","Diário"]
	var symbols=["bag","sword","forge","map","hero","talent","book"]
	var callbacks=[inventory,inventory,game.show_forge,map,game.show_heroes,game.show_talents,game.show_journal]
	var x=40.0
	for i in range(7):
		var w=264.0 if i==3 else 148.0
		action(labels[i],symbols[i],Vector2(x,620),Vector2(w,68),callbacks[i],i==3,true);x+=w+8

func premium() -> void:
	style_id=1;ink=Color("edf7f5");edge=Color("b2b688");surface=Color(.065,.13,.17,.94)
	portrait_panel(Vector2(24,24),Vector2(280,94))
	panel_at(Vector2(365,25),Vector2(550,55),Color(.055,.105,.14,.87),Color("727c65"))
	txt("ACAMPAMENTO DA ÚLTIMA CHAMA",Vector2(378,34),Vector2(524,37),21,ink,true)
	resources_at(Vector2(972,24),true)
	for i in range(3):
		action(["Mochila","Equipar","Talentos"][i],["bag","sword","talent"][i],Vector2(24,237+i*66),Vector2(171,54),[inventory,inventory,game.show_talents][i])
	for i in range(3):
		action(["Forja","Heróis","Diário"][i],["forge","hero","book"][i],Vector2(1085,237+i*66),Vector2(171,54),[game.show_forge,game.show_heroes,game.show_journal][i])
	nameplates()
	panel_at(Vector2(403,568),Vector2(474,126),Color(.055,.105,.14,.95),Color("7c987b"))
	action("EXPLORAR MASMORRAS","map",Vector2(419,582),Vector2(442,64),map,true)
	txt("Mina dos Sinos  •  Nível recomendado: 1",Vector2(419,652),Vector2(442,26),15,Color("c3d2c3"),true)
	action("Refúgio","fire",Vector2(24,631),Vector2(171,58),game.show_buildings)
	action("Menu","menu",Vector2(1085,631),Vector2(171,58),game.show_menu)

func immersive() -> void:
	style_id=2;ink=Color("fff1ce");edge=Color("cbaa70");surface=Color(.13,.16,.12,.88)
	portrait_panel(Vector2(24,24),Vector2(280,94))
	panel_at(Vector2(349,26),Vector2(582,48),Color(.10,.14,.105,.81),Color("8a946d"))
	txt("ACAMPAMENTO DA ÚLTIMA CHAMA",Vector2(362,32),Vector2(556,35),22,ink,true)
	resources_at(Vector2(972,24))
	action("Forja de Doran","forge",Vector2(125,286),Vector2(230,56),game.show_forge)
	action("Arquivo de Iria","book",Vector2(939,289),Vector2(230,56),game.show_journal)
	action("Fogueira","fire",Vector2(737,357),Vector2(174,50),game.show_buildings)
	nameplates()
	panel_at(Vector2(455,570),Vector2(370,34),Color(.10,.14,.105,.84),Color("82916d"))
	txt("Próxima expedição: Mina dos Sinos",Vector2(464,574),Vector2(352,26),15,ink,true)
	action("PARTIR À AVENTURA","map",Vector2(462,616),Vector2(356,70),map,true)
	action("Mochila","bag",Vector2(24,611),Vector2(135,77),inventory,false,true)
	action("Equipar","sword",Vector2(171,611),Vector2(135,77),inventory,false,true)
	for i in range(3):
		action(["Heróis","Talentos","Menu"][i],["hero","talent","menu"][i],Vector2(843+i*140,611),Vector2(133,77),[game.show_heroes,game.show_talents,game.show_menu][i],false,true)

func capture(name: String) -> void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	var frame=root.get_texture().get_image()
	assert(frame!=null and frame.get_width()==1280)
	assert(frame.save_png(output_dir.path_join(name+".png"))==OK)
	print("LAYOUT_CAPTURE: "+name)

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://qa_layout_options.json")
	game.progress.d.settings.sound=false;game.progress.d.tutorial=true
	if DisplayServer.get_name()=="headless":
		for build in [classic,premium,immersive]:
			game.show_hub();game.clear_ui();build.call();await process_frame
		print("LAYOUT_OPTIONS: three native Godot UI prototypes instantiated")
		game.queue_free();await process_frame;quit();return
	DirAccess.make_dir_recursive_absolute(output_dir)
	for entry in [[classic,"01_classico"],[premium,"02_premium"],[immersive,"03_imersivo"]]:
		game.show_hub();game.clear_ui();entry[0].call();await capture(entry[1])
	game.queue_free();await process_frame;quit()
