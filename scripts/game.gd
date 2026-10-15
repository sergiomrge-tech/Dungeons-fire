extends Node2D

const Actor = preload("res://scripts/actor.gd")
const World = preload("res://scripts/world.gd")
const Touch = preload("res://scripts/touch_controls.gd")
const Progress = preload("res://scripts/progression.gd")
const ClassicUI = preload("res://scripts/classic_ui.gd")
const Content = preload("res://scripts/content.gd")

var classic_ui
var db: DFContent
var progress: DFProgress
var world: DFWorld
var player: DFActor
var enemies: Array = []
var actors: Node2D
var ui: Control
var controls: DFTouch
var expedition_status: Label
var hud: Label
var health_bar: ProgressBar
var mana_bar: ProgressBar
var boss_hud: Label
var toast_label: Label
var camera: Camera2D
var screen: String = "menu"
var previous_screen: String = "hub"
var move_axis: Vector2 = Vector2.ZERO
var attack_held: bool = false
var keyboard_attack: bool = false
var step_timer: float = 0
var shake_timer: float = 0
var toast_timer: float = 0
var save_timer: float = 0
var room: int = 0
var dungeon: int = 0
var potions: int = 2
var loot: Dictionary = {"gold":0,"ore":0,"cloth":0,"xp":0}
var cleared_room: bool = false
var next_enemy_id: int = 1
var wave_ready: float = 0
var hero_dead: bool = false
var sounds: Dictionary = {}
var sfx_players: Array = []
var sfx_index: int = 0
var music: AudioStreamPlayer
var game_theme: Theme
var qa_mode: bool = false
var current_map_region: int = 0
var selected_map_dungeon: int = 0
var guard_charge: float = 0
var resource_cd: float = 0
var room_layout = DFDungeonLayout.new()
var room_events: Array = []
var interact_button: Button
var hit_stop: float = 0

func _ready() -> void:
	get_tree().quit_on_go_back=false
	get_tree().auto_accept_quit=false
	db=Content.new()
	progress=Progress.new(db)
	if "--qa" in OS.get_cmdline_user_args():
		qa_mode=true;progress.path="user://qa_save.json"
	progress.load_save()
	game_theme = make_theme()
	classic_ui=ClassicUI.new(self)
	world=World.new();world.game=self;add_child(world)
	actors=Node2D.new();add_child(actors)
	camera=Camera2D.new();camera.position=Vector2(640,360);add_child(camera)
	var canvas_layer = CanvasLayer.new();add_child(canvas_layer)
	ui=Control.new();ui.theme=game_theme;ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas_layer.add_child(ui)
	controls=Touch.new();controls.action.connect(on_action);canvas_layer.add_child(controls)
	toast_label=Label.new();toast_label.theme=game_theme;toast_label.position=Vector2(330,116);toast_label.size=Vector2(620,50);toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast_label.add_theme_color_override("font_color",Color("ffdfa1"));toast_label.add_theme_color_override("font_outline_color",Color("263a55"));toast_label.add_theme_constant_override("outline_size",6);toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;toast_label.add_theme_font_size_override("font_size",18);toast_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas_layer.add_child(toast_label)
	for sound in ["swing","impact","magic","coin","step","blade_heavy","shield","boss_slam","chest"]: sounds[sound]=load("res://assets/%s.wav"%sound)
	for i in range(6):
		var audio=AudioStreamPlayer.new();audio.volume_db=-12;add_child(audio);sfx_players.append(audio)
	music=AudioStreamPlayer.new();music.stream=load("res://assets/hearth.wav");music.volume_db=-12;add_child(music);music.finished.connect(func():if progress.d.settings.sound:music.play())
	if progress.d.settings.sound and not qa_mode:music.play()
	show_menu()

func make_theme() -> Theme:
	var t=Theme.new();t.default_font=load("res://assets/DejaVuSans.ttf");t.default_font_size=19
	var panel_style=StyleBoxFlat.new()
	panel_style.bg_color=Color(.20,.155,.12,.97);panel_style.border_color=Color("c6a56b")
	panel_style.set_border_width_all(2);panel_style.set_corner_radius_all(7)
	panel_style.shadow_color=Color(0,0,0,.35);panel_style.shadow_size=6;panel_style.shadow_offset=Vector2(0,3)
	panel_style.content_margin_left=16;panel_style.content_margin_top=10;panel_style.content_margin_right=16;panel_style.content_margin_bottom=10
	t.set_stylebox("panel","Panel",panel_style)
	var normal=panel_style.duplicate();normal.bg_color=Color("35281f");normal.shadow_size=2
	var hover=normal.duplicate();hover.bg_color=Color("57402b");hover.border_color=Color("efd39b")
	var pressed=normal.duplicate();pressed.bg_color=Color("281e17");pressed.shadow_size=0
	var disabled=normal.duplicate();disabled.bg_color=Color("302b24");disabled.border_color=Color("6f6551")
	for pair in [["normal",normal],["hover",hover],["pressed",pressed],["disabled",disabled]]:t.set_stylebox(pair[0],"Button",pair[1])
	var focus=normal.duplicate();focus.bg_color=Color.TRANSPARENT;focus.border_color=Color("ffda8b");focus.set_border_width_all(3)
	t.set_stylebox("focus","Button",focus)
	t.set_color("font_color","Button",Color("f7e8c5"));t.set_color("font_hover_color","Button",Color("fff4d9"));t.set_color("font_pressed_color","Button",Color("f7e8c5"));t.set_color("font_disabled_color","Button",Color("a99d83"))
	t.set_color("font_color","Label",Color("f7e8c5"))
	return t

func portrait(kind: String, pos: Vector2, dimensions: Vector2) -> TextureRect:
	var view=TextureRect.new();view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;view.texture=load("res://assets/portraits/%s.png"%kind)
	view.position=pos;view.size=dimensions;view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE;view.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;ui.add_child(view);return view

func meter(pos: Vector2, dimensions: Vector2, color: Color) -> ProgressBar:
	var bar=ProgressBar.new();bar.show_percentage=false;bar.position=pos;bar.size=dimensions;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bg=StyleBoxFlat.new();bg.bg_color=Color("29241e");bg.set_corner_radius_all(4);bg.border_color=Color("8a7959");bg.set_border_width_all(1)
	var fill=StyleBoxFlat.new();fill.bg_color=color;fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background",bg);bar.add_theme_stylebox_override("fill",fill);ui.add_child(bar);return bar

