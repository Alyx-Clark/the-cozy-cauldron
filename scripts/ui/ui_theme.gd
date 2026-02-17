class_name UITheme
## Static helper providing themed UI styles for The Cozy Cauldron.
##
## Lazy-loads font + all UI textures on first access. Consistent with the
## project's code-first pattern (like EffectsManager).
##
## Usage:
##   UITheme.get_font()                -> FontFile (m5x7 pixel font)
##   UITheme.make_wood_panel_style()   -> StyleBoxTexture (9-slice wood panel)
##   UITheme.make_dark_panel_style()   -> StyleBoxTexture (darker variant)
##   UITheme.make_parchment_style()    -> StyleBoxTexture (cream/tan paper)
##   UITheme.make_button_styleboxes()  -> Dictionary {normal, hover, pressed, disabled}
##   UITheme.get_coin_texture()        -> Texture2D
##   UITheme.get_lock_texture()        -> Texture2D
##   UITheme.apply_label_style(label, size, color)

# ── Color constants ──────────────────────────────────────────────────────────

const COLOR_TITLE := Color(1.0, 0.85, 0.5)       # Warm gold for titles
const COLOR_TEXT := Color(0.93, 0.88, 0.78)       # Cream for body text
const COLOR_TEXT_DIM := Color(0.65, 0.6, 0.52)    # Muted for secondary text
const COLOR_GOLD := Color(0.9, 0.78, 0.15)        # Bright gold for currency
const COLOR_POSITIVE := Color(0.3, 1.0, 0.4)      # Green for gains
const COLOR_NEGATIVE := Color(1.0, 0.4, 0.3)      # Red for costs/losses
const COLOR_LOCKED := Color(0.5, 0.5, 0.5)        # Grey for locked items

# ── Font size constants ──────────────────────────────────────────────────────

const FONT_SIZE_SMALL := 12
const FONT_SIZE_MEDIUM := 16
const FONT_SIZE_LARGE := 20
const FONT_SIZE_TITLE := 28

# ── Texture paths ────────────────────────────────────────────────────────────

const _FONT_PATH := "res://assets/fonts/m5x7.ttf"
const _WOOD_PANEL_PATH := "res://assets/sprites/ui/wood_panel.png"
const _DARK_PANEL_PATH := "res://assets/sprites/ui/wood_panel_dark.png"
const _PARCHMENT_PATH := "res://assets/sprites/ui/parchment.png"
const _COIN_PATH := "res://assets/sprites/ui/coin.png"
const _LOCK_PATH := "res://assets/sprites/ui/lock.png"
const _BTN_NORMAL_PATH := "res://assets/sprites/ui/button_wood.png"
const _BTN_HOVER_PATH := "res://assets/sprites/ui/button_wood_hover.png"
const _BTN_PRESSED_PATH := "res://assets/sprites/ui/button_wood_pressed.png"

# ── Lazy-loaded caches ───────────────────────────────────────────────────────

static var _font: Font = null
static var _coin_tex: Texture2D = null
static var _lock_tex: Texture2D = null

# ── Public API ───────────────────────────────────────────────────────────────

static func get_font() -> Font:
	if _font == null:
		if ResourceLoader.exists(_FONT_PATH):
			_font = load(_FONT_PATH) as Font
		else:
			_font = ThemeDB.fallback_font
	return _font

static func get_coin_texture() -> Texture2D:
	if _coin_tex == null:
		_coin_tex = load(_COIN_PATH) as Texture2D
	return _coin_tex

static func get_lock_texture() -> Texture2D:
	if _lock_tex == null:
		_lock_tex = load(_LOCK_PATH) as Texture2D
	return _lock_tex

static func make_wood_panel_style() -> StyleBoxTexture:
	return _make_9slice(_WOOD_PANEL_PATH, 6)

static func make_dark_panel_style() -> StyleBoxTexture:
	return _make_9slice(_DARK_PANEL_PATH, 6)

static func make_parchment_style() -> StyleBoxTexture:
	return _make_9slice(_PARCHMENT_PATH, 5)

static func make_button_styleboxes() -> Dictionary:
	var normal := _make_9slice(_BTN_NORMAL_PATH, 3)
	normal.content_margin_left = 6
	normal.content_margin_right = 6
	normal.content_margin_top = 3
	normal.content_margin_bottom = 3

	var hover := _make_9slice(_BTN_HOVER_PATH, 3)
	hover.content_margin_left = 6
	hover.content_margin_right = 6
	hover.content_margin_top = 3
	hover.content_margin_bottom = 3

	var pressed := _make_9slice(_BTN_PRESSED_PATH, 3)
	pressed.content_margin_left = 6
	pressed.content_margin_right = 6
	pressed.content_margin_top = 3
	pressed.content_margin_bottom = 3

	# Disabled: reuse normal but tinted grey
	var disabled := _make_9slice(_BTN_NORMAL_PATH, 3)
	disabled.content_margin_left = 6
	disabled.content_margin_right = 6
	disabled.content_margin_top = 3
	disabled.content_margin_bottom = 3
	disabled.modulate_color = Color(0.6, 0.6, 0.6, 0.7)

	return {
		"normal": normal,
		"hover": hover,
		"pressed": pressed,
		"disabled": disabled,
	}

## Apply pixel font + size + color to any Label node.
static func apply_label_style(label: Label, font_size: int = FONT_SIZE_MEDIUM, color: Color = COLOR_TEXT) -> void:
	label.add_theme_font_override("font", get_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

## Apply pixel font + size + color to a Button node.
static func apply_button_font(btn: Button, font_size: int = FONT_SIZE_MEDIUM, color: Color = COLOR_TEXT) -> void:
	btn.add_theme_font_override("font", get_font())
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", color)

## Apply full button theming: wood styleboxes + pixel font.
static func apply_button_theme(btn: Button, font_size: int = FONT_SIZE_MEDIUM) -> void:
	var styles := make_button_styleboxes()
	btn.add_theme_stylebox_override("normal", styles["normal"])
	btn.add_theme_stylebox_override("hover", styles["hover"])
	btn.add_theme_stylebox_override("pressed", styles["pressed"])
	btn.add_theme_stylebox_override("disabled", styles["disabled"])
	apply_button_font(btn, font_size)

# ── Private helpers ──────────────────────────────────────────────────────────

static func _make_9slice(path: String, margin: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path) as Texture2D
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = margin + 4
	style.content_margin_right = margin + 4
	style.content_margin_top = margin + 4
	style.content_margin_bottom = margin + 4
	return style
