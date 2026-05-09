extends Control
@onready
var player : GSPlayer = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var wish_text : String = ""
	wish_text += "smove: " + str(player.get_wish_direction().x)
	wish_text += "\nfmove: " + str(player.get_wish_direction().y)
	wish_text += "\nin air: " + str(player.is_airborne)
	wish_text += "\nair control amount: " + str(player.test)
	$wishess.text = wish_text
