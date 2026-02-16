extends Node2D
## Root scene script. Wires together all subsystems created at runtime.
##
## INITIALIZATION ORDER (matters!):
##   1. Scene-defined nodes (_ready): GameWorld, Toolbar, UI CanvasLayer
##   2. Player + RegionManager (structural — needed before save/load)
##   3. Managers: OrderManager, SaveManager, TutorialManager (created via .new())
##   4. UI panels: GoldDisplay, OrderPanel, UnlockShop, Minimap (added to UI CanvasLayer)
##   5. Cross-references: order_manager ↔ order_panel, save_manager ← grid + order + tutorial + region + player
##   6. Load save (or show tutorial on fresh start)
##   7. Restore machines + player position from save data
##
## Most nodes are created in code (not in the .tscn) because they're pure scripts
## with no scene structure — just a single node with a script attached.

@onready var game_world: Node2D = $GameWorld
@onready var toolbar: PanelContainer = $UI/Toolbar

var player: Player
var region_manager: RegionManager
var order_manager: Node
var save_manager: Node
var tutorial_manager: TutorialManager
var minimap: PanelContainer

# Region unlock prompt management
var _region_prompt: Node = null
var _prompt_region_id: int = -1

const CELL_SIZE := 64
# Default player spawn: center of Region 0 (Starter Workshop: 0,0 → 14,11)
const DEFAULT_SPAWN := Vector2(7 * 64 + 32, 5 * 64 + 32)

func _ready() -> void:
	toolbar.machine_selected.connect(game_world.select_machine)

	# --- Create Player (CharacterBody2D with Camera2D) ---
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = DEFAULT_SPAWN
	game_world.add_child(player)
	game_world.player = player

	# --- Create RegionManager ---
	region_manager = RegionManager.new()
	region_manager.name = "RegionManager"
	add_child(region_manager)
	game_world.region_manager = region_manager

	# --- Create RegionOverlay (visual layer in GameWorld) ---
	var region_overlay := RegionOverlay.new()
	region_overlay.name = "RegionOverlay"
	region_overlay.z_index = 0
	region_overlay.region_manager = region_manager
	# Insert before MachineContainer so it draws below machines
	game_world.add_child(region_overlay)
	game_world.move_child(region_overlay, 1)  # After GridOverlay

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

	minimap = preload("res://scripts/ui/minimap.gd").new()
	minimap.grid_manager = game_world.grid_manager
	minimap.region_manager = region_manager
	minimap.player = player
	$UI.add_child(minimap)

	# --- Wire save manager to all persistent subsystems ---
	save_manager.setup(game_world.grid_manager, order_manager, tutorial_manager, region_manager, player)

	# --- Load or fresh start ---
	if save_manager.load_game():
		_restore_machines()
		_restore_player_pos()
	else:
		tutorial_manager.show_initial_hint()

func _process(_delta: float) -> void:
	_check_region_prompt()

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

func _restore_player_pos() -> void:
	if save_manager.loaded_player_pos != null:
		player.position = save_manager.loaded_player_pos

## Check if player is near a locked region boundary and show/hide unlock prompt.
func _check_region_prompt() -> void:
	if region_manager == null or player == null:
		return

	var player_gp := player.get_grid_pos()
	var nearby_locked: Dictionary = _get_nearby_locked_region(player_gp)

	if nearby_locked.is_empty():
		# No locked region nearby — dismiss prompt if showing
		if _region_prompt != null:
			_region_prompt.queue_free()
			_region_prompt = null
			_prompt_region_id = -1
		return

	var rid: int = nearby_locked["id"]
	# Already showing this prompt
	if _region_prompt != null and _prompt_region_id == rid:
		return

	# Dismiss old prompt if it's for a different region
	if _region_prompt != null:
		_region_prompt.queue_free()
		_region_prompt = null

	# Show new prompt
	var prompt := preload("res://scripts/ui/region_prompt.gd").new()
	prompt.setup(nearby_locked, region_manager)
	$UI.add_child(prompt)
	_region_prompt = prompt
	_prompt_region_id = rid

## Find a locked region within 2 cells of player grid pos.
func _get_nearby_locked_region(player_gp: Vector2i) -> Dictionary:
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var check_pos := player_gp + Vector2i(dx, dy)
			var region := region_manager.get_region_at(check_pos)
			if not region.is_empty() and not (region["id"] in region_manager.unlocked_regions):
				return region
	return {}
