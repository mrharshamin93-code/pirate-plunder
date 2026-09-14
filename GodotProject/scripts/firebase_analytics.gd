extends Node

# Firebase Analytics bridge for Pirate's Plunder.
# This script is safe to keep enabled on desktop: it only sends events when a
# compatible Android Firebase Analytics singleton is present.

const FIREBASE_PROJECT_ID := "pirate-s-plunder-98456"
const FIREBASE_PROJECT_NUMBER := "525487780435"

var _analytics: Object = null
var _ready_for_events := false

func _ready() -> void:
	_analytics = _find_analytics_singleton()
	_ready_for_events = _analytics != null
	if _ready_for_events:
		print("[ANALYTICS] Firebase Analytics bridge connected")
		log_event("app_open", {"source": "godot"})
	else:
		print("[ANALYTICS] Firebase Analytics native plugin not found; events will not be uploaded on this build")

func is_connected() -> bool:
	return _ready_for_events

func log_event(event_name: String, params: Dictionary = {}) -> void:
	if event_name.is_empty():
		return
	if not _ready_for_events or _analytics == null:
		return

	# Different Godot Firebase Android plugins expose slightly different names.
	# Support the common variants so the game-side analytics code does not need
	# to change if the plugin implementation changes.
	if _analytics.has_method("log_event"):
		_analytics.call("log_event", event_name, params)
	elif _analytics.has_method("logEvent"):
		_analytics.call("logEvent", event_name, params)
	elif _analytics.has_method("send_event"):
		_analytics.call("send_event", event_name, params)

func set_user_property(property_name: String, value: String) -> void:
	if not _ready_for_events or _analytics == null:
		return
	if _analytics.has_method("set_user_property"):
		_analytics.call("set_user_property", property_name, value)
	elif _analytics.has_method("setUserProperty"):
		_analytics.call("setUserProperty", property_name, value)

func _find_analytics_singleton() -> Object:
	var candidates := [
		"FirebaseAnalytics",
		"Firebase.Analytics",
		"FirebaseAnalyticsPlugin",
		"GodotFirebaseAnalytics"
	]
	for singleton_name in candidates:
		if Engine.has_singleton(singleton_name):
			return Engine.get_singleton(singleton_name)
	return null
