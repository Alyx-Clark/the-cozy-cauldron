extends Node2D

@onready var grid_manager: GridManager = $GridManager
@onready var machine_container: Node2D = $MachineContainer
@onready var item_container: Node2D = $ItemContainer
@onready var ghost_preview: Node2D = $GhostPreview

# Current placement direction
var current_direction: Vector2i = Vector2i.RIGHT

# Currently selected machine type (set by toolbar)
var selected_machine: String = ""

# Scene references for machine types
var _machine_scenes: Dictionary = {}

func _ready() -> void:
	# Preload machine scenes
	_machine_scenes["conveyor"] = preload("res://scenes/machines/conveyor_belt.tscn")
	_machine_scenes["dispenser"] = preload("res://scenes/machines/dispenser.tscn")
	_machine_scenes["cauldron"] = preload("res://scenes/machines/cauldron.tscn")
	_machine_scenes["fast_belt"] = preload("res://scenes/machines/fast_belt.tscn")
	_machine_scenes["storage"] = preload("res://scenes/machines/storage_chest.tscn")
	_machine_scenes["splitter"] = preload("res://scenes/machines/splitter.tscn")
	_machine_scenes["sorter"] = preload("res://scenes/machines/sorter.tscn")
	_machine_scenes["bottler"] = preload("res://scenes/machines/bottler.tscn")
	_machine_scenes["auto_seller"] = preload("res://scenes/machines/auto_seller.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_ghost_preview(event.position)

	if event is InputEventMouseButton and event.pressed:
		var grid_pos := grid_manager.world_to_grid(event.position)

		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place(grid_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_remove(grid_pos)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_rotate_direction()

func _update_ghost_preview(mouse_pos: Vector2) -> void:
	if selected_machine == "":
		ghost_preview.hide_preview()
		return

	var grid_pos := grid_manager.world_to_grid(mouse_pos)
	var world_pos := grid_manager.grid_to_world(grid_pos)
	var valid := grid_manager.is_in_bounds(grid_pos) and grid_manager.is_cell_empty(grid_pos)
	# Also check unlock state
	if not GameState.is_machine_unlocked(selected_machine):
		valid = false
	var color := _get_machine_color(selected_machine)

	ghost_preview.update_preview(world_pos, color, current_direction, valid)

func _try_place(grid_pos: Vector2i) -> void:
	if selected_machine == "":
		# If clicking on an existing machine, interact with it
		var existing := grid_manager.get_machine_at(grid_pos)
		if existing is MachineBase:
			if existing.has_method("on_click"):
				existing.on_click()
			elif _try_hand_sell(existing):
				pass  # Sold a potion by hand
		return

	if not grid_manager.is_in_bounds(grid_pos) or not grid_manager.is_cell_empty(grid_pos):
		return

	if not _machine_scenes.has(selected_machine):
		return

	# Check unlock gating
	if not GameState.is_machine_unlocked(selected_machine):
		return

	var machine: MachineBase = _machine_scenes[selected_machine].instantiate()
	machine.direction = current_direction
	machine.grid_pos = grid_pos
	machine.grid_manager = grid_manager
	machine.item_container = item_container
	machine_container.add_child(machine)
	grid_manager.place_machine(grid_pos, machine)

func _try_remove(grid_pos: Vector2i) -> void:
	var machine := grid_manager.remove_machine(grid_pos)
	if machine == null:
		return
	# Clean up any item the machine is holding
	if machine is MachineBase and machine.current_item != null:
		machine.current_item.queue_free()
	machine.queue_free()

func _rotate_direction() -> void:
	current_direction = Vector2i(-current_direction.y, current_direction.x)
	# Update ghost preview
	var mouse_pos := get_viewport().get_mouse_position()
	_update_ghost_preview(mouse_pos)

func _get_machine_color(machine_type: String) -> Color:
	match machine_type:
		"conveyor":
			return Color(0.45, 0.45, 0.5)
		"dispenser":
			return Color(0.3, 0.65, 0.4)
		"cauldron":
			return Color(0.6, 0.35, 0.65)
		"fast_belt":
			return Color(0.75, 0.6, 0.2)
		"storage":
			return Color(0.55, 0.38, 0.2)
		"splitter":
			return Color(0.6, 0.3, 0.7)
		"sorter":
			return Color(0.2, 0.6, 0.6)
		"bottler":
			return Color(0.75, 0.55, 0.15)
		"auto_seller":
			return Color(0.8, 0.7, 0.1)
		_:
			return Color(0.5, 0.5, 0.5)

## Hand-sell: click a machine holding a potion to sell it manually for half price.
func _try_hand_sell(machine: MachineBase) -> bool:
	if machine.current_item == null or machine.current_item.is_moving:
		return false
	if not ItemTypes.is_potion(machine.current_item.item_type):
		return false
	@warning_ignore("integer_division")
	var price: int = maxi(1, GameState.get_potion_price(machine.current_item.item_type) / 2)
	GameState.add_gold(price)
	GameState.potion_sold.emit(machine.current_item.item_type, price)
	machine.current_item.queue_free()
	machine.current_item = null
	return true

## Called by toolbar when selection changes.
func select_machine(machine_type: String) -> void:
	selected_machine = machine_type
	var mouse_pos := get_viewport().get_mouse_position()
	_update_ghost_preview(mouse_pos)
