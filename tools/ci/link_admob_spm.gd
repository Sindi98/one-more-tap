extends SceneTree
## Links the AdMob Swift package (Google Mobile Ads) into an exported Xcode project.
## The plugin does it one frame after the export, which a command-line export
## never reaches: Godot quits first and the project builds without the SDK.
## Same code as the plugin, safe to run twice. From the project folder:
##   godot --headless --path . --script res://tools/ci/link_admob_spm.gd -- <path to project.pbxproj>

const PbxprojService := preload("res://addons/admob/internal/services/pbxproj_service.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not FileAccess.file_exists(args[0]):
		printerr("usage: -- <path to project.pbxproj>")
		quit(1)
		return
	var package := args[0].get_base_dir().get_base_dir().path_join("admob_spm/Package.swift")
	if not FileAccess.file_exists(package):
		printerr("admob_spm/Package.swift not found next to the Xcode project: export with the AdMob iOS plugin installed")
		quit(1)
		return
	PbxprojService.patch(args[0])
	var linked := FileAccess.get_file_as_string(args[0]).contains("PoingGodotAdMobDeps in Frameworks")
	if not linked:
		printerr("AdMob Swift package not linked in ", args[0])
	quit(0 if linked else 1)
