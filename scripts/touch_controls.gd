class_name DFTouch
extends Control

signal action(name: String, held: bool)
var axis: Vector2 = Vector2.ZERO
var active: bool = false
var stick_id: int = -1
var stick_center: Vector2 = Vector2(180,601)
var thumb: Vector2 = Vector2.ZERO
var touches: Dictionary = {}
var mouse_down: bool = false
var font: Font
var buttons: Dictionary = {"attack":Vector2(1130,611),"dodge":Vector2(987,625),"skill0":Vector2(1050,504),"skill1":Vector2(1180,493),"supreme":Vector2(893,513),"potion":Vector2(398,628)}
var cooldowns: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = load("res://assets/DejaVuSans.ttf")

func clear() -> void:
	stick_id=-1; axis=Vector2.ZERO; thumb=Vector2.ZERO; touches.clear(); mouse_down=false
	action.emit("attack",false)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventScreenTouch:
		if event.pressed: press(event.index,event.position)
		else: release(event.index)
	elif event is InputEventScreenDrag:
		if event.index==stick_id: move_stick(event.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT:
		mouse_down=event.pressed
		if mouse_down: press(-2,event.position)
		else: release(-2)
	elif event is InputEventMouseMotion and mouse_down:
		if stick_id==-2: move_stick(event.position)
	queue_redraw()

func press(id: int, pos: Vector2) -> void:
	if pos.distance_to(stick_center)<115 and stick_id==-1:
		stick_id=id; move_stick(pos); return
	for name in buttons:
		var radius = 65 if name=="attack" else 49
		if pos.distance_to(buttons[name])<radius:
			touches[id]=name; action.emit(name,true); return

func release(id: int) -> void:
	if id==stick_id: stick_id=-1; axis=Vector2.ZERO; thumb=Vector2.ZERO
	if touches.has(id):
		var name = touches[id]; touches.erase(id)
		if not touches.values().has(name): action.emit(name,false)

func move_stick(pos: Vector2) -> void:
	thumb = (pos-stick_center).limit_length(70)
	axis = thumb/70
	if axis.length()<.16: axis=Vector2.ZERO

func _draw() -> void:
	if not active or font==null: return
	draw_circle(stick_center,85,Color(.90,.95,1,.30))
	draw_arc(stick_center,85,0,TAU,50,Color(.80,.89,1,.85),2)
	draw_arc(stick_center,70,0,TAU,50,Color(.28,.42,.63,.30),1)
	draw_circle(stick_center+thumb,34,Color(.90,.95,1,.80))
	draw_arc(stick_center+thumb,34,0,TAU,32,Color(.35,.51,.72,.9),2)
	for i in range(4):
		var dir=Vector2.RIGHT.rotated(i*PI/2)
		draw_line(stick_center+dir*52,stick_center+dir*65,Color(.90,.96,1,.7),3)
	var labels = {"attack":"GOLPE","dodge":"ESQUIVA","skill0":"TÉCNICA","skill1":"PODER","supreme":"BRASA","potion":"CURAR"}
	for name in buttons:
		var center: Vector2 = buttons[name]
		var r = 61 if name=="attack" else 45
		var held = touches.values().has(name)
		draw_circle(center+Vector2(0,3),r+1,Color(.12,.21,.35,.26))
		draw_circle(center,r,Color(.91,.95,1,.88) if not held else Color(.69,.82,.97,.96))
		draw_arc(center,r,0,TAU,40,Color(.40,.57,.78,.95),2)
		draw_arc(center,r-5,0,TAU,40,Color(1,1,1,.8),1)
		draw_symbol(name,center-Vector2(0,8),Color("486d99"))
		var label: String = labels[name]
		var cd = float(cooldowns.get(name,0))
		if cd>0: label="%.1f" % cd
		var fs = 12 if name!="attack" else 15
		var tw = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		draw_string(font,center+Vector2(-tw/2,27),label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("2d486b"))
		if name=="supreme":draw_arc(center,r-6,-PI/2,-PI/2+TAU*float(cooldowns.get("charge",0))/100,35,Color(.96,.46,.19),3)

func draw_symbol(name: String, at: Vector2, color: Color) -> void:
	match name:
		"attack":
			draw_line(at+Vector2(-13,16),at+Vector2(17,-18),color,5,true)
			draw_line(at+Vector2(-17,2),at+Vector2(0,17),color,4,true)
			draw_line(at+Vector2(-16,19),at+Vector2(-20,23),color,6,true)
		"dodge":
			for i in range(2):
				var x=i*13-13
				draw_polyline(PackedVector2Array([at+Vector2(x-5,-13),at+Vector2(x+7,0),at+Vector2(x-5,13)]),color,4,true)
		"potion":
			draw_circle(at+Vector2(0,6),13,Color("8cc8a4"))
			draw_rect(Rect2(at+Vector2(-6,-15),Vector2(12,12)),color)
			draw_line(at+Vector2(-7,6),at+Vector2(7,6),Color.WHITE,3)
			draw_line(at+Vector2(0,-1),at+Vector2(0,13),Color.WHITE,3)
		_:
			var points=PackedVector2Array()
			for i in range(10):
				var radius=19.0 if i%2==0 else 8.0
				points.append(at+Vector2.UP.rotated(i*PI/5)*radius)
			draw_colored_polygon(points,Color("d8a455") if name=="supreme" else color)
			draw_circle(at,4,Color.WHITE)
