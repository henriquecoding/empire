class_name NativeActorFit
extends RefCounted

const PLAYABLE_FRAME := 64.0
const WORKER_FRAME := 32.0


static func scale_for(profile: StringName, controlled: bool) -> Vector2:
	var box := OriginalArt.new().body_box(profile, Vector2.ZERO)
	var limit := PLAYABLE_FRAME if controlled else WORKER_FRAME
	return Vector2.ONE * limit / maxf(box.size.x, box.size.y)


static func bounds(profile: StringName, controlled: bool, foot: Vector2) -> Rect2:
	var box := OriginalArt.new().body_box(profile, Vector2.ZERO)
	var fitted := scale_for(profile, controlled)
	return Rect2(foot + box.position * fitted, box.size * fitted)
