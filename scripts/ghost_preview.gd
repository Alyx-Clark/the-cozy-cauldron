extends Node2D
## Semi-transparent placement preview that follows the mouse cursor.
##
## Shows where a machine will be placed and in which direction. Displayed at
## z_index=5 (above everything in GameWorld) so it's always visible.
##
## STATES:
##   Valid   — machine color at 50% alpha, white direction arrow
##   Invalid — red tint (out of bounds, occupied, locked region, out of range)
##   Hidden  — no tool selected or mouse outside grid
##
## Controlled by game_world._update_ghost_preview() which calls update_preview()
## on every mouse motion event, and hide_preview() when no tool is selected.

var machine_color: Color = Color(0.5, 0.5, 0.5, 0.4)
var direction: Vector2i = Vector2i.RIGHT
var is_valid: bool = false

const MACHINE_SIZE := 52.0

func _ready() -> void:
	visible = false

func update_preview(pos: Vector2, color: Color, dir: Vector2i, valid: bool) -> void:
	position = pos
	machine_color = Color(color, 0.5) if valid else Color(1.0, 0.3, 0.3, 0.4)
	direction = dir
	is_valid = valid
	visible = true
	queue_redraw()

func hide_preview() -> void:
	visible = false

func _draw() -> void:
	var rect := Rect2(-MACHINE_SIZE / 2, -MACHINE_SIZE / 2, MACHINE_SIZE, MACHINE_SIZE)
	draw_rect(rect, machine_color)

	# Direction arrow
	var arrow_color := Color(1, 1, 1, 0.5)
	var arrow_end := Vector2(direction) * (MACHINE_SIZE / 2 - 4)
	draw_line(Vector2.ZERO, arrow_end, arrow_color, 2.0)
	var tip := arrow_end
	var perp := Vector2(-direction.y, direction.x) * 5.0
	var back := Vector2(direction) * -8.0
	draw_colored_polygon([tip, tip + back + perp, tip + back - perp], Color(arrow_color, 0.5))
