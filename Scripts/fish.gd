class_name Fish, "res://fish.png"

extends KinematicBody2D

enum AIState {
	IDLING,
	STOP_TO_TURN,
	TURNING,
	SWIMMING,
	BITING,
}

export(float) var distance_limit = 3
export(float) var max_speed = 100.0
export(float) var acceleration = 100.0

export(float) var min_rotate = .5
export(float) var max_rotate_speed = 200.0
export(float) var rot_acc = 3.0

export(float) var max_idle_time = 2.0

var current_state: int = 0
var current_idle_time: float = 0.0

var velocity: Vector2 = Vector2.ZERO
var start_move_pos: Vector2 = Vector2.ZERO
var start_move_dir: Vector2 = Vector2.ZERO
var dist_max_to_zero: float = 0.0
var time_max_to_zero: float = 0.0

var rotate_speed: float = 0.0
var start_rot_vec: Vector2 = Vector2.RIGHT
var rot_max_to_zero: float = 0.0
var time_rot_to_zero: float = 0.0

var debug_show: bool = false

onready var fish_size: Vector2 = $Sprite.texture.get_size() * scale
onready var fish_max_length: float = max(fish_size.x, fish_size.y)
onready var fish_square: Vector2 = Vector2(fish_max_length, fish_max_length)
onready var screen_size: Vector2 = get_viewport_rect().size - (fish_square * 2)
onready var target_pos: Vector2 = screen_size * 0.5 + fish_square
onready var target_pos_old: Vector2 = screen_size * 0.5 + fish_square

func _ready() -> void:
	randomize()
	max_rotate_speed = deg2rad(max_rotate_speed)
	min_rotate = deg2rad(min_rotate)

	time_max_to_zero = max_speed / acceleration
	dist_max_to_zero = .5 * acceleration * time_max_to_zero * time_max_to_zero
	
	time_rot_to_zero = max_rotate_speed / rot_acc
	rot_max_to_zero = .5 * rot_acc * time_rot_to_zero * time_rot_to_zero
	
func _draw() -> void:
	if not debug_show:
		return
	draw_line(Vector2.ZERO, velocity.rotated(-rotation) / max_speed * 100, Color.red, 3)
	draw_arc(Vector2.ZERO, 20, 0, rotate_speed / max_rotate_speed * PI, 16, Color.green, 3)

func _process(_delta: float) -> void:
	update()

func _physics_process(delta: float) -> void:
	var current_dir: Vector2 = global_transform.basis_xform(Vector2.RIGHT)
	var target_dir: Vector2 = target_pos - global_position
	var target_angle: float = current_dir.angle_to(target_dir)
	var dist: float = target_dir.length()
	
	if abs(target_angle) > abs(min_rotate) and dist > distance_limit:
		if current_state != AIState.TURNING:
			reset_starting_point()
			current_state = AIState.STOP_TO_TURN
	elif dist > distance_limit:
		if current_state != AIState.SWIMMING and current_state != AIState.STOP_TO_TURN:
			reset_starting_point()
		current_state = AIState.SWIMMING
	else:
		if current_state != AIState.IDLING:
			current_idle_time = max_idle_time
		current_state = AIState.IDLING

	if target_pos_old != target_pos:
		reset_starting_point()
	
	ai(start_move_pos, target_dir, current_dir, target_angle, delta)
	target_pos_old = target_pos

func reset_starting_point() -> void:
	start_rot_vec = global_transform.basis_xform(Vector2.RIGHT)
	start_move_pos = global_position
	start_move_dir = (target_pos - global_position).normalized()
	rotate_speed = 0

func ai(start_pos: Vector2, target_dir: Vector2, cur_dir: Vector2, angle: float, delta: float) -> void:
	var dist: float = target_dir.length()
	var dist_from_start: float = (target_pos - start_pos).length()
	var speed: float = velocity.length()
	var dir: Vector2 = target_dir.normalized()
	var velocity_dir: Vector2 = velocity.normalized() if velocity != Vector2.ZERO else dir
	
	angle = min(angle, 2 * PI - angle)
	var rot_from_start: float = start_rot_vec.angle_to(target_dir)

	match current_state:
		AIState.IDLING:
			velocity = Vector2.ZERO
			rotate_speed = 0.0
			
			current_idle_time -= delta
			if current_idle_time <= 0.0:
				target_pos = get_new_target()
			
			return
		AIState.STOP_TO_TURN:
			rotate_speed = 0.0
			if speed <= distance_limit:
				current_state = AIState.TURNING
			velocity -= velocity_dir * acceleration * delta
		AIState.TURNING:
			velocity = Vector2.ZERO
			if abs(angle) < deg2rad(min_rotate):
				rotation = dir.angle()
			else:
				var rot_acc_ing: bool = true
				if abs(rot_from_start) < rot_max_to_zero * 2:
					if abs(angle) < abs(rot_from_start) * .5:
						rot_acc_ing = false
				elif abs(angle) < rot_max_to_zero:
					rot_acc_ing = false
				
				if rot_acc_ing:
					rotate_speed += rot_acc * delta * sign(rot_from_start)
				else:
					rotate_speed -= rot_acc * delta * sign(rot_from_start)
				
				rotate_speed = clamp(abs(rotate_speed), min_rotate / delta, max_rotate_speed) * sign(rotate_speed)
				rotate(rotate_speed * delta)
			return
		AIState.SWIMMING:
			rotate_speed = 0.0
			var accelerating: bool = true
			
			if dist_from_start < dist_max_to_zero * 2:
				if dist < dist_from_start * .5:
					accelerating = false
			elif dist < dist_max_to_zero:
				accelerating = false
			
			if accelerating:
				velocity += velocity_dir * acceleration * delta
			else:
				velocity -= velocity_dir * acceleration * delta
		_:
			return

	velocity = Utils.clamp_vec2_to_mag(velocity, cur_dir, 0, max_speed)
	var _coll = move_and_collide(velocity * delta)

func get_new_target() -> Vector2:
	var ans := Vector2.ZERO
	ans.x = rand_range(fish_max_length, fish_max_length + screen_size.x)
	ans.y = rand_range(fish_max_length, fish_max_length + screen_size.y)
	return ans
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		debug_show = !debug_show
