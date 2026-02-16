extends Node2D
## Root scene script. Wires together all subsystems created at runtime.
##
## INITIALIZATION ORDER (matters!):
##   1. Scene-defined nodes (_ready): GameWorld, Toolbar, UI CanvasLayer
##   2. Managers: OrderManager, SaveManager, TutorialManager (created via .new())
##   3. UI panels: GoldDisplay, OrderPanel, UnlockShop (added to UI CanvasLayer)
##   4. Cross-references: order_manager ↔ order_panel, save_manager ← grid + order + tutorial
##   5. Load save (or show tutorial on fresh start)
##   6. Restore machines from save data (if loaded)
##
## Most nodes are created in code (not in the .tscn) because they're pure scripts
## with no scene structure — just a single node with a script attached.

@onready var game_world: Node2D = $GameWorld
@onready var toolbar: PanelContainer = $UI/Toolbar

var order_manager: Node
var save_manager: Node
var tutorial_manager: TutorialManager

func _ready() -> void:
	toolbar.machine_selected.connect(game_world.select_machine)

	# --- Create manager nodes (order matters: save_manager needs references to others) ---

	order_manager = preload("res://scripts/order_manager.gd").new()
	order_manager.name = "OrderManager"
	add_child(order_manager)

	save_manager = preload("res://scripts/save_manager.gd").new()
	save_manager.name = "SaveManager"
	add_child(save_manager)

	tutorial_manager = TutorialManager.new()
	tutorial_manager.name = "TutorialManager"
	add_child(tutorial_manager)
	tutorial_manager.setup($UI)
	game_world.tutorial_manager = tutorial_manager

	# --- Create UI panels (added to CanvasLayer so they render above the game world) ---

	var gold_display := preload("res://scripts/ui/gold_display.gd").new()
	gold_display.name = "GoldDisplay"
	$UI.add_child(gold_display)

	var order_panel := preload("res://scripts/ui/order_panel.gd").new()
	order_panel.name = "OrderPanel"
	$UI.add_child(order_panel)
	order_manager.order_panel = order_panel
	order_manager.ui_layer = $UI  # For notification popups

	var unlock_shop := preload("res://scripts/ui/unlock_shop.gd").new()
	unlock_shop.name = "UnlockShop"
	$UI.add_child(unlock_shop)

	# --- Wire save manager to all persistent subsystems ---
	save_manager.setup(game_world.grid_manager, order_manager, tutorial_manager)

	# --- Load or fresh start ---
	if save_manager.load_game():
		_restore_machines()
	else:
		tutorial_manager.show_initial_hint()

func _restore_machines() -> void:
	var machines: Array = save_manager.loaded_machines

	for entry in machines:
		var machine_type: String = entry.get("type", "")
		var grid_pos := Vector2i(int(entry.get("grid_x", 0)), int(entry.get("grid_y", 0)))
		var dir := Vector2i(int(entry.get("dir_x", 1)), int(entry.get("dir_y", 0)))

		if not game_world._machine_scenes.has(machine_type):
			continue

		var machine: MachineBase = game_world._machine_scenes[machine_type].instantiate()
		machine.direction = dir
		machine.grid_pos = grid_pos
		machine.grid_manager = game_world.grid_manager
		machine.item_container = game_world.item_container
		game_world.machine_container.add_child(machine)
		game_world.grid_manager.place_machine(grid_pos, machine)

		# Restore machine-specific config
		if machine is Dispenser and entry.has("ingredient_type"):
			machine.ingredient_type = int(entry["ingredient_type"])
			machine.queue_redraw()
		if machine is Sorter and entry.has("filter_type"):
			machine.filter_type = int(entry["filter_type"])
			machine.queue_redraw()
		if machine is StorageChest and entry.has("stored_items"):
			for item_type in entry["stored_items"]:
				machine.stored_items.append(int(item_type))
			machine.queue_redraw()
