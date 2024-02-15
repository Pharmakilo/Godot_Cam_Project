
extends Node3D

var cube: CharacterBody3D
var cam_offset = Vector3(0, 4, 6)
var cam_speed = 3.0

func _ready():
	cube = get_node("Cube") #gettig cube obstacle

func _process(delta):
	if not cube.free_camera_mode: # acces to freecam variable which controls the cam mode
		$Camera3D.position = lerp($Camera3D.position, cube.global_transform.origin + cam_offset, cam_speed * delta)
