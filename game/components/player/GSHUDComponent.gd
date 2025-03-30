extends CanvasLayer

## [CharacterBody3D] parent.
@export var player_root: GSPlayer

var gszip: GSZip = GSZip.new("res://game/ui/ui.zip")

@onready var available_variables: Dictionary = {
	"player_speed": player_root.movement_component.speed
}

var player_speed_label_initialized: bool = false
var player_class_image_initialized: bool = false

var gszip_data: GSZipData = gszip.get_data()
var gszip_assets: GSZipAssets = gszip.get_assets()

func _ready() -> void:
	_initiate_player_speed_label()
	_initiate_player_class()

func _physics_process(delta: float) -> void:
	if player_speed_label_initialized:
		for node: Control in get_node("hud_in_game_player_speed_label").get_children():
			if node.has_meta("player_speed"):
				if node.get_meta("player_speed") == true:
					node.text = str(player_root.movement_component.speed).pad_zeros(4)

func _initiate_player_speed_label() -> void:
	if gszip.is_valid_gszip():
		var player_speed_data: Dictionary = gszip_data.get_file_data("hud_in_game_player_speed_label.json")

		var hud_in_game_player_speed_label_node: Control = Control.new()

		hud_in_game_player_speed_label_node.name = "hud_in_game_player_speed_label"

		add_child(hud_in_game_player_speed_label_node)

		hud_in_game_player_speed_label_node.set_anchors_preset(player_speed_data["root_node"]["anchor_preset"])
		hud_in_game_player_speed_label_node.position = GSTools.string_to_vector(player_speed_data["root_node"]["transform"]["position"])

		for key: String in player_speed_data["root_node"]["nodes"].keys():
			if player_speed_data["root_node"]["nodes"][key]["type"] == "label":
				var label: Label = _initiate_label(player_speed_data, key)

				if label == null:
					return

				label.set_meta("player_speed", true)
				get_node(hud_in_game_player_speed_label_node.get_path()).add_child(label)

				player_speed_label_initialized = true

func _initiate_player_class() -> void:
	if gszip.is_valid_gszip():
		var player_class_image_data: Dictionary = gszip_data.get_file_data("hud_in_game_player_class.json")

		var hud_in_game_player_class_node: Control = Control.new()

		hud_in_game_player_class_node.name = "hud_in_game_player_class"

		add_child(hud_in_game_player_class_node)

		hud_in_game_player_class_node.set_anchors_preset(player_class_image_data["root_node"]["anchor_preset"])
		hud_in_game_player_class_node.position = GSTools.string_to_vector(player_class_image_data["root_node"]["transform"]["position"])

		for key: String in player_class_image_data["root_node"]["nodes"].keys():
			if player_class_image_data["root_node"]["nodes"][key]["type"] == "label":
				var label: Label = _initiate_label(player_class_image_data, key)

				if label == null:
					return

				label.set_meta("player_speed", true)
				get_node(hud_in_game_player_class_node.get_path()).add_child(label)

				player_speed_label_initialized = true
			elif player_class_image_data["root_node"]["nodes"][key]["type"] == "image":
				var texture_rect: TextureRect = _initiate_image(player_class_image_data, key, player_class_image_data["root_node"]["nodes"][key]["image"])

				if texture_rect == null:
					return
				
				get_node(hud_in_game_player_class_node.get_path()).add_child(texture_rect)
				
				player_class_image_initialized = true

func _initiate_label(json_data: Dictionary, label_name: String) -> Label:
	var label: Label = Label.new()

	label.name = label_name

	label.text = str(GSTools.string_to_variable(json_data["root_node"]["nodes"][label_name]["variables"]["text"], available_variables))

	label.horizontal_alignment = 1
	label.vertical_alignment = 1

	label.size = GSTools.string_to_vector(json_data["root_node"]["nodes"][label_name]["variables"]["transform"]["size"])
	label.rotation = json_data["root_node"]["nodes"][label_name]["variables"]["transform"]["rotation"]

	label.add_theme_font_override("font", gszip_assets.get_font(json_data["root_node"]["nodes"][label_name]["variables"]["label_settings"]["font"]["font"]))
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
	image_texture.set_image(gszip_assets.get_image(image_name))

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
