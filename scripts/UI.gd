# UI.gd
extends CanvasLayer

@onready var hp_bar: ProgressBar = $HUD/BottomBar/HBox/StatsBox/HPBar
@onready var mp_bar: ProgressBar = $HUD/BottomBar/HBox/StatsBox/MPBar
@onready var exp_bar: ProgressBar = $HUD/BottomBar/HBox/StatsBox/EXPBar
@onready var level_label: Label = $HUD/BottomBar/HBox/StatsBox/LevelLabel
@onready var meso_label: Label = $HUD/BottomBar/HBox/StatsBox/MesoLabel
@onready var wave_label: Label = $HUD/TopBar/WaveLabel
@onready var goddess_hp_bar: ProgressBar = $HUD/TopBar/GoddessHPBar
@onready var map_name_label: Label = $HUD/TopBar/MapNameLabel
@onready var broadcast_label: Label = $HUD/BroadcastLabel

@onready var job_select_modal: Control = $JobSelectModal
@onready var job_card_container: HBoxContainer = $JobSelectModal/ScrollContainer/JobCards
@onready var network_modal: Control = $NetworkModal
@onready var host_name_input: LineEdit = $NetworkModal/TabContainer/建立房間/VBox/NameInput
@onready var host_port_input: LineEdit = $NetworkModal/TabContainer/建立房間/VBox/PortInput
@onready var join_name_input: LineEdit = $NetworkModal/TabContainer/加入房間/VBox/NameInput
@onready var join_ip_input: LineEdit = $NetworkModal/TabContainer/加入房間/VBox/IPInput
@onready var join_port_input: LineEdit = $NetworkModal/TabContainer/加入房間/VBox/PortInput
@onready var party_list_label: Label = $NetworkModal/PartyStatus/MemberList
@onready var net_status_label: Label = $NetworkModal/PartyStatus/StatusLabel

# In-Game Chat Box
@onready var chat_container: Control = $HUD/ChatContainer
@onready var chat_input: LineEdit = $HUD/ChatContainer/InputRow/ChatInput
@onready var chat_log: RichTextLabel = $HUD/ChatContainer/ChatLog

# Pause & Modals
@onready var pause_modal: Control = $PauseModal
@onready var start_wave_btn: Button = $HUD/TopBar/StartWaveButton
@onready var buff_modal: Control = $BuffSelectionModal
@onready var buff_container: HBoxContainer = $BuffSelectionModal/CardContainer
@onready var pet_bag_modal: Control = $PetBagModal
@onready var pet_list_container: VBoxContainer = $PetBagModal/ScrollContainer/PetList
@onready var map_select_modal: Control = $MapSelectModal
@onready var map_list_container: GridContainer = $MapSelectModal/ScrollContainer/MapGrid
@onready var game_over_modal: Control = $GameOverModal
@onready var game_over_title: Label = $GameOverModal/TitleLabel

# Dynamic AP Stat Modal & Inventory/Equip Modal
var stat_modal: Control
var inventory_modal: Control
var current_inv_tab: String = "equip"

var broadcast_tween: Tween
var restart_timer_tween: Tween

func _ready():
	# Apply font to UI tree
	var font = load("res://assets/fonts/ChineseFont.ttf")
	if not font:
		var font_path = "res://assets/fonts/ChineseFont.ttf"
		if FileAccess.file_exists(font_path):
			var f = FontFile.new()
			f.data = FileAccess.get_file_as_bytes(font_path)
			font = f
	if font:
		var theme = Theme.new()
		theme.default_font = font
		theme.default_font_size = 14
		if $HUD:
			$HUD.theme = theme
	
	# Connect global signals
	Global.player_hp_changed.connect(update_player_hp)
	Global.player_mp_changed.connect(update_player_mp)
	Global.player_exp_changed.connect(update_player_exp)
	Global.player_job_changed.connect(update_player_job_display)
	Global.player_stats_changed.connect(refresh_stat_modal)
	Global.inventory_updated.connect(refresh_inventory_modal)
	Global.equipment_updated.connect(refresh_inventory_modal)
	Global.goddess_hp_changed.connect(update_goddess_hp)
	Global.wave_changed.connect(update_wave)
	Global.message_broadcast.connect(show_broadcast_message)
	Global.pet_inventory_updated.connect(refresh_pet_bag)
	Global.game_over_triggered.connect(show_game_over)
	LevelBuffManager.buff_selection_requested.connect(show_buff_choices)
	
	# Chat Signals
	if chat_input:
		chat_input.text_submitted.connect(_on_chat_text_submitted)
		chat_input.gui_input.connect(_on_chat_gui_input)
	
	# Network signals
	NetworkManager.player_connected.connect(_on_net_player_update)
	NetworkManager.player_disconnected.connect(_on_net_player_update)
	NetworkManager.chat_message_received.connect(_on_chat_received)
	
	# Initial UI updates
	update_player_hp(Global.player_hp, Global.player_max_hp)
	update_player_mp(Global.player_mp, Global.player_max_mp)
	update_player_exp(Global.player_exp, Global.player_max_exp, Global.player_level)
	update_player_job_display(Global.player_job_data)
	update_goddess_hp(Global.goddess_hp, Global.goddess_max_hp)
	update_wave(Global.current_wave, Global.MAX_WAVES)
	
	# Build dynamic AP and Inventory modals
	build_stat_modal()
	build_inventory_modal()
	
	setup_touch_controls()
	setup_job_selection_list()
	setup_map_selection_list()
	refresh_pet_bag()
	update_network_ui()

