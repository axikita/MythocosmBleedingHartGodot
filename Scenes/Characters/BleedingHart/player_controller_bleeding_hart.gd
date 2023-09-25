extends CharacterBody3D

@export var speed = 5.0
var turnSpeed = 0.1
var turnSpeedAirborne = 0.05
@export var jumpVelocity = 4.5
@export var jumpInputDecay = .5
var AirMoveAccel = 100.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var camRoot : Node #assigned in _ready, used for input coordinate transformation

@onready var meshRoot = get_node("BleedingHart")
@onready var animr : AnimationTree = get_node("BleedingHart/AnimationTree")

var animGrounded : bool = true
var animSpeed : float = 0.0
var animVertSpeed : float = 0.0
var animTurnSpeed : float = 0.0

var lastJumpTime : int = -10000
var was_on_ground = false
var jumpLatch = false
var jumpBufferStart = -1000
var jumpBufferWindow = 150

var animTurnSaved : float

func _ready():
	camRoot = get_tree().get_nodes_in_group("CameraRoot")[0]
	if camRoot == null:
		camRoot = get_tree().current_scene
	print(turnSpeedAirborne)

func _process(_delta):
	#raw speed
	if animSpeed>0.2:
		animr.set("parameters/conditions/Run", true)
		animr.set("parameters/conditions/Still", false)
	else: 
		animr.set("parameters/conditions/Run", false)
		animr.set("parameters/conditions/Still", true)
	
	if animGrounded:
		animr.set("parameters/conditions/Landed", true)
		animr.set("parameters/conditions/Airborne", false)
		#print("grounded")
	else:
		animr.set("parameters/conditions/Landed", false)
		animr.set("parameters/conditions/Airborne", true)
		animr.set("parameters/Airborne_BlendTree/Blend2/blend_amount", (clamp(animVertSpeed*.2,-1,1)+1)*0.5)
		#print("airborne")
	
	animr.set("parameters/Run_BlendTree/Blend3/blend_amount", clamp(animTurnSpeed,-1,1))
	#print(animTurnSpeed)
		


func _physics_process(delta):
	
	#input handling
	##fetch keyboard and joystick input and combine them according to loudest input component
	var key_input_dir : Vector2 = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	var joy_input_dir : Vector2 = Input.get_vector("LJoyLeft", "LJoyRight", "LJoyUp", "LJoyDown")
	var input_dir = key_input_dir
	if(joy_input_dir.x*joy_input_dir.x > key_input_dir.x*key_input_dir.x):
		input_dir.x = joy_input_dir.x
	if(joy_input_dir.y*joy_input_dir.y > key_input_dir.y*key_input_dir.y):
		input_dir.y = joy_input_dir.y
	
	var target_direction : Vector3 = (camRoot.transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	#cap at 1 but allow smaller inputs
	if target_direction.length_squared()>1:
		target_direction = target_direction.normalized()
	
	var currentDirection = transform.basis * Vector3.FORWARD
	var direction = Vector3.ZERO #declaration, this is overwritten in ground or air move
	
	
	
	
	#ground movement
	if is_on_floor():
			# Handle Jump.
		if Input.is_action_just_pressed("Jump"):
			velocity.y = jumpVelocity
			lastJumpTime = Time.get_ticks_msec()
			jumpLatch = true
			#print(jumpVelocity)
		elif(!was_on_ground and not jumpLatch and Input.is_action_pressed("Jump")) and Time.get_ticks_msec()-jumpBufferStart < jumpBufferWindow:
			velocity.y = jumpVelocity
			lastJumpTime = Time.get_ticks_msec()
			jumpLatch = true
		
		#movement
		direction = currentDirection.slerp(target_direction,turnSpeed)
		
		if input_dir.length_squared()>0.01:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
		
		
	#air movement
	else:
		if not Input.is_action_pressed("Jump"):
			jumpLatch = false
			
		if Input.is_action_just_pressed("Jump") and not jumpLatch:
			jumpBufferStart = Time.get_ticks_msec()
			
		
		velocity.y -= gravity * delta
		
		
		###force-based implementation- Depricated
		#var target_accel = target_direction*AirMoveAccel#*clampf(lerpf(1.0,0.0,(float(Time.get_ticks_msec())-float(lastJumpTime))/(jumpInputDecay*1000.0)),0.0,1.0)
		#direction = Vector3(velocity.x+(target_accel.x*delta),0.0,velocity.z+(target_accel.z*delta))
		#if direction.length_squared()>speed*speed:
		#	direction = direction.normalized()*speed
		#velocity.x = direction.x
		#velocity.z = direction.z
		
		#adjusted target starts at 100%, and linearly decays to zero at t=jumpInputDecay seconds after jump.
		var adjusted_target = target_direction * (((Time.get_ticks_msec()-lastJumpTime)/(jumpInputDecay*1000))+1) #1000 is the conversion from seconds to ms
		direction = currentDirection.slerp(adjusted_target,turnSpeedAirborne)
		
		if input_dir.length_squared()>0.01:
			velocity.x = lerpf(velocity.x, direction.x * speed, 0.2)
			velocity.z = lerpf(velocity.z, direction.z * speed, 0.2)
		else:
			velocity.x = move_toward(velocity.x, 0, .1)
			velocity.z = move_toward(velocity.z, 0, .1)
		
		
		
	was_on_ground = is_on_floor()
	
	
	
	
	
	#Player Facing
	
	if input_dir.length() > 0.01 :
		look_at(position+direction,Vector3.UP)
	
	
	#save animator parameters
	animGrounded = is_on_floor()
	animSpeed = input_dir.length()
	animVertSpeed = velocity.y
	animTurnSpeed = lerpf(animTurnSaved, target_direction.signed_angle_to(currentDirection, Vector3.UP), 0.1) #lerping between previous values avoids harsh discontinuity on keyboard input
	animTurnSaved = animTurnSpeed
	#animTurnSpeed = target_direction.signed_angle_to(currentDirection, Vector3.UP) #TODO: this is too abrupt for the leaning on kerboard.
	
	move_and_slide()
	
	#killfloor
	if position.y<-100:
		position = Vector3.UP*5
