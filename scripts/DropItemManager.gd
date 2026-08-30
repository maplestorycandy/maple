# DropItemManager.gd
# 100% 正版 BoBo 掉落保證：每隻怪物擊殺必定噴出【楓幣 + 專屬裝備 + 消耗藥水 + 戰利品材料】大爆裝！
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
	
	# 1. 楓幣金幣袋 (100% 必定掉落)
	var meso_val = max(30, int(monster_data.get("exp", 25) * randf_range(1.5, 3.0)))
	spawn_single_drop(parent, spawn_pos, {
		"name": "%d 楓幣" % meso_val,
		"type": "meso",
		"meso_amount": meso_val
	}, Vector2(randf_range(-40, 40), -160))
	
	# 2. 裝備掉落 (100% 必定掉落，BOSS 掉落 3~5 件神裝！)
	var eq_count = randi_range(3, 5) if is_boss else 1
	for i in range(eq_count):
		var eq_item = null
		if not eq_list.is_empty():
			eq_item = eq_list[randi() % eq_list.size()]
		else:
			eq_item = generate_fallback_equipment(mob_lvl, mob_name)
			
		var vel_x = randf_range(-110, 110)
		spawn_single_drop(parent, spawn_pos, {
			"name": eq_item.get("name", "稀有裝備"),
			"type": "equipment",
			"req_lvl": eq_item.get("req_lvl", mob_lvl),
			"job": eq_item.get("job", "")
		}, Vector2(vel_x, randf_range(-200, -150)))
		
	# 3. 消耗品 / 藥水 (100% 必定掉落)
	var pot_name = "紅色藥水"
	if not con_list.is_empty():
		pot_name = con_list[randi() % con_list.size()].get("name", "紅色藥水")
	else:
		pot_name = "紅色藥水" if mob_lvl < 25 else ("白色藥水" if mob_lvl < 60 else "超級藥水")
		
	spawn_single_drop(parent, spawn_pos, {
		"name": pot_name,
		"type": "consumable"
	}, Vector2(randf_range(-80, -20), -180))
	
	# 4. 材料 / 怪物戰利品 (100% 必定掉落)
	var mat_name = "%s的戰利品" % mob_name
	if not mat_list.is_empty():
		mat_name = mat_list[randi() % mat_list.size()].get("name", mat_name)
		
	spawn_single_drop(parent, spawn_pos, {
		"name": mat_name,
		"type": "material"
	}, Vector2(randf_range(20, 80), -180))

static func generate_fallback_equipment(lvl: int, _mob_name: String) -> Dictionary:
	var weapons = ["雙手劍", "精鋼短刀", "獵人之弓", "幻影法杖", "雷電手甲", "雙管短槍", "鋼鐵戰錘"]
	var armors = ["頭盔", "戰甲", "長袍", "皮靴", "護手", "木盾"]
	var is_wp = randf() < 0.6
	var item_base = weapons[randi() % weapons.size()] if is_wp else armors[randi() % armors.size()]
	var prefix = "初心者" if lvl < 15 else ("青銅" if lvl < 35 else ("鋼鐵" if lvl < 65 else ("精靈" if lvl < 90 else "傳奇神聖")))
	return {
		"name": "%s%s" % [prefix, item_base],
		"req_lvl": max(1, lvl),
		"job": "全職業"
	}

static func spawn_single_drop(parent: Node, pos: Vector2, item_data: Dictionary, initial_vel: Vector2 = Vector2.ZERO):
	if not drop_scene:
		drop_scene = load("res://scenes/entities/DropItem.tscn")
	var item = drop_scene.instantiate()
	item.setup(item_data, pos, initial_vel)
	if is_instance_valid(parent):
		parent.add_child.call_deferred(item)
	else:
		var cur = Engine.get_main_loop().current_scene
		if is_instance_valid(cur):
			cur.add_child.call_deferred(item)
