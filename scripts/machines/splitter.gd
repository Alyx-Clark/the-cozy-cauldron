class_name Splitter
extends MachineBase

# Splitter: accepts 1 input, produces 2 copies
# Primary output: direction (forward)
# Secondary output: 90° CW from direction (side)

var _waiting_for_arrival: bool = false
var _pending_type: int = ItemTypes.Type.NONE
var _output_stage: int = 0  # 0 = idle, 1 = pushing primary, 2 = pushing secondary

func _ready() -> void:
	machine_color = Color(0.6, 0.3, 0.7)  # Purple
	machine_label = "Split"
	setup_sprite("splitter")

func _get_side_direction() -> Vector2i:
	# 90° CW: (x,y) → (-y,x)
	return Vector2i(-direction.y, direction.x)

func _get_side_output_pos() -> Vector2i:
	return grid_pos + _get_side_direction()

func _process(_delta: float) -> void:
	# Handle incoming item arrival
	if _waiting_for_arrival and current_item != null and not current_item.is_moving:
		_consume_current_item()
		return

	# Try to push outputs
	if _output_stage == 1:
		_try_push_primary()
	elif _output_stage == 2:
		if current_item != null and not current_item.is_moving:
			_try_push_secondary()
		elif current_item == null:
			_try_push_secondary()

func receive_item(item: Node2D) -> bool:
	if _waiting_for_arrival or _output_stage != 0:
		return false
	if current_item != null:
		return false
	current_item = item
	_waiting_for_arrival = true
	return true

func _consume_current_item() -> void:
	_waiting_for_arrival = false
	_pending_type = current_item.item_type
	current_item.queue_free()
	current_item = null
	_output_stage = 1
	_try_push_primary()

func _try_push_primary() -> void:
	if item_container == null:
		_output_stage = 0
		return

	# Try to push to forward direction
	var target := get_output_machine()
	if target == null or target.current_item != null:
		return  # Wait until forward is free

	var item_scene := preload("res://scenes/items/item.tscn")
	var item: Item = item_scene.instantiate()
	item.setup(_pending_type, grid_manager.grid_to_world(grid_pos))
	item_container.add_child(item)

	# Push to forward target
	target.receive_item(item)
	var target_pos := grid_manager.grid_to_world(get_output_pos())
	item.move_to(target_pos)

	_output_stage = 2

func _try_push_secondary() -> void:
	if item_container == null:
		_output_stage = 0
		_pending_type = ItemTypes.Type.NONE
		return

	# Try to push to side direction
	var side_pos := _get_side_output_pos()
	var side_target: MachineBase = null
	if grid_manager != null:
		var machine := grid_manager.get_machine_at(side_pos)
		if machine is MachineBase:
			side_target = machine

	if side_target == null or side_target.current_item != null:
		return  # Wait until side is free

	var item_scene := preload("res://scenes/items/item.tscn")
	var item: Item = item_scene.instantiate()
	item.setup(_pending_type, grid_manager.grid_to_world(grid_pos))
	item_container.add_child(item)

	side_target.receive_item(item)
	var target_pos := grid_manager.grid_to_world(side_pos)
	item.move_to(target_pos)

	_output_stage = 0
	_pending_type = ItemTypes.Type.NONE

func _draw() -> void:
	# Forked arrows overlay (forward + side)
	var arrow_color := Color(1, 1, 1, 0.7)
	var dir_vec := Vector2(direction)
	var side_vec := Vector2(_get_side_direction())

	# Incoming line
	draw_line(dir_vec * (-MACHINE_SIZE / 2 + 4), Vector2.ZERO, arrow_color, 2.0)

	# Forward arrow
	var fwd_end := dir_vec * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2.ZERO, fwd_end, arrow_color, 2.0)
	var tip := fwd_end
	var perp := Vector2(-direction.y, direction.x) * 4.0
	var back := dir_vec * -7.0
	draw_colored_polygon([tip, tip + back + perp, tip + back - perp], arrow_color)

	# Side arrow
	var side_end := side_vec * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2.ZERO, side_end, arrow_color, 2.0)
	var tip2 := side_end
	var side_dir := _get_side_direction()
	var perp2 := Vector2(-side_dir.y, side_dir.x) * 4.0
	var back2 := side_vec * -7.0
	draw_colored_polygon([tip2, tip2 + back2 + perp2, tip2 + back2 - perp2], arrow_color)
