# DamageNumber.gd
# 經典楓之谷傷害飄字 (支援萬/百萬超額傷害無上限無限疊加與千分號排版)
extends Node2D

@onready var label: Label = $Label
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 380.0
var lifetime: float = 0.85
var timer: float = 0.0

func setup(amount: int, is_crit: bool, is_player_damage: bool = false, is_heal: bool = false, hit_index: int = 0, is_miss: bool = false):
	if not label:
		label = Label.new()
		add_child(label)
	
	# Stagger vertical position for multi-hit skills
	position.y -= (hit_index * 24.0)
	
	var formatted_num = format_number(amount)
	velocity = Vector2(randf_range(-20, 20), randf_range(-140, -200))
	
	# Calculate dynamic scale for big hits (scales with damage tier!)
	var base_scale = 1.15
	if amount >= 1000000:
		base_scale = 1.9
	elif amount >= 100000:
		base_scale = 1.6
	elif amount >= 10000:
		base_scale = 1.35
	elif amount >= 1000:
		base_scale = 1.2
		
	# Apply font styling with outline for crisp readability
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 17)
	
	if is_miss:
		# Classic Maple MISS: Purple/Violet bold stylized letters
		label.text = "MISS"
		label.modulate = Color(0.88, 0.45, 1.0) # Vivid Purple
		label.add_theme_color_override("font_outline_color", Color(0.18, 0.02, 0.28, 1.0))
		label.scale = Vector2(base_scale * 1.2, base_scale * 1.2)
	elif is_heal:
		label.text = "+" + formatted_num
		label.modulate = Color(0.2, 1.0, 0.4)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.3, 0.1, 1.0))
		label.scale = Vector2(base_scale * 1.1, base_scale * 1.1)
	elif is_player_damage:
		# Classic Maple Player Hurt: Distinct Purple Number with dark purple border (如截圖 1507)
		label.text = formatted_num
		label.modulate = Color(0.92, 0.48, 1.0) # Authentic Maple Purple
		label.add_theme_color_override("font_outline_color", Color(0.25, 0.05, 0.35, 1.0))
		label.scale = Vector2(base_scale * 1.15, base_scale * 1.15)
	elif is_crit:
		# Classic Maple Critical Hit: Hot Pink / Orange-Red Gradient Style (如截圖 5230, 42442)
		label.text = "CRIT! " + formatted_num
		label.modulate = Color(1.0, 0.25, 0.5) # Hot Pink / Red
		label.add_theme_color_override("font_outline_color", Color(0.45, 0.05, 0.1, 1.0))
		label.scale = Vector2(base_scale * 1.3, base_scale * 1.3)
	else:
		# Normal Maple Damage: Bright Orange-Gold numbers (如截圖 3818, 8030)
		label.text = formatted_num
		label.modulate = Color(1.0, 0.88, 0.2) # Bright Orange-Gold
		label.add_theme_color_override("font_outline_color", Color(0.4, 0.15, 0.0, 1.0))
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
