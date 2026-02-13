class_name Dispenser
extends MachineBase

# Which ingredient this dispenser spawns
var ingredient_type: int = ItemTypes.Type.MUSHROOM
var _ingredient_index: int = 0  # Index into ItemTypes.INGREDIENTS

# Spawn timing
const SPAWN_INTERVAL := 3.0
var _spawn_timer: float = 0.0

# Reference to the item container (set after placement)
var item_container: Node2D = null

func _ready() -> void:
	machine_color = Color(0.3, 0.65, 0.4)
	machine_label = "Disp"

func _process(delta: float) -> void:
	# Try to push out existing item first
	if current_item != null and not current_item.is_moving:
		_try_push_forward()

	# Spawn timer
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_try_spawn()

func _try_spawn() -> void:
	if current_item != null:
		return  # Already holding an item

	if item_container == null:
		return

	# Create the item
	var item_scene := preload("res://scenes/items/item.tscn")
	var item: Item = item_scene.instantiate()
	item.setup(ingredient_type, grid_manager.grid_to_world(grid_pos))
	item_container.add_child(item)
	current_item = item

func _try_push_forward() -> void:
	if current_item == null or current_item.is_moving:
		return

	if try_push_item(current_item):
		var target_pos := grid_manager.grid_to_world(get_output_pos())
		current_item.move_to(target_pos)
		current_item = null

## Cycle to next ingredient type when clicked.
func on_click() -> void:
	_ingredient_index = (_ingredient_index + 1) % ItemTypes.INGREDIENTS.size()
	ingredient_type = ItemTypes.INGREDIENTS[_ingredient_index]
	queue_redraw()

func _draw() -> void:
	# Draw dispenser body
	var rect := Rect2(-MACHINE_SIZE / 2, -MACHINE_SIZE / 2, MACHINE_SIZE, MACHINE_SIZE)
	draw_rect(rect, machine_color)

	# Draw ingredient color indicator
	var ingredient_color: Color = ItemTypes.COLORS.get(ingredient_type, Color.WHITE)
	draw_circle(Vector2.ZERO, 12.0, ingredient_color)

	# Direction arrow
	var arrow_color := Color(1, 1, 1, 0.6)
	var dir_vec := Vector2(direction)
	var arrow_end := dir_vec * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2.ZERO, arrow_end, arrow_color, 2.0)
	var tip := arrow_end
	var perp := Vector2(-direction.y, direction.x) * 5.0
	var back := dir_vec * -8.0
	draw_colored_polygon([tip, tip + back + perp, tip + back - perp], arrow_color)
