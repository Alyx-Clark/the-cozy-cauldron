class_name Item
extends Node2D
## Moving item entity — represents an ingredient or potion on the grid.
## Pushed between machines via the reservation model (see MachineBase).
## Rendered as a colored circle with an optional bottle outline when is_bottled=true.

var item_type: int = ItemTypes.Type.NONE
var is_bottled: bool = false  # Set by Bottler; doubles sell price at AutoSeller

# Smooth movement — item lerps toward target_position each frame
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var move_speed: float = 120.0  # px/s; FastBelt overrides to 240
const DEFAULT_SPEED := 120.0
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

	position = position.move_toward(target_position, move_speed * delta)

func move_to(world_pos: Vector2, speed: float = DEFAULT_SPEED) -> void:
	target_position = world_pos
	move_speed = speed
	is_moving = true

func _draw() -> void:
	var color: Color = ItemTypes.COLORS.get(item_type, Color.WHITE)
	draw_circle(Vector2.ZERO, ITEM_RADIUS, color)
	# Inner highlight
	draw_circle(Vector2(-2, -2), ITEM_RADIUS * 0.4, Color(color, 0.5).lightened(0.4))

	# Bottle outline for bottled potions
	if is_bottled:
		draw_arc(Vector2.ZERO, ITEM_RADIUS + 2, 0, TAU, 24, Color(0.9, 0.8, 0.5, 0.8), 2.0)
		# Bottle neck
		draw_line(Vector2(-3, -ITEM_RADIUS - 2), Vector2(-3, -ITEM_RADIUS - 6), Color(0.9, 0.8, 0.5, 0.8), 2.0)
		draw_line(Vector2(3, -ITEM_RADIUS - 2), Vector2(3, -ITEM_RADIUS - 6), Color(0.9, 0.8, 0.5, 0.8), 2.0)
		draw_line(Vector2(-3, -ITEM_RADIUS - 6), Vector2(3, -ITEM_RADIUS - 6), Color(0.9, 0.8, 0.5, 0.8), 2.0)
