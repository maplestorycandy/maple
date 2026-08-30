# DropItem.gd
extends CharacterBody2D

@export var item_name: String = "道具"
@export var item_type: String = "material" # "meso", "equipment", "consumable", "material"
@export var item_data: Dictionary = {}
@export var meso_amount: int = 0

var bounce_count: int = 0
var max_bounces: int = 2
var pickup_delay: float = 0.1 # Instant responsive pickup
var alive_timer: float = 0.0
var max_lifetime: float = 60.0 # Disappears after 60s
var is_picked_up: bool = false
var float_anim: float = 0.0

@onready var label: Label = $Label
@onready var icon_sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	z_index = 25
	add_to_group("drop_items")
	setup_visuals()

func setup(data: Dictionary, spawn_pos: Vector2, initial_vel: Vector2 = Vector2.ZERO):
	item_data = data
	item_name = data.get("name", "道具")
	item_type = data.get("type", "material")
	meso_amount = data.get("meso_amount", 0)
	
	global_position = spawn_pos
	if initial_vel == Vector2.ZERO:
		velocity = Vector2(randf_range(-90, 90), randf_range(-190, -140))
	else:
		velocity = initial_vel
		
	setup_visuals()

func setup_visuals():
	if not is_node_ready():
		return
		
	if label:
		if item_type == "meso":
			label.text = "%d 楓幣" % meso_amount
			label.modulate = Color(1.0, 0.85, 0.2)
		elif item_type == "equipment":
			var req_str = ""
			if item_data.has("req_lvl") and item_data.req_lvl > 0:
				req_str = " (Lv.%d)" % item_data.req_lvl
			label.text = "★ %s%s" % [item_name, req_str]
			label.modulate = Color(1.0, 0.5, 0.2) # Orange/Gold equipment highlight
		elif item_type == "consumable":
			label.text = item_name
			label.modulate = Color(0.4, 0.9, 1.0)
		else: # Material / ETC
			label.text = item_name
			label.modulate = Color(0.8, 0.9, 0.8)
			
	queue_redraw()

func _physics_process(delta):
	alive_timer += delta
	float_anim += delta * 5.0
	
	if alive_timer >= max_lifetime:
		queue_free()
		return
		
	if not is_on_floor():
		velocity.y += 650.0 * delta
	else:
		if bounce_count < max_bounces:
			bounce_count += 1
			velocity.y = -100.0 / bounce_count
			velocity.x *= 0.6
		else:
			velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
			
	move_and_slide()
	
	# Check Player Pickup
	if alive_timer >= pickup_delay and not is_picked_up:
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and global_position.distance_to(player.global_position) < 38.0:
			pickup_item(player)

func pickup_item(_player: CharacterBody2D):
	is_picked_up = true
	
	if item_type == "meso":
		Global.meso_gold += meso_amount
		Global.broadcast_message("★ 拾取楓幣: +%d 楓幣！" % meso_amount, Color(1.0, 0.85, 0.2))
	elif item_type == "equipment":
		var job_str = " [%s]" % item_data.get("job", "") if item_data.get("job", "") != "" else ""
		var lvl_str = " (Lv.%d)" % item_data.get("req_lvl", 0) if item_data.get("req_lvl", 0) > 0 else ""
		Global.add_item_to_inventory("equip", item_data)
		Global.broadcast_message("🎉 獲得裝備！【%s】%s%s 已放入裝備欄！" % [item_name, lvl_str, job_str], Color.GOLD)
	elif item_type == "consumable":
		Global.add_item_to_inventory("use", {"name": item_name, "type": "potion", "count": 1})
		Global.broadcast_message("★ 拾取道具：【%s】x1 已放入消耗欄！" % item_name, Color(0.4, 0.9, 1.0))
	else:
		Global.add_item_to_inventory("etc", {"name": item_name, "type": "material", "count": 1})
		Global.broadcast_message("★ 拾取材料戰利品：【%s】x1 已放入材料欄！" % item_name, Color(0.8, 0.9, 0.8))
		
	# Float up and vanish animation
	var tw = create_tween()
	tw.tween_property(self, "position:y", position.y - 30, 0.25)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)

func _draw():
	var bounce_y = sin(float_anim) * 2.0 if bounce_count >= max_bounces else 0.0
	
	if item_type == "meso":
		# Draw Meso Coin
		draw_circle(Vector2(0, -6 + bounce_y), 7, Color.GOLD)
		draw_circle(Vector2(0, -6 + bounce_y), 5, Color(1.0, 0.9, 0.3))
		draw_rect(Rect2(-2, -8 + bounce_y, 4, 4), Color(0.8, 0.6, 0.1), true)
	elif item_type == "equipment":
		# Golden Equipment aura
		draw_circle(Vector2(0, -10 + bounce_y), 12, Color(1.0, 0.8, 0.2, 0.4))
		draw_rect(Rect2(-8, -18 + bounce_y, 16, 16), Color(1.0, 0.4, 0.1), true)
		draw_rect(Rect2(-6, -16 + bounce_y, 12, 12), Color(1.0, 0.8, 0.3), true)
	elif item_type == "consumable":
		# Potion Bottle
		draw_circle(Vector2(0, -8 + bounce_y), 8, Color(0.2, 0.6, 1.0))
		draw_rect(Rect2(-3, -16 + bounce_y, 6, 6), Color(0.9, 0.9, 0.9), true)
	else:
		# Material Bag/Item
		draw_circle(Vector2(0, -7 + bounce_y), 7, Color(0.4, 0.8, 0.4))
		draw_circle(Vector2(0, -7 + bounce_y), 4, Color(0.8, 1.0, 0.8))
