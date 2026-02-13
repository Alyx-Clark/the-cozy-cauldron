extends Node2D

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
