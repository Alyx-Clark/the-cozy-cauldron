class_name Cauldron
extends MachineBase

# Cauldron stores up to 2 ingredients, then checks recipe
var stored_ingredients: Array = []  # Array of ItemTypes.Type values
const MAX_INGREDIENTS := 2

# Brewing timing
const BREW_TIME := 1.5
var _brew_timer: float = 0.0
var _is_brewing: bool = false
var _brew_result: int = ItemTypes.Type.NONE

# Whether we're waiting for an incoming item to arrive
var _waiting_for_arrival: bool = false

# Reference to item container for spawning output
var item_container: Node2D = null

func _ready() -> void:
	machine_color = Color(0.6, 0.35, 0.65)
	machine_label = "Cldn"

func _process(delta: float) -> void:
	if _is_brewing:
		_brew_timer += delta
		queue_redraw()  # Animate bubbles
		if _brew_timer >= BREW_TIME:
			_finish_brewing()
		return

	# Check if an incoming item has arrived and needs to be consumed
	if _waiting_for_arrival and current_item != null and not current_item.is_moving:
		_consume_current_item()
		return

	# If we have a completed potion, try to push it out
	if current_item != null and not current_item.is_moving and not _waiting_for_arrival:
		_try_push_output()

func receive_item(item: Node2D) -> bool:
	# Cauldron accepts items into its ingredient storage
	if _is_brewing:
		return false
	if stored_ingredients.size() >= MAX_INGREDIENTS:
		return false
	if current_item != null:
		return false  # Slot occupied (either incoming or output)

	# Reserve the slot — item will physically move here, then we consume it
	current_item = item
	_waiting_for_arrival = true
	return true

func _consume_current_item() -> void:
	_waiting_for_arrival = false
	var item_type: int = current_item.item_type
	current_item.queue_free()
	current_item = null

	stored_ingredients.append(item_type)
	queue_redraw()

	# Check if we have enough ingredients to brew
	if stored_ingredients.size() >= MAX_INGREDIENTS:
		_start_brewing()

func _start_brewing() -> void:
	var result := Recipes.check(stored_ingredients[0], stored_ingredients[1])
	if result == ItemTypes.Type.NONE:
		# Invalid recipe — discard ingredients
		stored_ingredients.clear()
		queue_redraw()
		return

	_brew_result = result
	_is_brewing = true
	_brew_timer = 0.0
	queue_redraw()

func _finish_brewing() -> void:
	_is_brewing = false
	stored_ingredients.clear()

	if item_container == null:
		_brew_result = ItemTypes.Type.NONE
		queue_redraw()
		return

	# Spawn the result potion
	var item_scene := preload("res://scenes/items/item.tscn")
	var item: Item = item_scene.instantiate()
	item.setup(_brew_result, grid_manager.grid_to_world(grid_pos))
	item_container.add_child(item)
	current_item = item
	_brew_result = ItemTypes.Type.NONE
	queue_redraw()

func _try_push_output() -> void:
	if current_item == null:
		return
	if try_push_item(current_item):
		var target_pos := grid_manager.grid_to_world(get_output_pos())
		current_item.move_to(target_pos)
		current_item = null

func _draw() -> void:
	# Draw cauldron body
	var rect := Rect2(-MACHINE_SIZE / 2, -MACHINE_SIZE / 2, MACHINE_SIZE, MACHINE_SIZE)
	draw_rect(rect, machine_color)

	# Inner cauldron bowl
	var bowl_color := Color(0.15, 0.1, 0.2)
	draw_circle(Vector2.ZERO, 18.0, bowl_color)

	# Show stored ingredients as small dots
	if not stored_ingredients.is_empty():
		for i in range(stored_ingredients.size()):
			var offset := Vector2(-8 + i * 16, 0)
			var color: Color = ItemTypes.COLORS.get(stored_ingredients[i], Color.WHITE)
			draw_circle(offset, 5.0, color)

	# Brewing indicator — animated bubbles
	if _is_brewing:
		var progress := _brew_timer / BREW_TIME
		var bubble_color := Color(0.8, 0.6, 1.0, 0.7)
		for i in range(3):
			var angle := progress * TAU * 2.0 + i * TAU / 3.0
			var pos := Vector2(cos(angle), sin(angle)) * 10.0
			draw_circle(pos, 3.0, bubble_color)

	# Direction arrow (output direction)
	var arrow_color := Color(1, 1, 1, 0.6)
	var dir_vec := Vector2(direction)
	var arrow_end := dir_vec * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2.ZERO, arrow_end, arrow_color, 2.0)
	var tip := arrow_end
	var perp := Vector2(-direction.y, direction.x) * 5.0
	var back := dir_vec * -8.0
	draw_colored_polygon([tip, tip + back + perp, tip + back - perp], arrow_color)
