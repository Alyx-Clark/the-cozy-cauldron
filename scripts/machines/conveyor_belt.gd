class_name ConveyorBelt
extends MachineBase

func _ready() -> void:
	machine_color = Color(0.45, 0.45, 0.5)
	machine_label = "Belt"

func _process(_delta: float) -> void:
	if current_item == null:
		return

	# Wait for item to arrive at our position
	if current_item.is_moving:
		return

	# Item is at rest here — try to push it forward
	if try_push_item(current_item):
		# Item was accepted by next machine, tell it to move there
		var target_pos := grid_manager.grid_to_world(get_output_pos())
		current_item.move_to(target_pos)
		current_item = null

func receive_item(item: Node2D) -> bool:
	if current_item != null:
		return false
	current_item = item
	return true

func _draw() -> void:
	# Draw belt body
	var rect := Rect2(-MACHINE_SIZE / 2, -MACHINE_SIZE / 2, MACHINE_SIZE, MACHINE_SIZE)
	draw_rect(rect, machine_color)

	# Draw belt lines
	var line_color := Color(0.55, 0.55, 0.6)
	var dir_vec := Vector2(direction)
	var perp := Vector2(-direction.y, direction.x)

	for i in range(-2, 3):
		var center := dir_vec * (i * 10.0)
		var start_pt := center + perp * (MACHINE_SIZE / 2 - 6)
		var end_pt := center - perp * (MACHINE_SIZE / 2 - 6)
		draw_line(start_pt, end_pt, line_color, 1.0)

	# Arrow
	var arrow_color := Color(1, 1, 1, 0.6)
	var arrow_end := dir_vec * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2.ZERO, arrow_end, arrow_color, 2.0)
	var tip := arrow_end
	var perp2 := Vector2(-direction.y, direction.x) * 5.0
	var back := dir_vec * -8.0
	draw_colored_polygon([tip, tip + back + perp2, tip + back - perp2], arrow_color)
