extends Node2D

const CELL_SIZE := 64
const GRID_WIDTH := 20
const GRID_HEIGHT := 11

func _draw() -> void:
	var dot_color := Color(1.0, 1.0, 1.0, 0.15)
	var dot_radius := 2.0

	for x in range(GRID_WIDTH + 1):
		for y in range(GRID_HEIGHT + 1):
			var pos := Vector2(x * CELL_SIZE, y * CELL_SIZE)
			draw_circle(pos, dot_radius, dot_color)
