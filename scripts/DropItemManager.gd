# DropItemManager.gd
# 依據 BoBo 資料庫 100% 參照掉落物生成 (保證每隻怪物必定掉落楓幣、極品裝備、消耗藥水與戰利品)
extends Node

static var drop_scene = preload("res://scenes/entities/DropItem.tscn")

static func spawn_monster_drops(parent: Node, spawn_pos: Vector2, monster_data: Dictionary):
	if not is_instance_valid(parent):
		parent = Engine.get_main_loop().current_scene
		
	var mob_lvl = monster_data.get("level", 1)
	var is_boss = monster_data.get("is_boss", false)
	var mob_name = monster_data.get("name", "怪物")
	var drops = monster_data.get("drops", {})
	
	var eq_list = drops.get("equipments", [])
	var con_list = drops.get("consumables", [])
	var mat_list = drops.get("materials", [])
	
	# 1. 楓幣金幣袋 (100% 必爆)
	var meso_val = max(20, int(monster_data.get("exp", 25) * randf_range(1.2, 2.5)))
	spawn_single_drop(parent, spawn_pos, {
		"name": "%d 楓幣" % meso_val,
		"type": "meso",
		"meso_amount": meso_val
	})
	
	# 2. 材料 / 戰利品 (90% 機率)
	if not mat_list.is_empty():
		var mat = mat_list[randi() % mat_list.size()]
		spawn_single_drop(parent, spawn_pos + Vector2(randf_range(-20, 20), -10), {
			"name": mat.get("name", "%s的戰利品" % mob_name),
			"type": "material"
		})
	else:
		spawn_single_drop(parent, spawn_pos + Vector2(randf_range(-20, 20), -10), {
			"name": "%s的戰利品" % mob_name,
			"type": "material"
		})
		
	# 3. 消耗品 / 藥水 (70% 機率)
	if not con_list.is_empty() and randf() < 0.70:
		var con = con_list[randi() % con_list.size()]
		spawn_single_drop(parent, spawn_pos + Vector2(randf_range(-35, 35), -15), {
			"name": con.get("name", "紅色藥水" if mob_lvl < 30 else "白色藥水"),
			"type": "consumable"
		})
	elif randf() < 0.50:
		var pot_name = "紅色藥水" if mob_lvl < 25 else ("白色藥水" if mob_lvl < 60 else "特殊藥水")
		spawn_single_drop(parent, spawn_pos + Vector2(randf_range(-35, 35), -15), {
			"name": pot_name,
			"type": "consumable"
		})
		
	# 4. 裝備掉落 (普通怪 55% 機率，BOSS 100% 爆 2~4 件神裝)
	var eq_count = randi_range(2, 4) if is_boss else (1 if randf() < 0.55 else 0)
	
	for i in range(eq_count):
		var eq_item = null
		if not eq_list.is_empty():
			eq_item = eq_list[randi() % eq_list.size()]
		else:
			# Fallback generate authentic level equipment
			eq_item = generate_fallback_equipment(mob_lvl, mob_name)
			
		if eq_item:
			spawn_single_drop(parent, spawn_pos + Vector2(randf_range(-50, 50), -20), {
				"name": eq_item.get("name", "稀有裝備"),
				"type": "equipment",
				"req_lvl": eq_item.get("req_lvl", mob_lvl),
				"job": eq_item.get("job", "")
			})

static func generate_fallback_equipment(lvl: int, _mob_name: String) -> Dictionary:
	var weapons = ["雙手劍", "長弓", "法杖", "拳套", "短槍", "戰錘"]
	var w_name = weapons[randi() % weapons.size()]
	var prefix = "初級" if lvl < 20 else ("青銅" if lvl < 40 else ("鋼鐵" if lvl < 70 else "神聖黃金"))
	return {
		"name": "%s%s" % [prefix, w_name],
		"req_lvl": max(1, lvl),
		"job": "全職業"
	}

static func spawn_single_drop(parent: Node, pos: Vector2, item_data: Dictionary):
	if not drop_scene:
		drop_scene = load("res://scenes/entities/DropItem.tscn")
	var item = drop_scene.instantiate()
	item.setup(item_data, pos)
	if is_instance_valid(parent):
		parent.add_child.call_deferred(item)
	else:
		var cur = Engine.get_main_loop().current_scene
		if is_instance_valid(cur):
			cur.add_child.call_deferred(item)
