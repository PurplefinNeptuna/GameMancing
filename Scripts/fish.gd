class_name Fish, "res://fish.png"

extends KinematicBody2D

enum AIState {
	IDLING,
	MOVING,
	BITING,
	FISHING,
}

export(float) var distance_limit = 3
export(float) var distance_limit_bite = 10
export(float) var distance_turn_priority = 50
export(float) var max_speed = 100.0
export(float) var acceleration = 150.0

export(float) var min_rotate = .5
export(float) var max_rotate_speed = 250.0
export(float) var rot_acc = 4.0

export(float) var max_idle_time = 2.0
export(float) var max_biting_time = .4

var current_state: int = 0
var current_idle_time: float = 0.0
var current_bite_time: float = 0.0

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
var bait_nearby: bool = false
var target_follow_bait: bool = false
var bait: WeakRef = null

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
	var target_dir: Vector2 = target_pos - global_position
	draw_line(Vector2.ZERO, target_dir.rotated(-rotation), Color.yellow, 3)
	draw_line(Vector2.ZERO, velocity.rotated(-rotation) / max_speed * 100, Color.red, 3)
	draw_arc(Vector2.ZERO, 20, 0, rotate_speed / max_rotate_speed * PI, 16, Color.green, 3)

func _process(_delta: float) -> void:
#	if target_follow_mouse:
#		target_to_mouse()
	update()

func _physics_process(delta: float) -> void:
	
	if bait_nearby:
		var current_bait = bait.get_ref() as Node if bait else null
		if current_bait:
			var bait_bitten: bool = current_bait.has_fish_biting if "has_fish_biting" in current_bait else true
			
			if target_follow_bait:
				if bait_bitten and current_state != AIState.BITING:
					target_follow_bait = false
					target_pos = get_new_target()
				else:
					target_pos = current_bait.global_position
			else:
				if not bait_bitten:
					target_follow_bait = true
					target_pos = current_bait.global_position
		else:
			bait_nearby = false
			target_follow_bait = false
			bait = null
			target_pos = get_new_target()
	
	var current_dir: Vector2 = global_transform.basis_xform(Vector2.RIGHT)
	var target_dir: Vector2 = target_pos - global_position
	var target_angle: float = current_dir.angle_to(target_dir)
	var dist: float = target_dir.length()

	var checkA: bool = dist > distance_limit
	var checkB: bool = (velocity.length() == 0.0 and rotate_speed == 0.0)
	
	var cur_bait = bait.get_ref() if bait else null
	#if ((checkA or checkB) and not(checkA and checkB)):
	if target_follow_bait and cur_bait and "has_fish_biting" in cur_bait and dist < distance_limit_bite and current_state != AIState.BITING:
		current_state = AIState.BITING
		current_bite_time = max_biting_time
		cur_bait.emit_signal("bait_bitten", weakref(self))
	elif checkA and current_state != AIState.BITING:
		if current_state != AIState.MOVING:
			reset_starting_point()
			reset_rotation()
		current_state = AIState.MOVING
	elif current_state != AIState.BITING:
		if current_state != AIState.IDLING or current_idle_time <= 0:
			current_idle_time = max_idle_time
		current_state = AIState.IDLING

	if target_pos_old != target_pos:
		reset_starting_point()
		reset_rotation()
	
	if rotate_speed == 0:
		reset_rotation()
		
	if velocity.length() < .5:
		reset_starting_point()
	
	ai(start_move_pos, target_dir, current_dir, target_angle, delta)
	target_pos_old = target_pos
	if checkB and current_state != AIState.BITING:
		if current_state != AIState.IDLING or current_idle_time <= 0:
			current_idle_time = max_idle_time
		current_state = AIState.IDLING

func reset_rotation() -> void:
	start_rot_vec = global_transform.basis_xform(Vector2.RIGHT)

func reset_starting_point() -> void:
	start_move_pos = global_position
	start_move_dir = (target_pos - global_position).normalized()