func label(text: String, pos: Vector2, size: Vector2, font_size: int = 20, color: Color = Color("f7e8c5")) -> Label:
	var l=Label.new();l.text=text;l.position=pos;l.size=size;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(l);return l

func button(text: String, pos: Vector2, size: Vector2, callback: Callable, disabled: bool = false) -> Button:
	var b=Button.new();b.text=text;b.position=pos;b.size=size;b.disabled=disabled;b.pressed.connect(callback);ui.add_child(b);return b

func panel(pos: Vector2, size: Vector2) -> Panel:
	var p=Panel.new();p.position=pos;p.size=size;ui.add_child(p)
	var trim=ClassicUI.Trim.new();trim.size=size;trim.wood=true;trim.color=Color("c6a56b");trim.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(trim)
	return p

func clear_ui() -> void:
	for child in ui.get_children():child.queue_free();ui.remove_child(child)
	controls.active=false;controls.clear();attack_held=false;keyboard_attack=false;move_axis=Vector2.ZERO
	toast_label.text="";toast_label.position.y=116;toast_timer=0
	interact_button=null
	hud=null;expedition_status=null;boss_hud=null;health_bar=null;mana_bar=null
	camera.zoom=Vector2.ONE;camera.position=Vector2(640,360)

func clear_actors() -> void:
	for a in actors.get_children():a.queue_free();actors.remove_child(a)
	player=null;enemies.clear();world.projectiles.clear();world.effects.clear();world.numbers.clear()

func title(text: String, subtitle: String = "") -> void:
	panel(Vector2(28,20),Vector2(1224,76))
	label(text,Vector2(50,30),Vector2(1100,34),27)
	label(subtitle,Vector2(52,66),Vector2(1100,25),16,Color("c5b795"))

func resources() -> String:
	return "%d ouro   |   %d minério   |   %d Cinza Viva" % [progress.d.gold,progress.d.ore,progress.d.ash]

func show_menu() -> void:
	clear_ui();clear_actors();screen="menu";world.change_theme(5)
	panel(Vector2(48,100),Vector2(530,526))
	label("DUNGEONS FIRES",Vector2(80,132),Vector2(490,60),40,Color("efd39b"))
	label("AS CINCO BRASAS",Vector2(84,192),Vector2(450,36),23,Color("e3b871"))
	var intro=label("Um fogo que apaga memórias.\nUm refúgio que ainda lembra.",Vector2(84,248),Vector2(450,64),20)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button("ENTRAR NO REFÚGIO",Vector2(84,339),Vector2(458,58),show_hub)
	button("RETOMAR EXPEDIÇÃO",Vector2(84,410),Vector2(458,55),resume_run,progress.d.run.is_empty())
	button("HISTÓRIA",Vector2(84,482),Vector2(220,53),func():show_lore(false))
	button("OPÇÕES",Vector2(320,482),Vector2(222,53),func():previous_screen="menu";show_settings())
	label("v0.5.0 • Uma aventura original em Edrava",Vector2(84,575),Vector2(450,28),16,Color("c5b795"))
	var hero=spawn_actor(progress.d.hero,Vector2(870,550),true,180,28);hero.size_scale=2.7
	label("Seu próximo capítulo começa aqui.",Vector2(710,590),Vector2(500,35),21,Color("ffffff"))

func spawn_actor(kind: String, pos: Vector2, human: bool, life: float, damage: float, boss: bool = false) -> DFActor:
	var a=Actor.new();a.id=next_enemy_id;next_enemy_id+=1;a.setup(self,kind,human,life,damage,boss);a.position=pos;a.z_index=int(pos.y);actors.add_child(a)
	if human:player=a
	else:enemies.append(a)
	if human:apply_equipment_visual(a)
	return a

func apply_equipment_visual(a: DFActor) -> void:
	var family=db.item(progress.d.equipped.weapon).get("family","")
	var special=family in ["hammer","focus","daggers"]
	a.atlas=load("res://assets/%s%s.png"%[a.kind,"_"+family if special else ""])

func relic_effect() -> String:
	return db.item(str(progress.d.equipped.relic)).get("effect","")

func show_hub() -> void:
	clear_ui();clear_actors();screen="hub";hero_dead=false;world.change_theme(5)
	spawn_actor(progress.d.hero,Vector2(635,488),true,progress.hero_stats().hp,progress.hero_stats().attack)
	spawn_actor("knight",Vector2(289,473),false,100,0)
	spawn_actor("maela",Vector2(997,488),false,100,0)
	if progress.d.cleared.size() >= 3:
		spawn_actor("neris",Vector2(1138,493),false,100,0)
	classic_ui.build()
	if not progress.d.tutorial:
		progress.d.tutorial=true;progress.save()
		toast("Comece na Mina dos Sinos pelo mapa. Equipe e melhore na forja.",7)

func show_journal() -> void:
	clear_ui();screen="journal";world.change_theme(5)
	panel(Vector2(65,111),Vector2(1150,565))
	title("DIÁRIO DE EDRAVA","Iria registra os nomes restaurados e os caminhos abertos.")
	var completed: int = progress.d.cleared.size()
	var next_index: int = progress.unlocked()
	label("CRÔNICAS DAS CINCO BRASAS",Vector2(100,144),Vector2(800,42),28,Color("efd39b"))
	label("%d / 15 expedições concluídas"%completed,Vector2(830,151),Vector2(330,34),20,Color("e3b871"))
	for chapter in range(5):
		var total: int = 0
		for idx in range(chapter*3,chapter*3+3):
			if progress.d.cleared.has(idx): total += 1
		var y: float = 207.0 + chapter*66.0
		var is_next: bool = (next_index / 3) == chapter and not progress.d.cleared.has(14)
		var region_title: String = str(db.regions[chapter])
		var status: String = "BRASA RECUPERADA" if total==3 else ("%d de 3 expedições" % total)
		label(("✦  " if total==3 else ("➤  " if is_next else "•  "))+region_title,Vector2(105,y),Vector2(670,31),22,Color("e3b871") if total==3 else Color("ead9b4"))
		label(status,Vector2(822,y+2),Vector2(330,29),18,Color("a4cd91") if total==3 else Color("c5b795"))
	var destination: String = "Os cinco guardiões libertados. O Refúgio floresce." if progress.d.cleared.has(14) else ("Próxima jornada: "+str(db.dungeons[next_index].name))
	label(destination,Vector2(103,557),Vector2(1050,38),19,Color("efd39b"))
	button("IR PARA O MAPA",Vector2(105,606),Vector2(365,53),func():show_map(progress.stage()))
	button("HISTÓRIA",Vector2(490,606),Vector2(280,53),func():show_lore(true))
	button("VOLTAR AO REFÚGIO",Vector2(794,606),Vector2(368,53),show_hub)

