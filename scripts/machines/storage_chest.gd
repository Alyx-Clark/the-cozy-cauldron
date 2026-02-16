class_name StorageChest
extends MachineBase

const MAX_STORED := 8

# Stored item types (FIFO queue)
var stored_items: Array = []

# Whether we're waiting for an incoming item to arrive
var _waiting_for_arrival: bool = false

func _ready() -> void:
	machine_color = Color(0.55, 0.38, 0.2)  # Brown
	machine_label = "Chest"
	setup_sprite("storage")

func _process(_delta: float) -> void:
	# Handle incoming item arrival
	if _waiting_for_arrival and current_item != null and not current_item.is_moving:
		_consume_current_item()
		return

	# Try to push stored items out
	if current_item == null and not stored_items.is_empty() and not _waiting_for_arrival:
		_try_output()

	# If we have a spawned output item, try to push it
	if current_item != null and not current_item.is_moving and not _waiting_for_arrival:
		_try_push_output()

func receive_item(item: Node2D) -> bool:
	if _waiting_for_arrival:
		return false
	if current_item != null:
		return false
	if stored_items.size() >= MAX_STORED:
		return false
	current_item = item
	_waiting_for_arrival = true
	return true

func _consume_current_item() -> void:
	_waiting_for_arrival = false
	stored_items.append(current_item.item_type)
	current_item.queue_free()
	current_item = null
	queue_redraw()

func _try_output() -> void:
	if item_container == null:
		return
	if stored_items.is_empty():
		return

	# Spawn an item from the front of the queue
	var item_scene := preload("res://scenes/items/item.tscn")
	var item: Item = item_scene.instantiate()
	item.setup(stored_items[0], grid_manager.grid_to_world(grid_pos))
	item_container.add_child(item)
	current_item = item
	stored_items.pop_front()
	queue_redraw()

func _try_push_output() -> void:
	if current_item == null:
		return
	if try_push_item(current_item):
		var target_pos := grid_manager.grid_to_world(get_output_pos())
		current_item.move_to(target_pos)
		current_item = null

func _draw() -> void:
	# Draw stored item dots (up to 8, in a 4x2 grid) overlay on sprite
	for i in range(stored_items.size()):
		@warning_ignore("integer_division")
		var col := i % 4
		@warning_ignore("integer_division")
		var row := i / 4
		var dot_x := -12.0 + col * 8.0
		var dot_y := 2.0 + row * 10.0
		var color: Color = ItemTypes.COLORS.get(stored_items[i], Color.WHITE)
		draw_circle(Vector2(dot_x, dot_y), 3.0, color)

	# Count label
	if not stored_items.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(-6, -6), str(stored_items.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.7))

	draw_direction_arrow()
