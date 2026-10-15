class_name DFRoomProp
extends Node2D

var cell: int=0
var display_size=Vector2(88,88)
var atlas: Texture2D

func _ready() -> void:
	atlas=load("res://assets/mine_props.png")
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	z_index=int(position.y)

func _draw() -> void:
	if atlas==null:return
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.30))
	draw_circle(Vector2.ZERO,display_size.x*.29,Color(0,0,0,.24))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect_region(atlas,Rect2(-display_size.x/2,-display_size.y+4,display_size.x,display_size.y),Rect2((cell%4)*256,(cell/4)*256,256,256))
