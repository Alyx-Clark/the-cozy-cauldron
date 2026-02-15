extends Node

# Generates and tracks potion orders

const MAX_ORDERS := 3
const ORDER_INTERVAL := 5.0  # Seconds between order generation attempts
const MIN_QUANTITY := 3
const MAX_QUANTITY := 8

var orders: Array = []  # Array of order dictionaries
var _order_timer: float = 0.0
var _next_id: int = 0

# Reference to order panel UI (set by main.gd)
var order_panel: Node = null

signal order_completed(order: Dictionary)

func _ready() -> void:
	GameState.potion_sold.connect(_on_potion_sold)

func _process(delta: float) -> void:
	if orders.size() >= MAX_ORDERS:
		return

	_order_timer += delta
	if _order_timer >= ORDER_INTERVAL:
		_order_timer = 0.0
		_try_generate_order()

func _try_generate_order() -> void:
	if orders.size() >= MAX_ORDERS:
		return

	# Get unlocked potion types
	var available_potions: Array = []
	for idx in GameState.unlocked_recipes:
		var ptype := Recipes.get_recipe_result(idx)
		if ptype != ItemTypes.Type.NONE:
			# Don't duplicate existing orders
			var already_ordered := false
			for order in orders:
				if order["potion_type"] == ptype:
					already_ordered = true
					break
			if not already_ordered:
				available_potions.append(ptype)

	if available_potions.is_empty():
		return

	# Pick a random potion type
	var potion_type: int = available_potions[randi() % available_potions.size()]
	var quantity: int = MIN_QUANTITY + randi() % (MAX_QUANTITY - MIN_QUANTITY + 1)
	var base_price: int = GameState.get_potion_price(potion_type)
	var reward: int = base_price * quantity + roundi(base_price * 0.5)  # Bonus on top

	var order := {
		"id": _next_id,
		"potion_type": potion_type,
		"quantity": quantity,
		"progress": 0,
		"reward": reward,
	}
	_next_id += 1
	orders.append(order)
	_update_panel()

func _on_potion_sold(potion_type: int, _amount: int) -> void:
	for order in orders:
		if order["potion_type"] == potion_type and order["progress"] < order["quantity"]:
			order["progress"] += 1
			if order["progress"] >= order["quantity"]:
				_complete_order(order)
			_update_panel()
			return  # Only fulfill one order per sale

func _complete_order(order: Dictionary) -> void:
	GameState.add_gold(order["reward"])
	orders.erase(order)
	order_completed.emit(order)
	_update_panel()

func _update_panel() -> void:
	if order_panel != null and order_panel.has_method("update_orders"):
		order_panel.update_orders(orders)

## Get order data for save/load.
func get_save_data() -> Array:
	return orders.duplicate(true)

## Restore orders from save data.
func load_save_data(data: Array) -> void:
	orders = data.duplicate(true)
	# Update next_id to avoid conflicts
	for order in orders:
		if order["id"] >= _next_id:
			_next_id = order["id"] + 1
	_update_panel()
