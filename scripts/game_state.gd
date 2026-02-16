extends Node
## Global game state singleton (autoload). Owns gold, unlock state, sell prices.
##
## AUTOLOAD CONSTRAINT: Autoload scripts in Godot 4 cannot reference class_name
## identifiers (e.g., Recipes, ItemTypes) at ANY point — not in const declarations,
## not in var initializers, not in function bodies. The parser will fail silently
## or produce cryptic errors. Use load() at runtime in _ready() to get references.
##
## Other scripts CAN reference this autoload by its registered name "GameState".
##
## SIGNALS: This is the central signal hub. Other systems connect to these:
##   gold_changed     → GoldDisplay (UI bounce), TutorialManager (shop hint)
##   recipe_unlocked  → Toolbar, UnlockShop (button refresh)
##   machine_unlocked → Toolbar, UnlockShop (button refresh)
##   potion_sold      → OrderManager (order progress tracking)
##   potion_brewed    → TutorialManager (hint triggers)
##   region_unlocked  → RegionOverlay (redraw), SaveManager (persist)

# Currency
var gold: int = 0

# Unlocked recipe indices (into Recipes.RECIPE_LIST)
var unlocked_recipes: Array = [0, 1]

# Unlocked machine keys
var unlocked_machines: Array = ["conveyor", "dispenser", "cauldron"]

# Signals
signal gold_changed(new_amount: int)
signal recipe_unlocked(index: int)
signal machine_unlocked(key: String)
signal potion_sold(potion_type: int, amount: int)
signal potion_brewed(potion_type: int)
signal region_unlocked(id: int)

# Potion sell prices — built in _ready()
var _potion_prices: Dictionary = {}

# Sell price by recipe index (mirrors recipe order)
const PRICE_BY_RECIPE: Array = [10, 15, 20, 25, 30, 35, 40, 45, 50, 60]

# Recipe unlock costs (indexed by recipe index)
const RECIPE_COSTS: Array = [
	0,    # Health Potion — starts unlocked
	0,    # Mana Potion — starts unlocked
	50,   # Speed Potion
	75,   # Love Potion
	100,  # Invisibility Potion
	150,  # Fire Resistance Potion
	200,  # Strength Potion
	275,  # Night Vision Potion
	350,  # Water Breathing Potion
	400,  # Lucky Potion
]

# Machine unlock costs
const MACHINE_COSTS: Dictionary = {
	"conveyor": 0,
	"dispenser": 0,
	"cauldron": 0,
	"fast_belt": 30,
	"storage": 60,
	"splitter": 100,
	"sorter": 80,
	"bottler": 120,
	"auto_seller": 250,
}

# Machine display names (for shop UI)
const MACHINE_NAMES: Dictionary = {
	"conveyor": "Conveyor Belt",
	"dispenser": "Dispenser",
	"cauldron": "Cauldron",
	"fast_belt": "Fast Belt",
	"storage": "Storage Chest",
	"splitter": "Splitter",
	"sorter": "Sorter",
	"bottler": "Bottler",
	"auto_seller": "Auto-Seller",
}

# Runtime references to class_name scripts (loaded in _ready)
var _recipes_script = null
var _recipe_count: int = 10  # fallback

func _ready() -> void:
	# Load script references at runtime (class_names are available now)
	_recipes_script = load("res://scripts/data/recipes.gd")
	if _recipes_script:
		_recipe_count = _recipes_script.RECIPE_LIST.size()
		# Build potion prices dict
		for i in range(_recipe_count):
			var potion_type: int = _recipes_script.RECIPE_LIST[i][2]
			if i < PRICE_BY_RECIPE.size():
				_potion_prices[potion_type] = PRICE_BY_RECIPE[i]
	sync_recipe_unlocks()

## Sell a potion. is_bottled doubles the price.
func sell_potion(potion_type: int, is_bottled: bool = false) -> void:
	var base_price: int = _potion_prices.get(potion_type, 5)
	var price: int = base_price * 2 if is_bottled else base_price
	add_gold(price)
	potion_sold.emit(potion_type, price)

## Add gold and emit signal.
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

## Spend gold. Returns true if successful.
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

## Unlock a recipe by index.
func unlock_recipe(index: int) -> bool:
	if index in unlocked_recipes:
		return false
	if index < 0 or index >= _recipe_count:
		return false
	var cost: int = RECIPE_COSTS[index]
	if not spend_gold(cost):
		return false
	unlocked_recipes.append(index)
	sync_recipe_unlocks()
	recipe_unlocked.emit(index)
	return true

## Unlock a machine by key.
func unlock_machine(key: String) -> bool:
	if key in unlocked_machines:
		return false
	if not MACHINE_COSTS.has(key):
		return false
	var cost: int = MACHINE_COSTS[key]
	if not spend_gold(cost):
		return false
	unlocked_machines.append(key)
	machine_unlocked.emit(key)
	return true

## Check if a machine is unlocked.
func is_machine_unlocked(key: String) -> bool:
	return key in unlocked_machines

## Check if a recipe is unlocked.
func is_recipe_unlocked(index: int) -> bool:
	return index in unlocked_recipes

## Get sell price for a potion type.
func get_potion_price(potion_type: int) -> int:
	return _potion_prices.get(potion_type, 5)

## Get ingredients that belong to unlocked recipes (for smart dispenser cycling).
func get_available_ingredients() -> Array:
	if _recipes_script == null:
		return []
	var ingredients: Array = []
	for idx in unlocked_recipes:
		var pair: Array = _recipes_script.get_recipe_ingredients(idx)
		for ing in pair:
			if not (ing in ingredients):
				ingredients.append(ing)
	ingredients.sort()
	return ingredients

## Sync Recipes.unlocked_indices with our state.
func sync_recipe_unlocks() -> void:
	if _recipes_script:
		_recipes_script.unlocked_indices = unlocked_recipes.duplicate()
