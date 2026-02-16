class_name Player
extends CharacterBody2D
## Walkable wizard character with WASD movement and a child Camera2D.
##
## MOVEMENT MODEL:
## 4-directional only (no diagonal) for a clean pixel aesthetic. When both axes
## are pressed, the dominant axis wins. Uses CharacterBody2D.move_and_slide()
## for smooth movement, then clamps position to world bounds.
##
## CAMERA: The Camera2D child (defined in player.tscn) follows the player with
## position smoothing. Camera limits are set to the full world bounds (3840x2240)
## so the viewport never shows outside the playable area.
##
## BUILD RANGE: The player's grid position is used by game_world.gd to enforce
## a 5-cell build range (Chebyshev distance). get_grid_pos() converts the pixel
## position to grid coordinates for this check.
##
## VISUALS: Placeholder _draw() renders a purple circle + triangle hat + facing
## indicator dot. Will be replaced with AnimatedSprite2D in Phase 5.

const MOVE_SPEED := 200.0  # px/s
const CELL_SIZE := 64       # Duplicated from GridManager (load order safety)

## Last movement direction -- used for the visual facing indicator.
var facing: Vector2i = Vector2i.DOWN

func _physics_process(_delta: float) -> void:
	# Poll WASD input (not ui_* actions -- those would conflict with UI navigation)
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1

	if input_dir != Vector2.ZERO:
		# 4-directional: pick the axis with the larger magnitude
		if absf(input_dir.x) >= absf(input_dir.y):
			input_dir = Vector2(signf(input_dir.x), 0)
		else:
			input_dir = Vector2(0, signf(input_dir.y))
		facing = Vector2i(input_dir)
		velocity = input_dir * MOVE_SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Clamp to world bounds (60x35 grid = 3840x2240 px, with 16px margin from edges)
	position.x = clampf(position.x, 16.0, 60.0 * CELL_SIZE - 16.0)
	position.y = clampf(position.y, 16.0, 35.0 * CELL_SIZE - 16.0)

	queue_redraw()

func _draw() -> void:
	# Placeholder wizard -- purple circle body + hat triangle + facing dot
	draw_circle(Vector2.ZERO, 14, Color(0.6, 0.3, 0.8))
	draw_circle(Vector2.ZERO, 14, Color(0.7, 0.4, 0.9), false, 2.0)
	draw_colored_polygon([
		Vector2(-8, -10),
		Vector2(8, -10),
		Vector2(0, -24),
	], Color(0.4, 0.2, 0.6))
	var indicator_pos := Vector2(facing) * 10.0
	draw_circle(indicator_pos, 3, Color(1, 1, 1, 0.6))

## Convert pixel position to grid coordinates for build range checks.
func get_grid_pos() -> Vector2i:
	@warning_ignore("integer_division")
	var gx: int = int(position.x) / CELL_SIZE
	@warning_ignore("integer_division")
	var gy: int = int(position.y) / CELL_SIZE
	return Vector2i(gx, gy)
