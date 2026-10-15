extends SceneTree
func _initialize() -> void:call_deferred("run")
func send(game, id: int, pos: Vector2, pressed: bool) -> void:
	var e=InputEventScreenTouch.new();e.index=id;e.position=game.get_viewport().get_screen_transform()*pos;e.pressed=pressed;Input.parse_input_event(e)
	Input.flush_buffered_events()
func run() -> void:
	root.size=Vector2i(640,360)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false);game.progress=DFProgress.new(DFContent.new(),"user://touch_pipeline_v05.json");game.progress.d.settings.sound=false;game.start_dungeon(0)
	send(game,0,Vector2(240,601),true);send(game,1,Vector2(1130,611),true);send(game,2,Vector2(987,625),true)
	await process_frame
	print(JSON.stringify({"stick":game.controls.stick_id,"touches":game.controls.touches,"axis":str(game.controls.axis),"dodge":game.player.dodge_cd,"viewport":str(root.get_visible_rect()),"transform":str(root.get_screen_transform())}))
	assert(game.controls.stick_id==0 and game.controls.touches.size()==2 and game.attack_held and game.player.dodge_cd>0,"Scaled synthetic input traverses actual _input pipeline")
	var start=game.player.position
	for i in range(15):game._physics_process(1.0/60)
	assert(game.player.position.x>start.x+20,"Simultaneous movement, attack and dodge moves player")
	for i in range(3):send(game,i,Vector2.ZERO,false)
	assert(game.controls.stick_id==-1 and game.controls.touches.is_empty() and not game.attack_held,"Contacts release independently")
	game.queue_free();await process_frame;print("TOUCH_PIPELINE: scaled native input passed");quit()
