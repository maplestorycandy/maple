# Meteor.gd
extends Node2D

var target_pos: Vector2 = Vector2.ZERO
var speed: float = 600.0
var exploded: bool = false
var blast_radius: float = 220.0
var blast_timer: float = 0.0
var blast_duration: float = 0.8
var damage: int = 350

func _ready():
	damage = int(Global.player_atk * 3.5)

func _process(delta):
	if not exploded:
		var dir = (target_pos - global_position).normalized()
		var dist = global_position.distance_to(target_pos)
		if dist <= speed * delta:
			global_position = target_pos
			explode()
		else:
			global_position += dir * speed * delta
	else:
		blast_timer += delta
		if blast_timer >= blast_duration:
			queue_free()
	queue_redraw()

func explode():
	exploded = true
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= blast_radius:
			if e.has_method("take_damage"):
				e.take_damage(damage, true)

func _draw():
	if not exploded:
		# Draw falling flaming meteor
		draw_circle(Vector2.ZERO, 20.0, Color(1.0, 0.3, 0.0))
		draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.8, 0.1))
		draw_line(Vector2.ZERO, Vector2(0, -60), Color(1.0, 0.4, 0.0, 0.7), 18.0)
	else:
		# Draw fiery shockwave explosion
		var progress = blast_timer / blast_duration
		var alpha = 1.0 - progress
		var current_r = blast_radius * progress
		draw_circle(Vector2.ZERO, current_r, Color(1.0, 0.3, 0.0, alpha * 0.4))
		draw_arc(Vector2.ZERO, current_r, 0, TAU, 32, Color(1.0, 0.8, 0.2, alpha * 0.9), 4.0)
