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
## VISUALS: AnimatedSprite2D with 4-direction walk/idle from spritesheet.

const MOVE_SPEED := 200.0  # px/s
const CELL_SIZE := 64       # Duplicated from GridManager (load order safety)
const FRAME_SIZE := Vector2(32, 48)
const WALK_FPS := 8

## Last movement direction -- used for animation selection and build range.
var facing: Vector2i = Vector2i.DOWN

var _anim_sprite: AnimatedSprite2D = null

func _ready() -> void:
	_setup_animated_sprite()

func _setup_animated_sprite() -> void:
	var spritesheet := load("res://assets/sprites/player/player_spritesheet.png") as Texture2D
	var frames := SpriteFrames.new()
	# Remove the auto-created "default" animation
	frames.remove_animation("default")

	# Rows: 0=down, 1=right, 2=up, 3=left
	var dir_names := ["down", "right", "up", "left"]

	for row in range(4):
		var walk_name: String = "walk_" + dir_names[row]
		var idle_name: String = "idle_" + dir_names[row]

		# Walk animation (4 frames, looping)
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, WALK_FPS)
		frames.set_animation_loop(walk_name, true)
		for col in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = spritesheet
			atlas.region = Rect2(col * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
			frames.add_frame(walk_name, atlas)

		# Idle animation (1 frame, non-looping)
		frames.add_animation(idle_name)
		frames.set_animation_speed(idle_name, 1)
		frames.set_animation_loop(idle_name, false)
		var idle_atlas := AtlasTexture.new()
		idle_atlas.atlas = spritesheet
		idle_atlas.region = Rect2(0, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(idle_name, idle_atlas)

	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.sprite_frames = frames
	_anim_sprite.offset = Vector2(0, -8)  # Align feet with collision center
	_anim_sprite.play("idle_down")
	add_child(_anim_sprite)

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

	_update_animation()

func _update_animation() -> void:
	if _anim_sprite == null:
		return

	var dir_name: String
	if facing == Vector2i.DOWN:
		dir_name = "down"
	elif facing == Vector2i.UP:
		dir_name = "up"
	elif facing == Vector2i.RIGHT:
		dir_name = "right"
	else:
		dir_name = "left"

	var is_walking: bool = velocity.length_squared() > 0.1
	var anim_name: String = ("walk_" if is_walking else "idle_") + dir_name

	if _anim_sprite.animation != anim_name:
		_anim_sprite.play(anim_name)

## Convert pixel position to grid coordinates for build range checks.
func get_grid_pos() -> Vector2i:
	@warning_ignore("integer_division")
	var gx: int = int(position.x) / CELL_SIZE
	@warning_ignore("integer_division")
	var gy: int = int(position.y) / CELL_SIZE
	return Vector2i(gx, gy)
