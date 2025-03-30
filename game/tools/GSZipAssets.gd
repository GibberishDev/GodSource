extends Resource
class_name GSZipAssets

var files: Array
var zip_path_file: String

func _init(data_zip_path_file: String, assets_files: PackedStringArray) -> void:
	zip_path_file = data_zip_path_file
	files = assets_files

func get_font(file_name: String) -> Variant:
	if files.has("assets/" + file_name):
		var reader: ZIPReader = ZIPReader.new()
		var error: Error = reader.open(zip_path_file)

		if error != OK:
			reader.close()
			return null

		if (file_name.ends_with(".ttf") or file_name.ends_with(".otf") or file_name.ends_with(".woff") or file_name.ends_with(".woff2") or file_name.ends_with(".pfb") or file_name.ends_with(".pfm")):
			var font_data: PackedByteArray = reader.read_file("assets/" + file_name)

			reader.close()

			if font_data.is_empty():
				return null

			var font_file: FontFile = FontFile.new()
			font_file.data = font_data

			return font_file

		reader.close()

	return null

func get_image(file_name: String) -> Variant:
	if files.has("assets/" + file_name):
		var reader: ZIPReader = ZIPReader.new()
		var error: Error = reader.open(zip_path_file)

		if error != OK:
			reader.close()
			return null

		if (file_name.ends_with(".png") or file_name.ends_with(".bmp") or file_name.ends_with(".jpg") or file_name.ends_with(".jpeg") or file_name.ends_with(".tga") or file_name.ends_with(".svg") or file_name.ends_with(".webp")):
			var image_data: PackedByteArray = reader.read_file("assets/" + file_name)

			reader.close()

			if image_data.is_empty():
				return null

			var image_file: Image = Image.new()
			image_file.load_png_from_buffer(image_data)

			return image_file

		reader.close()

	return null
