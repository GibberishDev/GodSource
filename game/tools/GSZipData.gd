extends Resource
class_name GSZipData

var files: Array
var zip_path_file: String

func _init(data_zip_path_file: String, data_files: PackedStringArray) -> void:
	zip_path_file = data_zip_path_file
	files = data_files

func get_count_files() -> int:
	return files.size()

func get_file_data(file_name: String) -> Dictionary:
	if files.has("data/" + file_name):
		var reader: ZIPReader = ZIPReader.new()
		var error: Error = reader.open(zip_path_file)

		if error != OK:
			return Dictionary()

		var resource: PackedByteArray = reader.read_file("data/" + file_name)
		var resource_as_text: String = resource.get_string_from_ascii()
		var resource_as_dictionary: Dictionary = JSON.parse_string(resource_as_text)

		reader.close()

		return resource_as_dictionary

	return Dictionary()
