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
signal skill_draft_requested(cards: Array)
signal keybindings_changed()
signal active_skills_updated()

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
var touch_move_dir: float = 0.0
var meso_gold: int = 500

# Custom Keybinding System
var custom_keybindings: Dictionary = {
	"attack": KEY_Z,
	"jump": KEY_SPACE,
	"skill_1": KEY_X,
	"skill_2": KEY_C,
	"skill_3": KEY_V,
	"skill_4": KEY_B,
	"skill_5": KEY_N,
	"skill_6": KEY_M,
	"ultimate": KEY_F,
	"tame_monster": KEY_E,
	"summon_pet": KEY_R,
	"potion_hp": KEY_1,
	"potion_mp": KEY_2
}

var unlocked_skills: Array = ["basic", "skill_1", "skill_2", "skill_3"]
var drafted_passives: Array = []

var exp_rate_multiplier: float = 5.0 # 500% EXP Multiplier (5x)

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

const SLOT_PRIORITY: Dictionary = {
	"weapon": 0,
	"hat": 1,
	"overall": 2,
	"gloves": 3,
	"shoes": 4,
	"shield": 5,
	"accessory": 6
}

# =========================================================================
# INVENTORY & EQUIPMENT MANAGEMENT (AUTO-SORT & STACKING)
# =========================================================================
func sort_equipment_inventory():
	equip_inventory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var slot_a = SLOT_PRIORITY.get(a.get("slot", "weapon"), 99)
		var slot_b = SLOT_PRIORITY.get(b.get("slot", "weapon"), 99)
		if slot_a != slot_b:
			return slot_a < slot_b
		var lvl_a = a.get("req_lvl", 1)
		var lvl_b = b.get("req_lvl", 1)
		if lvl_a != lvl_b:
			return lvl_a < lvl_b
		return a.get("name", "") < b.get("name", "")
	)

