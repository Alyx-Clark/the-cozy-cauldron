class_name AutoSeller
extends MachineBase

# Sink machine — accepts potions, sells them for gold. No output.

const SELL_TIME := 0.5

var _waiting_for_arrival: bool = false
var _is_selling: bool = false
var _sell_timer: float = 0.0
var _sell_type: int = ItemTypes.Type.NONE
var _sell_bottled: bool = false

# Flash effect when selling
var _flash_timer: float = 0.0

func _ready() -> void:
	machine_color = Color(0.8, 0.7, 0.1)  # Gold
	machine_label = "Sell"

func _process(delta: float) -> void:
	# Flash effect fade
	if _flash_timer > 0:
		_flash_timer -= delta
		queue_redraw()

	if _is_selling:
		_sell_timer += delta
		queue_redraw()
		if _sell_timer >= SELL_TIME:
			_finish_selling()
		return

	# Handle incoming item arrival
	if _waiting_for_arrival and current_item != null and not current_item.is_moving:
		_waiting_for_arrival = false
		_start_selling()
		return

func receive_item(item: Node2D) -> bool:
	if current_item != null or _is_selling or _waiting_for_arrival:
		return false
	# Only accept potions
	if not ItemTypes.is_potion(item.item_type):
		return false
	current_item = item
	_waiting_for_arrival = true
	return true

func _start_selling() -> void:
	if current_item == null:
		return
	_sell_type = current_item.item_type
	_sell_bottled = current_item.is_bottled
	current_item.queue_free()
	current_item = null
	_is_selling = true
	_sell_timer = 0.0
	queue_redraw()

func _finish_selling() -> void:
	_is_selling = false
	var price: int = GameState.get_potion_price(_sell_type)
	if _sell_bottled:
		price *= 2
	GameState.sell_potion(_sell_type, _sell_bottled)
	_flash_timer = 0.4

	# Gold burst + floating price text + sound
	var world_pos := grid_manager.grid_to_world(grid_pos)
	EffectsManager.spawn_burst(world_pos, Color(1.0, 0.85, 0.1), 8, 18.0, 0.4)
	EffectsManager.spawn_gold_text(world_pos, price)
	SoundManager.play("sell")

	_sell_type = ItemTypes.Type.NONE
	_sell_bottled = false
	queue_redraw()

func _draw() -> void:
	# Draw seller body
	var rect := Rect2(-MACHINE_SIZE / 2, -MACHINE_SIZE / 2, MACHINE_SIZE, MACHINE_SIZE)
	draw_rect(rect, machine_color)

	# Gold coin icon
	var coin_color := Color(1.0, 0.85, 0.1)
	draw_circle(Vector2.ZERO, 12.0, coin_color)
	draw_circle(Vector2.ZERO, 8.0, Color(0.9, 0.75, 0.05))
	# "G" on coin
	draw_string(ThemeDB.fallback_font, Vector2(-5, 5), "G", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.55, 0.0))

	# Selling progress
	if _is_selling:
		var progress := _sell_timer / SELL_TIME
		draw_arc(Vector2.ZERO, 16.0, -PI / 2, -PI / 2 + TAU * progress, 24, Color(1, 1, 1, 0.6), 2.0)

	# Sale flash effect
	if _flash_timer > 0:
		var alpha := _flash_timer / 0.4
		draw_circle(Vector2.ZERO, 20.0 + (1.0 - alpha) * 8.0, Color(1, 1, 0.5, alpha * 0.4))

	# No direction arrow needed — this is a sink
