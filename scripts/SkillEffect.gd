# SkillEffect.gd
# 楓之谷經典職業技能專屬特效繪製 (魔力之爪、劍氣斬、雙飛斬、迴旋斬、聖光創世紀、暴風神射、降龍十八掌等)
extends Node2D

var effect_type: String = "magic_claw"
var facing_dir: int = 1
var lifetime: float = 0.5
var timer: float = 0.0
var scale_factor: float = 1.0

func setup(p_type: String, p_pos: Vector2, p_facing: int = 1, p_duration: float = 0.55, p_scale: float = 1.0):
	effect_type = p_type
	global_position = p_pos
	facing_dir = p_facing
	lifetime = p_duration
	scale_factor = p_scale
	timer = 0.0

func _process(delta):
	timer += delta
	queue_redraw()
	if timer >= lifetime:
		queue_free()

func _draw():
	var progress = timer / max(0.01, lifetime)
	var alpha = 1.0 - pow(progress, 2.0)
	
	match effect_type:
		"magic_claw":
			# Twin Golden Arcane Claws Laceration
			var spread = progress * 24.0
			var c1 = Color(1.0, 0.9, 0.2, alpha)
			var c2 = Color(1.0, 0.5, 0.1, alpha * 0.8)
			# Claw 1
			draw_line(Vector2(-20 * facing_dir - spread, -35), Vector2(25 * facing_dir + spread, 20), c1, 6.0 * (1.0 - progress * 0.5))
			# Claw 2
			draw_line(Vector2(-10 * facing_dir - spread, -45), Vector2(35 * facing_dir + spread, 10), c2, 5.0 * (1.0 - progress * 0.5))
			# Sparkles
			draw_circle(Vector2(5 * facing_dir, -10), 12.0 * (1.0 - progress), Color(1.0, 1.0, 0.7, alpha))
			
		"power_strike", "melee_heavy":
			# Heavy Red/Gold Blade Slash Impact
			var slash_radius = 45.0 + progress * 25.0
			var start_ang = -PI/1.5 if facing_dir > 0 else PI/1.5
			var end_ang = PI/2.5 if facing_dir > 0 else -PI/2.5
			draw_arc(Vector2.ZERO, slash_radius, min(start_ang, end_ang), max(start_ang, end_ang), 24, Color(1.0, 0.3, 0.1, alpha), 8.0)
			draw_arc(Vector2(facing_dir * 5, 0), slash_radius * 0.9, min(start_ang, end_ang), max(start_ang, end_ang), 20, Color(1.0, 0.9, 0.3, alpha), 4.0)
			draw_circle(Vector2(facing_dir * 30, -10), 16.0 * (1.0 - progress), Color(1.0, 0.8, 0.2, alpha * 0.7))
			
		"aoe_slash", "rush_slash":
			# 360 Blue-White Sword Crescent Shockwave
			var cur_r = 30.0 + progress * 65.0
			draw_arc(Vector2.ZERO, cur_r, 0, TAU, 32, Color(0.3, 0.8, 1.0, alpha), 6.0)
			draw_arc(Vector2.ZERO, cur_r * 0.8, 0, TAU, 24, Color(1.0, 1.0, 1.0, alpha * 0.9), 3.0)
			
		"savage_blow", "assaulter":
			# 6 Multi-directional Shadow Dagger Slashes
			for i in range(6):
				var ang = (PI / 3.0) * float(i) + (progress * 0.5)
				var v1 = Vector2.from_angle(ang) * (15.0 + progress * 35.0)
				var v2 = Vector2.from_angle(ang + PI) * (15.0 + progress * 35.0)
				var slash_col = Color(0.8, 0.2, 1.0, alpha) if i % 2 == 0 else Color(1.0, 0.3, 0.6, alpha)
				draw_line(v1, v2, slash_col, 4.0)
			draw_circle(Vector2.ZERO, 15.0 * (1.0 - progress), Color(0.9, 0.4, 1.0, alpha * 0.6))
			
		"lucky_seven", "shuriken", "triple_throw":
			# Glowing Spinning Shuriken & Spark Trails
			var spin = timer * 25.0
			for i in range(4):
				var arm_ang = spin + (PI / 2.0) * float(i)
				var p = Vector2.from_angle(arm_ang) * 18.0
				draw_line(Vector2.ZERO, p, Color(0.4, 0.9, 1.0, alpha), 4.0)
			draw_circle(Vector2.ZERO, 6.0, Color(1.0, 1.0, 0.3, alpha))
			
		"arrow_rain", "hurricane":
			# Glowing Golden/Green Arrows Falling/Piercing
			var offset_x = (sin(timer * 20.0)) * 20.0
			draw_line(Vector2(offset_x, -60), Vector2(offset_x + facing_dir * 15, 20), Color(0.3, 1.0, 0.4, alpha), 5.0)
			draw_line(Vector2(offset_x - 15, -70), Vector2(offset_x - 15 + facing_dir * 15, 10), Color(1.0, 0.9, 0.2, alpha), 4.0)
			draw_line(Vector2(offset_x + 15, -50), Vector2(offset_x + 15 + facing_dir * 15, 30), Color(0.2, 0.9, 0.8, alpha), 4.0)
			
		"lightning_storm", "chain_lightning":
			# Jagged Lightning Thunder
			var cur_p = Vector2(0, -90)
			for i in range(5):
				var next_p = cur_p + Vector2(randf_range(-25, 25), 20.0)
				draw_line(cur_p, next_p, Color(0.5, 0.8, 1.0, alpha), 5.0)
				draw_line(cur_p, next_p, Color(1.0, 1.0, 1.0, alpha * 0.9), 2.0)
				cur_p = next_p
			draw_circle(cur_p, 20.0 * (1.0 - progress), Color(0.4, 0.9, 1.0, alpha * 0.7))
			
		"genesis", "angel_ray", "holy_slash":
			# Massive Pillar of Divine Golden Light
			var beam_w = 40.0 * (1.0 - progress * 0.3)
			draw_rect(Rect2(-beam_w/2.0, -250, beam_w, 300), Color(1.0, 0.9, 0.3, alpha * 0.6))
			draw_rect(Rect2(-beam_w/4.0, -250, beam_w/2.0, 300), Color(1.0, 1.0, 1.0, alpha * 0.9))
			draw_circle(Vector2.ZERO, 35.0 * (1.0 - progress), Color(1.0, 0.85, 0.2, alpha))
			
		"meteor", "blizzard":
			# Flaming/Icy Falling Meteor & Ground Shockwave
			var m_y = -120.0 + progress * 140.0
			draw_circle(Vector2(0, m_y), 24.0 * (1.0 - progress * 0.3), Color(1.0, 0.3, 0.1, alpha))
			draw_circle(Vector2(0, m_y), 14.0 * (1.0 - progress * 0.3), Color(1.0, 0.9, 0.2, alpha))
			if progress > 0.4:
				var ring_r = (progress - 0.4) * 80.0
				draw_arc(Vector2(0, 20), ring_r, 0, TAU, 24, Color(1.0, 0.4, 0.1, alpha), 6.0)
				
		"dragon_strike", "dragon_roar", "battleship":
			# Golden Dragon Spirit Surge
			var dragon_dist = progress * 70.0 * facing_dir
			draw_circle(Vector2(dragon_dist, -15), 28.0 * (1.0 - progress * 0.4), Color(1.0, 0.7, 0.1, alpha * 0.7))
			draw_circle(Vector2(dragon_dist, -15), 18.0 * (1.0 - progress * 0.4), Color(1.0, 0.95, 0.4, alpha))
			# Roar shockwave
			draw_arc(Vector2(dragon_dist, -15), 45.0 * (progress + 0.3), -PI/2.0, PI/2.0 if facing_dir > 0 else -PI/2.0, 16, Color(1.0, 0.5, 0.1, alpha), 7.0)
			
		_:
			# Default glowing impact burst
			draw_circle(Vector2.ZERO, 25.0 * (1.0 - progress), Color(1.0, 0.8, 0.3, alpha))