func add_item_to_inventory(category: String, item: Dictionary) -> bool:
	# Redirect ammo to use inventory
	var raw_slot = str(item.get("slot", "")).to_lower()
	var raw_name = str(item.get("name", ""))
	if raw_slot in ["arrow", "bullet", "throwing-star", "stars"] or "Arrow" in raw_name or "Bullet" in raw_name or "Throwing-Star" in raw_name:
		category = "use"

	match category.to_lower():
		"equip", "equipment":
			var full_item = build_equipment_stats(item)
			# Auto-stacking with same item name and slot
			for existing in equip_inventory:
				if existing.get("name", "") == full_item.get("name", "") and existing.get("slot", "") == full_item.get("slot", ""):
					existing["count"] = existing.get("count", 1) + item.get("count", 1)
					sort_equipment_inventory()
					emit_signal("inventory_updated")
					return true
					
			if equip_inventory.size() < 40:
				if not full_item.has("count"):
					full_item["count"] = 1
				equip_inventory.append(full_item)
				sort_equipment_inventory()
				emit_signal("inventory_updated")
				return true
		"use", "consumable":
			for existing in use_inventory:
				if existing.name == item.name:
					existing.count = existing.get("count", 1) + item.get("count", 1)
					emit_signal("inventory_updated")
					return true
			if use_inventory.size() < 40:
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
			if etc_inventory.size() < 40:
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
	var raw_slot = str(item.get("slot", "")).to_lower().strip_edges()
	
	var slot = ""
	
	# 1. Check raw slot if provided
	if raw_slot in ["hat", "cap", "helm", "headband", "hood"]:
		slot = "hat"
	elif raw_slot in ["overall", "top", "bottom", "dress", "robe", "suit", "pants", "skirt", "mail"]:
		slot = "overall"
	elif raw_slot in ["gloves", "glove", "half-glove", "gauntlet", "wrist"]:
		slot = "gloves"
	elif raw_slot in ["shoes", "boots", "slipper", "sandals"]:
		slot = "shoes"
	elif raw_slot in ["shield"]:
		slot = "shield"
	elif raw_slot in ["accessory", "earrings", "ring", "pendant", "cape", "belt", "necklace", "eye"]:
		slot = "accessory"
	elif raw_slot in ["weapon", "sword", "axe", "blunt", "spear", "polearm", "staff", "wand", "bow", "crossbow", "dagger", "claw", "knuckle", "gun", "cannon", "katar", "throwing-star", "bullet", "arrow"]:
		if raw_slot in ["arrow", "bullet", "throwing-star"]:
			slot = "accessory"
		else:
			slot = "weapon"
			
	# 2. Comprehensive keyword matching if slot still undetermined
	if slot == "":
		var lname = name.to_lower()
		if "earring" in lname or "ring" in lname or "pendant" in lname or "cape" in lname or "belt" in lname or "square" in lname or "necklace" in lname or "戒" in name or "項鍊" in name or "耳環" in name or "披風" in name or "眼罩" in name or "腰帶" in name or "墜飾" in name:
			slot = "accessory"
		elif "hat" in lname or "helm" in lname or "cap" in lname or "bandana" in lname or "hood" in lname or "circlet" in lname or "beret" in lname or "headband" in lname or "jester" in lname or "skullcap" in lname or "crown" in lname or "wisconsin" in lname or "koif" in lname or "burgernet" in lname or "帽" in name or "頭巾" in name or "頭盔" in name or "羽冠" in name or "冠" in name:
			slot = "hat"
		elif "glove" in lname or "gloves" in lname or "halfglove" in lname or "gauntlet" in lname or "savata" in lname or "mesana" in lname or "wolfskin" in lname or "fingerless" in lname or "手套" in name or "護手" in name or "護腕" in name or "指套" in name:
			slot = "gloves"
		elif "boot" in lname or "boots" in lname or "shoe" in lname or "shoes" in lname or "sandal" in lname or "sandals" in lname or "slipper" in lname or "gomushin" in lname or "heels" in lname or "krag" in lname or "nitty" in lname or "鞋" in name or "靴" in name or "長靴" in name or "皮靴" in name or "鐵鞋" in name:
			slot = "shoes"
		elif "shield" in lname or "lid" in lname or "fence" in lname or "盾" in name or "鍋蓋" in name:
			slot = "shield"
		elif "top" in lname or "bottom" in lname or "pant" in lname or "pants" in lname or "skirt" in lname or "robe" in lname or "suit" in lname or "overall" in lname or "mail" in lname or "armor" in lname or "chainmail" in lname or "jean" in lname or "jeans" in lname or "short" in lname or "shorts" in lname or "sweat" in lname or "shirt" in lname or "lagger" in lname or "carribean" in lname or "doros" in lname or "doroness" in lname or "starlight" in lname or "distinction" in lname or "calas" in lname or "china" in lname or "pao" in lname or "arianne" in lname or "avelin" in lname or "lolica" in lname or "nightshift" in lname or "corporal" in lname or "lamelle" in lname or "kendo" in lname or "套服" in name or "長袍" in name or "鎧甲" in name or "戰甲" in name or "衣服" in name or "上衣" in name or "褲" in name or "裙" in name or "袍" in name or "甲" in name:
			slot = "overall"
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
		item["luk"] = item.get("luk", int(req_lvl * 0.15) if "短刀" in name or "手甲" in name else 0)
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
	var cur_count = item.get("count", 1)
	var single_item = item.duplicate()
	single_item["count"] = 1
	
	# Decrement stack count or remove
	if cur_count > 1:
		item["count"] = cur_count - 1
	else:
		equip_inventory.remove_at(inv_index)
	
	# If slot already has equipped item, swap back to inventory
	if equipped_items[slot] != null:
		add_item_to_inventory("equip", equipped_items[slot])
		
	equipped_items[slot] = single_item
	
	sort_equipment_inventory()
	recalculate_stats()
	emit_signal("inventory_updated")
	emit_signal("equipment_updated")
	emit_signal("player_stats_changed")
	broadcast_message("⚔️ 已穿戴【%s】！屬性已即時實裝！" % single_item.name, Color(0.3, 1.0, 0.5))
	return true

