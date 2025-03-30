extends Resource
class_name GSZip

var zip_path_file: String
var zip_path: String
var zip_name: String

func _init(path_file: String) -> void:
	zip_path_file = path_file
	zip_path = zip_path_file.get_base_dir()
	zip_name = zip_path_file.get_file()

func is_valid_file_path() -> bool:
	if !zip_path.is_absolute_path():
		return false

	if !zip_name.is_valid_filename():
		return false

	if !zip_name.ends_with(".zip"):
		return false

	return true

func is_valid_gszip() -> bool:
	if !is_valid_file_path():
		return false

	var reader: ZIPReader = ZIPReader.new()
	var error: Error = reader.open(zip_path_file)

	if error != OK:
		reader.close()
		return false

	if !reader.file_exists("manifest.json"):
		reader.close()
		return false
	else:
		var manifest_resource: PackedByteArray = reader.read_file("manifest.json")
		var manifest_resource_as_text: String = manifest_resource.get_string_from_ascii()
		var manifest_resource_dictionary: Dictionary = JSON.parse_string(manifest_resource_as_text)

		if !manifest_resource_dictionary.has_all(["author", "package_name", "package_type", "package_version"]):
			reader.close()
			return false

	reader.close()

	return true

func get_manifest() -> GSZipManifest:
	if is_valid_gszip():
		var reader: ZIPReader = ZIPReader.new()
		var error: Error = reader.open(zip_path_file)

		if error != OK:
			reader.close()
			return GSZipManifest.new(Dictionary())

		var manifest_resource: PackedByteArray = reader.read_file("manifest.json")
		var manifest_resource_as_text: String = manifest_resource.get_string_from_ascii()
		var manifest_resource_dictionary: Dictionary = JSON.parse_string(manifest_resource_as_text)
		
		return GSZipManifest.new(manifest_resource_dictionary)

	return GSZipManifest.new(Dictionary())

func get_data() -> GSZipData:
	if is_valid_gszip():
		var files: Array = []

		var reader: ZIPReader = ZIPReader.new()
		var error: Error = reader.open(zip_path_file)

		if error != OK:
			reader.close()
			return GSZipData.new(String(), PackedStringArray())

		files = reader.get_files()
		files = files.filter(func(item: String) -> bool: return item.begins_with("data/") and item != "data/")

		reader.close()

		return GSZipData.new(zip_path_file, files)

	return GSZipData.new(String(), PackedStringArray())

func get_assets() -> GSZipAssets:
	if is_valid_gszip():
		var files: Array = []

		var reader: ZIPReader = ZIPReader.new()
		var error: Error = reader.open(zip_path_file)

		if error != OK:
			reader.close()
			return GSZipAssets.new(String(), PackedStringArray())

		files = reader.get_files()
		files = files.filter(func(item: String) -> bool: return item.begins_with("assets/") and item != "assets/")

		reader.close()

		return GSZipAssets.new(zip_path_file, files)

	return GSZipAssets.new(String(), PackedStringArray())
