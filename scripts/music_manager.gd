extends Node
## Autoload singleton for background music with crossfade support.
##
## AUTOLOAD CONSTRAINT: Cannot reference class_name identifiers. Use load() if needed.
##
## Two AudioStreamPlayer children enable smooth crossfading between tracks.
## Reads music_volume from SettingsManager. Supports volume ducking for pause menu.
##
## Usage:
##   MusicManager.play_track("menu_theme")
##   MusicManager.play_track("gameplay_theme")   -- crossfades from current
##   MusicManager.stop()                          -- fade out
##   MusicManager.set_volume_multiplier(0.5)      -- duck for pause

const CROSSFADE_DURATION := 1.0
const FADE_OUT_DURATION := 0.5
const BASE_VOLUME_DB := -6.0

const TRACK_PATHS: Dictionary = {
	"menu_theme": "res://assets/music/menu_theme.ogg",
	"gameplay_theme": "res://assets/music/gameplay_theme.ogg",
}

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _current_player: AudioStreamPlayer = null
var _current_track: String = ""
var _volume_multiplier: float = 1.0
var _crossfade_tween: Tween = null

func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.volume_db = -80.0
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.volume_db = -80.0
	add_child(_player_b)

	# Connect to SettingsManager for music volume changes
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		settings.settings_changed.connect(_on_settings_changed)

func play_track(track_name: String) -> void:
	if track_name == _current_track:
		return
	if not TRACK_PATHS.has(track_name):
		return

	var path: String = TRACK_PATHS[track_name]
	if not ResourceLoader.exists(path):
		return

	var stream = load(path)
	if stream == null:
		return

	# Pick the other player for crossfade
	var new_player: AudioStreamPlayer
	if _current_player == _player_a:
		new_player = _player_b
	else:
		new_player = _player_a

	# Kill any existing crossfade
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	# Set up the new player
	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.play()

	var target_db := _get_target_db()

	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)

	# Fade in new player
	_crossfade_tween.tween_property(new_player, "volume_db", target_db, CROSSFADE_DURATION)

	# Fade out old player (if playing)
	if _current_player != null and _current_player.playing:
		_crossfade_tween.tween_property(_current_player, "volume_db", -80.0, CROSSFADE_DURATION)
		var old_player := _current_player
		_crossfade_tween.set_parallel(false)
		_crossfade_tween.tween_callback(old_player.stop)

	_current_player = new_player
	_current_track = track_name

func stop() -> void:
	if _current_player == null or not _current_player.playing:
		_current_track = ""
		return

	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	var player := _current_player
	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(player, "volume_db", -80.0, FADE_OUT_DURATION)
	_crossfade_tween.tween_callback(player.stop)

	_current_player = null
	_current_track = ""

func set_volume_multiplier(mult: float) -> void:
	_volume_multiplier = clampf(mult, 0.0, 1.0)
	_apply_volume()

func _get_target_db() -> float:
	var settings = get_node_or_null("/root/SettingsManager")
	var music_vol: float = settings.music_volume if settings else 0.8
	var combined: float = music_vol * _volume_multiplier
	if combined <= 0.0:
		return -80.0
	return linear_to_db(combined) + BASE_VOLUME_DB

func _apply_volume() -> void:
	if _current_player != null and _current_player.playing:
		var target_db := _get_target_db()
		# Smooth transition over 0.3s
		var tween := create_tween()
		tween.tween_property(_current_player, "volume_db", target_db, 0.3)

func _on_settings_changed() -> void:
	_apply_volume()
