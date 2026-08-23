# Global.gd
extends Node

signal player_hp_changed(current: int, max_hp: int)
signal player_mp_changed(current: int, max_mp: int)
signal player_exp_changed(current: int, max_exp: int, level: int)
signal player_job_changed(job_data: Dictionary)
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

# Classic 4 Attributes
var stat_str: int = 25
var stat_dex: int = 12
var stat_int: int = 4
var stat_luk: int = 4
var weapon_atk: int = 42
var magic_atk: int = 5
var mastery: float = 0.60
var base_crit_rate: float = 0.15
var player_speed: float = 250.0
var meso_gold: int = 0

# Goddess Stats
var goddess_hp: int = 25000
var goddess_max_hp: int = 25000
var goddess_shield_active: bool = false

# Wave & Game State
var current_wave: int = 1
const MAX_WAVES: int = 50
var is_game_over: bool = false
var current_map_id: String = "henesys_field"

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
	
	# Load Chinese NotoSans font dynamically for Web & Desktop
	setup_chinese_font()
	
	set_player_job("warrior")

func setup_chinese_font():
	var font_path = "res://assets/fonts/NotoSansTC-Regular.otf"
	if not FileAccess.file_exists(font_path):
		font_path = "res://assets/fonts/NotoSansTC.ttf"
		
	var bytes = FileAccess.get_file_as_bytes(font_path)
	if bytes.size() > 0:
		var font = FontFile.new()
		font.data = bytes
		ThemeDB.fallback_font = font
	
	# Starter Companion: Snail
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

func set_player_job(job_id: String):
	player_job_id = job_id
	player_job_data = JobDatabase.get_job(job_id)
	
	var base = player_job_data.base_stats
	stat_str = base.str
	stat_dex = base.dex
	stat_int = base.int
	stat_luk = base.luk
	player_max_hp = base.hp
	player_hp = player_max_hp
	player_max_mp = base.mp
	player_mp = player_max_mp
	weapon_atk = base.watk
	magic_atk = base.matk
	mastery = base.mastery
	base_crit_rate = base.crit_rate
	
	# Apply growth if level > 1
	if player_level > 1:
		apply_level_growth(player_level - 1)
		
	emit_signal("player_job_changed", player_job_data)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	broadcast_message("【轉職成功】成為了 經典版 %s！" % player_job_data.name, player_job_data.color)

func apply_level_growth(levels_to_add: int):
	var growth = player_job_data.growth
	player_max_hp += growth.hp * levels_to_add
	player_hp = player_max_hp
	player_max_mp += growth.mp * levels_to_add
	player_mp = player_max_mp
	stat_str += growth.str * levels_to_add
	stat_dex += growth.dex * levels_to_add
	stat_int += growth.int * levels_to_add
	stat_luk += growth.luk * levels_to_add
	weapon_atk += growth.watk * levels_to_add
	if growth.has("matk"):
		magic_atk += growth.matk * levels_to_add

func add_exp(amount: int):
	player_exp += amount
	broadcast_message("+%d EXP" % amount, Color(1.0, 0.9, 0.3))
	while player_exp >= player_max_exp:
		player_exp -= player_max_exp
		level_up()
	emit_signal("player_exp_changed", player_exp, player_max_exp, player_level)

func level_up():
	player_level += 1
	player_max_exp = int(player_max_exp * 1.32) + 60
	apply_level_growth(1)
	
	broadcast_message("★ LEVEL UP! Lv.%d (%s) ★" % [player_level, player_job_data.name], Color(1.0, 0.84, 0.0))
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	emit_signal("player_exp_changed", player_exp, player_max_exp, player_level)
	
	# Check 3-choice buff trigger every 5 levels
	LevelBuffManager.check_level_up(player_level)

