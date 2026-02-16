class_name Item
extends Node2D
## Moving item entity — represents an ingredient or potion on the grid.
## Pushed between machines via the reservation model (see MachineBase).
## Rendered as a Sprite2D with an optional bottle overlay when bottled.

var item_type: int = ItemTypes.Type.NONE
var is_bottled: bool = false  # Set by Bottler via set_bottled(); doubles sell price

# Smooth movement — item lerps toward target_position each frame
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var move_speed: float = 120.0  # px/s; FastBelt overrides to 240
const DEFAULT_SPEED := 120.0
const ITEM_RADIUS := 10.0

# Sprite children
var _sprite: Sprite2D = null
var _bottle_overlay: Sprite2D = null

# Called when the item finishes arriving at its target
signal arrived

func _ready() -> void:
	target_position = position

func setup(type: int, pos: Vector2) -> void:
	item_type = type
	position = pos
	target_position = pos
	_setup_sprite()

func _setup_sprite() -> void:
	if _sprite != null:
		_sprite.queue_free()
	_sprite = Sprite2D.new()
	var path: String = ItemTypes.SPRITE_PATHS.get(item_type, "")
	if path != "":
		_sprite.texture = load(path)
	add_child(_sprite)

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

## Set bottled state and add/remove the golden bottle overlay sprite.
func set_bottled(bottled: bool) -> void:
	is_bottled = bottled
	if bottled and _bottle_overlay == null:
		_bottle_overlay = Sprite2D.new()
		_bottle_overlay.texture = load(ItemTypes.BOTTLE_OVERLAY_PATH)
		add_child(_bottle_overlay)
	elif not bottled and _bottle_overlay != null:
		_bottle_overlay.queue_free()
		_bottle_overlay = null
