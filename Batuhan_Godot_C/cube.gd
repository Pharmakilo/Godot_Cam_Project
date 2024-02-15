extends CharacterBody3D

# Cube control variables
@onready var pivot = $Pivot
@onready var mesh = $Pivot/MeshInstance3D
var cube_size = 1.0
var speed = 3.0
var rolling = false

# Camera mode variables
var free_camera_mode = false
var camera: Camera3D
var cam_offset = Vector3(0, 4, 6)
var cam_speed = 3.0
var acceleration = 50.0
var moveSpeed = 8.0
var mouseSpeed = 300.0
var camera_velocity = Vector3.ZERO
var lookAngles = Vector2.ZERO

func _ready():
	camera = get_parent().get_node("Camera3D")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta):
	if !free_camera_mode:
		handle_cube_movement(delta)

func _process(delta):
	print("hello")
	if free_camera_mode:
		update_camera_mode(delta)
	else:
		update_follow_mode(delta)

func _input(event):
	if Input.is_action_just_pressed("ui_toggle_camera"):
		free_camera_mode = !free_camera_mode
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if free_camera_mode else Input.MOUSE_MODE_VISIBLE)
		if free_camera_mode:
			camera.position = global_transform.origin + cam_offset
  # Adjust to your initial camera position in free mode
		camera_velocity = Vector3.ZERO  # Reset velocity when switching modes

	if free_camera_mode:
		handle_camera_input(event)

func handle_cube_movement(_delta):
	var forward = Vector3.FORWARD
	if Input.is_action_pressed("forward"):
		roll(forward)
	if Input.is_action_pressed("back"):
		roll(-forward)
	if Input.is_action_pressed("right"):
		roll(forward.cross(Vector3.UP))
	if Input.is_action_pressed("left"):
		roll(-forward.cross(Vector3.UP))

func roll(dir):
	# Do nothing if we're currently rolling.
	if rolling:
		return

	# Cast a ray to check for obstacles
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(mesh.global_position,
			mesh.global_position + dir * cube_size, collision_mask, [self])
	var collision = space.intersect_ray(ray)
	if collision:
		return

	rolling = true
	# Step 1
	pivot.translate(dir * cube_size / 2)
	mesh.global_translate(-dir * cube_size / 2)
	
	# Step 2
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(pivot, "transform",
			pivot.transform.rotated_local(axis, PI/2), 1 / speed)
	await tween.finished

	# Step 3:
	position += dir * cube_size
	var b = mesh.global_transform.basis
	pivot.transform = Transform3D.IDENTITY
	mesh.position = Vector3(0, cube_size / 2, 0)
	mesh.global_transform.basis = b
	rolling = false

func update_follow_mode(delta):
	camera.position = lerp(camera.position, self.global_transform.origin + cam_offset, cam_speed * delta)

func update_camera_mode(delta):
	var dir = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		dir -= camera.global_transform.basis.z.normalized()
	if Input.is_action_pressed("ui_down"):
		dir += camera.global_transform.basis.z.normalized()
	if Input.is_action_pressed("ui_left"):
		dir -= camera.global_transform.basis.x.normalized()
	if Input.is_action_pressed("ui_right"):
		dir += camera.global_transform.basis.x.normalized()

	camera_velocity = dir.normalized() * moveSpeed
	camera.global_translate(camera_velocity * delta)




func handle_camera_input(event):
	if event is InputEventMouseMotion:
		lookAngles.x -= event.relative.x / mouseSpeed
		lookAngles.y = clamp(lookAngles.y - event.relative.y / mouseSpeed, -PI / 2, PI / 2)
		camera.rotation_degrees = Vector3(lookAngles.y * (180 / PI), lookAngles.x * (180 / PI), 0)