func setup_touch_controls():
	var tc = get_node_or_null("HUD/TouchControls")
	if not tc:
		return
		
	# Left Virtual Pad (Movement)
	bind_hold_button(tc.get_node_or_null("LeftPad/BtnLeft"), "move_left")
	bind_hold_button(tc.get_node_or_null("LeftPad/BtnRight"), "move_right")
	bind_hold_button(tc.get_node_or_null("LeftPad/BtnDown"), "move_down")
	
	# Right Action & Skill Buttons
	bind_press_button(tc.get_node_or_null("RightPad/BtnJump"), "jump")
	bind_press_button(tc.get_node_or_null("RightPad/BtnAttack"), "attack_basic")
	bind_press_button(tc.get_node_or_null("RightPad/BtnSkill1"), "skill_1")
	bind_press_button(tc.get_node_or_null("RightPad/BtnSkill2"), "skill_2")
	bind_press_button(tc.get_node_or_null("RightPad/BtnSkill3"), "skill_3")
	bind_press_button(tc.get_node_or_null("RightPad/BtnCapture"), "capture")
	bind_press_button(tc.get_node_or_null("RightPad/BtnPet"), "summon_pet")
	
	# Top Quick Menu Buttons
	var top_nav = tc.get_node_or_null("TopMenuBar")
	if top_nav:
		var b_stats = top_nav.get_node_or_null("BtnStats")
		if b_stats: b_stats.pressed.connect(func(): toggle_modal(stat_modal))
		var b_inv = top_nav.get_node_or_null("BtnInventory")
		if b_inv: b_inv.pressed.connect(func(): toggle_modal(inventory_modal))
		var b_lobby = top_nav.get_node_or_null("BtnLobby")
		if b_lobby: b_lobby.pressed.connect(func(): toggle_modal(network_modal))
		var b_job = top_nav.get_node_or_null("BtnJob")
		if b_job: b_job.pressed.connect(func(): toggle_modal(job_select_modal))
		var b_map = top_nav.get_node_or_null("BtnMap")
		if b_map: b_map.pressed.connect(func(): toggle_modal(map_select_modal))
		var b_bag = top_nav.get_node_or_null("BtnBag")
		if b_bag: b_bag.pressed.connect(func(): toggle_modal(pet_bag_modal))
		var b_pause = top_nav.get_node_or_null("BtnPause")
		if b_pause: b_pause.pressed.connect(toggle_pause)

func bind_hold_button(btn: Button, action: String):
	if not is_instance_valid(btn):
		return
	btn.button_down.connect(func():
		Input.action_press(action)
	)
	btn.button_up.connect(func():
		Input.action_release(action)
	)

func bind_press_button(btn: Button, action: String):
	if not is_instance_valid(btn):
		return
	btn.button_down.connect(func():
		Input.action_press(action)
	)
	btn.button_up.connect(func():
		Input.action_release(action)
	)

func _process(_delta):
	if meso_label:
		meso_label.text = "楓幣: %d" % Global.meso_gold
	if map_name_label and MapDatabase.MAPS.has(Global.current_map_id):
		map_name_label.text = MapDatabase.MAPS[Global.current_map_id].name

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if chat_input and chat_input.has_focus():
			return
			
		match event.keycode:
			KEY_C, KEY_S:
				toggle_modal(stat_modal)
			KEY_I, KEY_E:
				toggle_modal(inventory_modal)
			KEY_M:
				toggle_modal(map_select_modal)
			KEY_J:
				toggle_modal(job_select_modal)
			KEY_P:
				toggle_modal(pet_bag_modal)
			KEY_N:
				toggle_modal(network_modal)
			KEY_ESCAPE:
				close_all_modals()

