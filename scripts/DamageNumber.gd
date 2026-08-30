# DamageNumber.gd
# 經典楓之谷傷害飄字 (支援萬/百萬超額傷害無上限無限疊加與千分號排版)
extends Node2D

@onready var label: Label = $Label
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 380.0
var lifetime: float = 0.85
var timer: float = 0.0

func setup(amount: int, is_crit: bool, is_player_damage: bool = false, is_heal: bool = false, hit_index: int = 0):
	if not label:
		label = Label.new()
		add_child(label)
	
	# Stagger vertical position for multi-hit skills
	position.y -= (hit_index * 24.0)
	
	var formatted_num = format_number(amount)
	velocity = Vector2(randf_range(-25, 25), randf_range(-150, -220))
	
	# Calculate dynamic scale for big hits (scales with damage tier!)
	var base_scale = 1.1
	if amount >= 1000000:
		base_scale = 1.9
	elif amount >= 100000:
		base_scale = 1.6
	elif amount >= 10000:
		base_scale = 1.35
	elif amount >= 1000:
		base_scale = 1.2
		
	if is_heal:
		label.text = "+" + formatted_num
		label.modulate = Color(0.2, 1.0, 0.4)
		label.scale = Vector2(base_scale * 1.1, base_scale * 1.1)
	elif is_player_damage:
		label.text = formatted_num
		label.modulate = Color(1.0, 0.25, 0.25)
		label.scale = Vector2(base_scale, base_scale)
	elif is_crit:
		# Classic Maple Yellow-Orange Critical Hit Style
		label.text = "CRIT! " + formatted_num
		label.modulate = Color(1.0, 0.82, 0.1)
		label.scale = Vector2(base_scale * 1.35, base_scale * 1.35)
	else:
		# Normal Maple Cream White / Light Orange numbers
		label.text = formatted_num
		label.modulate = Color(1.0, 0.95, 0.8)
		label.scale = Vector2(base_scale, base_scale)

func format_number(n: int) -> String:
	var s = str(n)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

func _process(delta):
	timer += delta
	position += velocity * delta
	velocity.y += gravity * delta
	
	# Ease out alpha fade
	var alpha = 1.0 - pow(timer / lifetime, 2.0)
	modulate.a = clamp(alpha, 0.0, 1.0)
	
	if timer >= lifetime:
		queue_free()