# 經典楓之谷傷害計算公式
func calculate_skill_damage(multiplier: float, is_magic: bool = false) -> Dictionary:
	var min_range: float = 10.0
	var max_range: float = 30.0
	
	match player_job_id:
		"warrior":
			max_range = ((stat_str * 4.0 + stat_dex) / 100.0) * weapon_atk
			min_range = ((stat_str * 4.0 * 0.9 * mastery + stat_dex) / 100.0) * weapon_atk
		"magician":
			max_range = ((magic_atk * magic_atk / 1000.0 + magic_atk * 3.2 + stat_int * 5.2) / 30.0) * 12.0
			min_range = ((magic_atk * magic_atk / 1000.0 + magic_atk * 3.2 * 0.9 * mastery + stat_int * 5.2) / 30.0) * 12.0
		"bowman":
			max_range = ((stat_dex * 3.4 + stat_str) / 100.0) * weapon_atk
			min_range = ((stat_dex * 3.4 * 0.9 * mastery + stat_str) / 100.0) * weapon_atk
		"thief":
			max_range = ((stat_luk * 5.0) / 100.0) * weapon_atk
			min_range = ((stat_luk * 2.5) / 100.0) * weapon_atk
		"pirate":
			max_range = ((stat_str * 4.8 + stat_dex) / 100.0) * weapon_atk
			min_range = ((stat_str * 4.8 * 0.9 * mastery + stat_dex) / 100.0) * weapon_atk
			
	# Apply Passive bonus multiplier
	var base_dmg = randf_range(min_range, max_range) * multiplier * passive_buffs.get("bonus_damage_mult", 1.0)
	
	# Roll critical hit
	var total_crit_rate = base_crit_rate + passive_buffs.get("crit_rate_boost", 0.0)
	var is_crit = randf() < total_crit_rate
	var final_damage = base_dmg
	if is_crit:
		final_damage = base_dmg * (1.5 + (stat_luk * 0.005)) # Critical bonus
		
	return {
		"damage": max(1, int(final_damage)),
		"is_crit": is_crit,
		"job_id": player_job_id
	}

func damage_player(amount: int) -> bool:
	if is_game_over:
		return false
	var defense = int(stat_str * 0.3 + stat_dex * 0.2)
	var effective_damage = max(1, amount - defense)
	player_hp = clamp(player_hp - effective_damage, 0, player_max_hp)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	
	if player_hp <= 0:
		trigger_game_over(false)
		return true
	return false

func heal_player(amount: int):
	player_hp = clamp(player_hp + amount, 0, player_max_hp)
	emit_signal("player_hp_changed", player_hp, player_max_hp)

func damage_goddess(amount: int):
	if is_game_over:
		return
	var final_amount = amount
	if passive_buffs.get("goddess_sanctuary", false):
		final_amount = int(final_amount * 0.6) # 40% damage reduction
		
	goddess_hp = clamp(goddess_hp - final_amount, 0, goddess_max_hp)
	emit_signal("goddess_hp_changed", goddess_hp, goddess_max_hp)
	
	if goddess_hp <= 0:
		trigger_game_over(false)

func heal_goddess(amount: int):
	goddess_hp = clamp(goddess_hp + amount, 0, goddess_max_hp)
	emit_signal("goddess_hp_changed", goddess_hp, goddess_max_hp)

func trigger_game_over(victory: bool):
	is_game_over = true
	emit_signal("game_over_triggered", victory)

func broadcast_message(text: String, color: Color = Color.WHITE):
	emit_signal("message_broadcast", text, color)

# Pet Inventory Functions
func add_pet_to_inventory(pet_data: Dictionary):
	pet_inventory.append(pet_data)
	emit_signal("pet_inventory_updated")
	broadcast_message("成功捕獲寵物: %s !" % pet_data.name, Color(0.2, 1.0, 0.4))

func select_active_pet(index: int):
	if index >= 0 and index < pet_inventory.size():
		active_pet_data = pet_inventory[index]
		emit_signal("pet_summoned", active_pet_data)

func dismiss_active_pet():
	active_pet_data = {}
	emit_signal("pet_unsummoned")

func change_map(map_id: String):
	current_map_id = map_id
	emit_signal("map_change_requested", map_id)
	broadcast_message("傳送至: %s" % MapDatabase.MAPS[map_id].name, Color(0.4, 0.8, 1.0))