func toggle_modal(modal: Control):
	if not is_instance_valid(modal):
		return
	var target_vis = not modal.visible
	close_all_modals()
	modal.visible = target_vis
	if modal.visible:
		if modal == stat_modal:
			refresh_stat_modal()
		elif modal == inventory_modal:
			refresh_inventory_modal()

func close_all_modals():
	if is_instance_valid(stat_modal): stat_modal.visible = false
	if is_instance_valid(inventory_modal): inventory_modal.visible = false
	if is_instance_valid(network_modal): network_modal.visible = false
	if is_instance_valid(job_select_modal): job_select_modal.visible = false
	if is_instance_valid(map_select_modal): map_select_modal.visible = false
	if is_instance_valid(pet_bag_modal): pet_bag_modal.visible = false

# =========================================================================
# CHARACTER STATS & AP POINT ALLOCATION MODAL (STR / DEX / INT / LUK / HP / MP)
# =========================================================================
func build_stat_modal():
	stat_modal = PanelContainer.new()
	stat_modal.name = "StatModal"
	stat_modal.custom_minimum_size = Vector2(480, 520)
	stat_modal.set_anchors_preset(Control.PRESET_CENTER)
	stat_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	stat_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	stat_modal.visible = false
	add_child(stat_modal)

func refresh_stat_modal():
	if not is_instance_valid(stat_modal):
		return
		
	for c in stat_modal.get_children():
		c.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "📊 角色屬性與能力值點數 (AP)"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): stat_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Job & Level Banner
	var job_name = Global.player_job_data.get("name", "新手")
	var info_lbl = Label.new()
	info_lbl.text = "Lv.%d  職業: 【%s】  |  HP: %d/%d  |  MP: %d/%d" % [Global.player_level, job_name, Global.player_hp, Global.player_max_hp, Global.player_mp, Global.player_max_mp]
	info_lbl.add_theme_font_size_override("font_size", 13)
	info_lbl.modulate = Color(0.4, 0.9, 1.0)
	main_vbox.add_child(info_lbl)
	
	# Available AP Row
	var ap_hbox = HBoxContainer.new()
	var ap_lbl = Label.new()
	ap_lbl.text = "⚡ 剩餘能力點數 (AP):  %d 點" % Global.available_ap
	ap_lbl.add_theme_font_size_override("font_size", 15)
	ap_lbl.modulate = Color(1.0, 0.5, 0.2) if Global.available_ap > 0 else Color.GRAY
	ap_hbox.add_child(ap_lbl)
	
	var auto_ap_btn = Button.new()
	auto_ap_btn.text = "⚡ 一鍵推薦配點"
	auto_ap_btn.disabled = (Global.available_ap <= 0)
	auto_ap_btn.pressed.connect(func():
		Global.auto_allocate_ap()
		refresh_stat_modal()
	)
	ap_hbox.add_child(auto_ap_btn)
	main_vbox.add_child(ap_hbox)
	
	# Attribute Grid (STR, DEX, INT, LUK, HP, MP)
	var stat_grid = GridContainer.new()
	stat_grid.columns = 4
	stat_grid.add_theme_constant_override("h_separation", 12)
	stat_grid.add_theme_constant_override("v_separation", 6)
	
	add_stat_row(stat_grid, "力量 (STR)", Global.stat_str, Global.equip_bonus_str, "str")
	add_stat_row(stat_grid, "敏捷 (DEX)", Global.stat_dex, Global.equip_bonus_dex, "dex")
	add_stat_row(stat_grid, "智力 (INT)", Global.stat_int, Global.equip_bonus_int, "int")
	add_stat_row(stat_grid, "幸運 (LUK)", Global.stat_luk, Global.equip_bonus_luk, "luk")
	add_stat_row(stat_grid, "生命值 (HP)", Global.player_max_hp, 0, "hp")
	add_stat_row(stat_grid, "魔力值 (MP)", Global.player_max_mp, 0, "mp")
	
	main_vbox.add_child(stat_grid)
	
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	# Combat Stats Summary
	var combat_title = Label.new()
	combat_title.text = "⚔️ 實時戰鬥數值面板 (已實裝裝備與屬性加成)"
	combat_title.add_theme_font_size_override("font_size", 13)
	combat_title.modulate = Color(0.9, 0.9, 0.6)
	main_vbox.add_child(combat_title)
	
	var c_grid = GridContainer.new()
	c_grid.columns = 2
	c_grid.add_theme_constant_override("h_separation", 20)
	c_grid.add_theme_constant_override("v_separation", 4)
	
	add_combat_stat_label(c_grid, "物理攻擊力: %d (裝備 +%d)" % [Global.weapon_atk, Global.equip_bonus_atk])
	add_combat_stat_label(c_grid, "魔法攻擊力: %d (裝備 +%d)" % [Global.magic_atk, Global.equip_bonus_magic_atk])
	add_combat_stat_label(c_grid, "物理防禦力: %d" % Global.equip_bonus_def)
	add_combat_stat_label(c_grid, "暴擊機率: %.1f%%" % (Global.base_crit_rate * 100.0))
	add_combat_stat_label(c_grid, "移動速度: %.0f (裝備 +%.0f)" % [Global.player_speed, Global.equip_bonus_speed])
	add_combat_stat_label(c_grid, "持有楓幣: %d 楓幣" % Global.meso_gold)
	
	main_vbox.add_child(c_grid)
	stat_modal.add_child(main_vbox)

