class_name Sorter
extends MachineBase

# Routes items by type. Click to set filter.
# Matching items → forward (direction), non-matching → 90° CW (side)

var filter_type: int = ItemTypes.Type.NONE
var _filter_index: int = -1  # Index into item type list, -1 = NONE (accept all)

var _waiting_for_arrival: bool = false

func _ready() -> void:
	machine_color = Color(0.2, 0.6, 0.6)  # Teal
	machine_label = "Sort"

func _get_side_direction() -> Vector2i:
	return Vector2i(-direction.y, direction.x)

func _get_side_output_pos() -> Vector2i:
	return grid_pos + _get_side_direction()

func _process(_delta: float) -> void:
	if current_item == null:
		return

	# Wait for item to arrive
	if _waiting_for_arrival and current_item.is_moving:
		return

	if _waiting_for_arrival and not current_item.is_moving:
		_waiting_for_arrival = false
		_route_item()
		return

	# If item is at rest and not waiting, try to push
	if not current_item.is_moving and not _waiting_for_arrival:
		_route_item()

func receive_item(item: Node2D) -> bool:
	if current_item != null:
		return false
	current_item = item
	_waiting_for_arrival = true
	return true

func _route_item() -> void:
	if current_item == null:
		return

	var matches: bool = (filter_type == ItemTypes.Type.NONE) or (current_item.item_type == filter_type)

	if matches:
		# Try forward
		var target := get_output_machine()
		if target != null and target.current_item == null:
			target.receive_item(current_item)
			var target_pos := grid_manager.grid_to_world(get_output_pos())
			current_item.move_to(target_pos)
			current_item = null
	else:
		# Try side
		var side_pos := _get_side_output_pos()
		var side_target: MachineBase = null
		if grid_manager != null:
			var machine := grid_manager.get_machine_at(side_pos)
			if machine is MachineBase:
				side_target = machine
		if side_target != null and side_target.current_item == null:
			side_target.receive_item(current_item)
			var target_pos := grid_manager.grid_to_world(side_pos)
			current_item.move_to(target_pos)
			current_item = null

## Cycle filter type when clicked.
func on_click() -> void:
	# Cycle through: NONE → all item types → NONE
	var all_types: Array = []
	for key in ItemTypes.COLORS.keys():
		all_types.append(key)
	all_types.sort()

	_filter_index += 1
	if _filter_index >= all_types.size():
		_filter_index = -1
		filter_type = ItemTypes.Type.NONE
	else:
		filter_type = all_types[_filter_index]
	queue_redraw()

func _draw() -> void:
	# Draw sorter body
	var rect := Rect2(-MACHINE_SIZE / 2, -MACHINE_SIZE / 2, MACHINE_SIZE, MACHINE_SIZE)
	draw_rect(rect, machine_color)

	# Draw filter indicator
	if filter_type != ItemTypes.Type.NONE:
		var filter_color: Color = ItemTypes.COLORS.get(filter_type, Color.WHITE)
		draw_circle(Vector2(0, -8), 8.0, filter_color)
	else:
		# Draw "all" indicator (white ring)
		draw_arc(Vector2(0, -8), 8.0, 0, TAU, 16, Color(1, 1, 1, 0.5), 2.0)

	var arrow_color := Color(1, 1, 1, 0.6)
	var dir_vec := Vector2(direction)
	var side_vec := Vector2(_get_side_direction())

	# Forward arrow (matching)
	var fwd_end := dir_vec * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2(0, 4), fwd_end, arrow_color, 2.0)
	var tip := fwd_end
	var perp := Vector2(-direction.y, direction.x) * 4.0
	var back := dir_vec * -7.0
	draw_colored_polygon([tip, tip + back + perp, tip + back - perp], arrow_color)

	# Side arrow (non-matching)
	var side_end := side_vec * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2(0, 4), side_end, Color(1, 0.6, 0.6, 0.6), 2.0)
	var tip2 := side_end
	var side_dir := _get_side_direction()
	var perp2 := Vector2(-side_dir.y, side_dir.x) * 4.0
	var back2 := side_vec * -7.0
	draw_colored_polygon([tip2, tip2 + back2 + perp2, tip2 + back2 - perp2], Color(1, 0.6, 0.6, 0.6))
