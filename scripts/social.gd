class_name Social
extends Node
## Word of mouth: sharing a picture of a run, asking for a store review, and the
## page where a shared link leads.
## On phones this goes through the share sheet and the review dialog of the
## system (plugins in addons/SharePlugin and addons/InappReviewPlugin); on the
## web version through the browser's share menu. Where neither exists (desktop,
## headless tests, a browser without sharing) the game does not offer them.

## Where a shared score leads: the page with the store links and the web version.
const SITE_URL := "https://sindi98.github.io/one-more-tap/"
const SHARE_FILE := "share.png"  ## in the app's data folder, which the share plugin may read

var _share: Object  ## SharePlugin singleton, phone builds only
var _review: Object  ## InappReviewPlugin singleton, phone builds only
var _review_ready := false
var _web_share := false


func _ready() -> void:
	if Engine.has_singleton("SharePlugin") and _share_plugin_supported():
		_share = Engine.get_singleton("SharePlugin")
	if Engine.has_singleton("InappReviewPlugin"):
		_review = Engine.get_singleton("InappReviewPlugin")
		_review.connect("review_info_generated", func() -> void: _review_ready = true)
	if OS.has_feature("web"):
		_web_share = JavaScriptBridge.eval("typeof navigator.share === 'function'", true)


func can_share() -> bool:
	return _share != null or _web_share


## Opens the share sheet with the picture and a line of text (with the link).
func share(image: Image, text: String) -> void:
	if _share != null:
		var path := OS.get_user_data_dir().path_join(SHARE_FILE)
		if image.save_png(path) != OK:
			return
		var data := {
			"title": "One More Tap",
			"subject": "One More Tap",
			"content": text,
			"mime_type": "image/png",
			"file_path": path,
		}
		_share.call("share", data)
	elif _web_share:
		# Browsers that cannot share files (some desktop ones) still get the text.
		var png := Marshalls.raw_to_base64(image.save_png_to_buffer())
		var js := (
			"""
			(function (png, text) {
				var bytes = Uint8Array.from(atob(png), function (c) { return c.charCodeAt(0); });
				var file = new File([bytes], 'one-more-tap.png', {type: 'image/png'});
				var data = {text: text};
				if (navigator.canShare && navigator.canShare({files: [file]})) {
					data.files = [file];
				}
				navigator.share(data).catch(function () {});
			})(%s, %s);
			"""
			% [JSON.stringify(png), JSON.stringify(text)]
		)
		JavaScriptBridge.eval(js)


## The page with the store links (the web version's way to the app).
func open_site() -> void:
	OS.shell_open(SITE_URL)


func can_review() -> bool:
	return _review != null


## Step one, as soon as the moment is right: the store gets the review ready in
## the background.
func prepare_review() -> void:
	if _review == null:
		return
	_review_ready = false
	_review.call("generate_review_info")


## Step two, a moment later: opens the store's review dialog if step one is
## done. True when it was asked; the store still decides whether to show it
## (it keeps its own limits, a few times a year).
func launch_review() -> bool:
	if not _review_ready:
		return false
	_review_ready = false
	_review.call("launch_review_flow")
	return true


## The share plugin needs iOS 16; the game runs from iOS 15.
func _share_plugin_supported() -> bool:
	return OS.get_name() != "iOS" or OS.get_version().get_slice(".", 0).to_int() >= 16
