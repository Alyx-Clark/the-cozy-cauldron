class_name BuildRangeOverlay
extends Node2D
## Draws a subtle highlight showing which cells are within build range of the player.
##
## Only visible when a tool is selected (machine placement mode).
## Uses Chebyshev distance (same as game_world.BUILD_RANGE).
## Alpha fades from ~0.08 (center) to ~0.03 (edges).

const CELL_SIZE := 64
const BUILD_RANGE := 5

var player: Player = null
var game_world: Node2D = null  # Needs .selected_machine

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if player == null or game_world == null:
		return
	if game_world.selected_machine == "":
		return

	var player_gp := player.get_grid_pos()

	for dx in range(-BUILD_RANGE, BUILD_RANGE + 1):
		for dy in range(-BUILD_RANGE, BUILD_RANGE + 1):
			var gp := player_gp + Vector2i(dx, dy)
			# Skip out-of-bounds cells
			if gp.x < 0 or gp.y < 0 or gp.x >= 60 or gp.y >= 35:
				continue

			# Fade alpha with distance
			var dist := maxi(absi(dx), absi(dy))
			var alpha: float = lerpf(0.08, 0.03, float(dist) / float(BUILD_RANGE))

			var rect := Rect2(
				Vector2(gp) * CELL_SIZE,
				Vector2(CELL_SIZE, CELL_SIZE),
			)
			draw_rect(rect, Color(0.4, 0.6, 1.0, alpha))

	# Dashed border around the range perimeter
	var tl := Vector2(player_gp - Vector2i(BUILD_RANGE, BUILD_RANGE)) * CELL_SIZE
	var br := Vector2(player_gp + Vector2i(BUILD_RANGE + 1, BUILD_RANGE + 1)) * CELL_SIZE
	var border_color := Color(0.4, 0.6, 1.0, 0.15)
	_draw_dashed_rect(Rect2(tl, br - tl), border_color)

func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var dash := 6.0
	var gap := 4.0
	var w := 1.0
	# Top
	_draw_dashed_line(rect.position, rect.position + Vector2(rect.size.x, 0), color, w, dash, gap)
	# Bottom
	_draw_dashed_line(rect.position + Vector2(0, rect.size.y), rect.position + rect.size, color, w, dash, gap)
	# Left
	_draw_dashed_line(rect.position, rect.position + Vector2(0, rect.size.y), color, w, dash, gap)
	# Right
	_draw_dashed_line(rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, color, w, dash, gap)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var length := from.distance_to(to)
	var dir := (to - from).normalized()
	var pos := 0.0
	while pos < length:
		var end_pos := minf(pos + dash, length)
		draw_line(from + dir * pos, from + dir * end_pos, color, width)
		pos = end_pos + gap
