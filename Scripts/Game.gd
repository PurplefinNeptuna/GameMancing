extends Node

export(String, FILE, "*tscn") var ikan_location
export(float) var ikan_size
export(Vector2) var spawn_rect
export(int) var jumlah_ikan

onready var Ikan: PackedScene = load(ikan_location) as PackedScene

func _ready() -> void:
	randomize()
	var spawn_pos := Vector2.ZERO

	for _i in range(jumlah_ikan):
		spawn_pos.x = rand_range(ikan_size, ikan_size + spawn_rect.x)
		spawn_pos.y = rand_range(ikan_size, ikan_size + spawn_rect.y)
		
		var ikan_baru: Fish= (Ikan as PackedScene).instance()
		add_child_below_node($ColorRect, ikan_baru)
		ikan_baru.global_position = spawn_pos
		ikan_baru.target_pos = ikan_baru.get_new_target()
		ikan_baru.target_pos_old = spawn_pos
		ikan_baru.rotation = rand_range(0, 2 * PI)
		ikan_baru.current_state = ikan_baru.AIState.IDLING
		ikan_baru.current_idle_time = 0.0
