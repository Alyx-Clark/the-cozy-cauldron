extends Node

const SAVE_PATH := "user://savegame.json"
const AUTO_SAVE_INTERVAL := 60.0

var _auto_save_timer: float = 0.0
var _grid_manager: GridManager = null
var _order_manager: Node = null

# Stored after load for main.gd to use for machine restoration
var loaded_machines: Array = []

func setup(grid_manager: GridManager, order_manager: Node) -> void:
	_grid_manager = grid_manager
	_order_manager = order_manager

func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		save_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S and event.ctrl_pressed:
			save_game()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func save_game() -> void:
	if _grid_manager == null:
		return

	var data := {
		"gold": GameState.gold,
		"unlocked_recipes": GameState.unlocked_recipes.duplicate(),
		"unlocked_machines": GameState.unlocked_machines.duplicate(),
		"machines": _serialize_machines(),
		"orders": _order_manager.get_save_data() if _order_manager != null else [],
	}

	var json_string := JSON.stringify(data, "  ")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return false

	var data: Dictionary = json.data
	if data.is_empty():
		return false

	# Restore game state
	GameState.gold = int(data.get("gold", 0))
	GameState.gold_changed.emit(GameState.gold)

	var saved_recipes: Array = data.get("unlocked_recipes", [0, 1])
	GameState.unlocked_recipes = []
	for r in saved_recipes:
		GameState.unlocked_recipes.append(int(r))
	GameState.sync_recipe_unlocks()

	var saved_machines: Array = data.get("unlocked_machines", ["conveyor", "dispenser", "cauldron"])
	GameState.unlocked_machines = []
	for m in saved_machines:
		GameState.unlocked_machines.append(str(m))

	# Emit signals so toolbar and UI refresh
	for m in GameState.unlocked_machines:
		GameState.machine_unlocked.emit(m)
	for r in GameState.unlocked_recipes:
		GameState.recipe_unlocked.emit(r)

	# Store machine layout data for main.gd to restore
	loaded_machines = data.get("machines", [])

	# Restore orders
	if _order_manager != null:
		var saved_orders: Array = data.get("orders", [])
		_order_manager.load_save_data(saved_orders)

	return true

func get_machine_data() -> Array:
	return _serialize_machines()

func _serialize_machines() -> Array:
	if _grid_manager == null:
		return []

	var machines: Array = []
	for machine in _grid_manager.get_all_machines():
		if machine is MachineBase:
			var entry := {
				"type": _get_machine_type_key(machine),
				"grid_x": machine.grid_pos.x,
				"grid_y": machine.grid_pos.y,
				"dir_x": machine.direction.x,
				"dir_y": machine.direction.y,
			}
			# Save machine-specific config
			if machine is Dispenser:
				entry["ingredient_type"] = machine.ingredient_type
			if machine is Sorter:
				entry["filter_type"] = machine.filter_type
			if machine is StorageChest and not machine.stored_items.is_empty():
				entry["stored_items"] = machine.stored_items.duplicate()
			machines.append(entry)
	return machines

func _get_machine_type_key(machine: MachineBase) -> String:
	if machine is ConveyorBelt:
		return "conveyor"
	if machine is Dispenser:
		return "dispenser"
	if machine is Cauldron:
		return "cauldron"
	if machine is FastBelt:
		return "fast_belt"
	if machine is StorageChest:
		return "storage"
	if machine is Splitter:
		return "splitter"
	if machine is Sorter:
		return "sorter"
	if machine is Bottler:
		return "bottler"
	if machine is AutoSeller:
		return "auto_seller"
	return "unknown"
