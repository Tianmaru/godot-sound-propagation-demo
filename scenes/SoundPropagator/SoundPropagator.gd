class_name grid_propagator
extends Spatial

signal sound_propagated

export(AudioStream) var stream
export(float) var PROPAGATION_SPEED = 10
export(float) var MAX_PROPAGATION_DISTANCE = 100
# export(float) var PROPAGATION_STEP_SIZE = 1

var listener
var grid_map : GridMap

var next_cells := []
var visited_cells := []
var activated_cells := []
var propagation_distance := 0

const PROPAGATION_DIRECTIONS = [
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.UP,
	Vector3.DOWN
]

# Called when the node enters the scene tree for the first time.
func _ready():
	propagation_distance = 0
	next_cells.append(grid_map.world_to_map(global_transform.origin))
	propagate_sound()

func propagate_sound():
	if next_cells.empty() or propagation_distance > MAX_PROPAGATION_DISTANCE:
		queue_free()
		return
	var cells = next_cells
	next_cells = []
	for cell in cells:
		visit_cell(cell)
	propagation_distance += 1
	emit_signal("sound_propagated")
	yield(get_tree().create_timer(1/PROPAGATION_SPEED), "timeout")
	propagate_sound()

func visit_cell(cell):
	var cell_pos = grid_map.map_to_world(cell.x, cell.y, cell.z)
	var listener_pos = listener.global_transform.origin
	var col = get_world().direct_space_state.intersect_ray(cell_pos, listener.translation)
	if col.empty() or col['collider'] == listener:
		spawn_audio_player(cell_pos)
		activated_cells.append(cell)
	else:
		for direction in PROPAGATION_DIRECTIONS:
			var neighbor = cell + direction
			var neighbor_pos = grid_map.map_to_world(neighbor.x, neighbor.y, neighbor.z)
			var is_grid_cell = grid_map.get_cell_item(neighbor.x, neighbor.y, neighbor.z) != GridMap.INVALID_CELL_ITEM
			var is_reachable = get_world().direct_space_state.intersect_ray(cell_pos, neighbor_pos).empty()
			if not neighbor in visited_cells and not neighbor in next_cells and is_grid_cell and is_reachable:
				next_cells.append(neighbor)
	visited_cells.append(cell)

func spawn_audio_player(spawn_pos):
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = stream
	get_tree().get_root().add_child(audio_player)
	audio_player.translation = spawn_pos
	audio_player.connect("finished", audio_player, "queue_free")
	audio_player.play()
