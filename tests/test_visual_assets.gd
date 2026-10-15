extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var names=["varek","varek_hammer","maela","maela_focus","neris","neris_daggers","knight","archer","brute","garron","sereia","rei","colosso","severan"]
	for name in names:
		var atlas=load("res://assets/%s.png"%name)
		assert(atlas.get_size()==Vector2(1536,192),"Eight uniformly sized authored poses: "+name)
		var portrait=load("res://assets/portraits/%s.png"%name)
		assert(portrait!=null,"Portrait exists: "+name)
	for index in range(6):
		var world=load("res://assets/painted_worlds/world_%d.webp"%index)
		assert(world.get_size()==Vector2(1280,720),"Full-screen world "+str(index))
	var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);await process_frame
	scene.set_physics_process(false);scene.start_dungeon(0)
	scene.player.start_action("attack","basic",.4)
	assert(scene.player.visual_frame()==4,"Windup artwork")
	scene.player.timer=.19
	assert(scene.player.visual_frame()==5,"Contact artwork aligned with damage window")
	scene.player.timer=.05
	assert(scene.player.visual_frame()==6,"Follow-through artwork")
	scene.update_hud();assert(scene.health_bar.value==scene.player.hp,"HP display follows state")
	scene.potions=1;scene.update_hud()
	assert(scene.expedition_status.text.contains("Poções 1"),"Potion label follows live state")
	for control in scene.ui.get_children():
		if control is TextureRect:assert(control.size.x<=82 and control.size.y<=92,"Combat portrait fits its panel")
	assert(scene.health_bar.size.y<=14 and scene.mana_bar.size.y<=9,"Compact meters do not inherit text height")
	scene.show_hub();assert(scene.health_bar==null,"Combat HUD cleared in hub")
	assert(not scene.controls.active,"No combat controls over hub")
	scene.queue_free();await process_frame
	print("VISUAL_ASSETS: 14 atlases, 112 poses, 14 portraits, 6 worlds and HUD/attack timing passed")
	quit()