func show_map(region: int = 0, selected: int = -1) -> void:
	clear_ui();clear_actors();screen="map";current_map_region=clampi(region,0,4);world.change_theme(current_map_region)
	var first=current_map_region*3
	selected_map_dungeon=clampi(progress.unlocked() if selected<0 else selected,first,first+2)
	classic_ui.build_map(current_map_region,selected_map_dungeon)

func show_preparation(index: int) -> void:
	clear_ui();screen="prepare";dungeon=index;world.change_theme(int(db.dungeons[index].region))
	panel(Vector2(155,99),Vector2(970,534));title(db.dungeons[index].name,"Preparação da expedição")
	var stats=progress.hero_stats()
	label("%s • Nível %d  |  Ataque %.0f  |  Defesa %.0f" %[progress.d.hero.capitalize(),stats.level,stats.attack,stats.defense],Vector2(210,166),Vector2(900,40),24)
	var lore_label=label(db.dungeons[index].lore,Vector2(210,233),Vector2(850,108),22);lore_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("Analógico: mover  |  Golpe: combo  |  Esquiva: evitar dano",Vector2(210,365),Vector2(890,30),20)
	label("Duas técnicas + Brasa suprema. Poções limitadas por expedição.",Vector2(210,405),Vector2(890,30),19)
	label("Solo • 5 salas • Vitória deposita saque no refúgio",Vector2(210,448),Vector2(890,30),18,Color("c5b795"))
	button("ENTRAR NA MASMORRA",Vector2(210,518),Vector2(490,66),func():confirm_start(index))
	button("VOLTAR",Vector2(745,518),Vector2(300,66),func():show_map(int(index/3)))

func confirm_start(index: int) -> void:
	if not progress.d.run.is_empty():
		dialog("Expedição em andamento","Começar outra expedição descarta o saque pendente da anterior. Seus equipamentos e o refúgio serão preservados.","COMEÇAR OUTRA",func():start_dungeon(index),func():show_preparation(index))
	else:start_dungeon(index)

func start_dungeon(index: int, resume: bool = false) -> void:
	clear_ui();clear_actors();screen="combat";hero_dead=false;dungeon=index;room=0;cleared_room=false;wave_ready=0;next_enemy_id=1
	world.change_theme(int(db.dungeons[index].region))
	var stats=progress.hero_stats();spawn_actor(progress.d.hero,Vector2(265,505),true,stats.hp,stats.attack);player.defense=stats.defense
	potions=3 if progress.d.hub.botica>=3 else 2
	loot={"gold":0,"ore":0,"cloth":0,"xp":0,"items":[]};room_events=[];guard_charge=0;hit_stop=0
	if resume:
		var run=progress.d.run.duplicate(true)
		room=int(run.room);potions=int(run.potions);loot=run.loot;cleared_room=run.cleared
		room_events=run.get("events",[]).duplicate();room_layout.configure(dungeon,room);world.configure_room()
		player.hp=float(run.hp);player.position=Vector2(run.x,run.y);player.supreme=float(run.get("supreme",0));player.mana=float(run.get("mana",100))
		for data in run.enemies:
			var a=spawn_actor(data.kind,Vector2(data.x,data.y),false,data.max_hp,data.attack,data.boss)
			a.hp=data.hp;a.id=int(data.id);a.facing=int(data.facing)
			a.boss_phase=int(data.get("boss_phase",1));a.boss_step=int(data.get("boss_step",0));a.elite=bool(data.get("elite",false))
			a.cooldown=1.0
			next_enemy_id=maxi(next_enemy_id,a.id+1)
	else:spawn_room()
	combat_ui();save_run()
	if resume:toast("Expedição restaurada. Vida, poções e saque preservados.",4)
	else:toast("Mova-se na profundidade do chão; observe os avisos dos ataques.",5)

func resume_run() -> void:
	if progress.d.run.is_empty():return
	var r=progress.d.run
	if not r.has_all(["dungeon","room","hp","enemies","loot","potions","x","y","cleared"]) or int(r.dungeon)<0 or int(r.dungeon)>=15 or float(r.hp)<=0:
		toast("Expedição não pôde ser restaurada. O progresso do refúgio está seguro.");return
	start_dungeon(int(r.dungeon),true)

func spawn_room() -> void:
	for a in enemies:
		if is_instance_valid(a): a.queue_free();actors.remove_child(a)
	enemies.clear();world.projectiles.clear();cleared_room=false
	player.position=Vector2(205,505)
	var region=int(db.dungeons[dungeon].region)
	var count=3+room%2
	room_layout.configure(dungeon,room);world.configure_room()
	if dungeon==0 and room<4:
		for entry in room_layout.definition.get("enemies",[]):
			var actor=spawn_actor(entry[0],Vector2(entry[1],entry[2]),false,(43+(15 if entry[0]=="brute" else 0))*entry[3],9)
			actor.elite=float(entry[3])>1.0
		if room_layout.definition.get("rest",false) and not room_events.has("MINE_REST_03"):
			player.hp=minf(player.max_hp,player.hp+player.max_hp*.25);room_events.append("MINE_REST_03")
			toast("Abrigo seguro • 25% de vida recuperada. Abra o baú antes de seguir.",5)
	elif room==4:
		var kind="brute"
		if db.dungeons[dungeon].guardian:kind=["garron","sereia","rei","colosso","severan"][region]
		var life=320 if dungeon==0 else 230+dungeon*47
		spawn_actor(kind,Vector2(900,480),false,life,20+region*4,true)
		if region>0:spawn_actor("knight",Vector2(1040,531),false,50+region*15,10+region*3)
	else:
		for i in range(count):
			var kind=["knight","archer","brute"][(i+room+dungeon)%3]
			spawn_actor(kind,Vector2(660+i*118,436+(i*41+room*19)%116),false,43+dungeon*11+(15 if kind=="brute" else 0),9+region*3)
		if room==3:
			player.hp=minf(player.max_hp,player.hp+player.max_hp*.25)
			toast("Descanso: recuperou 25% da vida. Prepare-se para o chefe.",5)
	if hud!=null:combat_ui()
	save_run()

