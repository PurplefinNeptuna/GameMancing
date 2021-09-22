extends Node

static func clamp_vec2_to_mag(vec: Vector2, dir: Vector2, min_mag: float, max_mag: float) -> Vector2:
	var ans := dir
	var mag: float = vec.length()
	var angle: float = abs(vec.angle_to(dir))
	if angle > PI * 0.5:
		mag *= -1
	mag = clamp(mag, min_mag, max_mag)
	ans *= mag
	return ans
