extends Resource
class_name GSZipManifest

var manifest: Dictionary

func _init(manifest_file: Dictionary) -> void:
	manifest = manifest_file

func is_valid_manifest() -> bool:
	if !manifest.has_all(["author", "package_name", "package_type", "package_version"]):
		return false
	return true

func get_package_author() -> String:
	if !manifest.has("author"):
		return String()
	return manifest["author"]

func get_package_version() -> String:
	if !manifest.has("package_version"):
		return String()
	return manifest["package_version"]

func get_package_name() -> String:
	if !manifest.has("package_name"):
		return String()
	return manifest["package_name"]

func get_package_type() -> String:
	if !manifest.has("package_type"):
		return String()
	return manifest["package_type"]
