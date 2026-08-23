# LevelBuffManager.gd
extends Node

signal buff_selection_requested(buffs: Array)
signal buff_applied(buff: Dictionary)

const BUFF_POOL = [
	{
		"id": "auto_sword_wave",
		"name": "天破狂刃 (自動技能)",
		"desc": "每 2.5 秒自動鎖定 650px 內最近敵人發射貫穿無雙劍氣！",
		"type": "auto_skill",
		"interval": 2.5,
		"icon_color": Color(0.9, 0.3, 0.2)
	},
	{
		"id": "auto_holy_rain",
		"name": "聖光裁決 (自動技能)",
		"desc": "每 4.0 秒在怪物最密集處降下毀滅聖光雨，造成 350% 範圍巨額傷害！",
		"type": "auto_skill",
		"interval": 4.0,
		"icon_color": Color(1.0, 0.9, 0.3)
	},
	{
		"id": "goddess_sanctuary",
		"name": "女神庇護結界 (被動)",
		"desc": "女神受到傷害減少 40%，且每秒替玩家與出戰寵物恢復 3% 最大生命！",
		"type": "passive_goddess",
		"icon_color": Color(0.2, 0.8, 1.0)
	},
	{
		"id": "chain_thunder",
		"name": "怒雷連鎖 (被動特效)",
		"desc": "所有普攻與技能 35% 機率觸發連鎖落雷，在 5 隻敵人之間彈跳轟炸！",
		"type": "on_hit",
		"icon_color": Color(0.8, 0.4, 1.0)
	},
	{
		"id": "tame_mastery",
		"name": "神之馭獸術 (核心特化)",
		"desc": "捕捉成功率提升至 100%，出戰寵物全屬性翻倍，並自帶範圍戰鬥震波！",
		"type": "pet_enhance",
		"icon_color": Color(0.3, 1.0, 0.5)
	},
	{
		"id": "speed_demon",
		"name": "極限超載 (屬性強化)",
		"desc": "移動速度 +40%，全技能冷卻縮減 35%，攻擊力提升 30%！",
		"type": "stat_boost",
		"icon_color": Color(1.0, 0.5, 0.1)
	},
	{
		"id": "vampiric_touch",
		"name": "嗜血汲取 (被動生存)",
		"desc": "擊殺或重擊敵人時汲取生命，恢復造成傷害 15% 的生命值！",
		"type": "vampire",
		"icon_color": Color(0.9, 0.1, 0.3)
	},
	{
		"id": "meteor_strike",
		"name": "末日隕石 (自動技能)",
		"desc": "每 6.0 秒召喚天外巨大隕石轟炸地面，造成大範圍擊退與燃燒！",
		"type": "auto_skill",
		"interval": 6.0,
		"icon_color": Color(1.0, 0.2, 0.1)
	}
]

var active_buffs: Array = []
var player_level: int = 1
var sanctuary_timer: float = 0.0

func _process(delta):
	# Handle Goddess Sanctuary passive periodic healing
	if Global.passive_buffs.get("goddess_sanctuary", false):
		sanctuary_timer += delta
		if sanctuary_timer >= 1.0:
			sanctuary_timer = 0.0
			var heal_p = int(Global.player_max_hp * 0.03)
			Global.heal_player(heal_p)
			if is_instance_valid(Global.active_pet_node):
				Global.active_pet_node.heal_pet(heal_p)

func check_level_up(new_level: int):
	player_level = new_level
	if player_level % 5 == 0:
		var choices = get_random_buff_choices(3)
		emit_signal("buff_selection_requested", choices)

func get_random_buff_choices(count: int = 3) -> Array:
	var available = []
	for b in BUFF_POOL:
		# Can pick auto-skills or passives (can stack level or new ones)
		available.append(b)
	available.shuffle()
	return available.slice(0, count)

func apply_selected_buff(buff: Dictionary, player_ref: CharacterBody2D):
	active_buffs.append(buff)
	emit_signal("buff_applied", buff)
	Global.broadcast_message("【獲得祝福】%s !" % buff.name, buff.get("icon_color", Color.GOLD))
	
	match buff.type:
		"auto_skill":
			setup_auto_skill_timer(buff, player_ref)
		"passive_goddess":
			Global.passive_buffs["goddess_sanctuary"] = true
		"on_hit":
			Global.passive_buffs["chain_thunder"] = true
		"pet_enhance":
			Global.passive_buffs["tame_mastery"] = true
			if is_instance_valid(Global.active_pet_node):
				Global.active_pet_node.apply_tame_mastery_buff()
		"stat_boost":
			Global.passive_buffs["speed_demon"] = true
			Global.player_speed *= 1.4
			Global.player_atk = int(Global.player_atk * 1.3)
			Global.passive_buffs["cooldown_reduction"] = 0.35
		"vampire":
			Global.passive_buffs["vampiric_drain"] = true

func setup_auto_skill_timer(buff: Dictionary, player_ref: CharacterBody2D):
	var timer = Timer.new()
	timer.wait_time = buff.interval
	timer.autostart = true
	timer.timeout.connect(func():
		execute_auto_skill(buff.id, player_ref)
	)
	if is_instance_valid(player_ref):
		player_ref.add_child(timer)

func execute_auto_skill(skill_id: String, player_ref: CharacterBody2D):
	if not is_instance_valid(player_ref):
		return
	
	# Find closest enemy or target
	var enemies = player_ref.get_tree().get_nodes_in_group("wave_attackers")
	enemies.append_array(player_ref.get_tree().get_nodes_in_group("enemies"))
	
	var closest_target: Node2D = null
	var min_dist = 700.0
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			var dist = player_ref.global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_target = enemy
				
	if closest_target:
		match skill_id:
			"auto_sword_wave":
				var slash_scene = load("res://scenes/skills/SwordWave.tscn")
				if slash_scene:
					var slash = slash_scene.instantiate()
					slash.global_position = player_ref.global_position + Vector2(0, -20)
					slash.target_direction = (closest_target.global_position - player_ref.global_position).normalized()
					player_ref.get_parent().add_child(slash)
			"auto_holy_rain":
				var holy_scene = load("res://scenes/skills/HolyRain.tscn")
				if holy_scene:
					var holy = holy_scene.instantiate()
					holy.global_position = closest_target.global_position
					player_ref.get_parent().add_child(holy)
			"meteor_strike":
				var meteor_scene = load("res://scenes/skills/Meteor.tscn")
				if meteor_scene:
					var meteor = meteor_scene.instantiate()
					meteor.global_position = closest_target.global_position + Vector2(0, -400)
					meteor.target_pos = closest_target.global_position
					player_ref.get_parent().add_child(meteor)