func unequip_item(slot: String) -> bool:
	if not equipped_items.has(slot) or equipped_items[slot] == null:
		return false
		
	var item = equipped_items[slot]
	equipped_items[slot] = null
	add_item_to_inventory("equip", item)
	
	sort_equipment_inventory()
	recalculate_stats()
	emit_signal("inventory_updated")
	emit_signal("equipment_updated")
	emit_signal("player_stats_changed")
	broadcast_message("卸下裝備【%s】。" % item.name, Color.WHITE)
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
	
	# Base level attack scaling (Every level makes you noticeably stronger!)
	var lvl_atk_bonus = player_level * 8
	
	# Update Attack Power based on Job Primary & Secondary Stat formulas (Infinitely scaling with AP & Equips!)
	match player_job_id:
		"warrior":
			weapon_atk = int((total_str * 4.2 + total_dex * 1.5) * 1.6) + int(equip_bonus_atk * 2.5) + lvl_atk_bonus + 45
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
		"archer":
			weapon_atk = int((total_dex * 4.4 + total_str * 1.3) * 1.6) + int(equip_bonus_atk * 2.5) + lvl_atk_bonus + 45
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
		"mage":
			magic_atk = int((total_int * 4.5 + total_luk * 1.5) * 1.7) + int(equip_bonus_magic_atk * 2.8) + (player_level * 10) + 60
			weapon_atk = int((total_str + total_dex) * 1.0) + equip_bonus_atk + 20
		"rogue":
			weapon_atk = int((total_luk * 4.6 + total_dex * 1.6) * 1.7) + int(equip_bonus_atk * 2.5) + lvl_atk_bonus + 50
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
		"pirate":
			weapon_atk = int((total_str * 4.2 + total_dex * 1.5) * 1.6) + int(equip_bonus_atk * 2.5) + lvl_atk_bonus + 45
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
		_:
			weapon_atk = int((total_str * 3.0 + total_dex * 1.2) * 1.2) + equip_bonus_atk + lvl_atk_bonus + 30
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
			
	player_speed = 250.0 + equip_bonus_speed + (50.0 if passive_buffs.get("speed_demon", false) else 0.0)
	base_crit_rate = clamp(0.15 + (float(total_luk) * 0.005) + passive_buffs.get("crit_rate_boost", 0.0), 0.15, 0.95)

# =========================================================================
# JOB & LEVELING SYSTEM
# =========================================================================
func set_player_job(job_id: String):
	if not JobDatabase.JOBS.has(job_id):
		return
	player_job_id = job_id
	player_job_data = JobDatabase.JOBS[job_id]
	
	# Update Job Initial Base Attributes
	var b_stats = player_job_data.get("base_stats", {})
	stat_str = b_stats.get("str", player_job_data.get("str", 25))
	stat_dex = b_stats.get("dex", player_job_data.get("dex", 15))
	stat_int = b_stats.get("int", player_job_data.get("int", 10))
	stat_luk = b_stats.get("luk", player_job_data.get("luk", 10))
	
	player_max_hp = b_stats.get("hp", player_job_data.get("base_hp", 650)) + (player_level - 1) * 80
	player_hp = player_max_hp
	player_max_mp = b_stats.get("mp", player_job_data.get("base_mp", 150)) + (player_level - 1) * 40
	player_mp = player_max_mp
	
	recalculate_stats()
	emit_signal("player_job_changed", player_job_data)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	emit_signal("player_stats_changed")

func add_exp(amount: int):
	var boosted_exp = int(amount * exp_rate_multiplier * passive_buffs.get("exp_gain_mult", 1.0))
	player_exp += boosted_exp
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
	# Every 5 levels, trigger 3-Choice Roguelike Skill Draft!
	if player_level % 5 == 0:
		var cards = generate_skill_draft_cards()
		emit_signal("skill_draft_requested", cards)


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
	var rolled_mult = randf_range(mastery_min, 1.05)
	var is_crit = randf() < base_crit_rate
	
	var final_dmg = base_dmg * multiplier * rolled_mult * passive_buffs.get("bonus_damage_mult", 1.0)
	if is_crit:
		final_dmg *= randf_range(2.0, 2.5) # 200% ~ 250% Critical Strike
		
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


