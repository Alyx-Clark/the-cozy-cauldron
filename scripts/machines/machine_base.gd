class_name MachineBase
extends Node2D
## Base class for all placeable machines. Implements the Push + Reservation item
## transport model that is the core of the automation system.
##
## ITEM FLOW (Push + Reservation):
## All item movement uses a "push" model — machines push items to their output
## neighbor. The flow for each item transfer is:
##   1. Machine A checks: does target exist AND is target.current_item == null?
##   2. Machine A calls target.receive_item(item) — target stores item reference
##      in current_item (reserving the slot so no other machine can send to it)
##   3. Item begins smooth visual movement toward target's position
##   4. Item arrives (is_moving == false) — target can now process or push onward
##
## The reservation prevents two machines from sending items to the same target
## simultaneously. Machines that consume items (Cauldron, StorageChest) use
## _waiting_for_arrival to distinguish "incoming item in transit" from
## "output item ready to push".
##
## SUBCLASS CONTRACT:
## - Override _ready() to call setup_sprite("type_key") for sprite visuals
## - Override _draw() for overlay visuals (arrows, indicators) drawn ON TOP of sprite
## - Override receive_item() to add acceptance conditions (e.g., potions only)
## - Call try_push_item() in _process() to push output to the next machine
## - Optionally implement on_click() for player interaction (dispenser cycling, etc.)

# Direction the machine faces (output direction).
# RIGHT = (1,0), DOWN = (0,1), LEFT = (-1,0), UP = (0,-1)
@export var direction: Vector2i = Vector2i.RIGHT

# Grid position — set by game_world.gd during placement, used for neighbor lookups
var grid_pos: Vector2i = Vector2i.ZERO

# Set on placement by game_world.gd. Used for grid queries (neighbor lookup, bounds).
var grid_manager: GridManager = null

# The item currently on/in this machine (reservation slot).
# Non-null means this machine is "occupied" — other machines cannot send items here.
var current_item: Node2D = null

# Shared Node2D parent for all Item instances. Set on placement by game_world.gd.
# Machines that spawn items (Dispenser, Cauldron, StorageChest, Splitter) add
# children to this container so items render at the correct z-layer.
var item_container: Node2D = null

# Override in subclass _ready() to set machine appearance
var machine_color: Color = Color(0.5, 0.5, 0.5)
var machine_label: String = "?"

# Sprite child node for machine texture (created by setup_sprite)
var machine_sprite: Sprite2D = null

# Duplicated from GridManager (can't cross-reference class_name constants reliably)
const CELL_SIZE := 64
const MACHINE_SIZE := 52.0  # Slightly smaller than cell for visual gap

# Sprite texture paths per machine type (duplicated — don't cross-reference class_name)
const SPRITE_PATHS: Dictionary = {
	"conveyor": "res://assets/sprites/machines/conveyor.png",
	"fast_belt": "res://assets/sprites/machines/fast_belt.png",
	"dispenser": "res://assets/sprites/machines/dispenser.png",
	"cauldron": "res://assets/sprites/machines/cauldron.png",
	"storage": "res://assets/sprites/machines/storage.png",
	"splitter": "res://assets/sprites/machines/splitter.png",
	"sorter": "res://assets/sprites/machines/sorter.png",
	"bottler": "res://assets/sprites/machines/bottler.png",
	"auto_seller": "res://assets/sprites/machines/auto_seller.png",
}

## Create a Sprite2D child with the machine texture, rotated to match direction.
## Called from subclass _ready(). show_behind_parent ensures _draw() overlays
## render ON TOP of the sprite.
func setup_sprite(machine_type: String) -> void:
	if not SPRITE_PATHS.has(machine_type):
		return
	machine_sprite = Sprite2D.new()
	machine_sprite.texture = load(SPRITE_PATHS[machine_type])
	machine_sprite.show_behind_parent = true
	machine_sprite.rotation = Vector2(direction).angle()
	add_child(machine_sprite)

## Update sprite rotation to match current direction.
func _update_sprite_rotation() -> void:
	if machine_sprite != null:
		machine_sprite.rotation = Vector2(direction).angle()

func _draw() -> void:
	# Draw direction arrow overlay (on top of sprite)
	draw_direction_arrow()

## Draw a direction arrow. Reusable helper for subclasses.
func draw_direction_arrow() -> void:
	var arrow_color := Color(1, 1, 1, 0.8)
	var arrow_end := Vector2(direction) * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2.ZERO, arrow_end, arrow_color, 2.0)
	var tip := arrow_end
	var perp := Vector2(-direction.y, direction.x) * 5.0
	var back := Vector2(direction) * -8.0
	draw_colored_polygon([tip, tip + back + perp, tip + back - perp], arrow_color)

## Rotate direction clockwise by 90 degrees.
func rotate_cw() -> void:
	# (x,y) → (−y,x) for CW rotation
	direction = Vector2i(-direction.y, direction.x)
	_update_sprite_rotation()
	queue_redraw()

## Get the grid position this machine outputs to.
func get_output_pos() -> Vector2i:
	return grid_pos + direction

## Get the machine at the output position, or null.
func get_output_machine() -> MachineBase:
	if grid_manager == null:
		return null
	var machine := grid_manager.get_machine_at(get_output_pos())
	if machine is MachineBase:
		return machine
	return null

## Try to push an item to the output machine. Returns true if successful.
func try_push_item(item: Node2D) -> bool:
	var target := get_output_machine()
	if target == null or target.current_item != null:
		return false
	return target.receive_item(item)

## Called when an item arrives at this machine. Override in subclasses.
## Returns true if the item was accepted.
func receive_item(item: Node2D) -> bool:
	if current_item != null:
		return false
	current_item = item
	return true
