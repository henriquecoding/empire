class_name NativeSceneryWalker
extends CharacterBody2D

# This controller belongs to the review fixture, not to the campaign simulation.
const REVIEW_SPEED := 160.0
const REVIEW_GRAVITY := 800.0
var family_id := "enramados"
var band := Band.Kind.SURFACE
var direction := 0.0
var actor: NativeSceneryActor


func _ready() -> void:
	z_index = 2
	collision_layer = Band.L_SURFACE
	collision_mask = Band.L_TERRAIN
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32.0, 64.0)
	shape.position.y = -32.0
	shape.shape = rect
	add_child(shape)
	actor = NativeSceneryActor.new()
	actor.controlled = true
	add_child(actor)


func _physics_process(delta: float) -> void:
	var proposed := position.x + direction * REVIEW_SPEED * delta
	velocity.x = direction * REVIEW_SPEED
	if not NativeSceneryCatalog.supports(family_id, proposed, band, 16.0):
		velocity.x = 0.0
	velocity.y += REVIEW_GRAVITY * delta
	move_and_slide()
	actor.walking = not is_zero_approx(velocity.x)
	if actor.walking:
		actor.facing = signf(velocity.x)


func use_passage() -> bool:
	if not NativeSceneryCatalog.passage_at(family_id, position.x):
		return false
	var destination := Band.Kind.UNDERGROUND if band == Band.Kind.SURFACE else Band.Kind.SURFACE
	if not NativeSceneryCatalog.supports(family_id, position.x, destination, 16.0):
		return false
	band = destination
	position.y = WorldPalette.ground_of(band)
	velocity = Vector2.ZERO
	collision_layer = Band.L_UNDER if band == Band.Kind.UNDERGROUND else Band.L_SURFACE
	return true