func combat_ui() -> void:
	clear_ui();screen="combat";controls.active=true;controls.hero_kind=progress.d.hero;toast_label.position.y=207
	if player!=null:
		var stats=progress.hero_stats()
		player.attack_power=stats.attack;player.defense=stats.defense
		player.max_hp=stats.hp;player.hp=minf(player.hp,player.max_hp)
		apply_equipment_visual(player)
	panel(Vector2(22,18),Vector2(380,108));portrait(progress.d.hero,Vector2(26,25),Vector2(82,92))
	hud=label("",Vector2(112,29),Vector2(278,34),16)
	health_bar=meter(Vector2(114,70),Vector2(263,14),Color("69ae83"));health_bar.max_value=player.max_hp
	mana_bar=meter(Vector2(114,94),Vector2(263,9),Color("6b9bce"));mana_bar.max_value=100
	panel(Vector2(420,20),Vector2(388,65))
	label(room_layout.definition.get("name",db.dungeons[dungeon].name),Vector2(438,29),Vector2(360,28),17)
	expedition_status=label("Sala %d / 5  •  Poções %d"%[room+1,potions],Vector2(438,56),Vector2(360,24),14,Color("c5b795"))
	button("MOCHILA",Vector2(838,24),Vector2(170,57),func():save_run();previous_screen="combat";show_inventory())
	button("PAUSA",Vector2(1023,24),Vector2(200,57),show_pause)
	boss_hud=label("",Vector2(630,135),Vector2(600,62),21,Color("f0dab0"))
	if cleared_room:
		button("PRÓXIMA SALA  →",Vector2(980,246),Vector2(255,52),next_room)
		button("DEPOSITAR SAQUE",Vector2(980,306),Vector2(255,46),retreat)
	interact_button=button("ABRIR BAÚ • F",Vector2(477,568),Vector2(300,52),interact_chest);interact_button.visible=false
	update_hud()

func update_hud() -> void:
	if player==null or hud==null:return
	hud.text="%s • Nv. %d\nVida %d / %d"%[progress.d.hero.capitalize(),progress.hero_stats().level,player.hp,player.max_hp]
	if expedition_status!=null:expedition_status.text="Sala %d / 5  •  Poções %d"%[room+1,potions]
	if health_bar!=null:health_bar.value=player.hp
	if mana_bar!=null:mana_bar.value=player.mana if player.kind=="maela" else player.supreme
	controls.cooldowns={"dodge":player.dodge_cd,"skill0":player.skill_cd[0],"skill1":player.skill_cd[1],"charge":player.supreme}
	controls.queue_redraw()
	if boss_hud!=null:
		boss_hud.text=""
		for enemy in enemies:
			if enemy.boss and enemy.hp>0:
				boss_hud.text="%s\nVida %d/%d • %s" %[db.dungeons[dungeon].boss,enemy.hp,enemy.max_hp,("POSTURA ABERTA" if enemy.state in ["recover","hurt"] else ("Fase II" if enemy.boss_phase==2 else "Fase I"))]

func move_actor(from: Vector2, motion: Vector2) -> Vector2:
	# Substeps prevent dodge/dash tunnelling through solid props.
	var count=maxi(1,int(ceil(motion.length()/10.0)))
	var pos=from
	for i in range(count):pos=room_layout.move(pos,motion/count)
	return pos

func nearby_chest() -> Dictionary:
	if player==null:return {}
	for chest in room_layout.definition.get("chests",[]):
		if not room_events.has(chest.id) and player.position.distance_to(Vector2(chest.x,chest.y))<115:return chest
	return {}

func interact_chest() -> void:
	if screen!="combat":return
	var chest=nearby_chest()
	if chest.is_empty():return
	var old_loot=loot.duplicate(true);var old_events=room_events.duplicate()
	for key in ["gold","ore","cloth"]:loot[key]+=int(chest.get(key,0))
	room_events.append(chest.id)
	if not save_run():loot=old_loot;room_events=old_events;return
	world.refresh_chests();play_sfx("chest")
	toast("Baú: +%d ouro • +%d minério • saque guardado na expedição"%[chest.gold,chest.ore],3)

func next_room() -> void:
	if not cleared_room:return
	room+=1
	spawn_room();combat_ui()

func windup_count() -> int:
	var count=0
	for enemy in enemies:
		if enemy.hp>0 and enemy.state in ["windup","attack"]:count+=1
	return count

