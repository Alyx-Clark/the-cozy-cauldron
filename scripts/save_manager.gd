extends Node
## JSON save/load with auto-save every 60s, manual Ctrl+S, and save-on-quit.
##
## SAVE FORMAT (user://savegame.json):
##   gold: int
##   unlocked_recipes: Array[int]     — recipe indices
##   unlocked_machines: Array[String] — machine type keys
##   machines: Array[Dict]            — grid_pos, direction, type, per-machine config
##   orders: Array[Dict]              — active order state
##   tutorial_seen: Array[String]     — hint IDs (added in Phase 3)
##
## BACKWARD COMPATIBILITY: New fields use data.get("key", default) so saves from
## earlier phases load without error. Missing fields get sensible defaults.
##
## MACHINE RESTORATION: After load_game(), the machine layout is stored in
## loaded_machines for main.gd to iterate and re-instantiate. This two-step
## process exists because save_manager doesn't own the machine scenes.

const SAVE_PATH := "user://savegame.json"
const AUTO_SAVE_INTERVAL := 60.0

var _auto_save_timer: float = 0.0
var _grid_manager: GridManager = null
var _order_manager: Node = null
var _tutorial_manager: Node = null

# Populated by load_game() — main.gd reads this to restore the machine layout
var loaded_machines: Array = []

func setup(grid_manager: GridManager, order_manager: Node, tutorial_manager: Node = null) -> void:
	_grid_manager = grid_manager
	_order_manager = order_manager
	_tutorial_manager = tutorial_manager

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
		"tutorial_seen": _tutorial_manager.get_save_data() if _tutorial_manager != null else [],
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

	# Restore tutorial state
	if _tutorial_manager != null:
		var saved_tutorial: Array = data.get("tutorial_seen", [])
		_tutorial_manager.load_save_data(saved_tutorial)

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
