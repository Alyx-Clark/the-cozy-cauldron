extends Node
## Autoload singleton for persistent user settings (volume, fullscreen).
##
## AUTOLOAD CONSTRAINT: Cannot reference class_name identifiers. Use load() if needed.
##
## Settings stored at user://settings.json. Loaded in _ready(), saved on any change.
##
## Other systems connect to settings_changed to react to volume/display changes:
##   SoundManager  -> adjusts SFX volume
##   MusicManager  -> adjusts music volume

const SETTINGS_PATH := "user://settings.json"

signal settings_changed

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var fullscreen: bool = false

func _ready() -> void:
	load_settings()
	_apply_fullscreen()
	_apply_master_volume()

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_master_volume()
	save_settings()
	settings_changed.emit()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	save_settings()
	settings_changed.emit()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	save_settings()
	settings_changed.emit()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	save_settings()
	settings_changed.emit()

func _apply_master_volume() -> void:
	var db: float = linear_to_db(master_volume) if master_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(0, db)

func _apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func save_settings() -> void:
	var data := {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
	}
	var json_string := JSON.stringify(data, "  ")
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return

	var data: Dictionary = json.data
	if data.is_empty():
		return

	master_volume = float(data.get("master_volume", 1.0))
	music_volume = float(data.get("music_volume", 0.8))
	sfx_volume = float(data.get("sfx_volume", 0.8))
	fullscreen = bool(data.get("fullscreen", false))
