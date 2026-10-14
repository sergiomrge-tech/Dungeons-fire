class_name DFWorld
extends Node2D

var game
var background: Texture2D
var theme_index: int = 5
var clock: float = 0
var numbers: Array = []
var effects: Array = []
var projectiles: Array = []
var font: Font
var overlay: Node2D

func _ready() -> void:
	font=load("res://assets/DejaVuSans.ttf")
	overlay=Node2D.new();overlay.z_index=1000;add_child(overlay)
	overlay.draw.connect(draw_effects)

func change_theme(index: int) -> void:
	theme_index=index
	background=load("res://assets/painted_worlds/world_%d.webp" % index)
	queue_redraw()
	if overlay!=null:overlay.queue_redraw()

func tick(delta: float) -> void:
	clock+=delta
	for n in numbers: n.time-=delta; n.pos.y-=delta*35
	numbers=numbers.filter(func(n):return n.time>0)
	for e in effects:e.time-=delta
	effects=effects.filter(func(e):return e.time>0)
	for p in projectiles:
		p.time-=delta; p.pos+=p.velocity*delta
		if p.player:
			for target in game.enemies:
				if target.hp>0 and absf(target.position.y-p.pos.y)<24 and absf(target.position.x-p.pos.x)<30 and not p.hit.has(target.id):
					p.hit.append(target.id)
					if target.hurt(p.damage,Vector2(signf(p.velocity.x)*8,0)):
						game.player.supreme=minf(100,game.player.supreme+4)
					if not p.piercing:p.time=0;break
		else:
			if game.player!=null and game.player.hp>0 and game.player.position.distance_to(p.pos)<30:
				game.player.hurt(p.damage);p.time=0
	projectiles=projectiles.filter(func(p):return p.time>0 and p.pos.x>-100 and p.pos.x<1380)
	queue_redraw()
	overlay.queue_redraw()

func missile(pos: Vector2, velocity: Vector2, damage: float, player: bool, color: Color, piercing: bool = false) -> void:
	projectiles.append({"pos":pos,"velocity":velocity,"damage":damage,"player":player,"time":3.0,"color":color,"hit":[],"piercing":piercing})

func fx(pos: Vector2, radius: float, color: Color, seconds: float = .4) -> void:
	effects.append({"pos":pos,"radius":radius,"color":color,"time":seconds,"duration":seconds})

func _draw() -> void:
	if background!=null: draw_texture_rect(background,Rect2(0,0,1280,720),false)
	var colors = [Color("78e0ea"),Color("b7e5ff"),Color("ffffff"),Color("ffcc75"),Color("d9c4ff"),Color("ffe8ba")]
	# Bounded ambient particles complement the painted environments.
	for i in range(22):
		var x = fmod(i*67.7+clock*(5+i%4)+sin(clock*.4+i)*15,1280)
		var y = fmod(i*31.0+clock*(12 if theme_index==2 else -9)+720,570)
		var color: Color = colors[theme_index]; color.a = .22 + .2 * sin(clock+i)
		draw_circle(Vector2(x,y),1.7 if theme_index==2 else 1.2,color)
	if theme_index == 5 and game != null and game.progress != null and game.screen in ["menu","hub","journal"]:
		draw_hub_recovery()
	if theme_index == 1:
		for i in range(8):
			var p = Vector2(270+i*93, 272+sin(i*2.4)*43)
			draw_arc(p, 6+fmod(clock*7+i*3,18), 0, TAU, 24, Color(.7,.94,1,.17),1)
	if game.screen == "combat":
		for i in range(12):
			draw_rect(Rect2(0,600+i*10,1280,10),Color(.12,.18,.28,i*.011))
# Decorative restoration grows from actual campaign and workshop progression.
# These ambient cues never alter collisions or consume gameplay resources.
func draw_hub_recovery() -> void:
	var victories: int = game.progress.d.cleared.size()
	var restored: int = 0
	for key in ["forge","sanctuary","botica","archive","barracks"]:
		restored += maxi(0,int(game.progress.d.hub[key])-1)
	var lights: Array[Vector2] = [Vector2(286,343),Vector2(621,313),Vector2(934,349),Vector2(1113,338)]
	var count: int = mini(lights.size(),1 + victories/3 + restored/2)
	for i in range(count):
		var pos: Vector2 = lights[i]
		var pulse: float = .5 + .5 * sin(clock*2.1+i*1.6)
		draw_circle(pos,17.0+pulse*7.0,Color(1,.72,.33,.055+pulse*.045))
		draw_circle(pos,4.0+pulse*.9,Color(1,.81,.50,.38+pulse*.34))
		for spark in range(3):
			var direction: float = float(spark)*TAU/3.0+float(i)
			var drift: Vector2 = Vector2(cos(direction),sin(direction))* (11.0+spark*3.0)
			draw_circle(pos+drift,1.0,Color(1,.84,.59,.16+pulse*.15))
	if victories >= 3:
		var banners: int = mini(8,3+victories/3+restored)
		for i in range(banners):
			var anchor: Vector2 = Vector2(445+i*44,234+sin(i*.5)*10)
			var fabric: Color = Color("c85f5c") if i%2==0 else Color("e7c77d")
			fabric.a = .83
			draw_colored_polygon(PackedVector2Array([anchor,anchor+Vector2(12,1),anchor+Vector2(6,19+sin(clock*1.6+i)*2)]),fabric)
	if restored >= 2:
		for i in range(mini(10,restored*2+victories/3)):
			var pos: Vector2 = Vector2(178+i*94,533+sin(float(i)*3.2)*18)
			var flutter: float = sin(clock*2.5+i)*3.0
			draw_line(pos,pos+Vector2(flutter,-8),Color("668d65"),2.0)
			draw_circle(pos+Vector2(flutter,-9),2.7,Color("efb2cb") if i%2==0 else Color("ffe19b"))

func draw_effects() -> void:
	for e in effects:
		var alpha = e.time/e.duration
		var color: Color = e.color; color.a*=alpha
		overlay.draw_arc(e.pos,e.radius*(1-alpha*.25),0,TAU,40,color,6)
		for i in range(9):
			var a = i*TAU/9+clock*3
			overlay.draw_circle(e.pos+Vector2(cos(a),sin(a)*.55)*e.radius*(1-alpha*.4),3,color)
	for p in projectiles:
		var facing = signf(p.velocity.x)
		var visual_pos: Vector2=p.pos-Vector2(0,65)
		overlay.draw_line(visual_pos-Vector2(facing*20,0),visual_pos+Vector2(facing*12,0),p.color,4)
		overlay.draw_circle(visual_pos,5,p.color)
	for n in numbers:
		var color = Color(1,.41,.42,n.time) if n.player else Color(1,.96,.76,n.time)
		overlay.draw_string_outline(font,n.pos,str(n.value),HORIZONTAL_ALIGNMENT_LEFT,-1,23,4,Color(.15,.19,.29,n.time))
		overlay.draw_string(font,n.pos,str(n.value),HORIZONTAL_ALIGNMENT_LEFT,-1,23,color)
