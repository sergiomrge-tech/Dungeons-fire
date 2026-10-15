extends SceneTree

var checks=0
var failures=[]

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var db=DFContent.new()
	for kind in ["ash_hound","bell_wraith","bone_sentinel","cinder_acolyte","glass_stalker"]:
		check(db.mob(kind).has("role"),"mob profile loaded: "+kind)
		check(ResourceLoader.exists("res://assets/%s.png"%kind),"mob atlas exists: "+kind)
	check(db.roster(0).has("ash_hound") and db.roster(1).has("bell_wraith") and db.roster(4).has("glass_stalker"),"regional rosters include new mobs")
	check(db.boons.size()==8,"eight expedition boons loaded")
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false);game.progress=DFProgress.new(db,"user://run_systems_v07.json");game.progress.d.settings.sound=false
	game.progress.d.cleared=[0,1,2,3,4,5]
	game.start_dungeon(1)
	var before_attack=game.player.attack_power
	game.cleared_room=true;game.route_step="choose";game.show_route_choice();game.choose_hunt_route()
	check(game.screen=="boon_draft" and game.boon_offers.size()==3,"hunt route opens a three-boon draft")
	var chosen=str(game.boon_offers[0]);game.select_route_boon(chosen)
	check(game.room==1 and game.room_risk,"pact advances to the risky branch")
	check(game.run_boons.has(chosen) and game.player.attack_power>=before_attack,"boon persists and updates the run build")
	check(game.enemies.any(func(e):return e.route_reward and e.elite),"risky branch spawns a bonus champion")
	check(game.progress.d.run.get("boons",[]).has(chosen) and bool(game.progress.d.run.get("room_risk",false)),"build and route survive save")
	game.show_pause();game.resume_run()
	check(game.run_boons.has(chosen) and game.enemies.any(func(e):return e.route_reward),"build and champion survive resume")
	var offers=game.boon_options();check(offers.size()==3 and not offers.has(chosen),"draft excludes owned boons")
	game.progress.d.camp_projects=["scribe_table"];game.run_boons=[];game.room=1;game.boon_reroll_used=false
	var original_offers=game.boon_options();game.boon_offers=original_offers.duplicate();game.route_step="draft";game.reroll_boon_offers()
	check(game.boon_reroll_used and game.boon_offers.size()==3 and game.boon_offers!=original_offers,"cartography project gives a distinct one-time reroll")
	game.progress.d.camp_projects=[];game.route_step="";game.boon_offers=[];game.run_boons=[]
	# The bone sentinel has a real directional guard; its back is more vulnerable.
	var bone=game.spawn_mob("bone_sentinel",Vector2(800,480),120,10)
	bone.facing=1;bone.state="idle";bone.invuln=0;var full=bone.hp
	bone.hurt(20,Vector2.ZERO,bone.position+Vector2(70,0));var front_loss=full-bone.hp
	bone.hp=full;bone.invuln=0;bone.state="idle";bone.hurt(20,Vector2.ZERO,bone.position-Vector2(70,0));var rear_loss=full-bone.hp
	check(front_loss<rear_loss,"bone sentinel blocks more damage from the front")
	# Acolytes use lighted area fireballs, while wraith bolts slow the hero.
	var acolyte=game.spawn_mob("cinder_acolyte",Vector2(940,480),100,12);acolyte.aim=game.player.position
	game.enemy_strike(acolyte)
	check(game.world.projectiles.back().style=="fireball" and game.world.projectiles.back().aoe>0,"cinder acolyte launches an area fireball")
	var wraith=game.spawn_mob("bell_wraith",Vector2(940,480),100,12);wraith.aim=game.player.position
	game.enemy_strike(wraith)
	check(game.world.projectiles.back().style=="spectral" and game.world.projectiles.back().slow,"bell wraith launches a slowing spectral bolt")
	# Maela and Neris now contribute distinct combat assists to the active hero.
	game.progress.d.hero="maela";game.progress.d.equipped.weapon="W_staff_0";game.start_dungeon(1)
	for enemy in game.enemies:enemy.position=Vector2(1160,550)
	var target=game.spawn_mob("knight",game.player.position+Vector2(78,0),150,1)
	game.player_strike(game.player,"skill1")
	check(game.synergy_cd>0 and target.stagger_multiplier>1,"Maela calls Varek's posture-breaking assist")
	game.progress.d.hero="neris";game.progress.d.equipped.weapon="W_bow_0";game.start_dungeon(1)
	for enemy in game.enemies:enemy.position=Vector2(1160,550)
	target=game.spawn_mob("knight",game.player.position+Vector2(78,0),150,1)
	game.player_strike(game.player,"skill1")
	check(target.marked>0 and game.synergy_cd>0,"Neris receives Maela's arcane mark")
	game.progress.d.hero="varek";game.progress.d.equipped.weapon="W_sword_0";game.start_dungeon(1)
	for enemy in game.enemies:enemy.position=Vector2(1160,550)
	target=game.spawn_mob("knight",game.player.position+Vector2(78,0),150,1)
	game.player_strike(game.player,"skill0")
	check(target.marked>0 and game.synergy_cd>0,"Varek receives Maela's ember follow-up")
	# Contract constraints and rewards.
	game.progress.d.contract_selected="flame_oath";game.start_dungeon(0)
	var potions=game.potions;game.player.hp=game.player.max_hp*.5;game.use_potion()
	check(game.potions==potions and game.contract_potions_used==0,"flame oath blocks potion use")
	game.loot={"gold":0,"ore":0,"xp":0,"items":[]};check(game.resolve_contract() and game.loot.gold==180 and game.loot.ore==12,"flame oath awards its bonus")
	game.progress.d.contract_selected="champion_hunt";game.start_dungeon(1)
	check(game.enemies.filter(func(e):return e.elite).size()>=1,"champion contract adds a tougher encounter")
	game.progress.d.contract_selected="swift_path";game.start_dungeon(1);game.contract_elapsed=421;game.contract_failed=true
	check(not game.resolve_contract(),"expired timed contract gives no reward")
	# Camp rescues unlock permanent projects and their effects.
	var camp=DFProgress.new(db,"user://camp_projects_v07.json");camp.d.gold=9000;camp.d.ore=900
	camp.complete(0,{});camp.complete(1,{});camp.complete(2,{})
	check(camp.d.camp_survivors==["tomas_bellkeeper"],"guardian victory records the rescued bellkeeper")
	check(camp.build_camp_project("supply_cache"),"three clears unlock the supply cache")
	for index in [3,4,5]:camp.complete(index,{})
	check(camp.build_camp_project("hunter_lodge"),"six clears unlock the hunters lodge")
	for index in [6,7,8]:camp.complete(index,{})
	check(camp.build_camp_project("scribe_table"),"nine clears unlock the cartography table")
	for index in [9,10,11]:camp.complete(index,{})
	check(camp.build_camp_project("ember_ward"),"twelve clears unlock the camp ward")
	game.progress=camp;game.progress.d.contract_selected="";game.start_dungeon(0)
	check(game.potions==3 and game.player.max_hp>game.progress.hero_stats().hp,"camp projects grant supply and health bonuses")
	game.show_camp_projects();check(game.screen=="camp_projects" and game.ui.get_children().any(func(n):return n is Label and n.text.contains("Sobreviventes acolhidos: Tomas")),"camp project screen shows rescued residents")
	var resident_rows=game.ui.get_children().filter(func(n):return n is Label and n.text.contains("está no refúgio"))
	check(resident_rows.size()==mini(4,game.progress.d.camp_survivors.size()) and resident_rows.all(func(n):return n.text.contains("\n")),"camp residents have their own readable line")
	game.show_contracts(0)
	var contract_buttons=game.ui.get_children().filter(func(n):return n is Button)
	check(contract_buttons.size()==5 and contract_buttons.all(func(n):return n.position.x>=180 and n.position.x+n.size.x<=1100),"contract actions fit their panel")
	game.boon_offers=["long_breath","hunter_sigil","soul_siphon"];game.show_boon_draft()
	var boon_cards=game.ui.get_children().filter(func(n):return n is Button and n.has_meta("boon_id"))
	check(boon_cards.size()==3 and boon_cards.all(func(n):return n.size.x==340 and n.position.x>=95 and n.position.x+n.size.x<=1185),"boon cards fit inside the panel")
	var boon_details=game.ui.get_children().filter(func(n):return n is Label and n.position.y==329)
	var details_fit=boon_details.size()==3
	for detail in boon_details:
		details_fit=details_fit and detail.size.x<=300 and detail.clip_text
		for line in detail.text.split("\n"):details_fit=details_fit and line.length()<=27
	for id in db.boons.keys():
		for line in game.wrap_card_text(str(db.boon(str(id)).description)).split("\n"):details_fit=details_fit and line.length()<=27
	check(details_fit,"all boon descriptions wrap inside their cards")
	var report={"suite":"run_systems_v07","checks":checks,"failures":failures,"new_mobs":5,"boons":8,"contracts":3,"camp_projects":4}
	print(JSON.stringify(report));game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
