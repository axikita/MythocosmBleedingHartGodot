extends Node3D

var Focus
@export var MotionEnabled = true
@export var camSpeedSensitivityVert = 5
@export var camSpeedSensitivityHoriz = 5
@export var camVertMin = -10
@export var camVertMax = 60
var sensModifier = 0.05


@onready var rig_hRot_Center = get_node(".")
@onready var rig_vRot_Center = get_node("CameraRigTarget")

# Called when the node enters the scene tree for the first time.
func _ready():
	if MotionEnabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	Focus = get_tree().get_nodes_in_group("Player")[0]
	if Focus == null:
		Focus = get_tree().current_scene
		push_error("CameraRig could not find Player. Check that the player character is present, and within the \"Player\" group.")

func _input(event):
	if MotionEnabled:
		if event is InputEventMouseMotion:
			var tempRotationVert = rig_vRot_Center.get_rotation_degrees().x - event.relative.y*camSpeedSensitivityVert*sensModifier
			var tempRotationHoriz = rig_hRot_Center.get_rotation_degrees().y - event.relative.x*camSpeedSensitivityHoriz*sensModifier
			tempRotationVert = clamp(tempRotationVert, -camVertMax, -camVertMin)
			rig_vRot_Center.rotation.x = deg_to_rad(tempRotationVert)
			
			rig_hRot_Center.rotation.y = deg_to_rad(tempRotationHoriz)
			
			
			
		if event.is_action_pressed("LeftClick"):
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				
				
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	global_position = Focus.global_position
	

