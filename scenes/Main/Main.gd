extends Spatial

export(AudioStream) var stream
export(float) var PROPAGATION_SPEED = 10
export(float) var MAX_PROPAGATION_DISTANCE = 100

const FLOOR_TILE_ID = 1

var spawn_pos = Vector3()

var sound_propagator
var sound_propagator_scn = preload("res://scenes/SoundPropagator/SoundPropagator.tscn")

onready var player = $Player
onready var map_camera = $MapCamera
onready var grid_map = $GridMap
onready var propagation_map = $PropagationMap
onready var popup = $CanvasLayer/InfoPanel

# Called when the node enters the scene tree for the first time.
func _ready():
	map_camera.current = false
	show_popup()

func _unhandled_input(event):
	if event.is_action_pressed("open_map"):
		set_map_open(not map_camera.current)
	if event.is_action_pressed("spawn_audio") and map_camera.current:
		spawn_pos = get_spawn_pos()
		if is_floor_tile(spawn_pos):
			create_sound_propagator(spawn_pos)
	if event.is_action_pressed("ui_exit"):
		show_popup()

func set_map_open(value):
	map_camera.current = value
	var mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	Input.set_mouse_mode(mouse_mode)
	player.set_physics_process(not value)
	player.set_process_unhandled_input(not value)

func get_spawn_pos():
	var mouse_pos = get_viewport().get_mouse_position()
	return map_camera.project_position(mouse_pos, 2)

func is_floor_tile(pos):
	var cell = grid_map.world_to_map(pos)
	return grid_map.get_cell_item(cell.x, cell.y, cell.z) == FLOOR_TILE_ID

func create_sound_propagator(pos):
	sound_propagator = sound_propagator_scn.instance()
	sound_propagator.stream = stream
	sound_propagator.listener = player
	sound_propagator.grid_map = grid_map
	sound_propagator.global_transform.origin = pos
	sound_propagator.MAX_PROPAGATION_DISTANCE = MAX_PROPAGATION_DISTANCE
	sound_propagator.PROPAGATION_SPEED = PROPAGATION_SPEED
	sound_propagator.connect("sound_propagated", self, "update_propagation_map")
	propagation_map.clear()
	add_child(sound_propagator)

func update_propagation_map():
	if not is_instance_valid(sound_propagator):
		return
	for cell in sound_propagator.visited_cells:
		propagation_map.set_cell_item(cell.x, cell.y, cell.z, 0)
	for cell in sound_propagator.activated_cells:
		propagation_map.set_cell_item(cell.x, cell.y, cell.z, 1)

func show_popup():
	popup.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_OkButton_button_down():
	popup.hide()
	if not map_camera.current:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_ExitButton_button_down():
	get_tree().quit()

func _on_HSlider_value_changed(value):
	PROPAGATION_SPEED = value
