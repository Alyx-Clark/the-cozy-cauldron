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
		current_item.is_bottled = true
		current_item.queue_redraw()
	queue_redraw()

func _try_push_output() -> void:
	if current_item == null:
		return
	if try_push_item(current_item):
		var target_pos := grid_manager.grid_to_world(get_output_pos())
		current_item.move_to(target_pos)
		current_item = null

func _draw() -> void:
	# Draw bottler body
	var rect := Rect2(-MACHINE_SIZE / 2, -MACHINE_SIZE / 2, MACHINE_SIZE, MACHINE_SIZE)
	draw_rect(rect, machine_color)

	# Draw bottle icon in center
	var bottle_color := Color(0.9, 0.85, 0.7, 0.7)
	# Bottle body
	draw_rect(Rect2(-6, -4, 12, 14), bottle_color, false, 2.0)
	# Bottle neck
	draw_rect(Rect2(-3, -10, 6, 6), bottle_color, false, 2.0)

	# Bottling progress indicator
	if _is_bottling:
		var progress := _bottle_timer / BOTTLE_TIME
		var fill_height := 14.0 * progress
		draw_rect(Rect2(-5, 10 - fill_height, 10, fill_height), Color(0.9, 0.8, 0.3, 0.6))

	# Direction arrow
	var arrow_color := Color(1, 1, 1, 0.6)
	var dir_vec := Vector2(direction)
	var arrow_end := dir_vec * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2.ZERO, arrow_end, arrow_color, 2.0)
	var tip := arrow_end
	var perp := Vector2(-direction.y, direction.x) * 5.0
	var back := dir_vec * -8.0
	draw_colored_polygon([tip, tip + back + perp, tip + back - perp], arrow_color)
