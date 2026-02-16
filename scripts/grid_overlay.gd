extends Node2D
## Draws faint dots at grid intersection points for visual reference.
##
## Camera-aware: only draws dots visible on screen by computing the visible
## world rect from the canvas transform inverse. This avoids drawing all 2100+
## dots every frame on the 60x35 grid.
##
## Redraws every frame via _process() → queue_redraw() because the camera moves
## as the player walks. Lives in GameWorld at z_index=0 (below everything).

const CELL_SIZE := 64
const GRID_WIDTH := 60
const GRID_HEIGHT := 35

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var dot_color := Color(1.0, 1.0, 1.0, 0.15)
	var dot_radius := 2.0

	# Only draw dots visible on screen (camera-aware)
	var inv := get_canvas_transform().affine_inverse()
	var vp_size := get_viewport_rect().size
	var top_left := inv * Vector2.ZERO
	var bottom_right := inv * vp_size

	@warning_ignore("integer_division")
	var start_x := maxi(0, int(top_left.x) / CELL_SIZE)
	@warning_ignore("integer_division")
	var end_x := mini(GRID_WIDTH, int(bottom_right.x) / CELL_SIZE + 1)
	@warning_ignore("integer_division")
	var start_y := maxi(0, int(top_left.y) / CELL_SIZE)
	@warning_ignore("integer_division")
	var end_y := mini(GRID_HEIGHT, int(bottom_right.y) / CELL_SIZE + 1)

	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var pos := Vector2(x * CELL_SIZE, y * CELL_SIZE)
			draw_circle(pos, dot_radius, dot_color)
