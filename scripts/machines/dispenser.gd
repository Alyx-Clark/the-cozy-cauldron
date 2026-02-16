class_name Dispenser
extends MachineBase

# Which ingredient this dispenser spawns
var ingredient_type: int = ItemTypes.Type.MUSHROOM
var _ingredient_index: int = 0  # Index into available ingredients list

# Spawn timing
const SPAWN_INTERVAL := 3.0
var _spawn_timer: float = 0.0

func _ready() -> void:
	machine_color = Color(0.3, 0.65, 0.4)
	machine_label = "Disp"
	setup_sprite("dispenser")
	# Initialize to first available ingredient
	var available := GameState.get_available_ingredients()
	if not available.is_empty():
		ingredient_type = available[0]
		_ingredient_index = 0

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

	# Small spawn puff + sound
	var ing_color: Color = ItemTypes.COLORS.get(ingredient_type, Color.WHITE)
	EffectsManager.spawn_burst(grid_manager.grid_to_world(grid_pos), ing_color, 4, 12.0, 0.3)
	SoundManager.play("dispense")

func _try_push_forward() -> void:
	if current_item == null or current_item.is_moving:
		return

	if try_push_item(current_item):
		var target_pos := grid_manager.grid_to_world(get_output_pos())
		current_item.move_to(target_pos)
		current_item = null

## Cycle to next ingredient type when clicked (only available ingredients).
func on_click() -> void:
	var available := GameState.get_available_ingredients()
	if available.is_empty():
		return
	_ingredient_index = (_ingredient_index + 1) % available.size()
	ingredient_type = available[_ingredient_index]
	SoundManager.play("click")
	# Discard the held item if it's the wrong type
	if current_item != null and current_item.item_type != ingredient_type:
		current_item.queue_free()
		current_item = null
	queue_redraw()

func _draw() -> void:
	# Ingredient color indicator (overlay on sprite)
	var ingredient_color: Color = ItemTypes.COLORS.get(ingredient_type, Color.WHITE)
	draw_circle(Vector2.ZERO, 10.0, ingredient_color)
	draw_direction_arrow()
