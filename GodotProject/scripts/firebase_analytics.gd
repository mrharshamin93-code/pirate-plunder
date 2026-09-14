extends Node

# Firebase Analytics bridge for Pirate's Plunder.
# Safe on desktop/editor builds: events are only uploaded when an Android
# Firebase Analytics singleton is available.

const FIREBASE_PROJECT_ID := "pirate-s-plunder-98456"
const FIREBASE_PROJECT_NUMBER := "525487780435"

var _analytics: Object = null
var _ready_for_events := false
var _last_game_started := false
var _last_game_over := false
var _last_collectibles_visible := false
var _last_selected_ship := -1

func _ready() -> void:
	_analytics = _find_analytics_singleton()
	_ready_for_events = _analytics != null
	if _ready_for_events:
		print("[ANALYTICS] Firebase Analytics bridge connected")
		log_event("app_open", {"source": "godot"})
	else:
		print("[ANALYTICS] Firebase Analytics native plugin not found; events will not be uploaded on this build")
	set_process(true)

func _process(_delta: float) -> void:
	_track_game_state()
	_track_collectibles_state()

func is_connected() -> bool:
	return _ready_for_events

func log_event(event_name: String, params: Dictionary = {}) -> void:
	if event_name.is_empty():
		return
	if not _ready_for_events or _analytics == null:
		return

	if _analytics.has_method("log_event"):
		_analytics.call("log_event", event_name, params)
	elif _analytics.has_method("logEvent"):
		_analytics.call("logEvent", event_name, params)
	elif _analytics.has_method("send_event"):
		_analytics.call("send_event", event_name, params)
	elif _analytics.has_method("analytics_send_events"):
		_analytics.call("analytics_send_events", event_name, params)

func set_user_property(property_name: String, value: String) -> void:
	if not _ready_for_events or _analytics == null:
		return
	if _analytics.has_method("set_user_property"):
		_analytics.call("set_user_property", property_name, value)
	elif _analytics.has_method("setUserProperty"):
		_analytics.call("setUserProperty", property_name, value)

func _track_game_state() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var started_value: Variant = scene.get("game_started")
	var over_value: Variant = scene.get("game_over")
	if started_value == null or over_value == null:
		_last_game_started = false
		_last_game_over = false
		return

	var started := bool(started_value)
	var over := bool(over_value)
	if started and not _last_game_started:
		log_event("game_start", {
			"ship": _selected_ship_name()
		})
	if over and not _last_game_over:
		var score_value: Variant = scene.get("score")
		var coins_value: Variant = scene.get("coins_collected")
		log_event("game_over", {
			"score": int(score_value) if score_value != null else 0,
			"coins_collected": int(coins_value) if coins_value != null else 0,
			"ship": _selected_ship_name()
		})

	_last_game_started = started
	_last_game_over = over

func _track_collectibles_state() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var overlay := scene.find_child("ExactCollectibles", true, false)
	var visible := overlay != null and overlay is CanvasItem and (overlay as CanvasItem).visible
	if visible and not _last_collectibles_visible:
		log_event("collectibles_open", {})
	_last_collectibles_visible = visible

	var collectibles := get_node_or_null("/root/BoatCollectibles")
	if collectibles == null or not collectibles.has_method("get_selected_index"):
		return
	var selected := int(collectibles.call("get_selected_index"))
	if _last_selected_ship == -1:
		_last_selected_ship = selected
		set_user_property("selected_ship", _selected_ship_name())
	elif selected != _last_selected_ship:
		_last_selected_ship = selected
		var ship_name := _selected_ship_name()
		set_user_property("selected_ship", ship_name)
		log_event("ship_equipped", {"ship": ship_name, "ship_index": selected})

func _selected_ship_name() -> String:
	var collectibles := get_node_or_null("/root/BoatCollectibles")
	if collectibles != null and collectibles.has_method("get_selected_name"):
		return String(collectibles.call("get_selected_name"))
	return "unknown"

func _find_analytics_singleton() -> Object:
	var candidates := [
		"GodotFirebaseAnalytics",
		"FirebaseAnalyticsPlugin",
		"FirebaseAnalytics",
		"Firebase",
		"Firebase.Analytics"
	]
	for singleton_name in candidates:
		if Engine.has_singleton(singleton_name):
			return Engine.get_singleton(singleton_name)
	return null
