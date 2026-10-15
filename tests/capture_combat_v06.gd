extends SceneTree
var output_dir="/tmp/dungeons-vfx"
var game
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):output_dir=arg.trim_prefix("--capture-dir=")
	call_deferred("run")
func frame() -> Image:
	await process_frame;await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func save_still(name: String) -> void:
	var img=await frame();assert(img.save_png(output_dir.path_join(name+".png"))==OK)
func prepare(kind: String) -> void:
	game.progress.d=game.progress.fresh();game.progress.d.settings.sound=false;game.progress.d.settings.shake=false;game.progress.d.tutorial=true
	game.progress.d.hero=kind;game.progress.d.equipped.weapon={"varek":"W_sword_0","maela":"W_staff_0","neris":"W_bow_0"}[kind]
	game.start_dungeon(0);game.room=1;game.spawn_room();game.combat_ui()
	game.player.position=Vector2(500,480)
	for i in range(game.enemies.size()):
		game.enemies[i].position=Vector2(635+i*95,456+i%2*65);game.enemies[i].cooldown=100
func record_hero(kind: String) -> void:
	prepare(kind)
	var folder=output_dir.path_join(kind);DirAccess.make_dir_recursive_absolute(folder)
	for i in range(112):
		var hero=game.player
		if kind=="varek":
			if i in [0,11,23]:hero.request_attack()
			if i==40:hero.request_skill(0)
			if i==59:hero.state="idle";hero.request_skill(1)
			if i==60:
				for enemy in game.enemies:
					if enemy.hp>0:
						enemy.position=hero.position+Vector2(70,0);enemy.facing=-1;enemy.start_action("attack","enemy",.30);break
			if i==82:hero.state="idle";hero.supreme=100;hero.request_supreme()
		else:
			if i==0:hero.request_attack()
			if i==24:hero.request_skill(0)
			if i==46:hero.state="idle";hero.request_skill(1)
			if i==76:hero.state="idle";hero.supreme=100;hero.request_supreme()
		for substep in range(2):game._physics_process(1.0/48)
		var img=await frame();assert(img.save_png(folder.path_join("frame_%04d.png"%i))==OK)
		if i==(49 if kind=="varek" else 56):assert(img.save_png(output_dir.path_join(kind+"_skill.png"))==OK)
		if i==96:assert(img.save_png(output_dir.path_join(kind+"_supreme.png"))==OK)
	print("VFX_CAPTURED: "+kind)
func verify_lighting() -> bool:
	prepare("varek");game.world.vfx.emit("charge",game.player.position-Vector2(0,60),Color("ffa34a"),110,.5,1,0,.5);game.world.vfx.tick(.1)
	for i in range(3):await process_frame
	var lit=await frame()
	for lamp in game.world.vfx.lights:lamp.enabled=false
	for i in range(3):await process_frame
	var unlit=await frame()
	var difference=0.0
	for x in range(440,560,6):
		for y in range(410,500,6):
			var a=lit.get_pixel(x,y);var b=unlit.get_pixel(x,y)
			difference+=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
	print("NATIVE_LIGHT_PIXEL_DIFFERENCE: "+str(difference))
	assert(lit.save_png(output_dir.path_join("native_light_on.png"))==OK)
	assert(unlit.save_png(output_dir.path_join("native_light_off.png"))==OK)
	if difference<=1.0:
		push_error("Native PointLight2D must change actual background/actor framebuffer pixels");return false
	return true
func record_boss() -> void:
	game.start_dungeon(2);game.room=4;game.spawn_room();game.combat_ui()
	game.player.position=Vector2(790,480)
	var boss=game.enemies[0];boss.boss_step=1;boss.cooldown=0
	var folder=output_dir.path_join("garron");DirAccess.make_dir_recursive_absolute(folder)
	for i in range(60):
		for substep in range(2):game._physics_process(1.0/48)
		var img=await frame();assert(img.save_png(folder.path_join("frame_%04d.png"%i))==OK)
		if i==38:assert(img.save_png(output_dir.path_join("garron_impact.png"))==OK)
func run() -> void:
	assert(DisplayServer.get_name()!="headless","Actual framebuffer required")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://combat_capture_v06.json")
	if not await verify_lighting():quit(1);return
	for hero in ["varek","maela","neris"]:await record_hero(hero)
	await record_boss()
	game.queue_free();await process_frame;quit()