func player_strike(a: DFActor, action_name: String) -> void:
	var weapon=db.item(progress.d.equipped.weapon)
	var family=weapon.get("family","sword")
	var ranged=family in ["staff","focus","bow"]
	var damage=a.attack_power*(1.3 if a.combo==2 and action_name=="basic" else 1.0)
	var range_x=145.0 if family=="hammer" else 116.0
	var depth=56.0
	var color=Color("ffd179")
	var charged=relic_effect()=="guard" and guard_charge>0
	var landed=false
	var omnidirectional=false
	if action_name=="skill0":
		damage*=2.1;range_x=240;depth=80
		if a.kind=="varek":range_x=170
	elif action_name=="skill1":
		damage*=1.5;range_x=210;depth=100;omnidirectional=true;ranged=false
		a.invuln=maxf(a.invuln,.55)
		color=Color("eba858")
	elif action_name=="supreme":
		damage*=4.2;range_x=390;depth=180;omnidirectional=true;ranged=false
		color=Color("fff0bc")
	if family=="hammer":damage*=1.15
	if ranged and action_name in ["basic","skill0"]:
		var y=a.position.y
		var nearest: DFActor=null
		var dist=600.0
		for e in enemies:
			if e.hp>0 and signf(e.position.x-a.position.x)==a.facing and e.position.distance_to(a.position)<dist:
				nearest=e;dist=e.position.distance_to(a.position)
		var vel=Vector2(a.facing,0)
		if nearest!=null:vel=(nearest.position-a.position).normalized()
		world.missile(a.position,vel*620,damage,true,Color("ff9759") if a.kind=="maela" else Color("e7d8ad"),action_name=="skill0")
		world.fx(a.position-Vector2(0,45),36,color,.23)
		return
	world.fx(a.position+Vector2(a.facing*70,-30),range_x*.48,color,.35)
	for e in enemies:
		if e.hp<=0:continue
		var diff: Vector2=e.position-a.position
		var in_front=diff.x*a.facing>=-24 or omnidirectional
		if in_front and absf(diff.x)<range_x and absf(diff.y)<depth and not room_layout.segment_blocked(a.position,e.position):
			var boost=1.0
			if charged:boost=1.25;e.stagger_multiplier=2.5
			if relic_effect()=="rupture" and action_name!="basic":boost=1.20
			if e.hurt(damage*boost,Vector2(a.facing*(18 if not e.boss else 4),0),a.position):
				landed=true
				a.supreme=minf(100,a.supreme+8)
				if action_name=="skill1" or relic_effect()=="slow":e.slowed=2.5

	if landed:
		hit_stop=.065 if a.combo==2 else .035
		if charged:
			guard_charge=0;world.fx(a.position-Vector2(0,40),95,Color("fff1a6"),.45);play_sfx("shield")

func enemy_strike(a: DFActor) -> void:
	if player.hp<=0:return
	if not a.boss_profile.is_empty():
		world.fx(a.position,90,Color("ff9955"),.35);play_sfx("boss_slam")
		if a.boss_profile.move!="rush" and DFBossPatterns.contains(a.boss_profile,player.position) and not room_layout.segment_blocked(a.boss_profile.origin,player.position):
			player.hurt(a.attack_power*a.boss_profile.damage,Vector2(a.facing*18,0),a.boss_profile.origin)
		return
	if a.kind in ["archer","sereia","severan"]:
		var vel=(a.aim-a.position).normalized()*320
		world.missile(a.position,vel,a.attack_power,false,Color("ee7068"))
		if a.boss and a.hp<a.max_hp*.5:
			world.missile(a.position,vel.rotated(.12),a.attack_power*.8,false,Color("c2dceb"))
			world.missile(a.position,vel.rotated(-.12),a.attack_power*.8,false,Color("c2dceb"))
	else:
		var reach=150.0 if a.boss else 89.0
		var depth=70.0 if a.boss else 45.0
		world.fx(a.position+Vector2(a.facing*40,-12),reach*.5,Color(1,.35,.24),.28)
		var diff: Vector2=player.position-a.position
		if absf(diff.x)<reach and absf(diff.y)<depth and diff.x*a.facing>-20 and not room_layout.segment_blocked(a.position,player.position):
			player.hurt(a.attack_power*(1.25 if a.boss and a.hp<a.max_hp*.5 else 1.0),Vector2(a.facing*13,0),a.position)
		if a.boss and a.hp<a.max_hp*.5:
			world.fx(a.position,110,Color("ed7851"),.5)
			if player.position.distance_to(a.position)<110:player.hurt(a.attack_power*.65,Vector2.ZERO,a.position)

func damage_text(pos: Vector2, value: int, human: bool) -> void:
	world.numbers.append({"pos":pos,"value":value,"time":1.0,"player":human})

func on_enemy_dead(a: DFActor) -> void:
	loot.gold+=8+dungeon*2;loot.ore+=1;loot.xp+=18+dungeon*7
	if a.id%3==0:loot.cloth+=1
	if a.id%4==0:
		if not loot.has("items"):loot.items=[]
		var candidates=db.unlocked_items(int(dungeon/3)+1,progress.d.hero).filter(func(item):return item.slot!="relic")
		if not candidates.is_empty():loot.items.append(candidates[(a.id+dungeon*7)%candidates.size()].id)
	if relic_effect()=="resource" and resource_cd<=0:
		player.mana=minf(100,player.mana+15);player.supreme=minf(100,player.supreme+8);resource_cd=3
	play_sfx("coin")
	save_run()

func on_player_dead() -> void:
	hero_dead=true;controls.active=false;controls.clear();attack_held=false
	progress.d.run={};progress.save()
	wave_ready=.9

func finish_dungeon() -> void:
	screen="result";controls.active=false
	var result=progress.complete(dungeon,loot)
	if result.has("error"):
		dialog("Falha ao salvar",result.error,"TENTAR NOVAMENTE",finish_dungeon,show_menu);return
	clear_ui();screen="result"
	panel(Vector2(170,128),Vector2(940,470))
	label("MASMORRA CONCLUÍDA",Vector2(218,166),Vector2(850,55),36,Color("e3b871"))
	label(db.dungeons[dungeon].name,Vector2(218,235),Vector2(850,55),25)
	label("+%d ouro    +%d minério\nHerói nível %d • %d equipamentos obtidos"%[result.gold,result.ore,result.level,result.items.size()],Vector2(218,307),Vector2(850,80),25)
	var message="Nova rota disponível no mapa." if result.first else "Materiais recebidos para novas melhorias."
	if db.dungeons[dungeon].guardian:message="Brasa recuperada! Núcleo e receita de relíquia liberados na Forja."
	if dungeon==2:message="Núcleo de Garron + receita Marca do Portão! Forja nível 2: defesa carrega um golpe que rompe postura."
	if dungeon==14:message="O Incêndio Branco terminou. Os nomes voltam a ser lembrados. Edrava pode mudar."
	var m=label(message,Vector2(218,406),Vector2(850,70),22);m.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button("VOLTAR AO REFÚGIO",Vector2(218,517),Vector2(450,56),show_hub)
	button("MAPA",Vector2(717,517),Vector2(300,56),func():show_map(int(db.dungeons[dungeon].region)))

