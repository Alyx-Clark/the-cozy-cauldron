class_name ConveyorBelt
extends MachineBase

func _ready() -> void:
	machine_color = Color(0.45, 0.45, 0.5)
	machine_label = "Belt"
	setup_sprite("conveyor")

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
	draw_direction_arrow()
