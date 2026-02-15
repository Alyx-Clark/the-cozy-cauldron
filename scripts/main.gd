extends Node2D

@onready var game_world: Node2D = $GameWorld
@onready var toolbar: PanelContainer = $UI/Toolbar

var order_manager: Node
var save_manager: Node

func _ready() -> void:
	toolbar.machine_selected.connect(game_world.select_machine)

	# Create order manager
	order_manager = preload("res://scripts/order_manager.gd").new()
	order_manager.name = "OrderManager"
	add_child(order_manager)

	# Create save manager
	save_manager = preload("res://scripts/save_manager.gd").new()
	save_manager.name = "SaveManager"
	add_child(save_manager)

	# Create gold display
	var gold_display := preload("res://scripts/ui/gold_display.gd").new()
	gold_display.name = "GoldDisplay"
	$UI.add_child(gold_display)

	# Create order panel
	var order_panel := preload("res://scripts/ui/order_panel.gd").new()
	order_panel.name = "OrderPanel"
	$UI.add_child(order_panel)
	order_manager.order_panel = order_panel

	# Create unlock shop
	var unlock_shop := preload("res://scripts/ui/unlock_shop.gd").new()
	unlock_shop.name = "UnlockShop"
	$UI.add_child(unlock_shop)

	# Setup save manager
	save_manager.setup(game_world.grid_manager, order_manager)

	# Try to load saved game
	if save_manager.load_game():
		_restore_machines()

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
