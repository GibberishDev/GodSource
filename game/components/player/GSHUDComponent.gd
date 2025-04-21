extends CanvasLayer

@export var player_root: GSPlayer

var gszip: GSZip = GSZip.new("res://game/ui/ui.zip")

@onready var available_variables: Dictionary = {}

var player_speed_label_initialized: bool = false
var player_class_image_initialized: bool = false

var gszip_data: GSZipData = gszip.get_data()
var gszip_assets: GSZipAssets = gszip.get_assets()

func _ready() -> void:
	_initiate_player_speed_label()
	_initiate_player_class()

func _physics_process(delta: float) -> void:
	available_variables = {
		"player_speed": int(player_root.get_velocity().length() * 100 / 1.905)
	}

	if player_speed_label_initialized:
		for node: Control in get_node("hud_in_game_player_speed_label").get_children():
			if node.has_meta("player_speed"):
				if node.get_meta("player_speed") == true:
					node.text = str(available_variables["player_speed"]).pad_zeros(4)

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
				var label: Label = gszip_assets._initiate_label(player_speed_data, key, available_variables)

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
				var label: Label = gszip_assets._initiate_label(player_class_image_data, key, available_variables)

				if label == null:
					return

				label.set_meta("player_speed", true)
				get_node(hud_in_game_player_class_node.get_path()).add_child(label)

				player_speed_label_initialized = true
			elif player_class_image_data["root_node"]["nodes"][key]["type"] == "image":
				var texture_rect: TextureRect = gszip_assets._initiate_image(player_class_image_data, key, player_class_image_data["root_node"]["nodes"][key]["image"])

				if texture_rect == null:
					return
				
				get_node(hud_in_game_player_class_node.get_path()).add_child(texture_rect)
				
				player_class_image_initialized = true