func add_stat_row(grid: GridContainer, label_text: String, base_val: int, bonus_val: int, stat_key: String):
	var name_lbl = Label.new()
	name_lbl.text = label_text
	grid.add_child(name_lbl)
	
	var val_lbl = Label.new()
	if bonus_val > 0:
		val_lbl.text = "%d (+%d)" % [base_val + bonus_val, bonus_val]
		val_lbl.modulate = Color(0.3, 1.0, 0.5)
	else:
		val_lbl.text = "%d" % base_val
	grid.add_child(val_lbl)
	
	var btn_add1 = Button.new()
	btn_add1.text = "+1"
	btn_add1.custom_minimum_size = Vector2(36, 26)
	btn_add1.disabled = (Global.available_ap < 1)
	btn_add1.pressed.connect(func():
		Global.allocate_ap(stat_key, 1)
		refresh_stat_modal()
	)
	grid.add_child(btn_add1)
	
	var btn_add5 = Button.new()
	btn_add5.text = "+5"
	btn_add5.custom_minimum_size = Vector2(36, 26)
	btn_add5.disabled = (Global.available_ap < 5)
	btn_add5.pressed.connect(func():
		Global.allocate_ap(stat_key, 5)
		refresh_stat_modal()
	)
	grid.add_child(btn_add5)

func add_combat_stat_label(grid: GridContainer, text: String):
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	grid.add_child(lbl)

# =========================================================================
# INVENTORY & EQUIPMENT SLOTS MODAL
# =========================================================================
func build_inventory_modal():
	inventory_modal = PanelContainer.new()
	inventory_modal.name = "InventoryModal"
	inventory_modal.custom_minimum_size = Vector2(780, 520)
	inventory_modal.set_anchors_preset(Control.PRESET_CENTER)
	inventory_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	inventory_modal.visible = false
	add_child(inventory_modal)

