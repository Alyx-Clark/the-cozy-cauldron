class_name EffectsManager
## Static factory for visual particle effects and floating text.
##
## Uses static methods so any script can call EffectsManager.spawn_burst() without
## needing a reference to an instance. The container node is set once from
## game_world._ready() via setup().
##
## Uses CPUParticles2D (not GPUParticles2D) because the project uses the
## GL Compatibility renderer, which doesn't support GPU particles.
## All particles are one_shot=true and auto-free via the finished signal.

static var _container: Node2D = null

## Must be called once from game_world._ready() with the EffectsContainer node.
static func setup(container: Node2D) -> void:
	_container = container

## Spawn a burst of particles at a world position.
static func spawn_burst(pos: Vector2, color: Color, count: int = 8, radius: float = 20.0, lifetime: float = 0.4) -> void:
	if _container == null:
		return
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = count
	particles.lifetime = lifetime
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = radius * 1.5
	particles.initial_velocity_max = radius * 2.5
	particles.gravity = Vector2.ZERO
	particles.damping_min = radius * 3.0
	particles.damping_max = radius * 4.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	# Fade out over lifetime
	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(color, 1.0))
	color_ramp.set_color(1, Color(color, 0.0))
	particles.color_ramp = color_ramp
	_container.add_child(particles)
	# Auto-free after particles finish
	particles.finished.connect(particles.queue_free)

## Spawn floating "+Xg" text that rises and fades out.
static func spawn_gold_text(pos: Vector2, amount: int) -> void:
	if _container == null:
		return
	var label := Label.new()
	label.text = "+" + str(amount) + "g"
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	label.add_theme_font_size_override("font_size", 16)
	label.position = pos - Vector2(20, 10)
	label.z_index = 10
	_container.add_child(label)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 40, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
