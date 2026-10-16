class_name NativeSceneryActor
extends Node2D

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
	var action := &"walk" if walking else &"idle"
	var frame := _art.frame_at(profile, _time, action)
	var pose := OriginalArt.posed(
		Vector2.ZERO, facing, NativeActorFit.scale_for(profile, controlled)
	)
	_art.draw_posed(self, profile, Color.WHITE, frame, pose)
