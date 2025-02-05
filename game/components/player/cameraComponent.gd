##[b][color=#f0b000]!!! IMPORTANT !!![/color] - This component requires to be a child of [CharacterBody3D] to function properly[b][br][br]
##This component listens to user inputs to move parent node in 3D space. All default values aren an example implementation and are converted from TF2 and correspond to default movement of Soldier
extends Node3D

## [CharacterBody3D] parent.
@onready
var P : CharacterBody3D = get_node("..")
@onready
var mvtComp : PlayerGSMvtComp = P.get_node("GSMvtComp")


@export_subgroup("Camera Settings")
@export
var cameraVewheight : float = 68*1.905/100
@export
var cameraDuckViewheght : float = 45*1.905/100
@export
var cameraZoomAbility : bool = true
@export_range(20.0,180.0,0.1)
var cameraZoomFOV : float = 90

var mouseCaptured : bool = false
var mousePosPreCapture : Vector2 = Vector2.ZERO

#global var
var lookDir : Vector3 = Vector3.ZERO

#settings var
var sensX : float = 0.0015
var sensY : float = 0.0015

#state var
var camSavedPos = null

func _physics_process(delta: float) -> void:
	smoothCamera(delta)
	$vis.rotation.y = getCamRot().y + deg_to_rad(90)
	var wDir : Vector3 = mvtComp.wDir
	%flForwardMove.scale.z = wDir.x
	%flUpMove.scale.y = wDir.y
	%flSideMove.scale.x = -wDir.z

func togglePointerLock() -> void:
	if mouseCaptured:
		releasePointer()
	else:
		grabPointer()


func grabPointer() -> void:
	mousePosPreCapture = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouseCaptured = true

func releasePointer() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouseCaptured = false
	Input.warp_mouse(mousePosPreCapture)

func _ready() -> void:
	grabPointer()
	$vis.visible = showAxis

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouseCaptured:
		firstPersonCamera(event)
	if Input.is_action_just_pressed("ui_cancel"):#TODO change to ESC input action
		togglePointerLock()

func firstPersonCamera(e: InputEventMouseMotion) -> void:
	$head.rotation.y -= e.screen_relative.x * sensX
	$head/camSmoother/cam.rotation.x = clamp($head/camSmoother/cam.rotation.x - e.screen_relative.y * sensY, -deg_to_rad(89), deg_to_rad(89))
	lookDir = Vector3($head/camSmoother/cam.rotation.x, $head.rotation.y, 0)

func saveCamPos() -> void:
	if camSavedPos == null:
		camSavedPos = $head/camSmoother.global_position

func smoothCamera(delta:float) -> void:
	if camSavedPos == null: return
	$head/camSmoother.global_position.y = camSavedPos.y
	$head/camSmoother.position.y = clampf($head/camSmoother.position.y, -.5, .5)
	var moveAmt = max(P.velocity.length() * delta, P.get_node("GSMvtComp").groundMaxSpeed * P.get_node("GSMvtComp").getSpeedMult() / 2 * delta)
	$head/camSmoother.position.y = move_toward($head/camSmoother.position.y, 0.0, moveAmt)
	camSavedPos = $head/camSmoother.global_position
	if $head/camSmoother.position.y == .0:
		camSavedPos = null

func crouch() -> void:
	saveCamPos()
	$head.position.y = cameraDuckViewheght

func uncrouch() -> void:
	saveCamPos()
	$head.position.y = cameraVewheight

func getCamRot() -> Vector3:
	return $head/camSmoother/cam.global_rotation

func getCamDir() -> Vector3:
	var dir : Vector3 = Vector3(0, 0, -1.0).rotated(Vector3.RIGHT, getCamRot().x).rotated(Vector3.UP,getCamRot().y)
	return dir.normalized()

@export
var showAxis := bool(false)