# =========================================================================
# ROGUELIKE SKILL DRAFT & CUSTOM KEYBINDINGS
# =========================================================================
func generate_skill_draft_cards() -> Array:
	var job_skills = player_job_data.get("skills", {})
	var candidates: Array = []
	
	# 1. Active Skill Unlocks & Enhancements
	for s_key in ["skill_4", "skill_5", "skill_6", "ultimate"]:
		if job_skills.has(s_key):
			var s_data = job_skills[s_key]
			var is_new = not (s_key in unlocked_skills)
			candidates.append({
				"id": s_key,
				"category": "active_skill",
				"name": ("【新技能解鎖】" if is_new else "【技能覺醒升級】") + s_data.get("name", ""),
				"rarity": "Legendary" if s_key == "ultimate" else "Epic",
				"desc": s_data.get("desc", "獲得強大職業主動技能！"),
				"icon": "⚔️" if "slash" in str(s_data) else ("🏹" if "arrow" in str(s_data) else ("⚡" if "magic" in str(s_data) else "💥")),
				"skill_key": s_key
			})
			
	# 2. Job-Specific Passives
	match player_job_id:
		"warrior":
			candidates.append({"id": "warrior_combo", "category": "passive", "name": "鬥氣狂熱 ‧ 黑暗神兵", "rarity": "Legendary", "desc": "每次攻擊累積鬥氣，最終傷害乘算提升 +45%！", "icon": "🔥", "buff": {"bonus_damage_mult": 0.45}})
			candidates.append({"id": "final_attack", "category": "passive", "name": "終極攻擊 (Final Attack)", "rarity": "Epic", "desc": "攻擊時 30% 機率額外追加 280% 巨力重斬！", "icon": "⚔️", "buff": {"final_attack_rate": 0.30}})
		"magician":
			candidates.append({"id": "magic_amp", "category": "passive", "name": "元素增幅 ‧ 魔力無限", "rarity": "Legendary", "desc": "全魔法技能傷害 +50%，消耗 MP 減少 20%！", "icon": "🔮", "buff": {"magic_atk_mult": 0.50, "mp_cost_reduction": 0.20}})
			candidates.append({"id": "magic_drain", "category": "passive", "name": "魔力吸取 ‧ 永恆治癒", "rarity": "Epic", "desc": "每次命中敵人吸收造成傷害 12% 轉化為生命與魔力！", "icon": "✨", "buff": {"life_steal": 0.12}})
		"bowman":
			candidates.append({"id": "sharp_eyes", "category": "passive", "name": "會心之眼 (Sharp Eyes)", "rarity": "Legendary", "desc": "暴擊率 +30%，暴擊傷害乘算提升 +70%！", "icon": "🎯", "buff": {"crit_rate": 0.30, "crit_dmg_mult": 0.70}})
			candidates.append({"id": "wind_walker", "category": "passive", "name": "風靈使者 ‧ 極速神箭", "rarity": "Epic", "desc": "射速提升 35%，所有技能冷卻縮減 30%！", "icon": "🍃", "buff": {"cooldown_reduction": 0.30}})
		"thief":
			candidates.append({"id": "shadow_partner_passive", "category": "passive", "name": "影之夥伴 ‧ 雙重暗殺", "rarity": "Legendary", "desc": "影分身常駐召喚！全攻擊額外造成 100% 獨立真實傷害！", "icon": "👤", "buff": {"shadow_partner_active": true}})
			candidates.append({"id": "deadly_poison", "category": "passive", "name": "致命劇毒 ‧ 刺客信條", "rarity": "Epic", "desc": "暴擊率 +25%，每次攻擊附帶劇毒持續扣血！", "icon": "🗡️", "buff": {"crit_rate": 0.25, "poison_touch": true}})
		"pirate":
			candidates.append({"id": "pirate_supercharge", "category": "passive", "name": "超負荷充能 ‧ 鋼鐵之軀", "rarity": "Legendary", "desc": "物理攻擊力 +40%，受到傷害減免 35%！", "icon": "⚓", "buff": {"watk_mult": 0.40, "damage_reduction": 0.35}})
			candidates.append({"id": "battleship_support", "category": "passive", "name": "海賊大砲 ‧ 全自動火力", "rarity": "Epic", "desc": "戰艦自動每 4 秒向周圍敵人發射 400% 重砲轟炸！", "icon": "💣", "buff": {"auto_cannon": true}})

	# 3. Global Transcendent Buffs
	candidates.append({"id": "divine_wrath", "category": "passive", "name": "天神下凡 ‧ 萬雷神罰", "rarity": "Legendary", "desc": "每 3.5 秒自動召喚全螢幕天雷轟炸所有怪物 500% 傷害！", "icon": "⚡", "buff": {"auto_lightning": true}})
	candidates.append({"id": "blood_thirst", "category": "passive", "name": "嗜血狂魔 ‧ 越戰越勇", "rarity": "Epic", "desc": "每次攻擊吸血 8% MaxHP，移動速度 +35%！", "icon": "🩸", "buff": {"life_steal": 0.08, "speed_bonus": 35.0}})
	candidates.append({"id": "wealth_frenzy", "category": "passive", "name": "黃金財富 ‧ 雙倍掉落", "rarity": "Rare", "desc": "怪物掉落楓幣與稀有裝備機率 +100%！", "icon": "💰", "buff": {"double_drops": true}})
	candidates.append({"id": "stat_titan", "category": "passive", "name": "泰坦神力 ‧ 全屬性飛升", "rarity": "Epic", "desc": "力量、敏捷、智力、幸運全體直接暴增 +80 點！", "icon": "💎", "buff": {"all_stats": 80}})
	
	candidates.shuffle()
	return candidates.slice(0, 3)

