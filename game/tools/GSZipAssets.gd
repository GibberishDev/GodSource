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

func _initiate_label(json_data: Dictionary, label_name: String, available_variables: Dictionary) -> Label:
	var label: Label = Label.new()

	label.name = label_name

	label.text = str(GSTools.string_to_variable(json_data["root_node"]["nodes"][label_name]["variables"]["text"], available_variables))

	label.horizontal_alignment = 1
	label.vertical_alignment = 1

	label.size = GSTools.string_to_vector(json_data["root_node"]["nodes"][label_name]["variables"]["transform"]["size"])
	label.rotation = json_data["root_node"]["nodes"][label_name]["variables"]["transform"]["rotation"]

	label.add_theme_font_override("font", get_font(json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["font"]["font"]))
	label.add_theme_font_size_override("font_size", json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["font"]["size"])
	label.add_theme_color_override("font_color", GSTools.string_to_color(json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["font"]["color"]))

	label.add_theme_constant_override("outline_size", json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["outline"]["size"])
	label.add_theme_color_override("font_outline_color", GSTools.string_to_color(json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["outline"]["color"]))

	label.add_theme_constant_override("shadow_outline_size", json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["shadow"]["size"])
	label.add_theme_color_override("font_shadow_color", GSTools.string_to_color(json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["shadow"]["color"]))
	label.add_theme_constant_override("shadow_offset_x", GSTools.string_to_vector(json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["shadow"]["offset"]).x)
	label.add_theme_constant_override("shadow_offset_y", GSTools.string_to_vector(json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["shadow"]["offset"]).y)

	label.set_anchors_preset(json_data["root_node"]["nodes"][label_name]["variables"]["anchor_preset"])
	label.position = GSTools.string_to_vector(json_data["root_node"]["nodes"][label_name]["variables"]["transform"]["position"])

	return label

func _initiate_image(json_data: Dictionary, key_name: String, image_name: String) -> TextureRect:
	var texture_tect: TextureRect = TextureRect.new()

	texture_tect.name = key_name

	var image_texture: ImageTexture = ImageTexture.new()
	image_texture.set_image(get_image(image_name))

	texture_tect.texture = image_texture

	texture_tect.expand_mode = json_data["root_node"]["nodes"][key_name]["variables"]["expand_mode"]
	texture_tect.stretch_mode = json_data["root_node"]["nodes"][key_name]["variables"]["stretch_mode"]
	texture_tect.flip_h = json_data["root_node"]["nodes"][key_name]["variables"]["flip_h"]
	texture_tect.flip_v = json_data["root_node"]["nodes"][key_name]["variables"]["flip_v"]

	texture_tect.size = GSTools.string_to_vector(json_data["root_node"]["nodes"][key_name]["variables"]["transform"]["size"])
	texture_tect.rotation = json_data["root_node"]["nodes"][key_name]["variables"]["transform"]["rotation"]

	texture_tect.set_anchors_preset(json_data["root_node"]["nodes"][key_name]["variables"]["anchor_preset"])
	texture_tect.position = GSTools.string_to_vector(json_data["root_node"]["nodes"][key_name]["variables"]["transform"]["position"])

	return texture_tect
