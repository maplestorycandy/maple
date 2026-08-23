# DamageNumber.gd
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
	
	# Stagger vertical position for multi-hit skills (Lucky Seven, Double Shot, Savage Blow)
	position.y -= (hit_index * 24.0)
	
	label.text = str(amount)
	velocity = Vector2(randf_range(-25, 25), randf_range(-150, -210))
	
	if is_heal:
		label.text = "+" + str(amount)
		label.modulate = Color(0.2, 1.0, 0.4)
		label.scale = Vector2(1.15, 1.15)
	elif is_player_damage:
		label.modulate = Color(1.0, 0.25, 0.25)
		label.scale = Vector2(1.1, 1.1)
	elif is_crit:
		# Classic Maple Yellow-Orange Critical Hit Style
		label.text = "CRIT! " + str(amount)
		label.modulate = Color(1.0, 0.82, 0.1)
		label.scale = Vector2(1.45, 1.45)
	else:
		# Normal Maple Cream White / Light Orange numbers
		label.modulate = Color(1.0, 0.95, 0.8)
		label.scale = Vector2(1.1, 1.1)

func _process(delta):
	timer += delta
	position += velocity * delta
	velocity.y += gravity * delta
	
	# Ease out alpha fade
	var alpha = 1.0 - pow(timer / lifetime, 2.0)
	modulate.a = clamp(alpha, 0.0, 1.0)
	
	if timer >= lifetime:
		queue_free()