func fail_screen() -> void:
	clear_ui();screen="failed"
	panel(Vector2(210,174),Vector2(860,390))
	label("A BRASA AINDA VIVE",Vector2(252,209),Vector2(800,55),35)
	label("O saque desta tentativa foi perdido.\nEquipamentos e melhorias do refúgio foram preservados.",Vector2(254,290),Vector2(780,85),23)
	button("TENTAR NOVAMENTE",Vector2(253,446),Vector2(420,60),func():start_dungeon(dungeon))
	button("REFÚGIO",Vector2(704,446),Vector2(300,60),show_hub)

func retreat() -> void:
	if not cleared_room:return
	var old=progress.d.duplicate(true)
	progress.d.gold+=loot.gold;progress.d.ore+=loot.ore;progress.d.cloth+=loot.cloth;progress.give_xp(loot.xp);progress.d.run={}
	for id in loot.get("items",[]):progress.grant_item(str(id))
	if not progress.save():progress.d=old;toast("Falha ao salvar retirada.");return
	show_hub();toast("Saque comum depositado. Recompensas de chefe exigem vitória.",5)

func use_potion() -> void:
	if potions<1 or player==null or player.hp<=0 or player.hp>=player.max_hp:return
	potions-=1
	var cure=[.30,.40,.45][int(progress.d.hub.botica)-1]
	player.hp=minf(player.max_hp,player.hp+player.max_hp*cure)
	world.fx(player.position-Vector2(0,50),60,Color("93cd89"),.5);play_sfx("magic");save_run()

func on_action(name: String, held: bool) -> void:
	if screen!="combat" or player==null:return
	if name=="attack":
		attack_held=held
		if held:player.request_attack()
	elif held:
		match name:
			"dodge":player.request_dodge()
			"skill0":player.request_skill(0)
			"skill1":player.request_skill(1)
			"supreme":player.request_supreme()
			"potion":use_potion()

func save_run() -> bool:
	if player==null or player.hp<=0 or hero_dead:return false
	var old_run=progress.d.run.duplicate(true)
	var enemy_data:Array=[]
	for a in enemies:
		if a.hp>0:enemy_data.append(a.snapshot())
	progress.d.run={"dungeon":dungeon,"room":room,"hp":player.hp,"x":player.position.x,"y":player.position.y,"potions":potions,"loot":loot.duplicate(true),"enemies":enemy_data,"cleared":cleared_room,"supreme":player.supreme,"mana":player.mana,"events":room_events.duplicate()}
	if not progress.save():progress.d.run=old_run;toast("Não foi possível salvar a expedição.");return false
	return true

func show_pause() -> void:
	save_run();clear_ui();screen="pause"
	panel(Vector2(375,166),Vector2(530,431));label("EXPEDIÇÃO PAUSADA",Vector2(410,204),Vector2(470,55),28)
	button("CONTINUAR",Vector2(412,278),Vector2(450,58),combat_ui)
	button("OPÇÕES",Vector2(412,351),Vector2(450,58),func():previous_screen="combat";show_settings())
	button("SALVAR E SAIR AO MENU",Vector2(412,424),Vector2(450,58),show_menu)
	button("ABANDONAR EXPEDIÇÃO",Vector2(412,497),Vector2(450,58),func():dialog("Abandonar?","O saque pendente será perdido. Seu equipamento e progresso permanente ficam preservados.","ABANDONAR",func():progress.d.run={};progress.save();show_hub(),show_pause))

func show_inventory() -> void:
	clear_ui();screen="inventory"
	panel(Vector2(35,20),Vector2(1210,681));title("MOCHILA E EQUIPAMENTOS",resources())
	var stats=progress.hero_stats()
	label("Ataque %.0f • Defesa %.0f • Vida %d"%[stats.attack,stats.defense,stats.hp],Vector2(66,120),Vector2(1050,34),22)
	item_scroll(progress.d.inventory,false)
	button("VOLTAR / X",Vector2(900,627),Vector2(300,55),back_context)
	label("Repetidos / mochila cheia convertem em minério nesta versão.",Vector2(65,641),Vector2(790,30),17)

func item_scroll(ids: Array, crafting: bool) -> void:
	var scroll=ScrollContainer.new();scroll.position=Vector2(60,174);scroll.size=Vector2(1150,432);ui.add_child(scroll)
	var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);scroll.add_child(list)
	for id in ids:
		var def=db.item(str(id))
		if def.is_empty():continue
		if def.hero!="all" and def.hero!=progress.d.hero:continue
		var row=HBoxContainer.new();row.custom_minimum_size=Vector2(1100,65);list.add_child(row)
		var text=Label.new();text.custom_minimum_size=Vector2(690,78);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_font_size_override("font_size",18)
		var n=int(progress.d.upgrades.get(id,0))
		var equipped=progress.d.equipped[def.slot]==id
		var current=db.item(str(progress.d.equipped.get(def.slot,"")))
		var diff=float(def.attack)-float(current.get("attack",0))
		text.text="%s +%d  %s\n%s • Atq %d / Def %d • Comparação atq %+d" %[def.name,n,"[EQUIPADO]" if equipped else "",["Comum","Raro","Épico","Lendário"][int(def.rarity)],def.attack,def.defense,diff]
		if def.id=="R_0":text.text+="\nDefesa frontal: próximo golpe +25% dano e 2,5x quebra de postura."
		elif def.slot=="relic" and def.get("core","")!="":text.text+="\nReceita: "+("liberada" if progress.recipe_unlocked(str(id)) else "vença o guardião regional")
		text.add_theme_color_override("font_color",[Color("e4d5b2"),Color("8dc8ef"),Color("d0a0ed"),Color("f4c278")][int(def.rarity)]);row.add_child(text)
		var b=Button.new();b.custom_minimum_size=Vector2(205,60);row.add_child(b)
		if crafting:
			b.text="%d ouro / %d minério\n%s"%[def.cost,def.ore,"FABRICAR" if progress.recipe_unlocked(str(id)) else "RECEITA BLOQUEADA"];b.add_theme_font_size_override("font_size",15)
			b.disabled=progress.d.inventory.has(id) or not progress.recipe_unlocked(str(id))
			b.pressed.connect(craft_item.bind(id))
		else:
			b.text="EQUIPADO" if equipped else "EQUIPAR";b.disabled=equipped
			b.pressed.connect(equip_item.bind(id))
			if previous_screen!="combat":
				var u=Button.new();u.custom_minimum_size=Vector2(170,60);u.text="MELHORAR\n%d ouro"%[40+n*25];u.add_theme_font_size_override("font_size",16);row.add_child(u)
				u.pressed.connect(upgrade_item.bind(id))