func refresh_inventory_modal():
	if not is_instance_valid(inventory_modal):
		return
		
	for c in inventory_modal.get_children():
		c.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "🎒 角色裝備欄 與 背包道具欄"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): inventory_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Body Split: Left (Equipped Slots) | Right (Inventory Tabs)
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 14)
	
	# --- LEFT: EQUIPPED SLOTS ---
	var equip_panel = PanelContainer.new()
	equip_panel.custom_minimum_size = Vector2(300, 420)
	
	var equip_vbox = VBoxContainer.new()
	var eq_title = Label.new()
	eq_title.text = "【當前穿戴裝備】(點擊卸下)"
	eq_title.add_theme_font_size_override("font_size", 13)
	eq_title.modulate = Color(0.3, 1.0, 0.5)
	equip_vbox.add_child(eq_title)
	
	var slots = [
		{"key": "weapon", "label": "⚔️ 武器"},
		{"key": "hat", "label": "👒 頭盔"},
		{"key": "overall", "label": "🥋 套服"},
		{"key": "gloves", "label": "🧤 手套"},
		{"key": "shoes", "label": "👢 鞋子"},
		{"key": "shield", "label": "🛡️ 盾牌"},
		{"key": "accessory", "label": "💍 飾品"}
	]
	
	for s in slots:
		var slot_key = s.key
		var slot_label = s.label
		var item = Global.equipped_items.get(slot_key, null)
		
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(80, 24)
		lbl.text = slot_label
		lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(lbl)
		
		if item != null:
			var item_btn = Button.new()
			item_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_btn.text = "%s" % item.name
			item_btn.modulate = Color(1.0, 0.8, 0.3)
			item_btn.tooltip_text = "點擊卸下裝備"
			item_btn.pressed.connect(func():
				Global.unequip_item(slot_key)
				refresh_inventory_modal()
			)
			row.add_child(item_btn)
		else:
			var empty_lbl = Label.new()
			empty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			empty_lbl.text = "[無裝備]"
			empty_lbl.modulate = Color.GRAY
			empty_lbl.add_theme_font_size_override("font_size", 12)
			row.add_child(empty_lbl)
			
		equip_vbox.add_child(row)
		
	# Equipped Stats Bonus Overview
	var bonus_box = VBoxContainer.new()
	var b_title = Label.new()
	b_title.text = "裝備屬性總加成: 攻+%d / 防+%d / 力量+%d / 敏捷+%d" % [Global.equip_bonus_atk, Global.equip_bonus_def, Global.equip_bonus_str, Global.equip_bonus_dex]
	b_title.add_theme_font_size_override("font_size", 11)
	b_title.modulate = Color(0.8, 0.9, 1.0)
	bonus_box.add_child(b_title)
	equip_vbox.add_child(bonus_box)
	
	equip_panel.add_child(equip_vbox)
	body_hbox.add_child(equip_panel)
	
	# --- RIGHT: INVENTORY TABS (Equip, Use, Etc) ---
	var inv_panel = PanelContainer.new()
	inv_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var inv_vbox = VBoxContainer.new()
	
	# Tab Buttons
	var tab_hbox = HBoxContainer.new()
	var tab_eq = Button.new()
	tab_eq.text = "【裝備 (%d/32)】" % Global.equip_inventory.size()
	tab_eq.pressed.connect(func():
		current_inv_tab = "equip"
		refresh_inventory_modal()
	)
	tab_hbox.add_child(tab_eq)
	
	var tab_use = Button.new()
	tab_use.text = "【消耗 (%d/32)】" % Global.use_inventory.size()
	tab_use.pressed.connect(func():
		current_inv_tab = "use"
		refresh_inventory_modal()
	)
	tab_hbox.add_child(tab_use)
	
	var tab_etc = Button.new()
	tab_etc.text = "【材料 (%d/32)】" % Global.etc_inventory.size()
	tab_etc.pressed.connect(func():
		current_inv_tab = "etc"
		refresh_inventory_modal()
	)
	tab_hbox.add_child(tab_etc)
	inv_vbox.add_child(tab_hbox)
	
	# Item Scroll List
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 320)
	
	var item_list = VBoxContainer.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	match current_inv_tab:
		"equip":
			if Global.equip_inventory.is_empty():
				var emp = Label.new()
				emp.text = "裝備欄為空。打怪可掉落稀有武器與防具！"
				emp.modulate = Color.GRAY
				item_list.add_child(emp)
			else:
				for i in range(Global.equip_inventory.size()):
					var eq = Global.equip_inventory[i]
					var row = HBoxContainer.new()
					var info = Label.new()
					info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					var job_s = " [%s]" % eq.get("job", "") if eq.get("job", "") != "" else ""
					var stats_s = "攻+%d 防+%d" % [eq.get("atk", 0), eq.get("def", 0)]
					info.text = "★ %s (Lv.%d%s) | %s" % [eq.name, eq.get("req_lvl", 1), job_s, stats_s]
					info.add_theme_font_size_override("font_size", 12)
					row.add_child(info)
					
					var eq_btn = Button.new()
					eq_btn.text = "穿戴"
					var idx = i
					eq_btn.pressed.connect(func():
						Global.equip_item(idx)
						refresh_inventory_modal()
					)
					row.add_child(eq_btn)
					item_list.add_child(row)
					
		"use":
			if Global.use_inventory.is_empty():
				var emp = Label.new()
				emp.text = "消耗欄為空。"
				emp.modulate = Color.GRAY
				item_list.add_child(emp)
			else:
				for i in range(Global.use_inventory.size()):
					var u_item = Global.use_inventory[i]
					var row = HBoxContainer.new()
					var info = Label.new()
					info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					info.text = "🧪 %s  (數量: %d)" % [u_item.name, u_item.get("count", 1)]
					info.add_theme_font_size_override("font_size", 12)
					row.add_child(info)
					
					var use_btn = Button.new()
					use_btn.text = "使用"
					var idx = i
					use_btn.pressed.connect(func():
						Global.use_consume_item(idx)
						refresh_inventory_modal()
					)
					row.add_child(use_btn)
					item_list.add_child(row)
					
		"etc":
			if Global.etc_inventory.is_empty():
				var emp = Label.new()
				emp.text = "材料欄為空。"
				emp.modulate = Color.GRAY
				item_list.add_child(emp)
			else:
				for etc_item in Global.etc_inventory:
					var row = HBoxContainer.new()
					var info = Label.new()
					info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					info.text = "📦 %s  (數量: %d)" % [etc_item.name, etc_item.get("count", 1)]
					info.add_theme_font_size_override("font_size", 12)
					row.add_child(info)
					item_list.add_child(row)
					
	scroll.add_child(item_list)
	inv_vbox.add_child(scroll)
	
	# Bottom Meso bar
	var meso_box = HBoxContainer.new()
	var meso_val = Label.new()
	meso_val.text = "💰 持有楓幣: %d 楓幣" % Global.meso_gold
	meso_val.add_theme_font_size_override("font_size", 13)
	meso_val.modulate = Color.GOLD
	meso_box.add_child(meso_val)
	inv_vbox.add_child(meso_box)
	
	inv_panel.add_child(inv_vbox)
	body_hbox.add_child(inv_panel)
	
	main_vbox.add_child(body_hbox)
	inventory_modal.add_child(main_vbox)

