extends Node

# Native sharing helper used directly by the SUNK screen Share button.
# Keeping the Android Intent logic here avoids intercepting/re-wiring the UI button.

func share_text(message: String) -> String:
	if OS.get_name() == "Android":
		var result: String = _share_android(message)
		if result == "ok":
			return result
		DisplayServer.clipboard_set(message)
		return result

	DisplayServer.clipboard_set(message)
	return "clipboard"

func _share_android(message: String) -> String:
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		push_error("Pirate's Plunder share: AndroidRuntime unavailable")
		return "AndroidRuntime unavailable"

	var activity: Variant = android_runtime.getActivity()
	if activity == null:
		push_error("Pirate's Plunder share: Android Activity unavailable")
		return "Android Activity unavailable"

	var Intent: Variant = JavaClassWrapper.wrap("android.content.Intent")
	if Intent == null:
		push_error("Pirate's Plunder share: Intent class unavailable")
		return "Intent unavailable"

	var intent: Variant = Intent.Intent()
	if intent == null:
		push_error("Pirate's Plunder share: could not create Intent")
		return "Could not create share Intent"

	intent.setAction(Intent.ACTION_SEND)
	intent.putExtra(Intent.EXTRA_TEXT, message)
	intent.setType("text/plain")
	activity.startActivity(intent)

	var exception: Variant = JavaClassWrapper.get_exception()
	if exception != null:
		push_error("Pirate's Plunder share: Android Intent failed: %s" % str(exception))
		return "Android share failed"

	return "ok"
