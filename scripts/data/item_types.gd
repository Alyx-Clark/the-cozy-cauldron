class_name ItemTypes

# Item type enum — all ingredients MUST come before all potions (is_potion relies on this)
enum Type {
	NONE = 0,
	# Ingredients (1–20)
	MUSHROOM,
	HERB,
	CRYSTAL,
	WATER,
	FEATHER,
	LIGHTNING,
	ROSE,
	HEART,
	SHADOW,
	MOONLIGHT,
	ICE,
	LAVA,
	DRAGON_SCALE,
	EMBER,
	GLOWSHROOM,
	EYE,
	SEAWEED,
	BUBBLE,
	CLOVER,
	STAR,
	# Potions (21–30)
	HEALTH_POTION,
	MANA_POTION,
	SPEED_POTION,
	LOVE_POTION,
	INVISIBILITY_POTION,
	FIRE_RESISTANCE_POTION,
	STRENGTH_POTION,
	NIGHT_VISION_POTION,
	WATER_BREATHING_POTION,
	LUCKY_POTION,
}

# Display colors for each item type (used by _draw)
const COLORS: Dictionary = {
	# Ingredients
	Type.MUSHROOM: Color(0.72, 0.28, 0.28),       # Red-brown
	Type.HERB: Color(0.35, 0.75, 0.35),            # Green
	Type.CRYSTAL: Color(0.55, 0.55, 0.95),         # Light blue
	Type.WATER: Color(0.25, 0.55, 0.85),           # Blue
	Type.FEATHER: Color(0.9, 0.9, 0.92),           # White
	Type.LIGHTNING: Color(1.0, 0.95, 0.2),         # Yellow
	Type.ROSE: Color(0.95, 0.4, 0.6),              # Pink
	Type.HEART: Color(0.85, 0.15, 0.25),           # Red
	Type.SHADOW: Color(0.25, 0.2, 0.35),           # Dark purple
	Type.MOONLIGHT: Color(0.85, 0.85, 0.7),        # Pale yellow
	Type.ICE: Color(0.6, 0.9, 0.95),               # Cyan
	Type.LAVA: Color(0.95, 0.4, 0.1),              # Orange-red
	Type.DRAGON_SCALE: Color(0.2, 0.5, 0.3),       # Dark green
	Type.EMBER: Color(1.0, 0.6, 0.15),             # Orange
	Type.GLOWSHROOM: Color(0.7, 0.95, 0.3),        # Yellow-green
	Type.EYE: Color(0.85, 0.7, 0.2),               # Amber
	Type.SEAWEED: Color(0.15, 0.5, 0.45),          # Dark teal
	Type.BUBBLE: Color(0.7, 0.9, 1.0),             # Light cyan
	Type.CLOVER: Color(0.2, 0.6, 0.25),            # Forest green
	Type.STAR: Color(1.0, 0.85, 0.2),              # Gold
	# Potions
	Type.HEALTH_POTION: Color(1.0, 0.2, 0.3),      # Bright red
	Type.MANA_POTION: Color(0.3, 0.2, 1.0),        # Bright blue
	Type.SPEED_POTION: Color(1.0, 0.95, 0.1),      # Bright yellow
	Type.LOVE_POTION: Color(1.0, 0.3, 0.65),       # Bright pink
	Type.INVISIBILITY_POTION: Color(0.85, 0.85, 0.9), # Near-white
	Type.FIRE_RESISTANCE_POTION: Color(1.0, 0.5, 0.0), # Bright orange
	Type.STRENGTH_POTION: Color(0.7, 0.1, 0.15),   # Burgundy
	Type.NIGHT_VISION_POTION: Color(0.6, 1.0, 0.2), # Bright yellow-green
	Type.WATER_BREATHING_POTION: Color(0.1, 0.85, 0.85), # Bright cyan
	Type.LUCKY_POTION: Color(1.0, 0.8, 0.0),       # Bright gold
}

# Display names
const NAMES: Dictionary = {
	Type.NONE: "None",
	Type.MUSHROOM: "Mushroom",
	Type.HERB: "Herb",
	Type.CRYSTAL: "Crystal",
	Type.WATER: "Water",
	Type.FEATHER: "Feather",
	Type.LIGHTNING: "Lightning",
	Type.ROSE: "Rose",
	Type.HEART: "Heart",
	Type.SHADOW: "Shadow",
	Type.MOONLIGHT: "Moonlight",
	Type.ICE: "Ice",
	Type.LAVA: "Lava",
	Type.DRAGON_SCALE: "Dragon Scale",
	Type.EMBER: "Ember",
	Type.GLOWSHROOM: "Glowshroom",
	Type.EYE: "Eye",
	Type.SEAWEED: "Seaweed",
	Type.BUBBLE: "Bubble",
	Type.CLOVER: "Clover",
	Type.STAR: "Star",
	Type.HEALTH_POTION: "Health Potion",
	Type.MANA_POTION: "Mana Potion",
	Type.SPEED_POTION: "Speed Potion",
	Type.LOVE_POTION: "Love Potion",
	Type.INVISIBILITY_POTION: "Invisibility Potion",
	Type.FIRE_RESISTANCE_POTION: "Fire Resistance Potion",
	Type.STRENGTH_POTION: "Strength Potion",
	Type.NIGHT_VISION_POTION: "Night Vision Potion",
	Type.WATER_BREATHING_POTION: "Water Breathing Potion",
	Type.LUCKY_POTION: "Lucky Potion",
}

# All 20 ingredients (full list — dispenser uses get_available_ingredients() for filtering)
const INGREDIENTS: Array = [
	Type.MUSHROOM,
	Type.HERB,
	Type.CRYSTAL,
	Type.WATER,
	Type.FEATHER,
	Type.LIGHTNING,
	Type.ROSE,
	Type.HEART,
	Type.SHADOW,
	Type.MOONLIGHT,
	Type.ICE,
	Type.LAVA,
	Type.DRAGON_SCALE,
	Type.EMBER,
	Type.GLOWSHROOM,
	Type.EYE,
	Type.SEAWEED,
	Type.BUBBLE,
	Type.CLOVER,
	Type.STAR,
]

# Whether an item type is a potion
static func is_potion(type: Type) -> bool:
	return type >= Type.HEALTH_POTION