func ai(start_pos: Vector2, target_dir: Vector2, cur_dir: Vector2, angle: float, delta: float) -> void:
	var dist: float = target_dir.length()
	var dist_from_start: float = (target_pos - start_pos).length()
	var speed: float = velocity.length()
	var speed_time_to_zero: float = speed / acceleration
	var dist_to_zero: float = acceleration * speed_time_to_zero * speed_time_to_zero * .5
	var dir: Vector2 = target_dir.normalized()
	var velocity_dir: Vector2 = velocity.normalized() if velocity != Vector2.ZERO else dir
	
	var is_rotating: bool = false
	var rot_from_start: float = start_rot_vec.angle_to(target_dir)
	var rot_dir: float = sign(rotate_speed) if abs(rotate_speed) > 0 else sign(rot_from_start)
	var rot_time_to_zero: float = rotate_speed / rot_acc
	var rot_to_zero: float = rot_acc * rot_time_to_zero * rot_time_to_zero * .5

	if 2.0 * PI - abs(angle) < abs(angle):
		angle = (2.0 * PI - abs(angle)) * sign(angle) * -1.0

	# DEBUG HERE
	var debug_angle: float = abs(round(rad2deg(angle)))
	var debug_rot: float = abs(round(rad2deg(rot_from_start)))
	debug_angle *= sign(angle) if abs(debug_angle) > 0.0 else 1.0
	debug_rot *= sign(rot_from_start) if abs(debug_rot) > 0.0 else 1.0
	var debug_dist: float = round(dist)
	var debug_dist0: float = round(dist_from_start)
	$DegText.text = debug_angle as String
	$DegText.text += "\n"
	$DegText.text += debug_rot as String
	$DegText.text += "\n"
	$DegText.text += debug_dist as String
	$DegText.text += "\n"
	$DegText.text += debug_dist0 as String

	match current_state:
		AIState.IDLING:
			velocity = Vector2.ZERO
			rotate_speed = 0.0
			
			current_idle_time -= delta
			if current_idle_time <= 0.0:
				target_pos = get_new_target()
			
			return
		AIState.MOVING, AIState.BITING:
			if current_state == AIState.BITING:
				var cur_bait = bait.get_ref() if bait else null

				current_bite_time -= delta
				if current_bite_time <= 0:
					current_state = AIState.MOVING
					bait_nearby = false
					target_follow_bait = false
					if cur_bait and "has_fish_biting" in cur_bait:
						cur_bait.emit_signal("bait_left")
					bait = null
					target_pos = get_new_target()
					return
				
				if not(cur_bait and "has_fish_biting" in cur_bait):
					current_state = AIState.MOVING
					target_pos = get_new_target()
					return
				else:
					if dist < 10:
						velocity = Vector2.ZERO

			var rot_right_dir: bool = sign(rot_from_start) == rot_dir
			
			if abs(angle) < min_rotate * 3.0:
				rotation = dir.angle()
				rotate_speed = 0
				reset_rotation()
			else:
				var rot_acc_ing: bool = true
				is_rotating = true
				if abs(angle) < rot_to_zero:
					rot_acc_ing = false
				elif abs(rot_from_start) < rot_max_to_zero * 2:
					if abs(angle) < abs(rot_from_start) * .5:
						rot_acc_ing = false
					else:
						rot_acc_ing = true
				elif abs(angle) < rot_max_to_zero:
					rot_acc_ing = false
				else:
					rot_acc_ing = true
				
				if not rot_right_dir:
					rot_acc_ing = !rot_acc_ing
				
				if rot_acc_ing:
					rotate_speed += rot_acc * delta * rot_dir
				else:
					rotate_speed -= rot_acc * delta * rot_dir

			var accelerating: bool = true
			
			if is_rotating and dist < distance_turn_priority and current_state != AIState.BITING:
				accelerating = false
			if dist < dist_to_zero:
				accelerating = false
			elif dist_from_start < dist_max_to_zero * 2:
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

	rotate_speed = clamp(rotate_speed, -max_rotate_speed, max_rotate_speed)
	velocity = Utils.clamp_vec2_to_mag(velocity, cur_dir, 0, max_speed)
	rotate(rotate_speed * delta)
	velocity = velocity.rotated(rotation - velocity.angle())
	var _coll = move_and_collide(velocity * delta)

func get_new_target() -> Vector2:
	var ans := Vector2.ZERO
	ans.x = rand_range(fish_max_length, fish_max_length + screen_size.x)
	ans.y = rand_range(fish_max_length, fish_max_length + screen_size.y)
	return ans

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		debug_show = !debug_show
		$DegText.visible = !$DegText.visible
	if Input.is_action_just_pressed("button1"):
		target_pos = get_new_target()
