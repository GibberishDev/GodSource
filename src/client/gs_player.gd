extends CharacterBody3D

#multiplayer vars
var peer_id : int

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_move : Vector2 = event.relative
		self.rotate_y(-mouse_move.x * 0.003)
		get_node("Camera3D").rotate(Vector3.LEFT, mouse_move.y * 0.003)
		get_node("Camera3D").rotation.x = clamp(get_node("Camera3D").rotation.x, -PI / 2, PI / 2)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("flashlight"):
		get_node("Camera3D/SpotLight3D").visible = !get_node("Camera3D/SpotLight3D").visible
func _physics_process(delta: float) -> void:
	# Add the gravity.
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction : Vector2 = get_node("PlayerInput").get_movement_wish_direction()
	direction = direction.normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
	
	get_node("Camera3D/Control/Label").text = "[color=red]" + str(self.position.x) + "[/color]"
