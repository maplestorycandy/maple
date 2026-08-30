# Global.gd
extends Node

signal player_hp_changed(current: int, max_hp: int)
signal player_mp_changed(current: int, max_mp: int)
signal player_exp_changed(current: int, max_exp: int, level: int)
signal player_job_changed(job_data: Dictionary)
signal player_stats_changed()
signal inventory_updated()
signal equipment_updated()
signal goddess_hp_changed(current: int, max_hp: int)
signal wave_changed(current_wave: int, max_wave: int)
signal pet_inventory_updated()
signal pet_summoned(pet_data: Dictionary)
signal pet_unsummoned()
signal message_broadcast(text: String, color: Color)
signal game_over_triggered(is_victory: bool)
signal map_change_requested(map_id: String)

# Job & Character Stats
var player_job_id: String = "warrior"
var player_job_data: Dictionary = {}

var player_level: int = 1
var player_exp: int = 0
var player_max_exp: int = 100
var player_hp: int = 750
var player_max_hp: int = 750
var player_mp: int = 120
var player_max_mp: int = 120

# Classic 4 Attributes & AP Point Allocation
var stat_str: int = 25
var stat_dex: int = 12
var stat_int: int = 4
var stat_luk: int = 4
var available_ap: int = 0 # 5 AP per level gained

# Equipment Bonus Attributes
var equip_bonus_atk: int = 0
var equip_bonus_magic_atk: int = 0
var equip_bonus_def: int = 0
var equip_bonus_speed: float = 0.0
var equip_bonus_str: int = 0
var equip_bonus_dex: int = 0
var equip_bonus_int: int = 0
var equip_bonus_luk: int = 0

# Base Combat Stats
var weapon_atk: int = 42
var magic_atk: int = 5
var mastery: float = 0.60
var base_crit_rate: float = 0.15
var player_speed: float = 250.0
var meso_gold: int = 500

# Inventory System (3 Categories: Equip, Use, Etc)
var equip_inventory: Array[Dictionary] = []
var use_inventory: Array[Dictionary] = []
var etc_inventory: Array[Dictionary] = []

# Equipped Slots
var equipped_items: Dictionary = {
	"weapon": null,
	"hat": null,
	"overall": null,
	"gloves": null,
	"shoes": null,
	"shield": null,
	"accessory": null
}

# Goddess Stats
var goddess_hp: int = 25000
var goddess_max_hp: int = 25000
var goddess_shield_active: bool = false

# Wave & Game State
var current_wave: int = 1
const MAX_WAVES: int = 50
var is_game_over: bool = false
var current_map_id: String = "100000000"

# Pet System
var pet_inventory: Array = []
var active_pet_data: Dictionary = {}
var active_pet_node: Node2D = null

