class_name MachineBase
extends Node2D

# Direction the machine faces (output direction)
# RIGHT = (1,0), DOWN = (0,1), LEFT = (-1,0), UP = (0,-1)
@export var direction: Vector2i = Vector2i.RIGHT

# Grid position (set by GridManager on placement)
var grid_pos: Vector2i = Vector2i.ZERO

# Reference to the grid manager (set on placement)
var grid_manager: GridManager = null

# Item currently on/in this machine (reservation slot)
var current_item: Node2D = null

# Machine display color (override in subclasses)
var machine_color: Color = Color(0.5, 0.5, 0.5)

# Machine display label (override in subclasses)
var machine_label: String = "?"

const CELL_SIZE := 64
const MACHINE_SIZE := 52.0  # Slightly smaller than cell for visual gap

func _draw() -> void:
	# Draw machine body
	var rect := Rect2(-MACHINE_SIZE / 2, -MACHINE_SIZE / 2, MACHINE_SIZE, MACHINE_SIZE)
	draw_rect(rect, machine_color)

	# Draw direction arrow
	var arrow_color := Color(1, 1, 1, 0.8)
	var arrow_start := Vector2.ZERO
	var arrow_end := Vector2(direction) * (MACHINE_SIZE / 2 - 4)
	draw_line(arrow_start, arrow_end, arrow_color, 2.0)

	# Draw small triangle at arrow tip
	var tip := arrow_end
	var perp := Vector2(-direction.y, direction.x) * 5.0
	var back := Vector2(direction) * -8.0
	draw_colored_polygon([tip, tip + back + perp, tip + back - perp], arrow_color)

## Rotate direction clockwise by 90 degrees.
func rotate_cw() -> void:
	# (x,y) → (−y,x) for CW rotation
	direction = Vector2i(-direction.y, direction.x)
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