# =========================================================================
# OTHER MODALS (Chat, Pause, Buffs, Pets, Maps)
# =========================================================================
func _on_chat_gui_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if chat_input:
				chat_input.text = ""
				chat_input.release_focus()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if chat_input and chat_input.text.strip_edges() != "":
				_on_chat_text_submitted(chat_input.text)

func _on_chat_text_submitted(new_text: String):
	var clean_text = new_text.strip_edges()
	if clean_text.is_empty():
		if chat_input:
			chat_input.release_focus()
		return
		
	var sender = NetworkManager.local_player_name if NetworkManager.is_multiplayer_active else "冒險家"
	NetworkManager.send_chat(clean_text)
	
	if chat_input:
		chat_input.text = ""
		chat_input.release_focus()

func _on_chat_received(sender: String, message: String):
	if not chat_log:
		return
	var time_str = Time.get_time_string_from_system().substr(0, 5)
	chat_log.append_text("[color=#88ccff][%s] %s:[/color] %s\n" % [time_str, sender, message])

func toggle_pause():
	get_tree().paused = not get_tree().paused
	if pause_modal:
		pause_modal.visible = get_tree().paused

func update_player_hp(cur: int, max_val: int):
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = cur
		var lbl = hp_bar.get_node_or_null("Label")
		if lbl:
			lbl.text = "HP: %d / %d" % [cur, max_val]

func update_player_mp(cur: int, max_val: int):
	if mp_bar:
		mp_bar.max_value = max_val
		mp_bar.value = cur
		var lbl = mp_bar.get_node_or_null("Label")
		if lbl:
			lbl.text = "MP: %d / %d" % [cur, max_val]

func update_player_exp(cur: int, max_val: int, lvl: int):
	if exp_bar:
		exp_bar.max_value = max_val
		exp_bar.value = cur
		var lbl = exp_bar.get_node_or_null("Label")
		if lbl:
			var pct = float(cur) / float(max(1, max_val)) * 100.0
			lbl.text = "EXP: %d / %d (%.1f%%)" % [cur, max_val, pct]
	if level_label:
		level_label.text = "Lv. %d" % lvl

func update_player_job_display(job_data: Dictionary):
	if level_label and not job_data.is_empty():
		level_label.text = "Lv. %d  [%s]" % [Global.player_level, job_data.get("name", "新手")]

func update_goddess_hp(cur: int, max_val: int):
	if goddess_hp_bar:
		goddess_hp_bar.max_value = max_val
		goddess_hp_bar.value = cur
		var lbl = goddess_hp_bar.get_node_or_null("Label")
		if lbl:
			var pct = float(cur) / float(max(1, max_val)) * 100.0
			lbl.text = "女神神聖結界: %d / %d (%.1f%%)" % [cur, max_val, pct]

func update_wave(cur: int, max_val: int):
	if wave_label:
		wave_label.text = "第 %d / %d 波 %s" % [
			cur, 
			max_val,
			"[BOSS 來襲!]" if cur % 5 == 0 else ""
		]

func _on_start_wave_button_pressed():
	var wave_ctrl = get_tree().current_scene.get_node_or_null("WaveDefenseController")
	if is_instance_valid(wave_ctrl):
		wave_ctrl.start_wave_from_host(Global.current_wave)
		if start_wave_btn:
			start_wave_btn.visible = false

func show_broadcast_message(text: String, color: Color):
	if not broadcast_label:
		return
	broadcast_label.text = text
	broadcast_label.modulate = color
	broadcast_label.visible = true
	
	if broadcast_tween and broadcast_tween.is_valid():
		broadcast_tween.kill()
		
	broadcast_tween = create_tween()
	broadcast_tween.tween_property(broadcast_label, "modulate:a", 1.0, 0.1)
	broadcast_tween.tween_interval(2.5)
	broadcast_tween.tween_property(broadcast_label, "modulate:a", 0.0, 0.5)

