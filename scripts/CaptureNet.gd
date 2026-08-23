# CaptureNet.gd
extends Area2D

var target_monster: Node2D = null
var speed: float = 550.0
var lifetime: float = 1.2
var timer: float = 0.0

func setup(target: Node2D):
	target_monster = target

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta):
	timer += delta
	if is_instance_valid(target_monster):
		var dir = (target_monster.global_position - global_position).normalized()
		position += dir * speed * delta
		if global_position.distance_to(target_monster.global_position) < 25.0:
			attempt_capture(target_monster)
	else:
		position += Vector2.RIGHT.rotated(rotation) * speed * delta
	
	queue_redraw()
	if timer >= lifetime:
		queue_free()

func _draw():
	# Draw glowing capture sphere / magic net
	draw_circle(Vector2.ZERO, 16.0, Color(0.2, 0.8, 1.0, 0.5))
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 16, Color(1.0, 1.0, 1.0, 0.9), 2.5)
	# Draw internal energy rings
	draw_arc(Vector2.ZERO, 8.0, timer * 5, timer * 5 + PI, 8, Color(0.9, 0.4, 1.0, 0.8), 2.0)

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		attempt_capture(body)

func _on_area_entered(area: Area2D):
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies"):
		attempt_capture(parent)

func attempt_capture(monster: Node2D):
	if not is_instance_valid(monster) or monster.is_queued_for_deletion():
		queue_free()
		return
	
	if monster.has_method("get_capture_data"):
		var data = monster.get_capture_data()
		var max_hp = data.get("max_hp", 100)
		var current_hp = data.get("hp", 100)
		var hp_percent = float(current_hp) / float(max_hp)
		
		var has_mastery = Global.passive_buffs.get("tame_mastery", false)
		
		# Bosses require mastery or under 20% HP; regular mobs require under 50% HP (or 100% with mastery)
		var can_tame = false
		if has_mastery:
			can_tame = true
		elif hp_percent <= 0.45:
			can_tame = true
		elif randf() < 0.2: # lucky small catch chance
			can_tame = true
			
		if can_tame:
			Global.add_pet_to_inventory(data)
			# Cleanly remove captured monster so it doesn't freeze or stall the game
			monster.on_captured()
		else:
			Global.broadcast_message("捕捉失敗！怪物血量過高 (%d%%)，請先削弱血量！" % int(hp_percent * 100), Color(1.0, 0.4, 0.4))
	
	queue_free()