func apply_draft_card(card: Dictionary):
	var cat = card.get("category", "")
	var name = card.get("name", "覺醒技能")
	
	if cat == "active_skill":
		var s_key = card.get("skill_key", "")
		if not (s_key in unlocked_skills):
			unlocked_skills.append(s_key)
			emit_signal("active_skills_updated")
			broadcast_message("🌟 成功覺醒解鎖全新技能：%s！" % name, Color(1.0, 0.85, 0.2))
		else:
			var s_data = player_job_data.get("skills", {}).get(s_key, {})
			s_data["multiplier"] = s_data.get("multiplier", 1.0) * 1.35
			broadcast_message("⚡ %s 威力提升 +35%！" % name, Color(0.3, 1.0, 0.5))
	else:
		drafted_passives.append(card)
		var buff = card.get("buff", {})
		for k in buff.keys():
			if k == "all_stats":
				stat_str += buff[k]
				stat_dex += buff[k]
				stat_int += buff[k]
				stat_luk += buff[k]
			elif typeof(buff[k]) == TYPE_FLOAT or typeof(buff[k]) == TYPE_INT:
				passive_buffs[k] = passive_buffs.get(k, 0.0) + buff[k]
			else:
				passive_buffs[k] = buff[k]
		recalculate_stats()
		broadcast_message("✨ 成功融合覺醒天賦【%s】！" % name, Color(0.4, 0.9, 1.0))

func rebind_key(action_name: String, key_code: int):
	custom_keybindings[action_name] = key_code
	emit_signal("keybindings_changed")
	save_keybindings()

func get_action_key_name(action_name: String) -> String:
	var code = custom_keybindings.get(action_name, KEY_Z)
	return OS.get_keycode_string(code)

func save_keybindings():
	var cfg = ConfigFile.new()
	for k in custom_keybindings.keys():
		cfg.set_value("keybindings", k, custom_keybindings[k])
	cfg.save("user://keybindings.cfg")

func load_keybindings():
	var cfg = ConfigFile.new()
	var err = cfg.load("user://keybindings.cfg")
	if err == OK:
		for k in custom_keybindings.keys():
			if cfg.has_section_key("keybindings", k):
				custom_keybindings[k] = cfg.get_value("keybindings", k)
