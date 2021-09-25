class_name Bob, "res://Sprites/bob.png"

signal bait_bitten(the_fish)
signal bait_left

extends Area2D

export(float) var speed = 50.0

var has_fish_biting: bool = false
var biting_fish: WeakRef = null

func _ready() -> void:
	var _err = self.connect("body_entered", self, "fish_nearby_enter")
	_err = self.connect("body_exited", self, "fish_nearby_exit")
	_err = self.connect("bait_bitten", self, "fish_bite")
	_err = self.connect("bait_left", self, "fish_left")

func _process(delta):
	var dir: Vector2 = get_global_mouse_position() - global_position
	global_position += dir.normalized() * speed * delta

func fish_nearby_enter(fish: Node) -> void:
	if not ("bait" in fish):
		return

	fish.bait_nearby = true
	fish.target_follow_bait = true if not has_fish_biting else false
	fish.bait = weakref(self)
#	var le_fishe: Fish = fish as Fish
#
#	le_fishe.target_follow_bait = true
#	le_fishe.bait = weakref(self)

func fish_nearby_exit(fish: Node) -> void:
	if not ("bait" in fish):
		return

	fish.bait_nearby = false
	fish.target_follow_bait = false
	fish.bait = null
#	var le_fishe: Fish = fish as Fish
#
#	le_fishe.target_follow_bait = false
#	le_fishe.bait = null

func fish_bite(fish: WeakRef) -> void:
	biting_fish = fish
	has_fish_biting = true
	
func fish_left() -> void:
	biting_fish = null
	has_fish_biting = false
