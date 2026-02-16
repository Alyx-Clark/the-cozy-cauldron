class_name Bottler
extends MachineBase

# Accepts potions only. Processes for 1.0s, sets is_bottled = true.
# Bottled potions sell for 2x at Auto-Seller.

const BOTTLE_TIME := 1.0

var _waiting_for_arrival: bool = false
var _is_bottling: bool = false
var _bottle_timer: float = 0.0

func _ready() -> void:
	machine_color = Color(0.75, 0.55, 0.15)  # Amber
	machine_label = "Btl"
	setup_sprite("bottler")

func _process(delta: float) -> void:
	if _is_bottling:
		_bottle_timer += delta
		queue_redraw()
		if _bottle_timer >= BOTTLE_TIME:
			_finish_bottling()
		return

	# Handle incoming item arrival
	if _waiting_for_arrival and current_item != null and not current_item.is_moving:
		_waiting_for_arrival = false
		_start_bottling()
		return

	# Try to push output
	if current_item != null and not current_item.is_moving and not _waiting_for_arrival:
		_try_push_output()

func receive_item(item: Node2D) -> bool:
	if current_item != null or _is_bottling or _waiting_for_arrival:
		return false
	# Only accept potions
	if not ItemTypes.is_potion(item.item_type):
		return false
	# Don't accept already bottled items
	if item.is_bottled:
		return false
	current_item = item
	_waiting_for_arrival = true
	return true

func _start_bottling() -> void:
	_is_bottling = true
	_bottle_timer = 0.0
	queue_redraw()

func _finish_bottling() -> void:
	_is_bottling = false
	if current_item != null:
		current_item.set_bottled(true)
	# Golden sparkle + sound on bottling complete
	EffectsManager.spawn_burst(grid_manager.grid_to_world(grid_pos), Color(1.0, 0.85, 0.3), 6, 16.0, 0.35)
	SoundManager.play("bottle")
	queue_redraw()

func _try_push_output() -> void:
	if current_item == null:
		return
	if try_push_item(current_item):
		var target_pos := grid_manager.grid_to_world(get_output_pos())
		current_item.move_to(target_pos)
		current_item = null

func _draw() -> void:
	# Bottling progress indicator overlay
	if _is_bottling:
		var progress := _bottle_timer / BOTTLE_TIME
		var fill_height := 14.0 * progress
		draw_rect(Rect2(-5, 10 - fill_height, 10, fill_height), Color(0.9, 0.8, 0.3, 0.6))

	draw_direction_arrow()
