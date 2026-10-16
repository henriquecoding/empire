class_name NativeSceneryActor
extends Node2D

const SHADOW_WIDTH_RATIO := 0.45
const HALF := 0.5
const SHADOW_HEIGHT := 4.0
const CONTACT_SHADOW := preload("res://art/export/_placeholder/contact_shadow_18.png")

var controlled := false
var walking := false
var facing := 1.0
var _time := 0.0
var _art := OriginalArt.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var profile := &"royal_king" if controlled else &"royal_citizen"
	var width := (
		NativeActorFit.bounds(profile, controlled, Vector2.ZERO).size.x * SHADOW_WIDTH_RATIO
	)
	draw_texture_rect(
		CONTACT_SHADOW,
		Rect2(-width * HALF, -SHADOW_HEIGHT * HALF, width, SHADOW_HEIGHT),
		false,
		WorldPalette.SOMBRA
	)
	var action := &"walk" if walking else &"idle"
	var frame := _art.frame_at(profile, _time, action)
	var pose := OriginalArt.posed(
		Vector2.ZERO, facing, NativeActorFit.scale_for(profile, controlled)
	)
	_art.draw_posed(self, profile, Color.WHITE, frame, pose)