# Buff Selection Modal (Every 5 Levels)
func show_buff_choices(buffs: Array):
	get_tree().paused = true
	buff_modal.visible = true
	
	for child in buff_container.get_children():
		child.queue_free()
		
	for buff in buffs:
		var card = Button.new()
		card.custom_minimum_size = Vector2(200, 260)
		card.text = "【%s】\n\n%s\n\n稀有度: %s" % [buff.name, buff.desc, buff.tier.to_upper()]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		match buff.tier:
			"legendary":
				card.modulate = Color(1.0, 0.85, 0.2)
			"epic":
				card.modulate = Color(0.8, 0.4, 1.0)
			"rare":
				card.modulate = Color(0.3, 0.7, 1.0)
			_:
				card.modulate = Color(0.8, 1.0, 0.8)
				
		var b_id = buff.id
		card.pressed.connect(func():
			LevelBuffManager.apply_buff(b_id)
			buff_modal.visible = false
			get_tree().paused = false
		)
		buff_container.add_child(card)

# Pet Bag UI
func refresh_pet_bag():
	if not pet_list_container:
		return
	for child in pet_list_container.get_children():
		child.queue_free()
		
	for i in range(Global.pet_inventory.size()):
		var pet = Global.pet_inventory[i]
		var row = HBoxContainer.new()
		
		var is_active = (Global.active_pet_data.get("name", "") == pet.name)
		var info_btn = Button.new()
		info_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_btn.text = "%s [%s] - HP: %d | 攻擊: %d" % [
			"★ " + pet.name if is_active else pet.name,
			"出戰中" if is_active else "休息中",
			pet.hp,
			pet.atk
		]
		if is_active:
			info_btn.modulate = Color.GREEN
		
		var pet_copy = pet
		info_btn.pressed.connect(func():
			if is_active:
				Global.dismiss_active_pet()
			else:
				Global.summon_pet(pet_copy)
			refresh_pet_bag()
		)
		row.add_child(info_btn)
		
		var del_btn = Button.new()
		del_btn.text = "🗑 放生"
		del_btn.modulate = Color(1.0, 0.4, 0.4)
		var idx = i
		del_btn.pressed.connect(func():
			Global.remove_pet_from_inventory(idx)
			refresh_pet_bag()
		)
		row.add_child(del_btn)
		
		pet_list_container.add_child(row)

# Map Selection Fast Travel with full monster slots & drops
func setup_map_selection_list():
	if not map_list_container:
		return
	for child in map_list_container.get_children():
		child.queue_free()
		
	var maps = MapDatabase.get_map_list()
	for map_info in maps:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(360, 110)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		
		# Header: Map Name + Region + Town/Field tag
		var header_hbox = HBoxContainer.new()
		var title_lbl = Label.new()
		title_lbl.text = "【%s】" % map_info.name
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.modulate = Color(1.0, 0.85, 0.2) if map_info.is_town else Color(0.4, 0.9, 1.0)
		header_hbox.add_child(title_lbl)
		
		var reg_lbl = Label.new()
		reg_lbl.text = "(%s)" % map_info.region
		reg_lbl.add_theme_font_size_override("font_size", 11)
		reg_lbl.modulate = Color(0.7, 0.8, 0.9)
		header_hbox.add_child(reg_lbl)
		
		vbox.add_child(header_hbox)
		
		# Monsters & Spawn Slots
		var mobs_str = "👾 怪物: "
		if map_info.monsters.is_empty():
			mobs_str += "無 (安全城鎮/休息區)"
		else:
			var m_parts = []
			for m in map_info.monsters:
				m_parts.append("%s Lv.%d [%d槽位]" % [m.name, m.level, m.slots])
			mobs_str += ", ".join(m_parts)
			
		var mob_lbl = Label.new()
		mob_lbl.text = mobs_str
		mob_lbl.add_theme_font_size_override("font_size", 11)
		mob_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mob_lbl.modulate = Color(1.0, 0.7, 0.6) if not map_info.monsters.is_empty() else Color(0.6, 1.0, 0.6)
		vbox.add_child(mob_lbl)
		
		# NPCs
		if not map_info.npcs.is_empty():
			var npc_lbl = Label.new()
			npc_lbl.text = "👤 NPC: " + ", ".join(map_info.npcs.slice(0, 4)) + (" 等..." if map_info.npcs.size() > 4 else "")
			npc_lbl.add_theme_font_size_override("font_size", 11)
			npc_lbl.modulate = Color(0.9, 0.9, 0.6)
			vbox.add_child(npc_lbl)
			
		# Portals
		if not map_info.normal_portals.is_empty():
			var p_titles = []
			for p in map_info.normal_portals.slice(0, 3):
				p_titles.append(p.title.replace("一般傳送點：", "").replace("前往", ""))
			var p_lbl = Label.new()
			p_lbl.text = "🚪 傳送: " + " ➔ ".join(p_titles)
			p_lbl.add_theme_font_size_override("font_size", 10)
			p_lbl.modulate = Color(0.5, 0.8, 1.0)
			vbox.add_child(p_lbl)
			
		# Travel Button
		var travel_btn = Button.new()
		travel_btn.text = "⚡ 傳送前往【%s】" % map_info.name
		travel_btn.custom_minimum_size = Vector2(0, 26)
		var mid = map_info.id
		travel_btn.pressed.connect(func():
			Global.change_map(mid)
			map_select_modal.visible = false
		)
		vbox.add_child(travel_btn)
		
		panel.add_child(vbox)
		map_list_container.add_child(panel)

