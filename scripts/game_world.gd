extends Node2D
## The game world handles all grid interaction: placing/removing machines, ghost
## preview, hand-selling potions, and dispatching effects/sounds/tutorial triggers.
##
## Input flows through _unhandled_input (so UI controls get priority):
##   - Mouse motion → update ghost preview (world coords via camera transform)
##   - Left click  → place machine (if tool selected) or interact/hand-sell (if not)
##   - Right click → remove machine
##   - R key       → rotate placement direction 90° CW
##
## Child nodes (defined in main.tscn, layered by z_index):
##   GridOverlay (z=0)        — faint dots at grid intersections
##   GridManager (z=0)        — no visuals, Dictionary-based grid data
##   MachineContainer (z=1)   — parent for all placed machine Node2D instances
##   ItemContainer (z=2)      — parent for all moving Item instances
##   EffectsContainer (z=4)   — parent for particle bursts and floating text
##   GhostPreview (z=5)       — translucent placement cursor

@onready var grid_manager: GridManager = $GridManager
@onready var machine_container: Node2D = $MachineContainer
@onready var item_container: Node2D = $ItemContainer
@onready var effects_container: Node2D = $EffectsContainer
@onready var ghost_preview: Node2D = $GhostPreview

var current_direction: Vector2i = Vector2i.RIGHT  # Placement direction, rotated with R
var selected_machine: String = ""                  # Current toolbar selection ("" = none)

# Preloaded PackedScenes keyed by machine type string (e.g., "conveyor" → conveyor_belt.tscn)
var _machine_scenes: Dictionary = {}

# Set by main.gd after creation. Used to fire contextual tutorial hints.
var tutorial_manager: TutorialManager = null

# Set by main.gd — needed for build range and region checks
var player: Player = null
var region_manager: RegionManager = null

const BUILD_RANGE := 5  # Max cells from player to place/interact

func _ready() -> void:
	EffectsManager.setup(effects_container)

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
		_update_ghost_preview(get_global_mouse_position())

	if event is InputEventMouseButton and event.pressed:
		var world_pos := get_global_mouse_position()
		var grid_pos := grid_manager.world_to_grid(world_pos)

		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place(grid_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_remove(grid_pos)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_rotate_direction()

func _update_ghost_preview(world_mouse_pos: Vector2) -> void:
	if selected_machine == "":
		ghost_preview.hide_preview()
		return

	var grid_pos := grid_manager.world_to_grid(world_mouse_pos)
	var world_pos := grid_manager.grid_to_world(grid_pos)
	var valid := grid_manager.is_in_bounds(grid_pos) and grid_manager.is_cell_empty(grid_pos)
	# Check unlock state
	if not GameState.is_machine_unlocked(selected_machine):
		valid = false
	# Check build range from player
	if not _is_in_build_range(grid_pos):
		valid = false
	# Check region is unlocked
	if region_manager != null and not region_manager.is_unlocked(grid_pos):
		valid = false
	var color := _get_machine_color(selected_machine)

	ghost_preview.update_preview(world_pos, color, current_direction, valid)

func _try_place(grid_pos: Vector2i) -> void:
	if selected_machine == "":
		# If clicking on an existing machine, interact with it
		if not _is_in_build_range(grid_pos):
			return
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

	# Check build range and region
	if not _is_in_build_range(grid_pos):
		return
	if region_manager != null and not region_manager.is_unlocked(grid_pos):
		return

	var machine: MachineBase = _machine_scenes[selected_machine].instantiate()
	machine.direction = current_direction
	machine.grid_pos = grid_pos
	machine.grid_manager = grid_manager
	machine.item_container = item_container
	machine_container.add_child(machine)
	grid_manager.place_machine(grid_pos, machine)

	# Placement burst + sound
	EffectsManager.spawn_burst(grid_manager.grid_to_world(grid_pos), Color(1.0, 1.0, 1.0, 0.7), 6, 16.0, 0.25)
	SoundManager.play("place")

	# Tutorial triggers
	if tutorial_manager != null:
		tutorial_manager.on_machine_placed(selected_machine)

func _try_remove(grid_pos: Vector2i) -> void:
	if not _is_in_build_range(grid_pos):
		return
	var machine := grid_manager.remove_machine(grid_pos)
	if machine == null:
		return
	# Removal burst + sound
	EffectsManager.spawn_burst(grid_manager.grid_to_world(grid_pos), Color(1.0, 0.5, 0.4, 0.7), 6, 16.0, 0.25)
	SoundManager.play("remove")
	# Clean up any item the machine is holding
	if machine is MachineBase and machine.current_item != null:
		machine.current_item.queue_free()
	machine.queue_free()

func _rotate_direction() -> void:
	current_direction = Vector2i(-current_direction.y, current_direction.x)
	_update_ghost_preview(get_global_mouse_position())

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
	# Hand-sell effects
	EffectsManager.spawn_burst(machine.position, Color(1.0, 0.85, 0.1), 6, 14.0, 0.3)
	EffectsManager.spawn_gold_text(machine.position, price)
	SoundManager.play("sell")
	machine.current_item.queue_free()
	machine.current_item = null
	return true

## Called by toolbar when selection changes.
func select_machine(machine_type: String) -> void:
	selected_machine = machine_type
	_update_ghost_preview(get_global_mouse_position())

## Check if a grid position is within build range of the player.
## Uses Chebyshev distance (max of dx, dy) — forms a square, not a circle.
## Returns true if no player exists (backward compat with pre-Phase-4 saves).
func _is_in_build_range(grid_pos: Vector2i) -> bool:
	if player == null:
		return true
	var player_gp := player.get_grid_pos()
	var dx := absi(grid_pos.x - player_gp.x)
	var dy := absi(grid_pos.y - player_gp.y)
	return dx <= BUILD_RANGE and dy <= BUILD_RANGE
