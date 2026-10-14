extends SceneTree

# Integration gate: journal, campaign recovery, physical states and hub NPCs.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.progress = DFProgress.new(DFContent.new(),"user://qa_v03_save.json")
	scene.progress.d.tutorial = true
	scene.show_hub()
	assert(scene.screen=="hub","Hub should be available")
	assert(scene.actors.get_children().filter(func(a):return a.kind=="neris").is_empty(),"Neris has not arrived")
	scene.show_journal()
	assert(scene.screen=="journal","Journal screen opens")
	assert(scene.ui.get_children().size()>8,"Journal has chapter entries")
	scene.progress.d.cleared = [0,1,2]
	scene.progress.d.hub.forge = 2
	scene.show_hub()
	assert(scene.actors.get_children().any(func(a):return a.kind=="neris"),"Neris appears after chapter milestone")
	scene.show_journal()
	assert(scene.current_map_region>=0,"Journal retains valid map data")
	scene.show_map(1)
	assert(scene.screen=="map","Journal leads back to the map")
	scene.start_dungeon(0)
	scene.player.request_dodge()
	assert(scene.player.state=="dodge","Dash state active")
	scene.player.queue_redraw()
	scene.world.queue_redraw()
	scene.show_hub()
	assert(not scene.controls.active,"Touch combat controls hidden in hub")
	scene.queue_free()
	await process_frame
	print("LIVING_HUB_V03: journal, three milestones, NPC, transitions and dodge passed")
	quit()