# Active Passive Buffs
var passive_buffs: Dictionary = {
	"tame_mastery": false,
	"goddess_sanctuary": false,
	"chain_thunder": false,
	"speed_demon": false,
	"vampiric_drain": false,
	"crit_rate_boost": 0.0,
	"bonus_damage_mult": 1.0,
	"cooldown_reduction": 0.0
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_chinese_font()
	set_player_job("warrior")
	
	# Give starter equipment & potions
	give_starter_kit()

func setup_chinese_font():
	var font = load("res://assets/fonts/ChineseFont.ttf")
	if not font:
		var font_path = "res://assets/fonts/ChineseFont.ttf"
		if FileAccess.file_exists(font_path):
			var f = FontFile.new()
			f.data = FileAccess.get_file_as_bytes(font_path)
			font = f
	if font:
		ThemeDB.fallback_font = font

func give_starter_kit():
	# Starter Starter Pets & Consumables
	add_pet_to_inventory({
		"id": 2,
		"name": "藍寶 (夥伴)",
		"type": "Snail",
		"hp": 300,
		"max_hp": 300,
		"atk": 35,
		"speed": 120,
		"color": Color(0.2, 0.5, 0.9),
		"scale": 1.0,
		"level": 1
	})
	
	add_item_to_inventory("use", {"name": "白色藥水", "type": "potion", "heal_hp": 150, "count": 10})
	add_item_to_inventory("use", {"name": "藍色藥水", "type": "potion", "heal_mp": 80, "count": 10})
	
	# Starter Weapon
	add_item_to_inventory("equip", {
		"name": "初心者之劍",
		"slot": "weapon",
		"req_lvl": 1,
		"job": "劍士",
		"atk": 18,
		"str": 3
	})
	
	# Auto equip starter weapon
	equip_item(0)

# =========================================================================
# AP POINT ALLOCATION (STR / DEX / INT / LUK / HP / MP)
# =========================================================================
func allocate_ap(stat_name: String, amount: int = 1) -> bool:
	if available_ap < amount:
		return false
		
	available_ap -= amount
	match stat_name:
		"str":
			stat_str += amount
			player_max_hp += amount * 12
			player_hp = min(player_max_hp, player_hp + amount * 12)
		"dex":
			stat_dex += amount
		"int":
			stat_int += amount
			player_max_mp += amount * 8
			player_mp = min(player_max_mp, player_mp + amount * 8)
		"luk":
			stat_luk += amount
		"hp":
			player_max_hp += amount * 25
			player_hp = min(player_max_hp, player_hp + amount * 25)
		"mp":
			player_max_mp += amount * 18
			player_mp = min(player_max_mp, player_mp + amount * 18)
			
	recalculate_stats()
	emit_signal("player_stats_changed")
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	return true

func auto_allocate_ap():
	if available_ap <= 0:
		return
	var primary_stat = "str"
	var secondary_stat = "dex"
	
	match player_job_id:
		"warrior":
			primary_stat = "str"
			secondary_stat = "dex"
		"archer":
			primary_stat = "dex"
			secondary_stat = "str"
		"mage":
			primary_stat = "int"
			secondary_stat = "luk"
		"rogue":
			primary_stat = "luk"
			secondary_stat = "dex"
		"pirate":
			primary_stat = "str"
			secondary_stat = "dex"
			
	while available_ap >= 5:
		allocate_ap(primary_stat, 4)
		allocate_ap(secondary_stat, 1)
	while available_ap > 0:
		allocate_ap(primary_stat, 1)
		
	broadcast_message("⚡ 自動配點完成！已為【%s】分配最佳屬性！" % player_job_data.get("name", "職業"), Color.GOLD)

# =========================================================================
# INVENTORY & EQUIPMENT MANAGEMENT
# =========================================================================
func add_item_to_inventory(category: String, item: Dictionary):
	match category.to_lower():
		"equip", "equipment":
			if equip_inventory.size() < 32:
				# Generate authentic equipment attributes if not set
				var full_item = build_equipment_stats(item)
				equip_inventory.append(full_item)
				emit_signal("inventory_updated")
				return true
		"use", "consumable":
			for existing in use_inventory:
				if existing.name == item.name:
					existing.count = existing.get("count", 1) + item.get("count", 1)
					emit_signal("inventory_updated")
					return true
			if use_inventory.size() < 32:
				var new_item = item.duplicate()
				if not new_item.has("count"):
					new_item["count"] = 1
				use_inventory.append(new_item)
				emit_signal("inventory_updated")
				return true
		"etc", "material":
			for existing in etc_inventory:
				if existing.name == item.name:
					existing.count = existing.get("count", 1) + item.get("count", 1)
					emit_signal("inventory_updated")
					return true
			if etc_inventory.size() < 32:
				var new_item = item.duplicate()
				if not new_item.has("count"):
					new_item["count"] = 1
				etc_inventory.append(new_item)
				emit_signal("inventory_updated")
				return true
	return false

func build_equipment_stats(base_item: Dictionary) -> Dictionary:
	var item = base_item.duplicate()
	var name = item.get("name", "裝備")
	var req_lvl = item.get("req_lvl", 1)
	
	# Determine slot
	var slot = "weapon"
	if "帽" in name or "頭巾" in name or "頭盔" in name:
		slot = "hat"
	elif "服" in name or "衣" in name or "袍" in name:
		slot = "overall"
	elif "褲" in name or "裙" in name:
		slot = "overall"
	elif "手套" in name or "護腕" in name:
		slot = "gloves"
	elif "鞋" in name or "靴" in name:
		slot = "shoes"
	elif "盾" in name:
		slot = "shield"
	elif "戒" in name or "項鍊" in name or "耳環" in name or "披風" in name:
		slot = "accessory"
	else:
		slot = "weapon"
		
	item["slot"] = slot
	
	# Generate realistic stat values based on level
	if slot == "weapon":
		item["atk"] = item.get("atk", int(15 + req_lvl * 1.8))
		item["magic_atk"] = item.get("magic_atk", int(req_lvl * 1.9) if "杖" in name else 0)
		item["str"] = item.get("str", int(req_lvl * 0.15))
		item["dex"] = item.get("dex", int(req_lvl * 0.15))
		item["int"] = item.get("int", int(req_lvl * 0.15) if "杖" in name else 0)
		item["luk"] = item.get("luk", int(req_lvl * 0.15) if "短刀" in name or "拳套" in name else 0)
	else:
		item["def"] = item.get("def", int(8 + req_lvl * 1.2))
		item["str"] = item.get("str", max(1, int(req_lvl * 0.1)))
		item["dex"] = item.get("dex", max(1, int(req_lvl * 0.1)))
		item["int"] = item.get("int", max(1, int(req_lvl * 0.1)))
		item["luk"] = item.get("luk", max(1, int(req_lvl * 0.1)))
		if slot == "shoes":
			item["speed"] = item.get("speed", 5.0 + float(req_lvl) * 0.2)
			
	return item

func equip_item(inv_index: int) -> bool:
	if inv_index < 0 or inv_index >= equip_inventory.size():
		return false
		
	var item = equip_inventory[inv_index]
	var req_lvl = item.get("req_lvl", 1)
	if player_level < req_lvl:
		broadcast_message("❌ 等級不足！需要 Lv.%d 才能穿戴【%s】！" % [req_lvl, item.name], Color.RED)
		return false
		
	var slot = item.get("slot", "weapon")
	
	# Remove item from inventory
	equip_inventory.remove_at(inv_index)
	
	# If slot already has equipped item, swap back to inventory
	if equipped_items[slot] != null:
		equip_inventory.append(equipped_items[slot])
		
	equipped_items[slot] = item
	
	recalculate_stats()
	emit_signal("inventory_updated")
	emit_signal("equipment_updated")
	emit_signal("player_stats_changed")
	broadcast_message("⚔️ 已穿戴【%s】！屬性已即時實裝！" % item.name, Color(0.3, 1.0, 0.5))
	return true

func unequip_item(slot: String) -> bool:
	if not equipped_items.has(slot) or equipped_items[slot] == null:
		return false
		
	if equip_inventory.size() >= 32:
		broadcast_message("❌ 背包空間已滿，無法卸下裝備！", Color.RED)
		return false
		
	var item = equipped_items[slot]
	equipped_items[slot] = null
	equip_inventory.append(item)
	
	recalculate_stats()
	emit_signal("inventory_updated")
	emit_signal("equipment_updated")
	emit_signal("player_stats_changed")
	broadcast_message("已卸下【%s】放入背包！" % item.name, Color.YELLOW)
	return true

func use_consume_item(inv_index: int) -> bool:
	if inv_index < 0 or inv_index >= use_inventory.size():
		return false
		
	var item = use_inventory[inv_index]
	var item_name = item.get("name", "")
	
	if "白色" in item_name or "特殊" in item_name:
		heal_player(150)
		broadcast_message("★ 使用【%s】: 恢復 150 HP！" % item_name, Color(0.2, 1.0, 0.4))
	elif "藍色" in item_name:
		player_mp = min(player_max_mp, player_mp + 80)
		emit_signal("player_mp_changed", player_mp, player_max_mp)
		broadcast_message("★ 使用【%s】: 恢復 80 MP！" % item_name, Color(0.3, 0.8, 1.0))
	else:
		heal_player(100)
		player_mp = min(player_max_mp, player_mp + 50)
		emit_signal("player_mp_changed", player_mp, player_max_mp)
		broadcast_message("★ 使用【%s】！" % item_name, Color.CYAN)
		
	item.count -= 1
	if item.count <= 0:
		use_inventory.remove_at(inv_index)
		
	emit_signal("inventory_updated")
	return true

func recalculate_stats():
	# Reset equipment bonuses
	equip_bonus_atk = 0
	equip_bonus_magic_atk = 0
	equip_bonus_def = 0
	equip_bonus_speed = 0.0
	equip_bonus_str = 0
	equip_bonus_dex = 0
	equip_bonus_int = 0
	equip_bonus_luk = 0
	
	for slot in equipped_items.keys():
		var eq = equipped_items[slot]
		if eq != null:
			equip_bonus_atk += eq.get("atk", 0)
			equip_bonus_magic_atk += eq.get("magic_atk", 0)
			equip_bonus_def += eq.get("def", 0)
			equip_bonus_speed += eq.get("speed", 0.0)
			equip_bonus_str += eq.get("str", 0)
			equip_bonus_dex += eq.get("dex", 0)
			equip_bonus_int += eq.get("int", 0)
			equip_bonus_luk += eq.get("luk", 0)
			
	# Total effective stats
	var total_str = stat_str + equip_bonus_str
	var total_dex = stat_dex + equip_bonus_dex
	var total_int = stat_int + equip_bonus_int
	var total_luk = stat_luk + equip_bonus_luk
	
	# Update Attack Power based on Job Primary & Secondary Stat formulas
	match player_job_id:
		"warrior":
			weapon_atk = int((total_str * 4.0 + total_dex) * 0.45) + equip_bonus_atk + 25
			magic_atk = int(total_int * 1.5) + equip_bonus_magic_atk
		"archer":
			weapon_atk = int((total_dex * 4.0 + total_str) * 0.45) + equip_bonus_atk + 25
			magic_atk = int(total_int * 1.5) + equip_bonus_magic_atk
		"mage":
			magic_atk = int((total_int * 4.0 + total_luk) * 0.50) + equip_bonus_magic_atk + 35
			weapon_atk = int((total_str + total_dex) * 0.3) + equip_bonus_atk + 10
		"rogue":
			weapon_atk = int((total_luk * 4.0 + total_dex) * 0.48) + equip_bonus_atk + 28
			magic_atk = int(total_int * 1.5) + equip_bonus_magic_atk
		"pirate":
			weapon_atk = int((total_str * 3.8 + total_dex) * 0.45) + equip_bonus_atk + 25
			magic_atk = int(total_int * 1.5) + equip_bonus_magic_atk
			
	player_speed = 250.0 + equip_bonus_speed + (50.0 if passive_buffs.get("speed_demon", false) else 0.0)
	base_crit_rate = 0.15 + (float(total_luk) * 0.003) + passive_buffs.get("crit_rate_boost", 0.0)

# =========================================================================
# JOB & LEVELING SYSTEM
# =========================================================================
func set_player_job(job_id: String):
	if not JobDatabase.JOBS.has(job_id):
		return
	player_job_id = job_id
	player_job_data = JobDatabase.JOBS[job_id]
	
	# Update Job Initial Base Attributes
	stat_str = player_job_data.get("str", 15)
	stat_dex = player_job_data.get("dex", 15)
	stat_int = player_job_data.get("int", 15)
	stat_luk = player_job_data.get("luk", 15)
	player_max_hp = player_job_data.get("base_hp", 600) + (player_level - 1) * 75
	player_hp = player_max_hp
	player_max_mp = player_job_data.get("base_mp", 150) + (player_level - 1) * 35
	player_mp = player_max_mp
	
	recalculate_stats()
	emit_signal("player_job_changed", player_job_data)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	emit_signal("player_stats_changed")

func add_exp(amount: int):
	player_exp += amount
	while player_exp >= player_max_exp:
		player_exp -= player_max_exp
		level_up()
	emit_signal("player_exp_changed", player_exp, player_max_exp, player_level)

func level_up():
	player_level += 1
	player_max_exp = int(player_max_exp * 1.35) + 30
	player_max_hp += 80
	player_hp = player_max_hp
	player_max_mp += 40
	player_mp = player_max_mp
	
	# Grant 5 AP per level
	available_ap += 5
	
	recalculate_stats()
	emit_signal("player_exp_changed", player_exp, player_max_exp, player_level)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	emit_signal("player_stats_changed")
	broadcast_message("🎉 恭喜升級！Lv.%d！獲得 5 點能力值點數 (AP)！" % player_level, Color.GOLD)

func damage_player(amount: int):
	if is_game_over:
		return
	var net_dmg = max(1, amount - int(equip_bonus_def * 0.4))
	player_hp = max(0, player_hp - net_dmg)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	
	if player_hp <= 0:
		broadcast_message("☠ 您已陣亡！5秒後在當前地圖復活...", Color.RED)
		var t = get_tree().create_timer(3.0)
		t.timeout.connect(func():
			player_hp = player_max_hp
			emit_signal("player_hp_changed", player_hp, player_max_hp)
			broadcast_message("★ 重獲新生！HP 全滿！", Color.GREEN)
		)

func heal_player(amount: int):
	player_hp = min(player_max_hp, player_hp + amount)
	emit_signal("player_hp_changed", player_hp, player_max_hp)

func damage_goddess(amount: int):
	if is_game_over or goddess_shield_active:
		return
	goddess_hp = max(0, goddess_hp - amount)
	emit_signal("goddess_hp_changed", goddess_hp, goddess_max_hp)
	
	if goddess_hp <= 0:
		trigger_game_over(false)

func heal_goddess(amount: int):
	goddess_hp = min(goddess_max_hp, goddess_hp + amount)
	emit_signal("goddess_hp_changed", goddess_hp, goddess_max_hp)

func trigger_game_over(is_victory: bool):
	if is_game_over:
		return
	is_game_over = true
	emit_signal("game_over_triggered", is_victory)

func broadcast_message(text: String, color: Color = Color.WHITE):
	emit_signal("message_broadcast", text, color)

func add_pet_to_inventory(pet_data: Dictionary):
	pet_inventory.append(pet_data)
	emit_signal("pet_inventory_updated")

func remove_pet_from_inventory(index: int):
	if index >= 0 and index < pet_inventory.size():
		var pet = pet_inventory[index]
		if active_pet_data.get("name", "") == pet.get("name", ""):
			dismiss_active_pet()
		pet_inventory.remove_at(index)
		var reward_meso = max(10, int(pet.get("hp", 100) * 0.05))
		meso_gold += reward_meso
		emit_signal("pet_inventory_updated")
func calculate_skill_damage(multiplier: float) -> Dictionary:
	var base_dmg = float(weapon_atk) if player_job_id != "mage" else float(magic_atk)
	var mastery_min = mastery
	var rolled_mult = randf_range(mastery_min, 1.0)
	var is_crit = randf() < base_crit_rate
	
	var final_dmg = base_dmg * multiplier * rolled_mult * passive_buffs.get("bonus_damage_mult", 1.0)
	if is_crit:
		final_dmg *= 1.5
		
	return {
		"damage": max(1, int(final_dmg)),
		"is_crit": is_crit
	}

func summon_pet(pet_data: Dictionary):
	active_pet_data = pet_data
	emit_signal("pet_summoned", pet_data)
	broadcast_message("召喚寵物夥伴: 【%s】出戰！" % pet_data.get("name", "寵物"), Color(0.3, 1.0, 0.5))

func dismiss_active_pet():
	if not active_pet_data.is_empty():
		var p_name = active_pet_data.get("name", "寵物")
		active_pet_data = {}
		emit_signal("pet_unsummoned")
		if is_instance_valid(active_pet_node):
			active_pet_node.queue_free()
		broadcast_message("寵物【%s】已召回休息。" % p_name, Color.WHITE)

func select_active_pet(index: int):
	if index >= 0 and index < pet_inventory.size():
		summon_pet(pet_inventory[index])

func reset_game_state():
	is_game_over = false
	current_wave = 1
	goddess_hp = goddess_max_hp
	player_hp = player_max_hp
	player_mp = player_max_mp
	emit_signal("goddess_hp_changed", goddess_hp, goddess_max_hp)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	emit_signal("wave_changed", current_wave, MAX_WAVES)

func change_map(map_id: String):
	current_map_id = map_id
	emit_signal("map_change_requested", map_id)
	if MapDatabase.MAPS.has(map_id):
		broadcast_message("傳送至: %s" % MapDatabase.MAPS[map_id].name, Color(0.4, 0.8, 1.0))
