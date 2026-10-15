extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://qa_classic_ui.json")
	game.progress.d.tutorial=true;game.progress.d.heroes.varek.xp=47
	game.progress.d.gold=12345;game.progress.d.ore=77;game.progress.d.ash=9
	game.show_hub();await process_frame
	assert(game.ui.get_node("HubHeroName").text=="Varek")
	assert(game.ui.get_node("HubXP").value==47 and game.ui.get_node("HubXP").max_value==100)
	assert(game.ui.get_node("HubGold").text=="12k" and game.ui.get_node("HubGold").tooltip_text=="12345")
	assert(game.ui.get_node("HubOre").text=="77" and game.ui.get_node("HubAsh").text=="9")
	for node in game.ui.get_children():
		if node is Button:
			assert(Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(node.get_rect()),"Touch action must stay in viewport")
	for entry in [["HubBag","inventory"],["HubSword","inventory"],["HubForge","forge"],["HubMap","map"],["HubHero","heroes"],["HubTalent","talents"],["HubBook","journal"],["HubFire","buildings"],["HubMenu","menu"]]:
		game.show_hub();await process_frame
		game.ui.get_node(entry[0]).pressed.emit();await process_frame
		assert(game.screen==entry[1],"Hub navigation: "+entry[0])
	game.show_map(0);await process_frame
	assert(game.actors.get_child_count()==0,"Hub actors must not appear over map destinations")
	assert(game.ui.has_node("MapDungeon0") and game.ui.has_node("MapDungeon1") and game.ui.has_node("MapDungeon2"))
	assert(not game.ui.get_node("MapPrepare").disabled,"First expedition is available")
	for control in game.ui.get_children():
		if control is Panel:assert(control.size.y<=146,"No full-screen opaque panel over the scenery")
	game.ui.get_node("MapDungeon2").pressed.emit();await process_frame
	assert(game.selected_map_dungeon==2 and game.ui.get_node("MapPrepare").disabled,"Locked marker can be inspected without entering")
	game.show_map(4);await process_frame
	assert(game.ui.has_node("MapDungeon12") and game.ui.has_node("MapDungeon14"),"Region markers follow actual dungeon IDs")
	game.show_map(0,0);game.ui.get_node("MapPrepare").pressed.emit();await process_frame
	assert(game.screen=="prepare" and game.dungeon==0,"Marker selection leads to real preparation")
	game.show_journal()
	var history=game.ui.get_children().filter(func(n):return n is Button and n.text=="HISTÓRIA")
	assert(history.size()==1);history[0].pressed.emit();assert(game.screen=="lore")
	game.start_dungeon(0);game.player.hp=91;game.save_run();game.show_hub();await process_frame
	assert(game.ui.has_node("HubResume"),"Saved expedition remains accessible")
	game.ui.get_node("HubResume").pressed.emit();await process_frame
	assert(game.screen=="combat" and game.player.hp==91,"Resume preserves expedition health")
	game.progress.d.run={};game.progress.d.cleared=[0,1,2,3,4,5]
	assert(game.progress.switch_hero("neris"));game.show_hub();await process_frame
	assert(game.ui.get_node("HubHeroName").text=="Neris","Hub reads the selected hero")
	game.queue_free();await process_frame
	print("CLASSIC_UI: live save values, 9 navigation actions, lore, resume and hero selection passed")
	quit()
