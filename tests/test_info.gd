extends SceneTree
## Headless tests for INFO: every license it names ships with its full text,
## and the engine's notices it relies on are there. Run from the project folder:
##   godot --headless --path . --script res://tests/test_info.gd
## Exit code 0 = all passed.

const InfoPanelScript := preload("res://scripts/info_panel.gd")

var _fails := 0


func _init() -> void:
	_test_license_texts()
	_test_engine_notices()
	_test_reflow()
	_test_fill()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _test_license_texts() -> void:
	var texts := Engine.get_license_info()
	for n: Array in InfoPanelScript.NOTICES:
		_check(
			texts.has(n[2]), "the text of the license of %s (%s) is in the engine" % [n[0], n[2]]
		)
	_check(not Engine.get_license_text().is_empty(), "Godot's own license")


## FreeType asks for a statement, ENet (Wi-Fi lobbies) and Mbed TLS (wss://)
## for their notices: INFO takes them from the engine.
func _test_engine_notices() -> void:
	var names := PackedStringArray()
	for component: Dictionary in Engine.get_copyright_info():
		names.append(str(component["name"]).to_lower())
	var all := " ".join(names)
	for part in ["freetype", "enet", "mbed"]:
		_check(part in all, "the engine lists %s" % part)
	var panel = InfoPanelScript.new()
	var credit: String = panel._freetype_credit()
	_check(credit.begins_with("Portions of this software are copyright © 1"), "years in: " + credit)
	panel.free()


func _test_reflow() -> void:
	var text := "First line\n  goes on.\n\nSecond\nparagraph.\n"
	_check(
		InfoPanelScript._reflow(text) == "First line goes on.\n\nSecond paragraph.",
		"lines join, paragraphs stay"
	)


func _test_fill() -> void:
	var panel = InfoPanelScript.new()
	panel._fill()
	var count: int = panel._list.get_child_count()
	_check(count > 3 * InfoPanelScript.NOTICES.size(), "INFO lists every notice (%d nodes)" % count)
	panel.free()
