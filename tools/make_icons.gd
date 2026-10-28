extends SceneTree
## Renders the app icons (PNG) from the SVG sources in assets/icons.
## Run from the project folder after changing an SVG:
##   godot --headless --path . --script res://tools/make_icons.gd

const DIR := "res://assets/icons/"
## source SVG -> [output PNG, size in px]
const ICONS := [
	["icon_full.svg", "icon_1024.png", 1024],  # iOS App Store icon
	["icon_full.svg", "icon_store_512.png", 512],  # Google Play listing icon
	["../../icon.svg", "icon_192.png", 192],  # Android legacy launcher icon
	["icon_foreground.svg", "adaptive_foreground_432.png", 432],
	["icon_background.svg", "adaptive_background_432.png", 432],
	["icon_monochrome.svg", "adaptive_monochrome_432.png", 432],
]


func _init() -> void:
	var failed := false
	for item in ICONS:
		var svg := FileAccess.get_file_as_string(DIR + item[0])
		var img := Image.new()
		var size: int = item[2]
		var probe := Image.new()
		if svg == "" or probe.load_svg_from_string(svg, 1.0) != OK:
			printerr("cannot read ", item[0])
			failed = true
			continue
		img.load_svg_from_string(svg, float(size) / probe.get_width())
		if item[0] == "icon_full.svg":
			img.convert(Image.FORMAT_RGB8)  # the App Store rejects icons with alpha
		img.save_png(DIR + item[1])
		print("%s -> %s (%dx%d)" % [item[0], item[1], img.get_width(), img.get_height()])
	quit(1 if failed else 0)