func show_forge() -> void:
	clear_ui();screen="forge";previous_screen="hub"
	panel(Vector2(35,20),Vector2(1210,681));title("FORJA DE DORAN • NÍVEL %d"%progress.d.hub.forge,resources())
	label("Fabricação garantida • Sem falha • Materiais de chefe liberam relíquias",Vector2(61,120),Vector2(1110,34),20)
	var ids:Array=[]
	for def in db.unlocked_items(progress.stage()+1,progress.d.hero):ids.append(def.id)
	item_scroll(ids,true)
	button("MOCHILA",Vector2(60,626),Vector2(310,55),func():previous_screen="hub";show_inventory())
	button("VOLTAR / X",Vector2(905,626),Vector2(300,55),show_hub)

func show_buildings() -> void:
	clear_ui();screen="buildings";panel(Vector2(80,20),Vector2(1120,682));title("APRIMORAR O REFÚGIO",resources())
	var keys=["forge","sanctuary","botica","archive","barracks"]
	var names=["Forja de Doran","Santuário das Brasas","Botica de Sava","Arquivo de Iria","Quartel de Oren"]
	var descriptions=["Melhorias +3 / +7 / +10; relíquias de chefe","Bônus de talentos: vida e ataque","Poções: cura maior; terceira carga no nível 3","Biblioteca dos nomes e progresso regional","Treinamento e marcos de expedição"]
	for i in range(5):
		var key=keys[i];var n=int(progress.d.hub[key]);var y=145+i*83
		label("%s  •  Nível %d\n%s"%[names[i],n,descriptions[i]],Vector2(119,y),Vector2(710,75),19)
		button("MÁXIMO" if n>=3 else "%d ouro / %d minério / 1 Cinza\nMELHORAR"%[250 if n==1 else 700,20 if n==1 else 50],Vector2(854,y),Vector2(298,65),upgrade_building.bind(key),n>=3)
	button("VOLTAR / X",Vector2(850,625),Vector2(300,55),show_hub)

func show_heroes() -> void:
	clear_ui();screen="heroes";panel(Vector2(65,20),Vector2(1150,680));title("PORTADORES DE BRASA","Experiência individual; campanha e recursos compartilhados.")
	var ids=["varek","maela","neris"]
	var desc=["Guardião da Forja\nEspada/escudo ou martelo\nTécnicas de impacto e proteção","Tecelã de Cinzas\nCajado ou foco\nMagia, mana e controle em área","Vigia dos Caminhos\nLâminas ou arco\nMobilidade, projéteis e flanco"]
	for i in range(3):
		var id=ids[i];var req=[0,3,6][i];var x=90+i*386
		label(id.capitalize(),Vector2(x,158),Vector2(350,40),30,Color("efd39b"))
		portrait(id,Vector2(x+108,206),Vector2(130,140))
		label(desc[i],Vector2(x,350),Vector2(350,100),18)
		label("Liberado" if progress.unlocked()>=req else "Conclua %d masmorras"%req,Vector2(x,455),Vector2(350,35),19)
		button("ESCOLHER",Vector2(x,506),Vector2(336,65),choose_hero.bind(id),progress.unlocked()<req)
	button("VOLTAR / X",Vector2(870,627),Vector2(300,55),show_hub)

func show_talents() -> void:
	clear_ui();screen="talents";panel(Vector2(160,90),Vector2(960,550));title("SANTUÁRIO DAS BRASAS",resources())
	var h=progress.d.heroes[progress.d.hero]
	var available=int(h.level)-1-int(h.talents)
	label("%s • Pontos disponíveis: %d"%[progress.d.hero.capitalize(),available],Vector2(215,172),Vector2(850,48),28)
	label("Vigília do Portador • Ranks %d\nCada ponto: +3,5%% ataque e +8 vida máxima.\nA árvore completa de especializações será expandida nas próximas versões."%h.talents,Vector2(215,267),Vector2(850,115),22)
	button("INVESTIR UM PONTO",Vector2(215,428),Vector2(460,62),func():h.talents+=1;progress.save();show_talents(),available<=0)
	button("REDEFINIR GRÁTIS",Vector2(705,428),Vector2(350,62),func():h.talents=0;progress.save();show_talents())
	button("VOLTAR / X",Vector2(760,550),Vector2(300,55),show_hub)

func show_lore(from_hub: bool) -> void:
	var back=show_hub if from_hub else show_menu
	clear_ui();screen="lore";panel(Vector2(105,80),Vector2(1070,577));title("A VIGÍLIA DOS NOMES","Arquivo de Iria")
	var text="Edrava nasceu sobre os ossos da Mãe da Aurora. Cinco brasas mantinham suas terras vivas, alimentadas pelas histórias dos que partiram.\n\nSeveran tentou trazer sua filha de volta queimando lembranças arrancadas dos vivos. O ritual criou o Incêndio Branco: uma chama fria que apaga nomes e aprisiona os mortos.\n\nNo Refúgio da Última Chama, Iria guarda um livro de nomes proibidos. Você é um Portador de Brasa, capaz de recuperar os guardiões e devolver ao mundo o direito de mudar."
	var l=label(text,Vector2(157,162),Vector2(960,344),23);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("Brasas recuperadas: %d de 5"%[progress.d.cleared.filter(func(i):return int(i)%3==2).size()],Vector2(159,533),Vector2(730,45),22,Color("e3b871"))
	button("VOLTAR / X",Vector2(788,580),Vector2(310,55),back)