func show_game_over(victory: bool):
	game_over_modal.visible = true
	var restart_btn = game_over_modal.get_node_or_null("RestartButton")
	
	if victory:
		game_over_title.text = "★ 恭喜通關 50 波攻城大獲全勝！★\n守護了女神與整個楓之谷世界！"
		game_over_title.modulate = Color.GOLD
	else:
		game_over_title.text = "☠ 守護失敗！女神結界已破碎 ☠\n即將自動重生，重新守護女神！"
		game_over_title.modulate = Color.RED
		
	if restart_timer_tween and restart_timer_tween.is_valid():
		restart_timer_tween.kill()
		
	restart_timer_tween = create_tween()
	var countdown_label = game_over_modal.get_node_or_null("CountdownLabel")
	if not countdown_label:
		countdown_label = Label.new()
		countdown_label.name = "CountdownLabel"
		countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown_label.position = Vector2(0, 180)
		countdown_label.size = Vector2(400, 30)
		countdown_label.add_theme_font_size_override("font_size", 16)
		countdown_label.modulate = Color.YELLOW
		game_over_modal.add_child(countdown_label)
		
	var seconds_left = 5
	countdown_label.text = "【%d 秒後自動重新開始守護】" % seconds_left
	
	for s in range(5, 0, -1):
		restart_timer_tween.tween_callback(func():
			if is_instance_valid(countdown_label):
				countdown_label.text = "【%d 秒後自動重新開始守護】" % s
		)
		restart_timer_tween.tween_interval(1.0)
		
	restart_timer_tween.tween_callback(func():
		_restart_defense_game()
	)
	
	if restart_btn:
		if not restart_btn.pressed.is_connected(_restart_defense_game):
			restart_btn.pressed.connect(_restart_defense_game)

func _restart_defense_game():
	if restart_timer_tween and restart_timer_tween.is_valid():
		restart_timer_tween.kill()
	game_over_modal.visible = false
	
	Global.reset_game_state()
	
	var wave_ctrl = get_tree().current_scene.get_node_or_null("WaveDefenseController")
	if is_instance_valid(wave_ctrl):
		wave_ctrl.restart_defense_loop()

func setup_job_selection_list():
	if not job_card_container:
		return
	for child in job_card_container.get_children():
		child.queue_free()
		
	for job_id in JobDatabase.JOBS.keys():
		var job = JobDatabase.JOBS[job_id]
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(160, 240)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		
		var icon = Label.new()
		icon.text = "⚔️" if job_id == "warrior" else ("🏹" if job_id == "archer" else ("🔮" if job_id == "mage" else ("🗡️" if job_id == "rogue" else "🔫")))
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 28)
		vbox.add_child(icon)
		
		var name_lbl = Label.new()
		name_lbl.text = job.get("name", "職業")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.modulate = job.get("color", Color.WHITE)
		name_lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(name_lbl)
		
		var desc = Label.new()
		desc.text = job.get("desc", "")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 11)
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(desc)
		
		var select_btn = Button.new()
		select_btn.text = "選擇轉職"
		var j_id = job_id
		select_btn.pressed.connect(func():
			Global.set_player_job(j_id)
			job_select_modal.visible = false
		)
		vbox.add_child(select_btn)
		
		card.add_child(vbox)
		job_card_container.add_child(card)

func update_network_ui():
	if not net_status_label:
		return
	if NetworkManager.is_multiplayer_active:
		if NetworkManager.is_host:
			net_status_label.text = "狀態: 房主 (正在主持防禦房間)"
		else:
			net_status_label.text = "狀態: 已連線進房"
		net_status_label.modulate = Color.GREEN
	else:
		net_status_label.text = "狀態: 單人離線模式"
		net_status_label.modulate = Color.WHITE

func _on_net_player_update(_id = 0):
	update_network_ui()
	if party_list_label:
		var txt = "隊伍成員:\n"
		for peer_id in NetworkManager.players.keys():
			var p_info = NetworkManager.players[peer_id]
			txt += "• %s (ID: %d)\n" % [p_info.name, peer_id]
		party_list_label.text = txt
