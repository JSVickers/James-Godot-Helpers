#	A collection of utility functions useful for manipulating vectors
#	Copyright JSVickers - See License
class_name VectorUtils
extends RefCounted

#	Apply acceleration to a vector, optionally along a curve
#	Return the difference between the two vectors
#	Difference can then be added to the first vector to increase its speed towards a direction
static func calculate_velocity_change(current_velocity: Vector3, direction: Vector3, movement_threshold: float, max_speed: float, min_speed: float, acceleration: float, deceleration: float, delta: float, acceleration_curve: Curve = null, decel_angle_deg: float = 45.0) -> Vector3:
	var target_velocity := Vector3.ZERO
	if direction.length() >= movement_threshold:
		target_velocity = direction.normalized() * max_speed
	
	var angle := 0.0
	if current_velocity.length() > 0.01:
		angle = rad_to_deg(acos(clampf(current_velocity.normalized().dot(target_velocity), -1, 1)))
	var decelerating := angle > decel_angle_deg or target_velocity == Vector3.ZERO
	
	var acceleration_rate := acceleration
	if decelerating:
		acceleration_rate = deceleration
	var min_speed_progress := min_speed / max_speed
	var speed_progress := clampf((current_velocity.length() / max_speed) + min_speed_progress, 0, 1)
	acceleration_rate = clampf(acceleration_rate * speed_progress, 0, acceleration_rate)
	if acceleration_curve != null:
		var curved_progress := acceleration_curve.sample(speed_progress)
		acceleration_rate = clampf(acceleration_rate * curved_progress, 0, acceleration_rate)
	
	var velocity_change := target_velocity - current_velocity
	var velocity_change_limit := acceleration_rate * delta
	if velocity_change.length() > velocity_change_limit:
		velocity_change = velocity_change.normalized() * velocity_change_limit
	
	
	return velocity_change