func show_settings() -> void:
	clear_ui();screen="settings";panel(Vector2(240,115),Vector2(800,530));title("OPÇÕES","Preferências salvas neste aparelho")
	button("ÁUDIO: %s"%["LIGADO" if progress.d.settings.sound else "DESLIGADO"],Vector2(287,180),Vector2(710,60),toggle_audio)
	button("TREMOR: %s"%["LIGADO" if progress.d.settings.shake else "DESLIGADO"],Vector2(287,258),Vector2(710,60),func():progress.d.settings.shake=not progress.d.settings.shake;progress.save();show_settings())
	button("DIFICULDADE: %s"%["HISTÓRIA (menos dano)" if progress.d.settings.story_mode else "AVENTURA"],Vector2(287,336),Vector2(710,60),func():progress.d.settings.story_mode=not progress.d.settings.story_mode;progress.save();show_settings(),previous_screen=="combat")
	button("ZOOM: %.1fx"%progress.d.settings.zoom,Vector2(287,414),Vector2(710,60),func():progress.d.settings.zoom=1.15 if progress.d.settings.zoom<1.1 else (1.3 if progress.d.settings.zoom<1.2 else 1.0);progress.save();show_settings())
	button("VOLTAR / X",Vector2(637,558),Vector2(360,55),back_context)

func back_context() -> void:
	if previous_screen=="combat":combat_ui()
	elif previous_screen=="menu":show_menu()
	else:show_hub()

func craft_item(id: String) -> void:
	if progress.buy_item(id):
		show_forge();toast("Item fabricado; equipe na mochila.")
	else:toast("Faltam recursos, material de chefe ou nível de forja.")

func equip_item(id: String) -> void:
	if progress.equip(id):show_inventory();toast("Equipamento atualizado.")

func upgrade_item(id: String) -> void:
	if progress.upgrade(id):show_inventory();toast("Aprimoramento +%d"%progress.d.upgrades[id])
	else:toast("Faltam ouro/minério ou limite da forja atingido.")

func upgrade_building(key: String) -> void:
	if progress.upgrade_hub(key):show_buildings();toast("Refúgio aprimorado.")
	else:toast("Conclua a região I/III e confira os materiais.")

func choose_hero(id: String) -> void:
	if not progress.d.run.is_empty():toast("Conclua ou abandone a expedição antes de trocar.")
	elif progress.switch_hero(id):show_hub()

func toggle_audio() -> void:
	progress.d.settings.sound=not progress.d.settings.sound;progress.save()
	if progress.d.settings.sound:music.play()
	else:music.stop()
	show_settings()

func dialog(heading: String, text: String, ok_text: String, ok: Callable, cancel: Callable) -> void:
	clear_ui();screen="dialog";panel(Vector2(243,166),Vector2(794,408))
	label(heading,Vector2(285,202),Vector2(712,52),30)
	var msg=label(text,Vector2(285,275),Vector2(712,145),22);msg.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(ok_text,Vector2(285,467),Vector2(420,59),ok)
	button("CANCELAR",Vector2(735,467),Vector2(260,59),cancel)

func toast(message: String, seconds: float = 3) -> void:
	if toast_label==null:return
	toast_label.text=message;toast_timer=seconds

func play_sfx(name: String) -> void:
	if qa_mode or not progress.d.settings.sound or not sounds.has(name):return
	var a=sfx_players[sfx_index%6];sfx_index+=1;a.stream=sounds[name];a.volume_db=-22 if name=="step" else -12;a.play()

func _physics_process(delta: float) -> void:
	if world==null:return
	toast_timer=maxf(0,toast_timer-delta)
	if toast_timer<=0:toast_label.text=""
	step_timer=maxf(0,step_timer-delta)
	guard_charge=maxf(0,guard_charge-delta);resource_cd=maxf(0,resource_cd-delta)
	if screen=="combat":
		var keys=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		move_axis=controls.axis if controls.axis.length()>.1 else keys.normalized()
		if hit_stop>0:
			hit_stop=maxf(0,hit_stop-delta);return
		player.tick(delta)
		for enemy in enemies:enemy.tick(delta)
		world.tick(delta)
		update_hud()
		if interact_button!=null:interact_button.visible=not nearby_chest().is_empty()
		world.refresh_gate()
		if hero_dead:
			wave_ready-=delta
			if wave_ready<=0:fail_screen()
			return
		if not cleared_room and enemies.all(func(a):return a.hp<=0):
			cleared_room=true
			if room==4:finish_dungeon();return
			save_run();combat_ui();toast("Sala liberada. Avance ou deposite o saque e retorne.",4)
		var zoom=float(progress.d.settings.zoom)
		if room==4:zoom=minf(zoom,1.15)
		camera.zoom=Vector2(zoom,zoom)
		var half=Vector2(640,360)/zoom
		camera.position=Vector2(clampf(player.position.x,half.x,1280-half.x),clampf(player.position.y-90,half.y,720-half.y))
		shake_timer=maxf(0,shake_timer-delta)
		if shake_timer>0 and progress.d.settings.shake:camera.offset=Vector2(sin(Time.get_ticks_msec()*.07)*3,cos(Time.get_ticks_msec()*.09)*2)
		else:camera.offset=Vector2.ZERO
		save_timer+=delta
		if save_timer>2:save_timer=0;save_run()
	else:
		world.clock+=delta;world.queue_redraw()
		for a in actors.get_children():a.anim_clock+=delta;a.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.keycode==KEY_ESCAPE and event.pressed:back()
		if screen=="combat" and player!=null:
			if event.keycode in [KEY_SPACE,KEY_J]:on_action("attack",event.pressed)
			if event.pressed:
				match event.keycode:
					KEY_K:player.request_dodge()
					KEY_Q:player.request_skill(0)
					KEY_E:player.request_skill(1)
					KEY_R:player.request_supreme()
					KEY_H:use_potion()
					KEY_F:interact_chest()

func back() -> void:
	match screen:
		"combat":show_pause()
		"pause":combat_ui()
		"inventory","settings":
			if previous_screen=="combat":combat_ui()
			elif previous_screen=="menu":show_menu()
			else:show_hub()
		"menu":get_tree().quit()
		_:show_hub()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:back()
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED] and screen=="combat":show_pause()
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if screen=="combat":save_run()
		get_tree().quit()

func _exit_tree() -> void:
	if music!=null:music.stop()
	for a in sfx_players:a.stop()
