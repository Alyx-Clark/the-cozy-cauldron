class_name FastBelt
extends MachineBase

const FAST_SPEED := 240.0  # 2x normal belt speed

func _ready() -> void:
	machine_color = Color(0.75, 0.6, 0.2)  # Golden
	machine_label = "Fast"
	setup_sprite("fast_belt")

func _process(_delta: float) -> void:
	if current_item == null:
		return

	if current_item.is_moving:
		return

	# Item is at rest — try to push forward
	if try_push_item(current_item):
		var target_pos := grid_manager.grid_to_world(get_output_pos())
		current_item.move_to(target_pos, FAST_SPEED)
		current_item = null

func receive_item(item: Node2D) -> bool:
	if current_item != null:
		return false
	current_item = item
	return true

func _draw() -> void:
	draw_direction_arrow()
