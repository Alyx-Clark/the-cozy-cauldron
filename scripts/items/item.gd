class_name Item
extends Node2D

var item_type: int = ItemTypes.Type.NONE

# Movement
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
const MOVE_SPEED := 120.0  # pixels per second
const ITEM_RADIUS := 10.0

# Called when the item finishes arriving at its target
signal arrived

func _ready() -> void:
	target_position = position

func setup(type: int, pos: Vector2) -> void:
	item_type = type
	position = pos
	target_position = pos
	queue_redraw()

func _process(delta: float) -> void:
	if not is_moving:
		return

	var distance := position.distance_to(target_position)
	if distance < 1.0:
		position = target_position
		is_moving = false
		arrived.emit()
		return

	position = position.move_toward(target_position, MOVE_SPEED * delta)

func move_to(world_pos: Vector2) -> void:
	target_position = world_pos
	is_moving = true

func _draw() -> void:
	var color: Color = ItemTypes.COLORS.get(item_type, Color.WHITE)
	draw_circle(Vector2.ZERO, ITEM_RADIUS, color)
	# Inner highlight
	draw_circle(Vector2(-2, -2), ITEM_RADIUS * 0.4, Color(color, 0.5).lightened(0.4))
