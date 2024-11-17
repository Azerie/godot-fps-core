extends CharacterBody3D # TODO: inertia and sliding hitbox

# all exported vars should be constants
# Move speed of the character
@export var moveSpeed = 8
@export var dashSpeed = 20
@export var slideSpeed = 12

# camera sens
@export var rotationSpeed = 0.11

@export var accelearation = 10.0
@export var deceleration = 0.5

@export var jumpHeight = 1.2
# how much velocity is kept from the previous frame (from 0 to 1)
@export var inertiaCoef = 0.5
# Time required to pass before being able to jump again
@export var jumpTimeout = 0
@export var dashTimeout = 0
@export var slideCamDiff = 0.5

# camera constraints
@export var MinCameraAngle = -50
@export var MaxCameraAngle = 50


var _speed = 0;
var _rotationVelocity = 0;
var _verticalVelocity = 0;
var _terminalVelocity = 53.0;
var _jumpTimeoutDelta = 0;
var _dashTimeoutDelta = 0;
var _slideDirection = Vector3.ONE;

var _cameraYrotation = 0;

var  moveInput = Vector2.ZERO;
var  lookInput = Vector2.ZERO;

enum State {DEFAULT, SLIDING}
var state = State.DEFAULT

var justDashed = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# pass
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	UpdateState(delta)
	HandleInput(delta)
	ApplyGravity(delta)
	Move(delta)

func _physics_process(delta):
	move_and_slide()


func _input(event):
	if event is InputEventMouseMotion:
		event = event as InputEventMouseMotion
		lookInput = event.relative


func UpdateState(delta):
	# update jump
	if _jumpTimeoutDelta >= 0:
		_jumpTimeoutDelta -= delta
	
	# update dash
	if _dashTimeoutDelta >= 0:
		_dashTimeoutDelta -= delta


func Jump():
	stopSlide()
	_verticalVelocity = sqrt(2 * jumpHeight * gravity)
	_jumpTimeoutDelta = jumpTimeout


func Dash():
	stopSlide()
	var dashVelocity = Vector3(moveInput.x, 0, moveInput.y) * dashSpeed
	# add better way to get deadzone or something
	if moveInput.length() <= 0.01:
		dashVelocity = transform.basis * Vector3.FORWARD * dashSpeed
	velocity += dashVelocity
	justDashed = true
	_dashTimeoutDelta = dashTimeout


func canJump():
	return is_on_floor() && _jumpTimeoutDelta <= 0


func canDash():
	return _dashTimeoutDelta <= 0


func isSliding():
	return state == State.SLIDING


func startSlide():
	if !isSliding():
		var cam = get_node("CameraPivot")
		cam.position.y -= slideCamDiff
		
		state = State.SLIDING
		_slideDirection = transform.basis * Vector3.FORWARD
		var currentDirection = transform.basis * Vector3(moveInput.x, 0, moveInput.y).normalized()
		if currentDirection != Vector3.ZERO:
			_slideDirection = currentDirection


func stopSlide():
	if isSliding():
		var cam = get_node("CameraPivot")
		cam.position.y += slideCamDiff

		state = State.DEFAULT


func ApplyGravity(delta):
	if is_on_floor():
		if _verticalVelocity < 0:
			_verticalVelocity = -2
	
	if _verticalVelocity > -_terminalVelocity:
		_verticalVelocity -= gravity * delta


func HandleInput(delta):
	moveInput = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	
	if Input.is_action_just_pressed("Jump") && canJump():
		Jump();
	
	if Input.is_action_just_pressed("Dash") && canDash():
		Dash();
	
	if Input.is_action_just_pressed("Slide") && is_on_floor():
		startSlide()
	
	if Input.is_action_just_released("Slide") && isSliding():
		stopSlide()
	
	OnLook(delta)


func Move(delta):
	var currentHorizontalSpeed = Vector3(velocity.x, 0, velocity.z).length();
	# can probably work with vector2 here
	var currentHorizontalVelocity = Vector3(velocity.x, 0, velocity.z)
	
	var speedOffset = 0.1
	# inputMagnitude should be different for a controller
	var inputMagnitude = 1
	
	var targetSpeed = currentHorizontalSpeed
	if isSliding():
		targetSpeed = slideSpeed
	elif is_on_floor() && !justDashed:
		targetSpeed = moveSpeed
	elif moveInput == Vector2.ZERO && !justDashed:
		targetSpeed = 0
	
	# accelerate or decelerate to target speed
	if currentHorizontalSpeed < targetSpeed - speedOffset:
		_speed = lerpf(currentHorizontalSpeed, targetSpeed * inputMagnitude, delta * accelearation)
		# maybe round speed up to 5 digits of sth
	elif currentHorizontalSpeed > targetSpeed + speedOffset:
		_speed = lerpf(currentHorizontalSpeed, targetSpeed * inputMagnitude, delta * deceleration)
	else:
		_speed = targetSpeed
	
	var inputDirection = Vector3(moveInput.x, 0, moveInput.y).normalized()
	if moveInput != Vector2.ZERO:
		inputDirection = (transform.basis * inputDirection).normalized()
	
	if isSliding():
		inputDirection = _slideDirection
	
	# get the velocity if player inputs were always aligned with movement
	var snapHorizontalVelocity = inputDirection * _speed
	
	var newHorizontalVelocity = currentHorizontalVelocity * inertiaCoef + snapHorizontalVelocity * (1 - inertiaCoef)
	if justDashed:
		newHorizontalVelocity = snapHorizontalVelocity
	justDashed = false
	
	velocity = newHorizontalVelocity + Vector3(0, _verticalVelocity, 0)


func OnLook(delta):
	_rotationVelocity = lookInput.x * rotationSpeed
	
	rotate_y(-_rotationVelocity * PI / 180)
	
	var cam = get_node("CameraPivot")
	
	_cameraYrotation -= lookInput.y * rotationSpeed;
	_cameraYrotation = clamp(_cameraYrotation, MinCameraAngle, MaxCameraAngle);

	var newRotation = Vector3(_cameraYrotation, cam.rotation_degrees.y, cam.rotation_degrees.z);

	cam.rotation_degrees = newRotation;
	lookInput = Vector2.ZERO
