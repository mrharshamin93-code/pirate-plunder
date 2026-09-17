extends Node

# Firebase Analytics bridge for Pirate's Plunder.
# Safe on desktop/editor builds: events are only uploaded when an Android
# Firebase Analytics singleton is available.

const FIREBASE_PROJECT_ID := "pirate-s-plunder-98456"
const FIREBASE_PROJECT_NUMBER := "525487780435"
const SCORE_MILESTONES := [100, 250, 500, 1000, 2500, 5000, 10000]
const SHIP_NAMES := ["Regular Ship", "Crimson Raider", "Black Pearl", "Royal Fortune", "Ghost Ship", "Inferno", "Sea Serpent", "Golden Galleon"]
const SHIP_UNLOCKS := [0, 500, 1000, 2000, 3500, 5000, 7500, 10000]
const MINE_NAMES := ["Standard", "Rusty", "Camo", "Danger", "Ice", "Gold", "Skull", "Electric", "Lava", "Void"]
const MINE_UNLOCKS := [0, 500, 1000, 1500, 2000, 3000, 4000, 5000, 7500, 10000]

var _analytics: Object = null
var _ready_for_events := false
var _last_game_started := false
var _last_game_over := false
var _last_collectibles_visible := false
var _last_selected_ship := -1
var _last_score := 0
var _game_started_at_ms := 0
var _games_started := 0
var _milestones_sent: Dictionary = {}
var _previous_personal_best := 0
var _last_share_msec_seen := 0
var _leaderboard_submit_pending := false
var _leaderboard_submit_score := 0

func _ready() -> void:
	_analytics = _find_analytics_singleton()
	_ready_for_events = _analytics != null
	_previous_personal_best = _read_personal_best()
	if _ready_for_events:
		print("[ANALYTICS] Firebase Analytics bridge connected")
		log_event("app_open", {"source": "godot"})
	else:
		print("[ANALYTICS] Firebase Analytics native plugin not found; events will not be uploaded on this build")
	set_process(true)

func _process(_delta: float) -> void:
	_track_game_state()
	_track_collectibles_state()
	_track_sunk_actions()

func analytics_is_connected() -> bool:
	return _ready_for_events

func log_event(event_name: String, params: Dictionary = {}) -> void:
	if event_name.is_empty() or not _ready_for_events or _analytics == null:
		return
	if _analytics.has_method("log_event"):
		_analytics.call("log_event", event_name, params)
	elif _analytics.has_method("logEvent"):
		_analytics.call("logEvent", event_name, params)
	elif _analytics.has_method("send_event"):
		_analytics.call("send_event", event_name, params)
	elif _analytics.has_method("analytics_send_events"):
		_analytics.call("analytics_send_events", event_name, params)

func track(event_name: String, params: Dictionary = {}) -> void:
	log_event(event_name, params)

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
		_last_score = 0
		return

	var started := bool(started_value)
	var over := bool(over_value)
	var score_value: Variant = scene.get("score")
	var current_score := int(score_value) if score_value != null else 0

	if started and not _last_game_started:
		_games_started += 1
		_game_started_at_ms = Time.get_ticks_msec()
		_last_score = 0
		_milestones_sent.clear()
		_previous_personal_best = _read_personal_best()
		log_event("game_start", {"ship": _selected_ship_name(), "game_number": _games_started})
		if _games_started > 1:
			log_event("play_again", {"previous_game_completed": true})

	if started and not over:
		_track_score_milestones(current_score)

	if over and not _last_game_over:
		var coins_value: Variant = scene.get("coins_collected")
		var duration_seconds := 0.0
		if _game_started_at_ms > 0:
			duration_seconds = maxf(0.0, float(Time.get_ticks_msec() - _game_started_at_ms) / 1000.0)
		log_event("game_over", {
			"score": current_score,
			"coins_collected": int(coins_value) if coins_value != null else 0,
			"duration_seconds": duration_seconds,
			"ship": _selected_ship_name()
		})
		_track_new_unlocks(_previous_personal_best, current_score)

	_last_score = current_score
	_last_game_started = started
	_last_game_over = over

func _track_score_milestones(current_score: int) -> void:
	for milestone in SCORE_MILESTONES:
		if current_score >= milestone and _last_score < milestone and not _milestones_sent.has(milestone):
			_milestones_sent[milestone] = true
			log_event("score_milestone", {"milestone": milestone, "score": current_score, "ship": _selected_ship_name()})

func _track_new_unlocks(old_best: int, run_score: int) -> void:
	var new_best := maxi(old_best, run_score)
	if new_best <= old_best:
		return
	for i in range(1, SHIP_UNLOCKS.size()):
		var requirement: int = SHIP_UNLOCKS[i]
		if old_best < requirement and new_best >= requirement:
			track_collectible_unlocked("ship", SHIP_NAMES[i], requirement)
	for i in range(1, MINE_UNLOCKS.size()):
		var requirement: int = MINE_UNLOCKS[i]
		if old_best < requirement and new_best >= requirement:
			track_collectible_unlocked("mine", MINE_NAMES[i], requirement)

func _track_collectibles_state() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var overlay := scene.find_child("ExactCollectibles", true, false)
	if overlay == null:
		overlay = scene.find_child("CollectiblesPanel", true, false)
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

func _track_sunk_actions() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var sunk := scene.find_child("SunkPanel", true, false)
	if sunk == null:
		return

	var share_value: Variant = sunk.get("last_share_msec")
	if share_value != null:
		var share_msec := int(share_value)
		if share_msec > 0 and share_msec != _last_share_msec_seen:
			_last_share_msec_seen = share_msec
			track_share("sunk_screen")

	var pending_value: Variant = sunk.get("pending_action")
	var submitted_score_value: Variant = sunk.get("submitted_score")
	if pending_value == null:
		return
	var pending := String(pending_value)
	if pending == "submit" and not _leaderboard_submit_pending:
		_leaderboard_submit_pending = true
		_leaderboard_submit_score = int(submitted_score_value) if submitted_score_value != null else 0
	elif _leaderboard_submit_pending and pending != "submit":
		var footer := sunk.find_child("Footer", true, false) as Label
		var success := footer != null and footer.text.begins_with("Score submitted!")
		track_leaderboard_submit(_leaderboard_submit_score, success)
		_leaderboard_submit_pending = false
		_leaderboard_submit_score = 0

func track_share(source: String = "game") -> void:
	log_event("share_clicked", {"source": source})

func track_leaderboard_submit(score: int, success: bool = true) -> void:
	log_event("leaderboard_submit", {"score": score, "success": success})

func track_collectible_unlocked(item_type: String, item_name: String, requirement: int = 0) -> void:
	log_event("collectible_unlocked", {"item_type": item_type, "item_name": item_name, "requirement": requirement})

func _read_personal_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load("user://leaderboard.cfg") == OK:
		return maxi(0, int(cfg.get_value("player", "personal_best", 0)))
	return 0

func _selected_ship_name() -> String:
	var collectibles := get_node_or_null("/root/BoatCollectibles")
	if collectibles != null and collectibles.has_method("get_selected_name"):
		return String(collectibles.call("get_selected_name"))
	return "unknown"

func _find_analytics_singleton() -> Object:
	var candidates := ["GodotFirebaseAnalytics", "FirebaseAnalyticsPlugin", "FirebaseAnalytics", "Firebase", "Firebase.Analytics"]
	for singleton_name in candidates:
		if Engine.has_singleton(singleton_name):
			return Engine.get_singleton(singleton_name)
	return null
