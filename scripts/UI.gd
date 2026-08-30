# UI.gd
extends CanvasLayer

var hp_bar: ProgressBar
var mp_bar: ProgressBar
var exp_bar: ProgressBar
var level_label: Label
var meso_label: Label
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

# Dynamic AP Stat Modal & Inventory/Equip Modal & Skill Modal
var stat_modal: Control
var inventory_modal: Control
var skill_modal: Control
var skill_draft_modal: Control
var keybinding_modal: Control
var scroll_workshop_modal: Control
var accuracy_modal: Control
var weapon_attack_modal: Control
var scroll_calc_modal: Control
var monster_book_modal: Control
var accuracy_calc_mode: String = "physical"
var accuracy_selected_mob_id: int = 100100
var accuracy_search_query: String = ""
var weapon_calc_selected_key: String = "two_sword"
var weapon_calc_str: int = 110
var weapon_calc_dex: int = 20
var weapon_calc_luk: int = 20
var weapon_calc_watk: int = 55
var weapon_calc_mastery: float = 60.0
var scroll_calc_slots: int = 7
var scroll_calc_rate: float = 60.0
var scroll_calc_want: int = 4
var scroll_calc_price: int = 500000
var monster_book_selected_id: int = 100100
var monster_book_search_query: String = ""
var monster_book_level_filter: String = "all"
var item_book_modal: Control
var item_book_tab: String = "equip"
var item_book_search_query: String = ""
var item_book_slot_filter: String = "all"
var item_book_selected_id: int = 1002067
var current_workshop_scroll_idx: int = -1
var selected_enhance_target_type: String = "equipped"
var selected_enhance_target_key = "weapon"
var currently_rebinding_action: String = ""
var current_inv_tab: String = "equip"

# Top Boss HP Bar UI
var boss_bar_panel: PanelContainer
var boss_bar_progress: ProgressBar
var boss_bar_label: Label
var boss_bar_name_label: Label

# Classic Maple Bottom Bar UI Elements
var lvl_badge_lbl: Label
var char_name_lbl: Label
var job_name_lbl: Label
var hp_bar_label: Label
var mp_bar_label: Label
var exp_bar_label: Label
var meso_bottom_label: Label

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
	Global.player_sp_changed.connect(func(_sp): refresh_skill_modal())
	Global.skill_points_allocated.connect(func(_s, _l): refresh_skill_modal())
	Global.boss_hp_updated.connect(update_boss_hp_bar)
	Global.inventory_updated.connect(refresh_inventory_modal)
	Global.equipment_updated.connect(refresh_inventory_modal)
	Global.goddess_hp_changed.connect(update_goddess_hp)
	Global.wave_changed.connect(update_wave)
	Global.message_broadcast.connect(show_broadcast_message)
	Global.pet_inventory_updated.connect(refresh_pet_bag)
	Global.game_over_triggered.connect(show_game_over)
	LevelBuffManager.buff_selection_requested.connect(show_buff_choices)
	Global.skill_draft_requested.connect(show_skill_draft_modal)
	Global.keybindings_changed.connect(refresh_keybinding_modal)
	
	# Chat Signals
	if chat_input:
		chat_input.text_submitted.connect(_on_chat_text_submitted)
		chat_input.gui_input.connect(_on_chat_gui_input)
	
	# Network signals
	NetworkManager.player_connected.connect(_on_net_player_update)
	NetworkManager.player_disconnected.connect(_on_net_player_update)
	NetworkManager.chat_message_received.connect(_on_chat_received)
	
	# Setup Classic Maple Bottom Status Bar & Build Modals
	setup_classic_maple_bottom_bar()
	
	# Initial UI updates
	update_player_hp(Global.player_hp, Global.player_max_hp)
	update_player_mp(Global.player_mp, Global.player_max_mp)
	update_player_exp(Global.player_exp, Global.player_max_exp, Global.player_level)
	update_player_job_display(Global.player_job_data)
	update_goddess_hp(Global.goddess_hp, Global.goddess_max_hp)
	update_wave(Global.current_wave, Global.MAX_WAVES)
	
	# Build dynamic AP, Inventory, Skill, and Boss HP modals
	build_stat_modal()
	build_inventory_modal()
	build_skill_modal()
	build_top_boss_hp_bar()
	build_scroll_workshop_modal()
	build_accuracy_modal()
	build_weapon_attack_modal()
	build_scroll_calc_modal()
	build_monster_book_modal()
	build_item_book_modal()
	build_keybinding_modal()
	
	setup_touch_controls()
	setup_job_selection_list()
	setup_map_selection_list()
	refresh_pet_bag()
	update_network_ui()
	
	Global.broadcast_message("⚡ 伺服器經驗值倍率：500% (5倍經驗急速升等)！", Color(1.0, 0.85, 0.2))

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
	
	# Clean Top Menu Bar (Hide old overlapping bar to give clean view of wave and map)
	var top_nav = tc.get_node_or_null("TopMenuBar")
	if top_nav:
		top_nav.visible = false
		
	Global.skill_slots_changed.connect(update_touch_skill_labels)
	Global.player_job_changed.connect(func(_j): update_touch_skill_labels())
	update_touch_skill_labels()

func update_touch_skill_labels():
	var tc = get_node_or_null("HUD/TouchControls")
	if not is_instance_valid(tc):
		return
		
	var btn1 = tc.get_node_or_null("RightPad/BtnSkill1")
	var btn2 = tc.get_node_or_null("RightPad/BtnSkill2")
	var btn3 = tc.get_node_or_null("RightPad/BtnSkill3")
	
	var job_skills = Global.player_job_data.get("skills", {})
	
	if is_instance_valid(btn1):
		var s1_id = Global.equipped_skill_slots.get("slot_1", "skill_1")
		var s1 = job_skills.get(s1_id, {})
		var n1 = s1.get("name", "一轉")
		btn1.text = "%s\n(Z)" % n1.substr(0, 4)
		
	if is_instance_valid(btn2):
		var s2_id = Global.equipped_skill_slots.get("slot_2", "skill_2")
		var s2 = job_skills.get(s2_id, {})
		var n2 = s2.get("name", "二轉")
		btn2.text = "%s\n(C)" % n2.substr(0, 4)
		
	if is_instance_valid(btn3):
		var s3_id = Global.equipped_skill_slots.get("slot_3", "skill_3")
		var s3 = job_skills.get(s3_id, {})
		var n3 = s3.get("name", "奧義")
		btn3.text = "%s\n(V)" % n3.substr(0, 4)

func bind_hold_button(btn: Button, action: String):
	if not is_instance_valid(btn):
		return
	btn.button_down.connect(func():
		if action == "move_left":
			Global.touch_move_dir = -1.0
		elif action == "move_right":
			Global.touch_move_dir = 1.0
		Input.action_press(action)
	)
	btn.button_up.connect(func():
		if (action == "move_left" and Global.touch_move_dir < 0.0) or (action == "move_right" and Global.touch_move_dir > 0.0):
			Global.touch_move_dir = 0.0
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
	if is_instance_valid(meso_bottom_label):
		meso_bottom_label.text = "💰 %s" % format_hp_num(Global.meso_gold)
	if is_instance_valid(map_name_label) and MapDatabase.MAPS.has(Global.current_map_id):
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
			KEY_K:
				toggle_modal(skill_modal)
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
		elif modal == skill_modal:
			refresh_skill_modal()
		elif modal == keybinding_modal:
			refresh_keybinding_modal()
		elif modal == map_select_modal:
			setup_map_selection_list()
		elif modal == job_select_modal:
			setup_job_selection_list()
		elif modal == pet_bag_modal:
			refresh_pet_bag()
		elif modal == monster_book_modal:
			refresh_monster_book_modal()
		elif modal == item_book_modal:
			refresh_item_book_modal()
		elif modal == scroll_workshop_modal:
			refresh_scroll_workshop()
		elif modal == accuracy_modal:
			refresh_accuracy_modal()
		elif modal == weapon_attack_modal:
			refresh_weapon_attack_modal()
		elif modal == scroll_calc_modal:
			refresh_scroll_calc_modal()

func close_all_modals():
	if is_instance_valid(stat_modal): stat_modal.visible = false
	if is_instance_valid(inventory_modal): inventory_modal.visible = false
	if is_instance_valid(skill_modal): skill_modal.visible = false
	if is_instance_valid(network_modal): network_modal.visible = false
	if is_instance_valid(job_select_modal): job_select_modal.visible = false
	if is_instance_valid(map_select_modal): map_select_modal.visible = false
	if is_instance_valid(pet_bag_modal): pet_bag_modal.visible = false
	if is_instance_valid(keybinding_modal): keybinding_modal.visible = false
	if is_instance_valid(scroll_workshop_modal): scroll_workshop_modal.visible = false
	if is_instance_valid(accuracy_modal): accuracy_modal.visible = false
	if is_instance_valid(weapon_attack_modal): weapon_attack_modal.visible = false
	if is_instance_valid(scroll_calc_modal): scroll_calc_modal.visible = false
	if is_instance_valid(monster_book_modal): monster_book_modal.visible = false
	if is_instance_valid(item_book_modal): item_book_modal.visible = false

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
	var w_class = Global.get_current_equipped_weapon_class()
	var total_str = Global.stat_str + Global.equip_bonus_str
	var total_dex = Global.stat_dex + Global.equip_bonus_dex
	var total_luk = Global.stat_luk + Global.equip_bonus_luk
	var total_watk = max(10, Global.weapon_atk + Global.equip_bonus_atk)
	var mastery_p = clamp((Global.mastery + Global.passive_buffs.get("mastery_boost", 0.0)) * 100.0, 10.0, 90.0)
	var wp_range = Global.calculate_weapon_attack_power_range(w_class, total_str, total_dex, total_luk, total_watk, mastery_p)
	
	add_combat_stat_label(c_grid, "⚔️ 物理攻擊力: %d ~ %d" % [wp_range.min_atk, wp_range.max_atk])
	add_combat_stat_label(c_grid, "✨ 魔法攻擊力: %d (裝備 +%d)" % [Global.magic_atk, Global.equip_bonus_magic_atk])
	add_combat_stat_label(c_grid, "🛡️ 物理防禦力: %d" % Global.equip_bonus_def)
	add_combat_stat_label(c_grid, "💥 暴擊機率: %.1f%%" % (Global.base_crit_rate * 100.0))
	add_combat_stat_label(c_grid, "🎯 物理命中: %d (裝備 +%d)" % [Global.get_player_physical_accuracy(), Global.equip_bonus_acc])
	add_combat_stat_label(c_grid, "✨ 魔法命中: %d (裝備 +%d)" % [Global.get_player_magic_accuracy(), Global.equip_bonus_magic_acc])
	add_combat_stat_label(c_grid, "💨 迴避值: %d (裝備 +%d)" % [Global.get_player_avoidability(), Global.equip_bonus_avoid])
	add_combat_stat_label(c_grid, "🏃 移動速度: %.0f (裝備 +%.0f)" % [Global.player_speed, Global.equip_bonus_speed])
	add_combat_stat_label(c_grid, "💰 持有楓幣: %d 楓幣" % Global.meso_gold)
	
	main_vbox.add_child(c_grid)
	
	# Tool Buttons Row
	var tools_hbox = HBoxContainer.new()
	tools_hbox.add_theme_constant_override("separation", 10)
	
	var wp_tool_btn = Button.new()
	wp_tool_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wp_tool_btn.text = "⚔️ 武器面板攻擊力計算器 (16類武器試算)"
	wp_tool_btn.modulate = Color(1.0, 0.75, 0.2)
	wp_tool_btn.pressed.connect(func():
		open_weapon_attack_modal()
	)
	tools_hbox.add_child(wp_tool_btn)
	
	var acc_tool_btn = Button.new()
	acc_tool_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acc_tool_btn.text = "🎯 命中門檻試算器 (對怪不MISS試算)"
	acc_tool_btn.modulate = Color(0.4, 0.9, 1.0)
	acc_tool_btn.pressed.connect(func():
		open_accuracy_modal()
	)
	tools_hbox.add_child(acc_tool_btn)
	main_vbox.add_child(tools_hbox)
	
	var mob_book_btn = Button.new()
	mob_book_btn.text = "📖 楓之谷官方怪物圖鑑與掉落查詢 (332 隻怪物 / 7,257 筆官方掉落資料)"
	mob_book_btn.modulate = Color(0.4, 1.0, 0.6)
	mob_book_btn.pressed.connect(func():
		open_monster_book_modal()
	)
	main_vbox.add_child(mob_book_btn)
	
	var item_book_btn = Button.new()
	item_book_btn.text = "🎒 官方裝備與道具圖鑑 (4,529 件裝備 / 671 種道具 / 數值查詢)"
	item_book_btn.modulate = Color(1.0, 0.65, 0.3)
	item_book_btn.pressed.connect(func():
		open_item_book_modal()
	)
	main_vbox.add_child(item_book_btn)
	
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
# TOP BOSS HP BAR (CLASSIC MAPLESTORY STYLE)
# =========================================================================
func build_top_boss_hp_bar():
	boss_bar_panel = PanelContainer.new()
	boss_bar_panel.name = "TopBossHPBar"
	boss_bar_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_bar_panel.offset_left = 220
	boss_bar_panel.offset_right = -220
	boss_bar_panel.offset_top = 8
	boss_bar_panel.offset_bottom = 54
	boss_bar_panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.border_color = Color(0.85, 0.65, 0.2, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	boss_bar_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	var top_row = HBoxContainer.new()
	boss_bar_name_label = Label.new()
	boss_bar_name_label.text = "👑 【BOSS】"
	boss_bar_name_label.add_theme_font_size_override("font_size", 14)
	boss_bar_name_label.modulate = Color(1.0, 0.85, 0.2)
	top_row.add_child(boss_bar_name_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	
	boss_bar_label = Label.new()
	boss_bar_label.text = "100%"
	boss_bar_label.add_theme_font_size_override("font_size", 12)
	boss_bar_label.modulate = Color(1.0, 0.95, 0.8)
	top_row.add_child(boss_bar_label)
	vbox.add_child(top_row)
	
	# Crimson/Red Maple Boss HP Progress Bar
	boss_bar_progress = ProgressBar.new()
	boss_bar_progress.custom_minimum_size = Vector2(0, 16)
	boss_bar_progress.min_value = 0.0
	boss_bar_progress.max_value = 100.0
	boss_bar_progress.value = 100.0
	boss_bar_progress.show_percentage = false
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.18, 0.05, 0.05, 1.0)
	bg_style.set_corner_radius_all(2)
	boss_bar_progress.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.95, 0.15, 0.15, 1.0)
	fill_style.set_corner_radius_all(2)
	boss_bar_progress.add_theme_stylebox_override("fill", fill_style)
	
	vbox.add_child(boss_bar_progress)
	boss_bar_panel.add_child(vbox)
	
	# Add directly to HUD so it sits at the absolute top layer
	$HUD.add_child(boss_bar_panel)

func update_boss_hp_bar(boss_name: String, cur_hp: int, max_hp: int, is_alive: bool):
	if not is_instance_valid(boss_bar_panel):
		return
		
	if is_alive and cur_hp > 0:
		boss_bar_panel.visible = true
		boss_bar_name_label.text = "🐉 %s" % boss_name
		var pct = clamp(float(cur_hp) / float(max(1, max_hp)) * 100.0, 0.0, 100.0)
		boss_bar_progress.value = pct
		boss_bar_label.text = "%s / %s (%.1f%%)" % [format_hp_num(cur_hp), format_hp_num(max_hp), pct]
	else:
		if boss_bar_panel.visible:
			boss_bar_progress.value = 0.0
			boss_bar_label.text = "DEFEATED (0%)"
			var tween = create_tween()
			tween.tween_interval(2.0)
			tween.tween_callback(func():
				if is_instance_valid(boss_bar_panel):
					boss_bar_panel.visible = false
			)

func format_hp_num(n: int) -> String:
	var s = str(n)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

# =========================================================================
# SKILL BOOK & SP POINT ALLOCATION MODAL (快捷鍵 K)
# =========================================================================
func build_skill_modal():
	skill_modal = PanelContainer.new()
	skill_modal.name = "SkillModal"
	skill_modal.custom_minimum_size = Vector2(760, 560)
	skill_modal.set_anchors_preset(Control.PRESET_CENTER)
	skill_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	skill_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	skill_modal.visible = false
	add_child(skill_modal)

func refresh_skill_modal():
	if not is_instance_valid(skill_modal):
		return
		
	for c in skill_modal.get_children():
		c.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "📖 技能書與技能配點系統 (SP)"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): skill_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Job Banner & SP Counter
	var sub_bar = HBoxContainer.new()
	sub_bar.add_theme_constant_override("separation", 16)
	
	var job_name = Global.player_job_data.get("name", "初心者")
	var job_lbl = Label.new()
	job_lbl.text = "目前職業: 【%s】  |  等級: Lv.%d" % [job_name, Global.player_level]
	job_lbl.add_theme_font_size_override("font_size", 14)
	job_lbl.modulate = Color(0.4, 0.9, 1.0)
	sub_bar.add_child(job_lbl)
	
	var sp_lbl = Label.new()
	sp_lbl.text = "⚡ 剩餘技能點數 (SP): %d 點" % Global.available_sp
	sp_lbl.add_theme_font_size_override("font_size", 15)
	sp_lbl.modulate = Color.GOLD if Global.available_sp > 0 else Color.GRAY
	sub_bar.add_child(sp_lbl)
	
	var sub_spacer = Control.new()
	sub_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_bar.add_child(sub_spacer)
	
	var auto_sp_btn = Button.new()
	auto_sp_btn.text = "⚡ 一鍵推薦加點"
	auto_sp_btn.disabled = (Global.available_sp <= 0)
	auto_sp_btn.pressed.connect(func():
		Global.auto_allocate_sp()
		refresh_skill_modal()
	)
	sub_bar.add_child(auto_sp_btn)
	
	var reset_sp_btn = Button.new()
	reset_sp_btn.text = "🔄 重置點數"
	reset_sp_btn.pressed.connect(func():
		Global.reset_sp()
		refresh_skill_modal()
	)
	sub_bar.add_child(reset_sp_btn)
	
	main_vbox.add_child(sub_bar)
	
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	# Scroll Container for Skills
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 390)
	
	var skill_list_vbox = VBoxContainer.new()
	skill_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_list_vbox.add_theme_constant_override("separation", 8)
	
	var job_skills = Global.player_job_data.get("skills", {})
	for s_key in job_skills.keys():
		var s_data = job_skills[s_key]
		var cur_lvl = Global.player_skill_levels.get(s_key, 1)
		var max_lvl = s_data.get("max_lvl", 20)
		var is_max = cur_lvl >= max_lvl
		
		var cur_stats = JobDatabase.get_skill_stats(Global.player_job_id, s_key, cur_lvl)
		var next_stats = JobDatabase.get_skill_stats(Global.player_job_id, s_key, cur_lvl + 1)
		
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.14, 0.18, 0.85)
		card_style.border_color = Color.GOLD if is_max else Color(0.25, 0.35, 0.5)
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(4)
		card_style.content_margin_left = 10
		card_style.content_margin_right = 10
		card_style.content_margin_top = 8
		card_style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", card_style)
		
		var card_hbox = HBoxContainer.new()
		card_hbox.add_theme_constant_override("separation", 12)
		
		# Check which slots this skill is equipped to
		var equipped_slots = []
		for slot_k in Global.equipped_skill_slots.keys():
			if Global.equipped_skill_slots[slot_k] == s_key:
				var slot_str = slot_k.replace("slot_1", "快捷 1 (Z)").replace("slot_2", "快捷 2 (C)").replace("slot_3", "快捷 3 (V)").replace("slot_4", "快捷 4 (A)").replace("slot_5", "快捷 5 (S)").replace("slot_6", "快捷 6 (D)").replace("ultimate", "奧義 (F)")
				equipped_slots.append(slot_str)
				
		# Left: Icon & Name & Level & Equipped Tag
		var left_vbox = VBoxContainer.new()
		left_vbox.custom_minimum_size = Vector2(175, 0)
		
		var s_name_lbl = Label.new()
		s_name_lbl.text = "%s %s" % [s_data.get("icon", "⚔️"), s_data.get("name", "")]
		s_name_lbl.add_theme_font_size_override("font_size", 14)
		s_name_lbl.modulate = Color(1.0, 0.9, 0.4)
		left_vbox.add_child(s_name_lbl)
		
		var s_lvl_lbl = Label.new()
		s_lvl_lbl.text = "等級: Lv.%d / %d %s" % [cur_lvl, max_lvl, ("(MAX)" if is_max else "")]
		s_lvl_lbl.add_theme_font_size_override("font_size", 12)
		s_lvl_lbl.modulate = Color.GOLD if is_max else Color(0.3, 1.0, 0.5)
		left_vbox.add_child(s_lvl_lbl)
		
		if not equipped_slots.is_empty():
			var eq_lbl = Label.new()
			eq_lbl.text = "⚡ %s" % "、".join(equipped_slots)
			eq_lbl.add_theme_font_size_override("font_size", 11)
			eq_lbl.modulate = Color(1.0, 0.75, 0.2)
			left_vbox.add_child(eq_lbl)
			
		card_hbox.add_child(left_vbox)
		
		# Middle: Description and Stats
		var mid_vbox = VBoxContainer.new()
		mid_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var desc_lbl = Label.new()
		desc_lbl.text = s_data.get("desc", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.7, 0.8, 0.9)
		mid_vbox.add_child(desc_lbl)
		
		var cur_eff_lbl = Label.new()
		var mult_pct = int(cur_stats.get("multiplier", 1.0) * 100.0)
		var hits = cur_stats.get("hits", 1)
		var mp = cur_stats.get("mp", 0)
		var cd = cur_stats.get("cd", 0.0)
		cur_eff_lbl.text = "【當前】傷害: %d%% | 段數: %d | 消耗 MP: %d | 冷卻: %.1fs" % [mult_pct, hits, mp, cd]
		cur_eff_lbl.add_theme_font_size_override("font_size", 11)
		cur_eff_lbl.modulate = Color(0.4, 0.9, 1.0)
		mid_vbox.add_child(cur_eff_lbl)
		
		if not is_max:
			var nxt_eff_lbl = Label.new()
			var n_mult_pct = int(next_stats.get("multiplier", 1.0) * 100.0)
			var n_mp = next_stats.get("mp", 0)
			nxt_eff_lbl.text = "【下一級】傷害: %d%% (↑+%d%%) | 消耗 MP: %d" % [n_mult_pct, (n_mult_pct - mult_pct), n_mp]
			nxt_eff_lbl.add_theme_font_size_override("font_size", 11)
			nxt_eff_lbl.modulate = Color(0.3, 1.0, 0.5)
			mid_vbox.add_child(nxt_eff_lbl)
			
		card_hbox.add_child(mid_vbox)
		
		# Right: Action Buttons (Cast, Equip Slot, Upgrade)
		var right_vbox = VBoxContainer.new()
		right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		right_vbox.add_theme_constant_override("separation", 3)
		
		# Direct Cast Button
		var cast_btn = Button.new()
		cast_btn.text = "⚡ 立即施放"
		cast_btn.custom_minimum_size = Vector2(110, 24)
		cast_btn.modulate = Color(0.5, 0.95, 1.0)
		cast_btn.pressed.connect(func():
			Global.request_cast_skill(s_key)
		)
		right_vbox.add_child(cast_btn)
		
		# Slot Selection Dropdown
		var opt_btn = OptionButton.new()
		opt_btn.custom_minimum_size = Vector2(110, 24)
		opt_btn.add_item("⚙️ 配置至快捷鍵...")
		opt_btn.add_item("配置至 快捷 1 (Z)", 1)
		opt_btn.add_item("配置至 快捷 2 (C)", 2)
		opt_btn.add_item("配置至 快捷 3 (V)", 3)
		opt_btn.add_item("配置至 快捷 4 (A)", 4)
		opt_btn.add_item("配置至 快捷 5 (S)", 5)
		opt_btn.add_item("配置至 快捷 6 (D)", 6)
		opt_btn.add_item("配置至 奧義 (F)", 7)
		opt_btn.item_selected.connect(func(idx):
			if idx == 1: Global.equip_skill_to_slot("slot_1", s_key)
			elif idx == 2: Global.equip_skill_to_slot("slot_2", s_key)
			elif idx == 3: Global.equip_skill_to_slot("slot_3", s_key)
			elif idx == 4: Global.equip_skill_to_slot("slot_4", s_key)
			elif idx == 5: Global.equip_skill_to_slot("slot_5", s_key)
			elif idx == 6: Global.equip_skill_to_slot("slot_6", s_key)
			elif idx == 7: Global.equip_skill_to_slot("ultimate", s_key)
			refresh_skill_modal()
		)
		right_vbox.add_child(opt_btn)
		
		# SP Upgrade Buttons
		var sp_btn_hbox = HBoxContainer.new()
		sp_btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		sp_btn_hbox.add_theme_constant_override("separation", 4)
		
		var add1_btn = Button.new()
		add1_btn.text = " ＋1 "
		add1_btn.custom_minimum_size = Vector2(52, 24)
		add1_btn.disabled = (Global.available_sp < 1 or is_max)
		add1_btn.pressed.connect(func():
			Global.allocate_sp(s_key, 1)
			refresh_skill_modal()
		)
		sp_btn_hbox.add_child(add1_btn)
		
		var max_btn = Button.new()
		max_btn.text = " ＋MAX "
		max_btn.custom_minimum_size = Vector2(54, 24)
		max_btn.disabled = (Global.available_sp < 1 or is_max)
		max_btn.pressed.connect(func():
			Global.allocate_sp(s_key, max_lvl - cur_lvl)
			refresh_skill_modal()
		)
		sp_btn_hbox.add_child(max_btn)
		right_vbox.add_child(sp_btn_hbox)
		
		card_hbox.add_child(right_vbox)
		card.add_child(card_hbox)
		skill_list_vbox.add_child(card)
		
	scroll.add_child(skill_list_vbox)
	main_vbox.add_child(scroll)
	skill_modal.add_child(main_vbox)

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
				emp.text = "裝備欄為空。擊殺怪物與BOSS會必定掉落豐富神裝！"
				emp.modulate = Color.GRAY
				item_list.add_child(emp)
			else:
				var slot_labels = {
					"weapon": "⚔️[武器]",
					"hat": "👒[頭盔]",
					"overall": "🥋[衣服]",
					"gloves": "🧤[手套]",
					"shoes": "👢[鞋子]",
					"shield": "🛡️[盾牌]",
					"accessory": "💍[飾品]"
				}
				for i in range(Global.equip_inventory.size()):
					var eq = Global.equip_inventory[i]
					var row = HBoxContainer.new()
					var info = Label.new()
					info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					var job_s = " [%s]" % eq.get("job", "") if eq.get("job", "") != "" else ""
					var stats_s = "攻+%d 防+%d" % [eq.get("atk", 0), eq.get("def", 0)]
					var slot_tag = slot_labels.get(eq.get("slot", "weapon"), "⚔️[裝備]")
					var count_tag = " x%d" % eq.count if eq.get("count", 1) > 1 else ""
					var succ_cnt = eq.get("scroll_success_count", 0)
					var plus_str = " (+%d)" % succ_cnt if succ_cnt > 0 else ""
					var rem_slots = eq.get("upgrade_slots_remaining", 7)
					var tot_slots = eq.get("upgrade_slots_total", 7)
					var slot_info = " [可升級: %d/%d]" % [rem_slots, tot_slots]
					
					info.text = "%s %s%s%s (Lv.%d%s) | %s%s" % [slot_tag, eq.name, plus_str, count_tag, eq.get("req_lvl", 1), job_s, stats_s, slot_info]
					info.add_theme_font_size_override("font_size", 12)
					if succ_cnt > 0:
						info.modulate = Color(1.0, 0.85, 0.2) # Gold for enhanced
					elif eq.get("req_lvl", 1) > Global.player_level:
						info.modulate = Color(1.0, 0.4, 0.4) # Red for high level requirement
					else:
						info.modulate = Color(1.0, 0.9, 0.6) # Gold/Cream for wearable
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
					var is_scroll = (u_item.get("type", "") == "scroll") or (u_item.name.find("卷軸") != -1) or (u_item.name.find("卷") != -1)
					var row = HBoxContainer.new()
					var info = Label.new()
					info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					
					if is_scroll:
						info.text = "📜 %s  (數量: %d)" % [u_item.name, u_item.get("count", 1)]
						info.modulate = Color(1.0, 0.85, 0.2)
					else:
						info.text = "🧪 %s  (數量: %d)" % [u_item.name, u_item.get("count", 1)]
						info.modulate = Color(0.4, 0.9, 1.0)
					info.add_theme_font_size_override("font_size", 12)
					row.add_child(info)
					
					var act_btn = Button.new()
					var idx = i
					if is_scroll:
						act_btn.text = "✨ 衝裝"
						act_btn.modulate = Color(1.0, 0.85, 0.2)
						act_btn.pressed.connect(func():
							open_scroll_workshop(idx)
						)
					else:
						act_btn.text = "使用"
						act_btn.pressed.connect(func():
							Global.use_consume_item(idx)
							refresh_inventory_modal()
						)
					row.add_child(act_btn)
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
# MAPLESTORY SCROLL ENHANCEMENT WORKSHOP MODAL (楓之谷衝裝鐵匠鋪)
# =========================================================================
func build_scroll_workshop_modal():
	scroll_workshop_modal = PanelContainer.new()
	scroll_workshop_modal.name = "ScrollWorkshopModal"
	scroll_workshop_modal.custom_minimum_size = Vector2(680, 520)
	scroll_workshop_modal.set_anchors_preset(Control.PRESET_CENTER)
	scroll_workshop_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	scroll_workshop_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	scroll_workshop_modal.visible = false
	add_child(scroll_workshop_modal)

func open_scroll_workshop(scroll_idx: int):
	current_workshop_scroll_idx = scroll_idx
	if not is_instance_valid(scroll_workshop_modal):
		build_scroll_workshop_modal()
	scroll_workshop_modal.visible = true
	refresh_scroll_workshop()

func refresh_scroll_workshop():
	if not is_instance_valid(scroll_workshop_modal):
		return
		
	for c in scroll_workshop_modal.get_children():
		c.queue_free()
		
	if current_workshop_scroll_idx < 0 or current_workshop_scroll_idx >= Global.use_inventory.size():
		scroll_workshop_modal.visible = false
		return
		
	var scroll_item = Global.use_inventory[current_workshop_scroll_idx]
	var scroll_data = ScrollDatabase.get_scroll_by_name(scroll_item.get("name", ""))
	if scroll_data.is_empty():
		scroll_data = ScrollDatabase.get_scroll(scroll_item.get("id", ""))
	if scroll_data.is_empty():
		scroll_data = scroll_item
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "🔨 楓之谷衝裝鐵匠鋪 (裝備卷軸強化)"
	title.add_theme_font_size_override("font_size", 17)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var calc_btn = Button.new()
	calc_btn.text = "📊 強化機率計算機"
	calc_btn.modulate = Color(0.4, 0.9, 1.0)
	calc_btn.pressed.connect(func():
		open_scroll_calc_modal()
	)
	header.add_child(calc_btn)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): scroll_workshop_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Scroll Information Banner
	var scroll_card = PanelContainer.new()
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0.12, 0.15, 0.22, 0.95)
	s_style.border_color = Color(0.9, 0.7, 0.2, 1.0)
	s_style.set_border_width_all(2)
	s_style.set_corner_radius_all(4)
	s_style.content_margin_left = 12
	s_style.content_margin_right = 12
	s_style.content_margin_top = 8
	s_style.content_margin_bottom = 8
	scroll_card.add_theme_stylebox_override("panel", s_style)
	
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 4)
	
	var s_name_lbl = Label.new()
	s_name_lbl.text = "📜 目前選擇卷軸：【%s】 (剩餘數量: %d)" % [scroll_data.get("name", "卷軸"), scroll_item.get("count", 1)]
	s_name_lbl.add_theme_font_size_override("font_size", 14)
	s_name_lbl.modulate = Color(1.0, 0.85, 0.2)
	card_vbox.add_child(s_name_lbl)
	
	var rate = scroll_data.get("rate", 60)
	var is_cursed = scroll_data.get("is_cursed", false) or rate in [30, 70]
	var s_details_lbl = Label.new()
	var cursed_warning = "  |  ⚠️ 詛咒卷軸：失敗時 50% 機率裝備損毀消失！" if is_cursed else "  |  失敗時扣除 1 次可升級次數。"
	s_details_lbl.text = "適用部位: 【%s】  |  成功機率: %d%%%s" % [scroll_data.get("target_slot", "weapon"), rate, cursed_warning]
	s_details_lbl.add_theme_font_size_override("font_size", 12)
	s_details_lbl.modulate = Color(1.0, 0.4, 0.4) if is_cursed else Color(0.6, 0.9, 1.0)
	card_vbox.add_child(s_details_lbl)
	
	# Stats gained on success
	var stats_gain_str = ""
	var s_stats = scroll_data.get("stats", {})
	for k in s_stats.keys():
		stats_gain_str += "%s +%d  " % [k.to_upper(), s_stats[k]]
	if stats_gain_str == "":
		stats_gain_str = "物理/魔法攻擊力與屬性提升"
	var s_gain_lbl = Label.new()
	s_gain_lbl.text = "✨ 成功時效果預覽: 【%s】" % stats_gain_str
	s_gain_lbl.add_theme_font_size_override("font_size", 12)
	s_gain_lbl.modulate = Color(0.4, 1.0, 0.6)
	card_vbox.add_child(s_gain_lbl)
	
	scroll_card.add_child(card_vbox)
	main_vbox.add_child(scroll_card)
	
	# Target Equipment Selection List
	var list_title = Label.new()
	list_title.text = "🎯 請選擇要進行強化 (衝裝) 的裝備："
	list_title.add_theme_font_size_override("font_size", 13)
	list_title.modulate = Color.WHITE
	main_vbox.add_child(list_title)
	
	var scroll_equip_container = ScrollContainer.new()
	scroll_equip_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_equip_container.custom_minimum_size = Vector2(0, 200)
	
	var eq_vbox = VBoxContainer.new()
	eq_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_vbox.add_theme_constant_override("separation", 6)
	
	var eligible_count = 0
	
	# 1. Check currently equipped gear
	for slot_key in Global.equipped_items.keys():
		var eq = Global.equipped_items[slot_key]
		if eq != null and ScrollDatabase.is_scroll_compatible_with_equip(scroll_data, eq):
			eligible_count += 1
			var row = create_enhance_target_row(eq, "equipped", slot_key, "【身上穿戴】")
			eq_vbox.add_child(row)
			
	# 2. Check inventory equipment
	for i in range(Global.equip_inventory.size()):
		var eq = Global.equip_inventory[i]
		if ScrollDatabase.is_scroll_compatible_with_equip(scroll_data, eq):
			eligible_count += 1
			var row = create_enhance_target_row(eq, "inventory", i, "【背包裝備】")
			eq_vbox.add_child(row)
			
	if eligible_count == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "⚠️ 目前身上與背包中沒有符合該卷軸部位且可升級的裝備！"
		empty_lbl.modulate = Color(1.0, 0.5, 0.5)
		eq_vbox.add_child(empty_lbl)
		
	scroll_equip_container.add_child(eq_vbox)
	main_vbox.add_child(scroll_equip_container)
	
	# Bottom Action Bar
	var bot_hbox = HBoxContainer.new()
	bot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bot_hbox.add_theme_constant_override("separation", 20)
	
	var cancel_btn = Button.new()
	cancel_btn.text = " ✕ 關閉鐵匠鋪 "
	cancel_btn.custom_minimum_size = Vector2(140, 36)
	cancel_btn.pressed.connect(func(): scroll_workshop_modal.visible = false)
	bot_hbox.add_child(cancel_btn)
	
	main_vbox.add_child(bot_hbox)
	scroll_workshop_modal.add_child(main_vbox)

func create_enhance_target_row(eq: Dictionary, target_type: String, target_key, location_prefix: String) -> Control:
	var row = PanelContainer.new()
	var r_style = StyleBoxFlat.new()
	r_style.bg_color = Color(0.08, 0.10, 0.15, 0.9)
	r_style.set_border_width_all(1)
	r_style.border_color = Color(0.25, 0.35, 0.5)
	r_style.set_corner_radius_all(3)
	r_style.content_margin_left = 8
	r_style.content_margin_right = 8
	r_style.content_margin_top = 6
	r_style.content_margin_bottom = 6
	row.add_theme_stylebox_override("panel", r_style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var succ_cnt = eq.get("scroll_success_count", 0)
	var plus_str = " (+%d)" % succ_cnt if succ_cnt > 0 else ""
	var rem_slots = eq.get("upgrade_slots_remaining", 7)
	var tot_slots = eq.get("upgrade_slots_total", 7)
	
	var lbl = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = "%s %s%s (Lv.%d) | 攻+%d 防+%d | 可升級次數: %d/%d" % [
		location_prefix, eq.name, plus_str, eq.get("req_lvl", 1), eq.get("atk", 0), eq.get("def", 0), rem_slots, tot_slots
	]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(1.0, 0.85, 0.2) if succ_cnt > 0 else Color.WHITE
	hbox.add_child(lbl)
	
	var do_btn = Button.new()
	do_btn.text = "✨ 進行衝裝"
	do_btn.custom_minimum_size = Vector2(100, 28)
	if rem_slots <= 0:
		do_btn.disabled = true
		do_btn.text = "已無次數"
	else:
		do_btn.pressed.connect(func():
			var res = Global.apply_scroll_to_equipment(current_workshop_scroll_idx, target_type, target_key)
			refresh_scroll_workshop()
			refresh_inventory_modal()
		)
	hbox.add_child(do_btn)
	row.add_child(hbox)
	return row

# =========================================================================
# ACCURACY CALCULATOR MODAL (新楓之谷經典版命中門檻試算)
# https://bobogameguides.com/maplestory-classic/tools/accuracy/
# =========================================================================
func build_accuracy_modal():
	accuracy_modal = PanelContainer.new()
	accuracy_modal.name = "AccuracyModal"
	accuracy_modal.custom_minimum_size = Vector2(740, 560)
	accuracy_modal.set_anchors_preset(Control.PRESET_CENTER)
	accuracy_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	accuracy_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	accuracy_modal.visible = false
	add_child(accuracy_modal)

func open_accuracy_modal():
	if not is_instance_valid(accuracy_modal):
		build_accuracy_modal()
	accuracy_modal.visible = true
	refresh_accuracy_modal()

func refresh_accuracy_modal():
	if not is_instance_valid(accuracy_modal):
		return
		
	for c in accuracy_modal.get_children():
		c.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "🎯 新楓之谷經典版 命中門檻試算｜物理與魔法命中"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): accuracy_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Subtitle / Description
	var sub_lbl = Label.new()
	sub_lbl.text = "怪物等級與迴避來自官方客戶端 (波波攻略島)；估算物理或魔法攻擊不出現 MISS 所需的命中門檻與實戰命中率。"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.8, 0.9)
	main_vbox.add_child(sub_lbl)
	
	# Mode Toggle Bar
	var mode_hbox = HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 10)
	
	var mode_title = Label.new()
	mode_title.text = "攻擊類型："
	mode_title.add_theme_font_size_override("font_size", 12)
	mode_hbox.add_child(mode_title)
	
	var phys_btn = Button.new()
	phys_btn.text = "⚔️ 物理攻擊 (當前命中: %d)" % Global.get_player_physical_accuracy()
	if accuracy_calc_mode == "physical":
		phys_btn.modulate = Color(1.0, 0.85, 0.2)
	phys_btn.pressed.connect(func():
		accuracy_calc_mode = "physical"
		refresh_accuracy_modal()
	)
	mode_hbox.add_child(phys_btn)
	
	var magic_btn = Button.new()
	magic_btn.text = "✨ 魔法攻擊 (當前魔法命中: %d)" % Global.get_player_magic_accuracy()
	if accuracy_calc_mode == "magic":
		magic_btn.modulate = Color(0.4, 0.9, 1.0)
	magic_btn.pressed.connect(func():
		accuracy_calc_mode = "magic"
		refresh_accuracy_modal()
	)
	mode_hbox.add_child(magic_btn)
	
	main_vbox.add_child(mode_hbox)
	
	# Split Layout: Left Monster List / Right Calculation Card
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	
	# --- LEFT: Monster Selector ---
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(280, 260)
	var l_vbox = VBoxContainer.new()
	l_vbox.add_theme_constant_override("separation", 4)
	
	var search_input = LineEdit.new()
	search_input.placeholder_text = "🔍 搜尋怪物名稱 (如: 嫩寶, 炎魔)..."
	search_input.text = accuracy_search_query
	search_input.text_changed.connect(func(new_text):
		accuracy_search_query = new_text
		refresh_accuracy_modal()
	)
	l_vbox.add_child(search_input)
	
	var mob_scroll = ScrollContainer.new()
	mob_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mob_list = VBoxContainer.new()
	mob_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var selected_mob = null
	for m in MonsterDatabaseFull.MONSTERS:
		if m.id == accuracy_selected_mob_id:
			selected_mob = m
		var m_name = m.get("name", "")
		if accuracy_search_query != "" and m_name.find(accuracy_search_query) == -1:
			continue
			
		var mob_btn = Button.new()
		var m_lvl = m.get("level", 1)
		var m_eva = m.get("avoid", m.get("eva", int(m_lvl * 0.25)))
		mob_btn.text = "Lv.%d %s (迴避 %d)" % [m_lvl, m_name, m_eva]
		mob_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if m.id == accuracy_selected_mob_id:
			mob_btn.modulate = Color(1.0, 0.85, 0.2)
		var mid = m.id
		mob_btn.pressed.connect(func():
			accuracy_selected_mob_id = mid
			refresh_accuracy_modal()
		)
		mob_list.add_child(mob_btn)
		
	if selected_mob == null and not MonsterDatabaseFull.MONSTERS.is_empty():
		selected_mob = MonsterDatabaseFull.MONSTERS[0]
		accuracy_selected_mob_id = selected_mob.id
		
	mob_scroll.add_child(mob_list)
	l_vbox.add_child(mob_scroll)
	left_panel.add_child(l_vbox)
	body_hbox.add_child(left_panel)
	
	# --- RIGHT: Live Accuracy Calculator Result ---
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var r_vbox = VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 8)
	
	if selected_mob != null:
		var mob_lvl = selected_mob.get("level", 1)
		var mob_avoid = selected_mob.get("avoid", selected_mob.get("eva", int(mob_lvl * 0.25)))
		var mob_name = selected_mob.get("name", "怪物")
		
		var calc_res = {}
		if accuracy_calc_mode == "magic":
			calc_res = Global.calculate_magic_accuracy_threshold(mob_lvl, mob_avoid)
		else:
			calc_res = Global.calculate_physical_accuracy_threshold(mob_lvl, mob_avoid)
			
		# Results Grid
		var res_grid = GridContainer.new()
		res_grid.columns = 2
		res_grid.add_theme_constant_override("h_separation", 10)
		res_grid.add_theme_constant_override("v_separation", 6)
		
		add_acc_result_card(res_grid, "怪物官方資料", "【%s】Lv.%d | 迴避 %d" % [mob_name, mob_lvl, mob_avoid], Color.WHITE)
		add_acc_result_card(res_grid, "等級差 (D = max(0, 怪Lv - 人Lv))", "%d 級" % calc_res.diff, Color(0.4, 0.9, 1.0))
		add_acc_result_card(res_grid, "估算 100% 必中門檻", "%d 點" % calc_res.threshold if calc_res.threshold > 0 else "0 (不需額外命中)", Color.GOLD)
		add_acc_result_card(res_grid, "你目前面板命中", "%d 點" % calc_res.current, Color(0.3, 1.0, 0.5))
		add_acc_result_card(res_grid, "還差命中 (Gap)", "%d 點" % calc_res.gap if calc_res.gap > 0 else "0 (已達 100% 必中)", Color(1.0, 0.4, 0.4) if calc_res.gap > 0 else Color(0.3, 1.0, 0.5))
		add_acc_result_card(res_grid, "實戰命中率預估", "%.1f%%" % (calc_res.hit_rate * 100.0), Color.GOLD if calc_res.hit_rate >= 1.0 else Color.SALMON)
		
		r_vbox.add_child(res_grid)
		
		# Status Banner Alert
		var status_panel = PanelContainer.new()
		var st_style = StyleBoxFlat.new()
		st_style.set_corner_radius_all(4)
		st_style.content_margin_left = 10
		st_style.content_margin_right = 10
		st_style.content_margin_top = 8
		st_style.content_margin_bottom = 8
		
		var st_lbl = Label.new()
		st_lbl.add_theme_font_size_override("font_size", 12)
		if calc_res.is_sufficient:
			st_style.bg_color = Color(0.05, 0.25, 0.12, 0.9)
			st_style.border_color = Color(0.3, 1.0, 0.5)
			st_style.set_border_width_all(1)
			st_lbl.text = "✅ 命中已達 100% 門檻！攻擊【%s】完全不會出現 MISS！" % mob_name
			st_lbl.modulate = Color(0.4, 1.0, 0.6)
		else:
			st_style.bg_color = Color(0.28, 0.10, 0.10, 0.9)
			st_style.border_color = Color(1.0, 0.3, 0.3)
			st_style.set_border_width_all(1)
			st_lbl.text = "⚠️ 命中不足！尚差 %d 點命中，當前命中率估算為 %.1f%%（可能出現紫色 MISS）！可藉由點 DEX / LUK 或裝備卷軸提升！" % [calc_res.gap, (calc_res.hit_rate * 100.0)]
			st_lbl.modulate = Color(1.0, 0.6, 0.6)
		status_panel.add_theme_stylebox_override("panel", st_style)
		status_panel.add_child(st_lbl)
		r_vbox.add_child(status_panel)
		
		# Formula Explanation Box
		var formula_box = VBoxContainer.new()
		var f_title = Label.new()
		f_title.text = "📖 門檻公式推導 (Bobo 官方舊制社群公式)："
		f_title.add_theme_font_size_override("font_size", 11)
		f_title.modulate = Color.GRAY
		formula_box.add_child(f_title)
		
		var f_desc = Label.new()
		f_desc.add_theme_font_size_override("font_size", 10)
		f_desc.modulate = Color(0.6, 0.7, 0.8)
		if accuracy_calc_mode == "magic":
			f_desc.text = "• 魔法命中 = floor(INT / 10) + floor(LUK / 10) + 裝備魔法命中\n• 魔法門檻 = floor((怪物迴避 + 1) × (1 + 0.04 × D))\n• D = max(0, 怪物Lv - 角色Lv)"
		else:
			f_desc.text = "• 物理命中 = DEX × 0.8 + LUK × 0.5 + 裝備物理命中\n• 物理門檻 = ceil((55.2 + 2.15 × D) × (怪物迴避 / 15))\n• D = max(0, 怪物Lv - 角色Lv)"
		formula_box.add_child(f_desc)
		r_vbox.add_child(formula_box)
		
	right_panel.add_child(r_vbox)
	body_hbox.add_child(right_panel)
	
	main_vbox.add_child(body_hbox)
	accuracy_modal.add_child(main_vbox)

func add_acc_result_card(grid: GridContainer, title_text: String, val_text: String, val_color: Color):
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	c_style.set_corner_radius_all(3)
	c_style.content_margin_left = 6
	c_style.content_margin_right = 6
	c_style.content_margin_top = 4
	c_style.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", c_style)
	
	var vbox = VBoxContainer.new()
	var t_lbl = Label.new()
	t_lbl.text = title_text
	t_lbl.add_theme_font_size_override("font_size", 10)
	t_lbl.modulate = Color.GRAY
	vbox.add_child(t_lbl)
	
	var v_lbl = Label.new()
	v_lbl.text = val_text
	v_lbl.add_theme_font_size_override("font_size", 12)
	v_lbl.modulate = val_color
	vbox.add_child(v_lbl)
	
	card.add_child(vbox)
	grid.add_child(card)

# =========================================================================
# WEAPON ATTACK POWER CALCULATOR MODAL (新楓之谷經典版武器面板攻擊力計算器)
# https://bobogameguides.com/maplestory-classic/tools/attack-power/
# =========================================================================
func build_weapon_attack_modal():
	weapon_attack_modal = PanelContainer.new()
	weapon_attack_modal.name = "WeaponAttackModal"
	weapon_attack_modal.custom_minimum_size = Vector2(780, 580)
	weapon_attack_modal.set_anchors_preset(Control.PRESET_CENTER)
	weapon_attack_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	weapon_attack_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	weapon_attack_modal.visible = false
	add_child(weapon_attack_modal)

func open_weapon_attack_modal():
	if not is_instance_valid(weapon_attack_modal):
		build_weapon_attack_modal()
	# Preload character's current stats into inputs
	weapon_calc_str = Global.stat_str + Global.equip_bonus_str
	weapon_calc_dex = Global.stat_dex + Global.equip_bonus_dex
	weapon_calc_luk = Global.stat_luk + Global.equip_bonus_luk
	weapon_calc_watk = max(10, Global.weapon_atk + Global.equip_bonus_atk)
	weapon_calc_selected_key = Global.get_current_equipped_weapon_class()
	weapon_calc_mastery = clamp((Global.mastery + Global.passive_buffs.get("mastery_boost", 0.0)) * 100.0, 10.0, 90.0)
	weapon_attack_modal.visible = true
	refresh_weapon_attack_modal()

func refresh_weapon_attack_modal():
	if not is_instance_valid(weapon_attack_modal):
		return
		
	for c in weapon_attack_modal.get_children():
		c.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "⚔️ 新楓之谷經典版 武器面板攻擊力計算器｜上下限試算"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): weapon_attack_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Subtitle / Lead
	var sub_lbl = Label.new()
	sub_lbl.text = "依 1.14.6 官方客戶端 16 類武器係數與計算式：上下限均依官方做法向下取整 (floor)。"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.8, 0.9)
	main_vbox.add_child(sub_lbl)
	
	# Split Layout: Left Form Inputs | Right Live Output & Coefficient Table
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	
	# --- LEFT: Form Inputs ---
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(340, 460)
	var in_vbox = VBoxContainer.new()
	in_vbox.add_theme_constant_override("separation", 6)
	
	var w_lbl = Label.new()
	w_lbl.text = "武器類別 (16類官方武器)："
	w_lbl.add_theme_font_size_override("font_size", 12)
	in_vbox.add_child(w_lbl)
	
	var w_opt = OptionButton.new()
	var w_keys = Global.WEAPON_COEFFICIENTS.keys()
	for idx in range(w_keys.size()):
		var k = w_keys[idx]
		var d = Global.WEAPON_COEFFICIENTS[k]
		w_opt.add_item("%s (%s)" % [d.name, d.note], idx)
		if k == weapon_calc_selected_key:
			w_opt.selected = idx
			
	w_opt.item_selected.connect(func(idx):
		weapon_calc_selected_key = w_keys[idx]
		refresh_weapon_attack_modal()
	)
	in_vbox.add_child(w_opt)
	
	# Quick Sync button
	var sync_btn = Button.new()
	sync_btn.text = "🔄 帶入角色目前真實穿戴與屬性"
	sync_btn.modulate = Color(0.3, 1.0, 0.5)
	sync_btn.pressed.connect(func():
		weapon_calc_str = Global.stat_str + Global.equip_bonus_str
		weapon_calc_dex = Global.stat_dex + Global.equip_bonus_dex
		weapon_calc_luk = Global.stat_luk + Global.equip_bonus_luk
		weapon_calc_watk = max(10, Global.weapon_atk + Global.equip_bonus_atk)
		weapon_calc_selected_key = Global.get_current_equipped_weapon_class()
		weapon_calc_mastery = clamp((Global.mastery + Global.passive_buffs.get("mastery_boost", 0.0)) * 100.0, 10.0, 90.0)
		refresh_weapon_attack_modal()
	)
	in_vbox.add_child(sync_btn)
	
	# Stat Inputs Grid
	var f_grid = GridContainer.new()
	f_grid.columns = 2
	f_grid.add_theme_constant_override("h_separation", 10)
	f_grid.add_theme_constant_override("v_separation", 4)
	
	add_num_input(f_grid, "總 STR (力量)", weapon_calc_str, func(v): weapon_calc_str = v; refresh_weapon_attack_modal())
	add_num_input(f_grid, "總 DEX (敏捷)", weapon_calc_dex, func(v): weapon_calc_dex = v; refresh_weapon_attack_modal())
	add_num_input(f_grid, "總 LUK (幸運)", weapon_calc_luk, func(v): weapon_calc_luk = v; refresh_weapon_attack_modal())
	add_num_input(f_grid, "總物攻 (WATK)", weapon_calc_watk, func(v): weapon_calc_watk = v; refresh_weapon_attack_modal())
	
	in_vbox.add_child(f_grid)
	
	# Mastery Selector
	var m_lbl = Label.new()
	m_lbl.text = "武器熟練度 (Mastery)："
	m_lbl.add_theme_font_size_override("font_size", 12)
	in_vbox.add_child(m_lbl)
	
	var m_opt = OptionButton.new()
	var m_presets = [
		{"label": "未學精準技能 (10%)", "val": 10.0},
		{"label": "精準技能 Lv 1–2 (15%)", "val": 15.0},
		{"label": "精準技能 Lv 5–6 (25%)", "val": 25.0},
		{"label": "精準技能 Lv 9–10 (35%)", "val": 35.0},
		{"label": "精準技能 Lv 15–16 (50%)", "val": 50.0},
		{"label": "精準技能 Lv 19–20 (60% MAX)", "val": 60.0}
	]
	for idx in range(m_presets.size()):
		var p = m_presets[idx]
		m_opt.add_item(p.label, idx)
		if abs(p.val - weapon_calc_mastery) < 1.0:
			m_opt.selected = idx
			
	m_opt.item_selected.connect(func(idx):
		weapon_calc_mastery = m_presets[idx].val
		refresh_weapon_attack_modal()
	)
	in_vbox.add_child(m_opt)
	
	left_panel.add_child(in_vbox)
	body_hbox.add_child(left_panel)
	
	# --- RIGHT: Calculation Result & Coefficients Table ---
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var r_vbox = VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 8)
	
	# Calculate Output
	var calc_out = Global.calculate_weapon_attack_power_range(
		weapon_calc_selected_key, weapon_calc_str, weapon_calc_dex, weapon_calc_luk, weapon_calc_watk, weapon_calc_mastery
	)
	
	# Big Output Display Cards
	var res_hbox = HBoxContainer.new()
	res_hbox.add_theme_constant_override("separation", 10)
	
	var min_card = PanelContainer.new()
	min_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c_style_min = StyleBoxFlat.new()
	c_style_min.bg_color = Color(0.12, 0.16, 0.22, 0.95)
	c_style_min.set_corner_radius_all(4)
	c_style_min.content_margin_left = 10
	c_style_min.content_margin_top = 8
	c_style_min.content_margin_bottom = 8
	c_style_min.border_color = Color(0.3, 0.8, 1.0)
	c_style_min.set_border_width_all(1)
	min_card.add_theme_stylebox_override("panel", c_style_min)
	
	var min_v = VBoxContainer.new()
	var min_t = Label.new()
	min_t.text = "面板攻擊力下限 (MIN)"
	min_t.add_theme_font_size_override("font_size", 11)
	min_t.modulate = Color.GRAY
	min_v.add_child(min_t)
	var min_val = Label.new()
	min_val.text = "%d" % calc_out.min_atk
	min_val.add_theme_font_size_override("font_size", 24)
	min_val.modulate = Color(0.4, 0.9, 1.0)
	min_v.add_child(min_val)
	min_card.add_child(min_v)
	res_hbox.add_child(min_card)
	
	var max_card = PanelContainer.new()
	max_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c_style_max = StyleBoxFlat.new()
	c_style_max.bg_color = Color(0.20, 0.16, 0.08, 0.95)
	c_style_max.set_corner_radius_all(4)
	c_style_max.content_margin_left = 10
	c_style_max.content_margin_top = 8
	c_style_max.content_margin_bottom = 8
	c_style_max.border_color = Color(1.0, 0.85, 0.2)
	c_style_max.set_border_width_all(1)
	max_card.add_theme_stylebox_override("panel", c_style_max)
	
	var max_v = VBoxContainer.new()
	var max_t = Label.new()
	max_t.text = "面板攻擊力上限 (MAX)"
	max_t.add_theme_font_size_override("font_size", 11)
	max_t.modulate = Color.GRAY
	max_v.add_child(max_t)
	var max_val = Label.new()
	max_val.text = "%d" % calc_out.max_atk
	max_val.add_theme_font_size_override("font_size", 24)
	max_val.modulate = Color(1.0, 0.85, 0.2)
	max_v.add_child(max_val)
	max_card.add_child(max_v)
	res_hbox.add_child(max_card)
	
	r_vbox.add_child(res_hbox)
	
	# Breakdown Description
	var info_box = PanelContainer.new()
	var ib_style = StyleBoxFlat.new()
	ib_style.bg_color = Color(0.08, 0.10, 0.14, 0.9)
	ib_style.set_corner_radius_all(4)
	ib_style.content_margin_left = 8
	ib_style.content_margin_right = 8
	ib_style.content_margin_top = 6
	ib_style.content_margin_bottom = 6
	info_box.add_theme_stylebox_override("panel", ib_style)
	
	var info_t = Label.new()
	info_t.text = "📌 目前套用：【%s】\n• 主屬性: %s (下限係數 %.1f / 上限係數 %.1f)\n• 副屬性: %s  |  熟練修正: %.2f (熟練度 %.0f%%)" % [
		calc_out.weapon_name, calc_out.main_stat, calc_out.min_coeff, calc_out.max_coeff, calc_out.sub_stat, calc_out.mastery_modifier, weapon_calc_mastery
	]
	info_t.add_theme_font_size_override("font_size", 11)
	info_t.modulate = Color(0.9, 0.95, 1.0)
	info_box.add_child(info_t)
	r_vbox.add_child(info_box)
	
	# 16-Weapon Coefficient Table
	var table_scroll = ScrollContainer.new()
	table_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_scroll.custom_minimum_size = Vector2(0, 160)
	
	var t_vbox = VBoxContainer.new()
	t_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_vbox.add_theme_constant_override("separation", 2)
	
	var t_head = Label.new()
	t_head.text = "📋 1.14.6 官方物理面板係數速查表："
	t_head.add_theme_font_size_override("font_size", 11)
	t_head.modulate = Color.GOLD
	t_vbox.add_child(t_head)
	
	for k in Global.WEAPON_COEFFICIENTS.keys():
		var wd = Global.WEAPON_COEFFICIENTS[k]
		var r_lbl = Label.new()
		r_lbl.text = "• %s: 主%s / 副%s | 下限 %.1f / 上限 %.1f (%s)" % [
			wd.name, wd.main_stat.to_upper(), wd.sub_stat.to_upper(), wd.min_coeff, wd.max_coeff, wd.note
		]
		r_lbl.add_theme_font_size_override("font_size", 10)
		if k == weapon_calc_selected_key:
			r_lbl.modulate = Color(1.0, 0.85, 0.2)
		else:
			r_lbl.modulate = Color(0.7, 0.7, 0.7)
		t_vbox.add_child(r_lbl)
		
	table_scroll.add_child(t_vbox)
	r_vbox.add_child(table_scroll)
	
	right_panel.add_child(r_vbox)
	body_hbox.add_child(right_panel)
	
	main_vbox.add_child(body_hbox)
	weapon_attack_modal.add_child(main_vbox)

func add_num_input(grid: GridContainer, label_text: String, init_val: int, on_changed: Callable):
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(0.8, 0.85, 0.9)
	grid.add_child(lbl)
	
	var input = SpinBox.new()
	input.min_value = 0
	input.max_value = 99999
	input.value = init_val
	input.value_changed.connect(func(v): on_changed.call(int(v)))
	grid.add_child(input)

# =========================================================================
# SCROLL ENHANCEMENT PROBABILITY CALCULATOR MODAL (新楓之谷經典版卷軸強化計算機)
# https://bobogameguides.com/maplestory-classic/guides/scroll-calculator.html
# =========================================================================
func build_scroll_calc_modal():
	scroll_calc_modal = PanelContainer.new()
	scroll_calc_modal.name = "ScrollCalcModal"
	scroll_calc_modal.custom_minimum_size = Vector2(780, 600)
	scroll_calc_modal.set_anchors_preset(Control.PRESET_CENTER)
	scroll_calc_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	scroll_calc_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	scroll_calc_modal.visible = false
	add_child(scroll_calc_modal)

func open_scroll_calc_modal():
	if not is_instance_valid(scroll_calc_modal):
		build_scroll_calc_modal()
	scroll_calc_modal.visible = true
	refresh_scroll_calc_modal()

func refresh_scroll_calc_modal():
	if not is_instance_valid(scroll_calc_modal):
		return
		
	for c in scroll_calc_modal.get_children():
		c.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "📊 新楓之谷經典版 卷軸強化機率計算機｜二項分布精確計算"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): scroll_calc_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Lead
	var sub_lbl = Label.new()
	sub_lbl.text = "輸入裝備可強化次數、卷軸成功率與價格，算出成功次數分布、期望成功數與期望花費 (精確閉式解)。"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.8, 0.9)
	main_vbox.add_child(sub_lbl)
	
	# Split Layout: Left Parameters | Right Results & Distribution Bars
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	
	# --- LEFT: Parameters Input ---
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(280, 480)
	var in_vbox = VBoxContainer.new()
	in_vbox.add_theme_constant_override("separation", 8)
	
	# 1. Total Slots
	var s_lbl = Label.new()
	s_lbl.text = "裝備可強化次數 (Slots)："
	s_lbl.add_theme_font_size_override("font_size", 11)
	s_lbl.modulate = Color(0.85, 0.85, 0.9)
	in_vbox.add_child(s_lbl)
	
	var s_spin = SpinBox.new()
	s_spin.min_value = 1
	s_spin.max_value = 30
	s_spin.value = scroll_calc_slots
	s_spin.value_changed.connect(func(v):
		scroll_calc_slots = int(v)
		if scroll_calc_want > scroll_calc_slots:
			scroll_calc_want = scroll_calc_slots
		refresh_scroll_calc_modal()
	)
	in_vbox.add_child(s_spin)
	
	# 2. Scroll Rate Dropdown
	var r_lbl = Label.new()
	r_lbl.text = "卷軸成功率："
	r_lbl.add_theme_font_size_override("font_size", 11)
	r_lbl.modulate = Color(0.85, 0.85, 0.9)
	in_vbox.add_child(r_lbl)
	
	var r_opt = OptionButton.new()
	var rates = [
		{"label": "10% (高風險高回報)", "val": 10.0},
		{"label": "30% (詛咒卷軸)", "val": 30.0},
		{"label": "60% (一般標準卷軸)", "val": 60.0},
		{"label": "70% (詛咒卷軸)", "val": 70.0},
		{"label": "100% (穩健必成)", "val": 100.0}
	]
	for idx in range(rates.size()):
		var rd = rates[idx]
		r_opt.add_item(rd.label, idx)
		if abs(rd.val - scroll_calc_rate) < 0.1:
			r_opt.selected = idx
			
	r_opt.item_selected.connect(func(idx):
		scroll_calc_rate = rates[idx].val
		refresh_scroll_calc_modal()
	)
	in_vbox.add_child(r_opt)
	
	# 3. Want Success Count
	var w_lbl = Label.new()
	w_lbl.text = "期望至少成功幾次："
	w_lbl.add_theme_font_size_override("font_size", 11)
	w_lbl.modulate = Color(0.85, 0.85, 0.9)
	in_vbox.add_child(w_lbl)
	
	var w_spin = SpinBox.new()
	w_spin.min_value = 0
	w_spin.max_value = scroll_calc_slots
	w_spin.value = scroll_calc_want
	w_spin.value_changed.connect(func(v):
		scroll_calc_want = int(v)
		refresh_scroll_calc_modal()
	)
	in_vbox.add_child(w_spin)
	
	# 4. Scroll Unit Price
	var p_lbl = Label.new()
	p_lbl.text = "卷軸單價 (楓幣，選填)："
	p_lbl.add_theme_font_size_override("font_size", 11)
	p_lbl.modulate = Color(0.85, 0.85, 0.9)
	in_vbox.add_child(p_lbl)
	
	var p_spin = SpinBox.new()
	p_spin.min_value = 0
	p_spin.max_value = 999999999
	p_spin.step = 10000
	p_spin.value = scroll_calc_price
	p_spin.value_changed.connect(func(v):
		scroll_calc_price = int(v)
		refresh_scroll_calc_modal()
	)
	in_vbox.add_child(p_spin)
	
	# Note Card
	var note_card = PanelContainer.new()
	var nc_style = StyleBoxFlat.new()
	nc_style.bg_color = Color(0.08, 0.10, 0.15, 0.9)
	nc_style.set_corner_radius_all(4)
	nc_style.content_margin_left = 8
	nc_style.content_margin_right = 8
	nc_style.content_margin_top = 8
	nc_style.content_margin_bottom = 8
	note_card.add_theme_stylebox_override("panel", nc_style)
	
	var nt_lbl = Label.new()
	nt_lbl.text = "📜 官方經典規則：\n• 一般卷軸失敗時裝備保留，消耗該張卷軸與 1 次升級機會。\n• 衝裝為獨立二項分布，衝到次數用完即停止。"
	nt_lbl.add_theme_font_size_override("font_size", 10)
	nt_lbl.modulate = Color(0.7, 0.8, 0.9)
	note_card.add_child(nt_lbl)
	in_vbox.add_child(note_card)
	
	left_panel.add_child(in_vbox)
	body_hbox.add_child(left_panel)
	
	# --- RIGHT: Results Summary & Probability Distribution Bars ---
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var r_vbox = VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 8)
	
	# Calculate results using Global.calculate_scroll_probabilities
	var calc_res = Global.calculate_scroll_probabilities(
		scroll_calc_slots, scroll_calc_rate, scroll_calc_want, scroll_calc_price
	)
	
	# 4 Summary Cards Grid
	var res_grid = GridContainer.new()
	res_grid.columns = 2
	res_grid.add_theme_constant_override("h_separation", 10)
	res_grid.add_theme_constant_override("v_separation", 6)
	
	add_acc_result_card(res_grid, "期望成功次數 (E = N × p)", "%.2f 次" % calc_res.expected_success, Color.GOLD)
	add_acc_result_card(res_grid, "至少成功 %d 次的精確機率" % scroll_calc_want, "%.2f%%" % calc_res.at_least_prob_pct, Color(0.3, 1.0, 0.5) if calc_res.at_least_prob_pct >= 50.0 else Color(1.0, 0.6, 0.4))
	add_acc_result_card(res_grid, "最可能的成功次數 (Mode)", "%d 次" % calc_res.mode_k, Color(0.4, 0.9, 1.0))
	add_acc_result_card(res_grid, "期望卷軸總花費", "%d 楓幣" % calc_res.expected_cost, Color.GOLD)
	
	r_vbox.add_child(res_grid)
	
	# Distribution Title
	var dist_title = Label.new()
	dist_title.text = "📈 成功次數的機率分布 (Probability Distribution)："
	dist_title.add_theme_font_size_override("font_size", 12)
	dist_title.modulate = Color.WHITE
	r_vbox.add_child(dist_title)
	
	# Scrollable Bars Container
	var dist_scroll = ScrollContainer.new()
	dist_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dist_scroll.custom_minimum_size = Vector2(0, 220)
	
	var dist_list = VBoxContainer.new()
	dist_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dist_list.add_theme_constant_override("separation", 4)
	
	for entry in calc_res.distribution:
		var k = entry.k
		var pct = entry.pct
		var is_highlight = (k >= scroll_calc_want)
		
		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 8)
		
		var k_lbl = Label.new()
		k_lbl.custom_minimum_size = Vector2(85, 0)
		k_lbl.text = "成功 %d 次:" % k
		k_lbl.add_theme_font_size_override("font_size", 11)
		k_lbl.modulate = Color.GOLD if is_highlight else Color.GRAY
		row_hbox.add_child(k_lbl)
		
		var bar = ProgressBar.new()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 16)
		bar.max_value = 100.0
		bar.value = pct
		bar.show_percentage = false
		
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = Color(0.9, 0.75, 0.2) if is_highlight else Color(0.3, 0.4, 0.5, 0.6)
		b_style.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", b_style)
		row_hbox.add_child(bar)
		
		var pct_lbl = Label.new()
		pct_lbl.custom_minimum_size = Vector2(75, 0)
		pct_lbl.text = "%.2f%%" % pct
		pct_lbl.add_theme_font_size_override("font_size", 11)
		pct_lbl.modulate = Color(1.0, 0.85, 0.2) if is_highlight else Color(0.6, 0.6, 0.6)
		row_hbox.add_child(pct_lbl)
		
		dist_list.add_child(row_hbox)
		
	dist_scroll.add_child(dist_list)
	r_vbox.add_child(dist_scroll)
	
	right_panel.add_child(r_vbox)
	body_hbox.add_child(right_panel)
	
	main_vbox.add_child(body_hbox)
	scroll_calc_modal.add_child(main_vbox)

# =========================================================================
# MONSTER & OFFICIAL DROPS ENCYCLOPEDIA MODAL (新楓之谷經典版官方怪物圖鑑與掉落查詢)
# https://bobogameguides.com/maplestory-classic/monsters/
# =========================================================================
func build_monster_book_modal():
	monster_book_modal = PanelContainer.new()
	monster_book_modal.name = "MonsterBookModal"
	monster_book_modal.custom_minimum_size = Vector2(860, 640)
	monster_book_modal.set_anchors_preset(Control.PRESET_CENTER)
	monster_book_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	monster_book_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	monster_book_modal.visible = false
	add_child(monster_book_modal)

func open_monster_book_modal():
	if not is_instance_valid(monster_book_modal):
		build_monster_book_modal()
	monster_book_modal.visible = true
	refresh_monster_book_modal()

func refresh_monster_book_modal():
	if not is_instance_valid(monster_book_modal):
		return
		
	for c in monster_book_modal.get_children():
		c.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "📖 新楓之谷經典版 官方怪物圖鑑與掉落資料庫 (332 隻怪物 / 7,257 筆掉落)"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): monster_book_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Subtitle
	var sub_lbl = Label.new()
	sub_lbl.text = "1.14.6 官方客戶端怪物數據庫：怪物等級、HP、EXP、物攻、物防、命中、迴避與官方完整掉落物清單。"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.modulate = Color(0.7, 0.8, 0.9)
	main_vbox.add_child(sub_lbl)
	
	# Body Split
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	
	# --- LEFT: Monster Selector & Filters ---
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(300, 520)
	var l_vbox = VBoxContainer.new()
	l_vbox.add_theme_constant_override("separation", 6)
	
	# Search Box
	var s_input = LineEdit.new()
	s_input.placeholder_text = "🔍 搜尋怪物名稱或 ID (如: 嫩寶, 炎魔)..."
	s_input.text = monster_book_search_query
	s_input.text_changed.connect(func(t):
		monster_book_search_query = t
		refresh_monster_book_modal()
	)
	l_vbox.add_child(s_input)
	
	# Level Filter Dropdown
	var lvl_opt = OptionButton.new()
	var lvl_filters = [
		{"label": "全部等級 (1 ~ 200)", "val": "all"},
		{"label": "Lv 1 ～ 20", "val": "1-20"},
		{"label": "Lv 21 ～ 40", "val": "21-40"},
		{"label": "Lv 41 ～ 60", "val": "41-60"},
		{"label": "Lv 61 ～ 80", "val": "61-80"},
		{"label": "Lv 81 ～ 100", "val": "81-100"},
		{"label": "Lv 101 ～ 120", "val": "101-120"},
		{"label": "Lv 121+", "val": "121+"},
		{"label": "👑 僅看 BOSS 怪物", "val": "boss"}
	]
	for idx in range(lvl_filters.size()):
		var f = lvl_filters[idx]
		lvl_opt.add_item(f.label, idx)
		if f.val == monster_book_level_filter:
			lvl_opt.selected = idx
			
	lvl_opt.item_selected.connect(func(idx):
		monster_book_level_filter = lvl_filters[idx].val
		refresh_monster_book_modal()
	)
	l_vbox.add_child(lvl_opt)
	
	# Scrollable Monster List
	var mob_scroll = ScrollContainer.new()
	mob_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mob_list = VBoxContainer.new()
	mob_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var selected_mob = null
	var count_visible = 0
	
	for m in MonsterDatabaseFull.MONSTERS:
		var m_id = m.id
		var m_name = m.get("name", "")
		var m_lvl = m.get("level", 1)
		var is_boss = m.get("is_boss", false)
		
		# Level filter
		var pass_lvl = true
		match monster_book_level_filter:
			"1-20": pass_lvl = (m_lvl >= 1 and m_lvl <= 20)
			"21-40": pass_lvl = (m_lvl >= 21 and m_lvl <= 40)
			"41-60": pass_lvl = (m_lvl >= 41 and m_lvl <= 60)
			"61-80": pass_lvl = (m_lvl >= 61 and m_lvl <= 80)
			"81-100": pass_lvl = (m_lvl >= 81 and m_lvl <= 100)
			"101-120": pass_lvl = (m_lvl >= 101 and m_lvl <= 120)
			"121+": pass_lvl = (m_lvl >= 121)
			"boss": pass_lvl = is_boss
			
		if not pass_lvl:
			continue
			
		# Search filter
		if monster_book_search_query != "":
			var q = monster_book_search_query.to_lower()
			if m_name.to_lower().find(q) == -1 and str(m_id).find(q) == -1:
				continue
				
		count_visible += 1
		if m_id == monster_book_selected_id:
			selected_mob = m
			
		var mob_btn = Button.new()
		var boss_tag = "👑 " if is_boss else ""
		mob_btn.text = "%sLv.%d %s (HP %d)" % [boss_tag, m_lvl, m_name, m.get("hp", 0)]
		mob_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if m_id == monster_book_selected_id:
			mob_btn.modulate = Color(1.0, 0.85, 0.2)
		mob_btn.pressed.connect(func():
			monster_book_selected_id = m_id
			refresh_monster_book_modal()
		)
		mob_list.add_child(mob_btn)
		
	if selected_mob == null and not MonsterDatabaseFull.MONSTERS.is_empty():
		selected_mob = MonsterDatabaseFull.MONSTERS[0]
		monster_book_selected_id = selected_mob.id
		
	mob_scroll.add_child(mob_list)
	l_vbox.add_child(mob_scroll)
	
	var count_lbl = Label.new()
	count_lbl.text = "顯示 %d / 332 隻怪物" % count_visible
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.modulate = Color.GRAY
	l_vbox.add_child(count_lbl)
	
	left_panel.add_child(l_vbox)
	body_hbox.add_child(left_panel)
	
	# --- RIGHT: Monster Detail & Full Drops Display ---
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var r_vbox = VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 8)
	
	if selected_mob != null:
		# Header Info
		var mob_h = HBoxContainer.new()
		var m_title = Label.new()
		var boss_prefix = "👑 BOSS " if selected_mob.get("is_boss", false) else ""
		m_title.text = "【%s%s】 Lv.%d (ID: %d)" % [boss_prefix, selected_mob.get("name", ""), selected_mob.get("level", 1), selected_mob.id]
		m_title.add_theme_font_size_override("font_size", 15)
		m_title.modulate = Color(1.0, 0.85, 0.2) if selected_mob.get("is_boss", false) else Color.WHITE
		mob_h.add_child(m_title)
		
		var h_spacer = Control.new()
		h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mob_h.add_child(h_spacer)
		
		var sim_acc_btn = Button.new()
		sim_acc_btn.text = "🎯 命中試算"
		sim_acc_btn.modulate = Color(0.4, 0.9, 1.0)
		sim_acc_btn.pressed.connect(func():
			accuracy_selected_mob_id = selected_mob.id
			monster_book_modal.visible = false
			open_accuracy_modal()
		)
		mob_h.add_child(sim_acc_btn)
		r_vbox.add_child(mob_h)
		
		# 10 Combat Stats Grid
		var s_grid = GridContainer.new()
		s_grid.columns = 5
		s_grid.add_theme_constant_override("h_separation", 6)
		s_grid.add_theme_constant_override("v_separation", 4)
		
		add_stat_tag_card(s_grid, "HP", str(selected_mob.get("hp", 0)), Color(1.0, 0.4, 0.4))
		add_stat_tag_card(s_grid, "MP", str(selected_mob.get("mp", 0)), Color(0.4, 0.7, 1.0))
		add_stat_tag_card(s_grid, "EXP 經驗", str(selected_mob.get("exp", 0)), Color.GOLD)
		add_stat_tag_card(s_grid, "物理攻擊", str(selected_mob.get("watk", 0)), Color(1.0, 0.8, 0.4))
		add_stat_tag_card(s_grid, "魔法攻擊", str(selected_mob.get("matk", 0)), Color(0.8, 0.6, 1.0))
		add_stat_tag_card(s_grid, "物理防禦", str(selected_mob.get("wdef", 0)), Color(0.7, 0.9, 0.7))
		add_stat_tag_card(s_grid, "魔法防禦", str(selected_mob.get("mdef", 0)), Color(0.7, 0.8, 1.0))
		add_stat_tag_card(s_grid, "命中值", str(selected_mob.get("acc", 0)), Color(0.9, 0.9, 0.9))
		add_stat_tag_card(s_grid, "迴避值", str(selected_mob.get("avoid", 0)), Color(1.0, 0.85, 0.3))
		add_stat_tag_card(s_grid, "移動速度", str(selected_mob.get("speed", 0)), Color(0.6, 1.0, 0.8))
		
		r_vbox.add_child(s_grid)
		
		# Drop Categories Scroll Container
		var drops_scroll = ScrollContainer.new()
		drops_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		drops_scroll.custom_minimum_size = Vector2(0, 320)
		
		var drops_vbox = VBoxContainer.new()
		drops_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		drops_vbox.add_theme_constant_override("separation", 8)
		
		var all_drops = selected_mob.get("drops", [])
		var equips = []
		var scrolls = []
		var uses = []
		var materials = []
		
		for d in all_drops:
			match d.get("type", ""):
				"equip": equips.append(d)
				"scroll": scrolls.append(d)
				"use": uses.append(d)
				"etc", "material": materials.append(d)
				
		add_drop_category_section(drops_vbox, "🗡️ 官方裝備掉落 (%d 件)" % equips.size(), equips, Color(1.0, 0.6, 0.3))
		add_drop_category_section(drops_vbox, "📜 官方卷軸／製作圖 (%d 種)" % scrolls.size(), scrolls, Color.GOLD)
		add_drop_category_section(drops_vbox, "🧪 官方消耗品／藥水／彈藥 (%d 種)" % uses.size(), uses, Color(0.4, 0.9, 1.0))
		add_drop_category_section(drops_vbox, "💎 官方材料／戰利品 (%d 種)" % materials.size(), materials, Color(0.4, 1.0, 0.6))
		
		drops_scroll.add_child(drops_vbox)
		r_vbox.add_child(drops_scroll)
		
	right_panel.add_child(r_vbox)
	body_hbox.add_child(right_panel)
	
	main_vbox.add_child(body_hbox)
	monster_book_modal.add_child(main_vbox)

func add_stat_tag_card(grid: GridContainer, label_t: String, val_t: String, val_color: Color):
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.10, 0.12, 0.16, 0.9)
	c_style.set_corner_radius_all(3)
	c_style.content_margin_left = 6
	c_style.content_margin_top = 4
	c_style.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", c_style)
	
	var v = VBoxContainer.new()
	var l = Label.new()
	l.text = label_t
	l.add_theme_font_size_override("font_size", 9)
	l.modulate = Color.GRAY
	v.add_child(l)
	
	var val = Label.new()
	val.text = val_t
	val.add_theme_font_size_override("font_size", 11)
	val.modulate = val_color
	v.add_child(val)
	
	card.add_child(v)
	grid.add_child(card)

func add_drop_category_section(parent: VBoxContainer, cat_title: String, item_list: Array, cat_color: Color):
	if item_list.is_empty():
		return
		
	var head = Label.new()
	head.text = cat_title
	head.add_theme_font_size_override("font_size", 12)
	head.modulate = cat_color
	parent.add_child(head)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	
	for it in item_list:
		var item_card = PanelContainer.new()
		item_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ic_style = StyleBoxFlat.new()
		ic_style.bg_color = Color(0.12, 0.14, 0.18, 0.8)
		ic_style.set_corner_radius_all(3)
		ic_style.content_margin_left = 8
		ic_style.content_margin_right = 8
		ic_style.content_margin_top = 4
		ic_style.content_margin_bottom = 4
		item_card.add_theme_stylebox_override("panel", ic_style)
		
		var lbl = Label.new()
		lbl.text = "• %s (ID: %d)" % [it.get("name", "道具"), it.get("id", 0)]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.modulate = Color(0.9, 0.95, 1.0)
		item_card.add_child(lbl)
		
		grid.add_child(item_card)
		
	parent.add_child(grid)

# =========================================================================
# OFFICIAL ITEMS & EQUIPMENT ENCYCLOPEDIA MODAL (官方裝備與道具圖鑑資料庫)
# https://bobogameguides.com/maplestory-classic/items/ & equipment/
# =========================================================================
func build_item_book_modal():
	item_book_modal = PanelContainer.new()
	item_book_modal.name = "ItemBookModal"
	item_book_modal.custom_minimum_size = Vector2(880, 640)
	item_book_modal.set_anchors_preset(Control.PRESET_CENTER)
	item_book_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	item_book_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	item_book_modal.visible = false
	add_child(item_book_modal)

func open_item_book_modal():
	if not is_instance_valid(item_book_modal):
		build_item_book_modal()
	item_book_modal.visible = true
	refresh_item_book_modal()

func refresh_item_book_modal():
	if not is_instance_valid(item_book_modal):
		return
		
	for c in item_book_modal.get_children():
		c.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "🎒 新楓之谷經典版 官方裝備與道具資料庫 (4,529 件裝備 / 671 種道具)"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.pressed.connect(func(): item_book_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Subtitle / Tabs
	var tab_hbox = HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 10)
	
	var tab_eq = Button.new()
	tab_eq.text = "🗡️ 官方裝備 (4,529 件)"
	if item_book_tab == "equip":
		tab_eq.modulate = Color(1.0, 0.85, 0.2)
	tab_eq.pressed.connect(func():
		item_book_tab = "equip"
		refresh_item_book_modal()
	)
	tab_hbox.add_child(tab_eq)
	
	var tab_con = Button.new()
	tab_con.text = "🧪 消耗品與藥水 (110 種)"
	if item_book_tab == "consumable":
		tab_con.modulate = Color(0.4, 0.9, 1.0)
	tab_con.pressed.connect(func():
		item_book_tab = "consumable"
		refresh_item_book_modal()
	)
	tab_hbox.add_child(tab_con)
	
	var tab_mat = Button.new()
	tab_mat.text = "💎 怪物戰利品與母礦 (561 種)"
	if item_book_tab == "material":
		tab_mat.modulate = Color(0.4, 1.0, 0.6)
	tab_mat.pressed.connect(func():
		item_book_tab = "material"
		refresh_item_book_modal()
	)
	tab_hbox.add_child(tab_mat)
	
	main_vbox.add_child(tab_hbox)
	
	# Body Split
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	
	# --- LEFT: Filter & Item List ---
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(320, 520)
	var l_vbox = VBoxContainer.new()
	l_vbox.add_theme_constant_override("separation", 6)
	
	# Search Box
	var s_input = LineEdit.new()
	s_input.placeholder_text = "🔍 搜尋名稱或 ID (如: 綠髮帶, 紅色藥水)..."
	s_input.text = item_book_search_query
	s_input.text_changed.connect(func(t):
		item_book_search_query = t
		refresh_item_book_modal()
	)
	l_vbox.add_child(s_input)
	
	# Slot Filter Dropdown (Only for Equipments)
	if item_book_tab == "equip":
		var slot_opt = OptionButton.new()
		var slot_filters = [
			{"label": "全部部位 (帽子/衣服/武器/飾品)", "val": "all"},
			{"label": "👑 帽子 (Hat)", "val": "hat"},
			{"label": "👕 上衣 (Top)", "val": "top"},
			{"label": "👖 下衣 (Bottom)", "val": "bottom"},
			{"label": "🥋 套服 (Overall)", "val": "overall"},
			{"label": "👟 鞋子 (Shoes)", "val": "shoes"},
			{"label": "🧤 手套 (Gloves)", "val": "gloves"},
			{"label": "🗡️ 單手武器 (One-Handed)", "val": "one_handed"},
			{"label": "⚔️ 雙手武器 (Two-Handed)", "val": "two_handed"},
			{"label": "💍 飾品與其他 (Accessory)", "val": "accessory"}
		]
		for idx in range(slot_filters.size()):
			var sf = slot_filters[idx]
			slot_opt.add_item(sf.label, idx)
			if sf.val == item_book_slot_filter:
				slot_opt.selected = idx
				
		slot_opt.item_selected.connect(func(idx):
			item_book_slot_filter = slot_filters[idx].val
			refresh_item_book_modal()
		)
		l_vbox.add_child(slot_opt)
		
	# Scrollable Item List
	var item_scroll = ScrollContainer.new()
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var item_list_vbox = VBoxContainer.new()
	item_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var selected_entry = null
	var visible_count = 0
	var q = item_book_search_query.strip_edges().to_lower()
	
	if item_book_tab == "equip":
		for eq_id in EquipmentDatabaseFull.EQUIPMENTS.keys():
			var eq = EquipmentDatabaseFull.EQUIPMENTS[eq_id]
			var eq_name = eq.get("name", "")
			var slot = eq.get("slot", "")
			var req_l = eq.get("req_lvl", 0)
			
			if item_book_slot_filter != "all" and slot != item_book_slot_filter:
				continue
				
			if q != "" and eq_name.to_lower().find(q) == -1 and str(eq_id).find(q) == -1:
				continue
				
			visible_count += 1
			if eq_id == item_book_selected_id:
				selected_entry = eq
				
			var btn = Button.new()
			btn.text = "Lv.%d %s (%s)" % [req_l, eq_name, eq.get("slot_name", "裝備")]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if eq_id == item_book_selected_id:
				btn.modulate = Color(1.0, 0.85, 0.2)
			btn.pressed.connect(func():
				item_book_selected_id = eq_id
				refresh_item_book_modal()
			)
			item_list_vbox.add_child(btn)
			
		if selected_entry == null and not EquipmentDatabaseFull.EQUIPMENTS.is_empty():
			var first_k = EquipmentDatabaseFull.EQUIPMENTS.keys()[0]
			selected_entry = EquipmentDatabaseFull.EQUIPMENTS[first_k]
			item_book_selected_id = first_k
	else:
		for item_id in ItemDatabaseFull.ITEMS.keys():
			var it = ItemDatabaseFull.ITEMS[item_id]
			var it_name = it.get("name", "")
			var cat = it.get("category", "")
			
			if item_book_tab == "consumable" and cat != "consumable":
				continue
			elif item_book_tab == "material" and cat not in ["material", "ore"]:
				continue
				
			if q != "" and it_name.to_lower().find(q) == -1 and str(item_id).find(q) == -1:
				continue
				
			visible_count += 1
			if item_id == item_book_selected_id:
				selected_entry = it
				
			var btn = Button.new()
			btn.text = "%s (ID: %d)" % [it_name, item_id]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if item_id == item_book_selected_id:
				btn.modulate = Color(1.0, 0.85, 0.2)
			btn.pressed.connect(func():
				item_book_selected_id = item_id
				refresh_item_book_modal()
			)
			item_list_vbox.add_child(btn)
			
		if selected_entry == null and not ItemDatabaseFull.ITEMS.is_empty():
			var first_k = ItemDatabaseFull.ITEMS.keys()[0]
			selected_entry = ItemDatabaseFull.ITEMS[first_k]
			item_book_selected_id = first_k
			
	item_scroll.add_child(item_list_vbox)
	l_vbox.add_child(item_scroll)
	
	var c_lbl = Label.new()
	c_lbl.text = "顯示 %d 筆項目" % visible_count
	c_lbl.add_theme_font_size_override("font_size", 10)
	c_lbl.modulate = Color.GRAY
	l_vbox.add_child(c_lbl)
	
	left_panel.add_child(l_vbox)
	body_hbox.add_child(left_panel)
	
	# --- RIGHT: Detailed Item Card ---
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var r_vbox = VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 8)
	
	if selected_entry != null:
		var name_str = selected_entry.get("name", "")
		var id_val = selected_entry.get("id", 0)
		
		# Title
		var title_lbl = Label.new()
		title_lbl.text = "【%s】 (官方 ID: %d)" % [name_str, id_val]
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.modulate = Color(1.0, 0.85, 0.2)
		r_vbox.add_child(title_lbl)
		
		# Metadata & Stats Grid
		if item_book_tab == "equip":
			var eq_grid = GridContainer.new()
			eq_grid.columns = 4
			eq_grid.add_theme_constant_override("h_separation", 6)
			eq_grid.add_theme_constant_override("v_separation", 4)
			
			add_stat_tag_card(eq_grid, "裝備部位", selected_entry.get("slot_name", "裝備"), Color(0.4, 0.9, 1.0))
			add_stat_tag_card(eq_grid, "需求等級", "Lv.%d" % selected_entry.get("req_lvl", 0), Color.GOLD)
			add_stat_tag_card(eq_grid, "適用職業", selected_entry.get("req_job", "全職業"), Color(0.8, 1.0, 0.6))
			add_stat_tag_card(eq_grid, "升級次數", "%d 次" % selected_entry.get("upgrade_slots_remaining", 7), Color(1.0, 0.6, 0.4))
			add_stat_tag_card(eq_grid, "物理攻擊 (WATK)", "+%d" % selected_entry.get("watk", 0), Color.GOLD)
			add_stat_tag_card(eq_grid, "魔法攻擊 (MATK)", "+%d" % selected_entry.get("matk", 0), Color(0.8, 0.6, 1.0))
			add_stat_tag_card(eq_grid, "物理防禦 (WDEF)", "+%d" % selected_entry.get("wdef", 0), Color(0.7, 0.9, 0.7))
			add_stat_tag_card(eq_grid, "魔法防禦 (MDEF)", "+%d" % selected_entry.get("mdef", 0), Color(0.7, 0.8, 1.0))
			add_stat_tag_card(eq_grid, "力量 (STR)", "+%d" % selected_entry.get("str", 0), Color.WHITE)
			add_stat_tag_card(eq_grid, "敏捷 (DEX)", "+%d" % selected_entry.get("dex", 0), Color.WHITE)
			add_stat_tag_card(eq_grid, "智力 (INT)", "+%d" % selected_entry.get("int", 0), Color.WHITE)
			add_stat_tag_card(eq_grid, "幸運 (LUK)", "+%d" % selected_entry.get("luk", 0), Color.WHITE)
			
			r_vbox.add_child(eq_grid)
		else:
			var it_grid = GridContainer.new()
			it_grid.columns = 3
			it_grid.add_theme_constant_override("h_separation", 6)
			it_grid.add_theme_constant_override("v_separation", 4)
			
			add_stat_tag_card(it_grid, "道具類別", selected_entry.get("category", "道具"), Color(0.4, 0.9, 1.0))
			add_stat_tag_card(it_grid, "恢復 HP", "+%d" % selected_entry.get("hp_heal", 0), Color(1.0, 0.4, 0.4))
			add_stat_tag_card(it_grid, "恢復 MP", "+%d" % selected_entry.get("mp_heal", 0), Color(0.4, 0.7, 1.0))
			
			r_vbox.add_child(it_grid)
			
		# Which Monsters Drop This Item? (Reverse Lookup from MonsterDatabaseFull)
		var drop_src_title = Label.new()
		drop_src_title.text = "👾 掉落來源怪物 (官方掉落關係)："
		drop_src_title.add_theme_font_size_override("font_size", 12)
		drop_src_title.modulate = Color.GOLD
		r_vbox.add_child(drop_src_title)
		
		var src_scroll = ScrollContainer.new()
		src_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		src_scroll.custom_minimum_size = Vector2(0, 260)
		
		var src_grid = GridContainer.new()
		src_grid.columns = 2
		src_grid.add_theme_constant_override("h_separation", 8)
		src_grid.add_theme_constant_override("v_separation", 4)
		src_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var drop_mobs_found = []
		for m in MonsterDatabaseFull.MONSTERS:
			for d in m.get("drops", []):
				if d.get("id", 0) == id_val or d.get("name", "") == name_str:
					drop_mobs_found.append(m)
					break
					
		if not drop_mobs_found.is_empty():
			for mob in drop_mobs_found:
				var m_card = PanelContainer.new()
				m_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var mc_style = StyleBoxFlat.new()
				mc_style.bg_color = Color(0.12, 0.14, 0.18, 0.8)
				mc_style.set_corner_radius_all(3)
				mc_style.content_margin_left = 8
				mc_style.content_margin_right = 8
				mc_style.content_margin_top = 4
				mc_style.content_margin_bottom = 4
				m_card.add_theme_stylebox_override("panel", mc_style)
				
				var m_lbl = Label.new()
				var boss_t = "👑 " if mob.get("is_boss", false) else ""
				m_lbl.text = "• %sLv.%d %s (HP %d)" % [boss_t, mob.get("level", 1), mob.get("name", ""), mob.get("hp", 0)]
				m_lbl.add_theme_font_size_override("font_size", 11)
				m_lbl.modulate = Color(1.0, 0.85, 0.2) if mob.get("is_boss", false) else Color(0.85, 0.9, 1.0)
				m_card.add_child(m_lbl)
				src_grid.add_child(m_card)
		else:
			var no_src = Label.new()
			no_src.text = "（此道具主要來自商店販售、任務獎勵或轉蛋機）"
			no_src.add_theme_font_size_override("font_size", 11)
			no_src.modulate = Color.GRAY
			src_grid.add_child(no_src)
			
		src_scroll.add_child(src_grid)
		r_vbox.add_child(src_scroll)
		
	right_panel.add_child(r_vbox)
	body_hbox.add_child(right_panel)
	
	main_vbox.add_child(body_hbox)
	item_book_modal.add_child(main_vbox)


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

# =========================================================================
# CLASSIC MAPLESTORY BOTTOM STATUS BAR (1:1 REPLICA)
# =========================================================================
func setup_classic_maple_bottom_bar():
	var bottom_bar_node = $HUD.get_node_or_null("BottomBar")
	if not bottom_bar_node:
		return
		
	# Clear old placeholder nodes
	for child in bottom_bar_node.get_children():
		child.queue_free()
		
	# Configure BottomBar container styling
	bottom_bar_node.custom_minimum_size = Vector2(0, 52)
	bottom_bar_node.anchors_preset = Control.PRESET_BOTTOM_WIDE
	bottom_bar_node.offset_top = -52
	bottom_bar_node.offset_bottom = 0
	bottom_bar_node.offset_left = 0
	bottom_bar_node.offset_right = 0
	bottom_bar_node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom_bar_node.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.10, 0.12, 0.17, 0.98) # Dark Maple Metallic Slate
	bar_style.border_color = Color(0.38, 0.46, 0.58, 1.0) # Metallic Silver-Blue Top Bevel
	bar_style.border_width_top = 2
	bar_style.content_margin_left = 8
	bar_style.content_margin_right = 8
	bar_style.content_margin_top = 4
	bar_style.content_margin_bottom = 4
	bottom_bar_node.add_theme_stylebox_override("panel", bar_style)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MapleStatusHBox"
	main_hbox.anchors_preset = Control.PRESET_FULL_RECT
	main_hbox.add_theme_constant_override("separation", 10)
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# -------------------------------------------------------------
	# 1. LV Badge & Character Info (左側等級與職業角色名)
	# -------------------------------------------------------------
	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 6)
	info_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# LV. Pill
	var lv_pill = PanelContainer.new()
	var lv_pill_style = StyleBoxFlat.new()
	lv_pill_style.bg_color = Color(0.05, 0.06, 0.08, 1.0)
	lv_pill_style.border_color = Color(0.25, 0.3, 0.4, 1.0)
	lv_pill_style.set_border_width_all(1)
	lv_pill_style.set_corner_radius_all(3)
	lv_pill_style.content_margin_left = 5
	lv_pill_style.content_margin_right = 5
	lv_pill_style.content_margin_top = 2
	lv_pill_style.content_margin_bottom = 2
	lv_pill.add_theme_stylebox_override("panel", lv_pill_style)
	
	var lv_tag_lbl = Label.new()
	lv_tag_lbl.text = "LV."
	lv_tag_lbl.add_theme_font_size_override("font_size", 12)
	lv_tag_lbl.modulate = Color.WHITE
	lv_pill.add_child(lv_tag_lbl)
	info_hbox.add_child(lv_pill)
	
	# Orange Level Number Box (經典橘底黑框等級徽章)
	var num_box = PanelContainer.new()
	var num_box_style = StyleBoxFlat.new()
	num_box_style.bg_color = Color(0.9, 0.42, 0.02, 1.0) # Maple Amber Orange
	num_box_style.border_color = Color(0.55, 0.22, 0.0, 1.0)
	num_box_style.set_border_width_all(1)
	num_box_style.set_corner_radius_all(3)
	num_box_style.content_margin_left = 6
	num_box_style.content_margin_right = 6
	num_box_style.content_margin_top = 2
	num_box_style.content_margin_bottom = 2
	num_box.add_theme_stylebox_override("panel", num_box_style)
	
	lvl_badge_lbl = Label.new()
	lvl_badge_lbl.text = str(Global.player_level)
	lvl_badge_lbl.add_theme_font_size_override("font_size", 13)
	lvl_badge_lbl.add_theme_constant_override("outline_size", 2)
	lvl_badge_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lvl_badge_lbl.modulate = Color.WHITE
	num_box.add_child(lvl_badge_lbl)
	info_hbox.add_child(num_box)
	
	# Job & Name Stack (職業與角色名稱)
	var name_vbox = VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 0)
	name_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	job_name_lbl = Label.new()
	job_name_lbl.text = Global.player_job_data.get("name", "初心者").split(" ")[0]
	job_name_lbl.add_theme_font_size_override("font_size", 11)
	job_name_lbl.modulate = Color(0.65, 0.9, 1.0)
	name_vbox.add_child(job_name_lbl)
	
	char_name_lbl = Label.new()
	char_name_lbl.text = "嵐司洛"
	char_name_lbl.add_theme_font_size_override("font_size", 11)
	char_name_lbl.modulate = Color.WHITE
	name_vbox.add_child(char_name_lbl)
	info_hbox.add_child(name_vbox)
	
	main_hbox.add_child(info_hbox)
	
	# -------------------------------------------------------------
	# 2. HP, MP, EXP Progress Bars (經典血量/魔力/經驗條)
	# -------------------------------------------------------------
	var bars_hbox = HBoxContainer.new()
	bars_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars_hbox.add_theme_constant_override("separation", 10)
	bars_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# --- HP Bar ---
	var hp_vbox = VBoxContainer.new()
	hp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_vbox.add_theme_constant_override("separation", 2)
	
	hp_bar_label = Label.new()
	hp_bar_label.text = "HP [%d/%d]" % [Global.player_hp, Global.player_max_hp]
	hp_bar_label.add_theme_font_size_override("font_size", 11)
	hp_bar_label.add_theme_constant_override("outline_size", 3)
	hp_bar_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_bar_label.modulate = Color.WHITE
	hp_vbox.add_child(hp_bar_label)
	
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 14)
	hp_bar.min_value = 0
	hp_bar.max_value = Global.player_max_hp
	hp_bar.value = Global.player_hp
	hp_bar.show_percentage = false
	
	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.22, 0.05, 0.05, 1.0)
	hp_bg.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.92, 0.15, 0.15, 1.0) # Maple Scarlet Red
	hp_fill.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_vbox.add_child(hp_bar)
	bars_hbox.add_child(hp_vbox)
	
	# --- MP Bar ---
	var mp_vbox = VBoxContainer.new()
	mp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_vbox.add_theme_constant_override("separation", 2)
	
	mp_bar_label = Label.new()
	mp_bar_label.text = "MP [%d/%d]" % [Global.player_mp, Global.player_max_mp]
	mp_bar_label.add_theme_font_size_override("font_size", 11)
	mp_bar_label.add_theme_constant_override("outline_size", 3)
	mp_bar_label.add_theme_color_override("font_outline_color", Color.BLACK)
	mp_bar_label.modulate = Color.WHITE
	mp_vbox.add_child(mp_bar_label)
	
	mp_bar = ProgressBar.new()
	mp_bar.custom_minimum_size = Vector2(0, 14)
	mp_bar.min_value = 0
	mp_bar.max_value = Global.player_max_mp
	mp_bar.value = Global.player_mp
	mp_bar.show_percentage = false
	
	var mp_bg = StyleBoxFlat.new()
	mp_bg.bg_color = Color(0.05, 0.12, 0.22, 1.0)
	mp_bg.set_corner_radius_all(2)
	mp_bar.add_theme_stylebox_override("background", mp_bg)
	
	var mp_fill = StyleBoxFlat.new()
	mp_fill.bg_color = Color(0.12, 0.55, 0.95, 1.0) # Maple Azure Blue
	mp_fill.set_corner_radius_all(2)
	mp_bar.add_theme_stylebox_override("fill", mp_fill)
	mp_vbox.add_child(mp_bar)
	bars_hbox.add_child(mp_vbox)
	
	# --- EXP Bar ---
	var exp_vbox = VBoxContainer.new()
	exp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_vbox.add_theme_constant_override("separation", 2)
	
	var exp_pct = float(Global.player_exp) / float(max(1, Global.player_max_exp)) * 100.0
	exp_bar_label = Label.new()
	exp_bar_label.text = "EXP %d [%.2f%%]" % [Global.player_exp, exp_pct]
	exp_bar_label.add_theme_font_size_override("font_size", 11)
	exp_bar_label.add_theme_constant_override("outline_size", 3)
	exp_bar_label.add_theme_color_override("font_outline_color", Color.BLACK)
	exp_bar_label.modulate = Color.WHITE
	exp_vbox.add_child(exp_bar_label)
	
	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(0, 14)
	exp_bar.min_value = 0
	exp_bar.max_value = Global.player_max_exp
	exp_bar.value = Global.player_exp
	exp_bar.show_percentage = false
	
	var exp_bg = StyleBoxFlat.new()
	exp_bg.bg_color = Color(0.12, 0.18, 0.05, 1.0)
	exp_bg.set_corner_radius_all(2)
	exp_bar.add_theme_stylebox_override("background", exp_bg)
	
	var exp_fill = StyleBoxFlat.new()
	exp_fill.bg_color = Color(0.65, 0.88, 0.15, 1.0) # Maple Lime Green
	exp_fill.set_corner_radius_all(2)
	exp_bar.add_theme_stylebox_override("fill", exp_fill)
	exp_vbox.add_child(exp_bar)
	bars_hbox.add_child(exp_vbox)
	
	main_hbox.add_child(bars_hbox)
	
	# -------------------------------------------------------------
	# 3. Meso & 6 Classic Maple Buttons (裝備/地圖/轉職/技能/屬性/熱鍵選項)
	# -------------------------------------------------------------
	var right_hbox = HBoxContainer.new()
	right_hbox.add_theme_constant_override("separation", 5)
	right_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	meso_bottom_label = Label.new()
	meso_bottom_label.text = "💰 %s" % format_hp_num(Global.meso_gold)
	meso_bottom_label.add_theme_font_size_override("font_size", 12)
	meso_bottom_label.modulate = Color.GOLD
	right_hbox.add_child(meso_bottom_label)
	
	# Button 1: 裝備 (原購物商城位置)
	var btn_equip = create_classic_bottom_btn("裝備", Color(0.85, 0.18, 0.18), Color(0.5, 0.05, 0.05))
	btn_equip.pressed.connect(func(): toggle_modal(inventory_modal))
	right_hbox.add_child(btn_equip)
	
	# Button 2: 地圖 (原拍賣位置)
	var btn_map = create_classic_bottom_btn("地圖", Color(0.18, 0.65, 0.22), Color(0.08, 0.35, 0.1))
	btn_map.pressed.connect(func(): toggle_modal(map_select_modal))
	right_hbox.add_child(btn_map)
	
	# Button 3: 轉職 (原目錄位置)
	var btn_job = create_classic_bottom_btn("轉職", Color(0.92, 0.55, 0.05), Color(0.55, 0.3, 0.02))
	btn_job.pressed.connect(func(): toggle_modal(job_select_modal))
	right_hbox.add_child(btn_job)
	
	# Button 4: 技能
	var btn_skill = create_classic_bottom_btn("技能", Color(0.65, 0.25, 0.85), Color(0.4, 0.1, 0.55))
	btn_skill.pressed.connect(func(): toggle_modal(skill_modal))
	right_hbox.add_child(btn_skill)
	
	# Button 5: 屬性
	var btn_stat = create_classic_bottom_btn("屬性", Color(0.15, 0.65, 0.75), Color(0.05, 0.35, 0.45))
	btn_stat.pressed.connect(func(): toggle_modal(stat_modal))
	right_hbox.add_child(btn_stat)
	
	# Button 6: 熱鍵選項
	var btn_keys = create_classic_bottom_btn("熱鍵選項", Color(0.12, 0.45, 0.85), Color(0.05, 0.22, 0.5))
	btn_keys.pressed.connect(show_keybinding_modal)
	right_hbox.add_child(btn_keys)
	
	main_hbox.add_child(right_hbox)
	bottom_bar_node.add_child(main_hbox)

func create_classic_bottom_btn(btn_text: String, bg_color: Color, border_color: Color) -> Button:
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(62, 30)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_constant_override("outline_size", 2)
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)
	return btn

func update_player_hp(cur: int, max_val: int):
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = cur
	if hp_bar_label:
		hp_bar_label.text = "HP [%d/%d]" % [cur, max_val]

func update_player_mp(cur: int, max_val: int):
	if mp_bar:
		mp_bar.max_value = max_val
		mp_bar.value = cur
	if mp_bar_label:
		mp_bar_label.text = "MP [%d/%d]" % [cur, max_val]

func update_player_exp(cur: int, max_val: int, lvl: int):
	if exp_bar:
		exp_bar.max_value = max_val
		exp_bar.value = cur
	if exp_bar_label:
		var pct = float(cur) / float(max(1, max_val)) * 100.0
		exp_bar_label.text = "EXP %d [%.2f%%]" % [cur, pct]
	if lvl_badge_lbl:
		lvl_badge_lbl.text = str(lvl)

func update_player_job_display(job_data: Dictionary):
	if not job_data.is_empty():
		var j_name = job_data.get("name", "初心者").split(" ")[0]
		if job_name_lbl:
			job_name_lbl.text = j_name
		if char_name_lbl:
			char_name_lbl.text = "嵐司洛"

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

# =========================================================================
# TABBED REGIONAL MAP BROWSER & TELEPORTATION DIRECTORY (100% FAITHFUL TO BOBO)
# =========================================================================
var current_selected_map_region: String = "henesys"

func setup_map_selection_list():
	render_tabbed_map_browser(current_selected_map_region)

func render_tabbed_map_browser(selected_region_id: String):
	if not is_instance_valid(map_select_modal):
		return
		
	current_selected_map_region = selected_region_id
	
	for child in map_select_modal.get_children():
		child.queue_free()
		
	map_select_modal.custom_minimum_size = Vector2(900, 620)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 8)
	
	# Top Header Bar
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	
	var title = Label.new()
	title.text = "🗺️ 楓之谷世界地圖 ‧ 全分區地圖與怪物目錄"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(title)
	
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(sp)
	
	var search_input = LineEdit.new()
	search_input.placeholder_text = "🔍 搜尋地圖名稱或出沒怪物..."
	search_input.custom_minimum_size = Vector2(240, 32)
	header.add_child(search_input)
	
	var close_btn = Button.new()
	close_btn.text = " ✕ 關閉 "
	close_btn.pressed.connect(func(): map_select_modal.visible = false)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Region Tabs Bar
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 5)
	
	var region_tabs = [
		{"id": "henesys", "name": "🏹 弓箭手村", "color": Color(1.0, 0.85, 0.2)},
		{"id": "ellinia", "name": "🌲 魔法森林", "color": Color(0.3, 1.0, 0.5)},
		{"id": "perion", "name": "🏛️ 勇士之村", "color": Color(1.0, 0.6, 0.2)},
		{"id": "kerning", "name": "🏙️ 墮落城市", "color": Color(0.4, 0.9, 1.0)},
		{"id": "sleepywood", "name": "🌋 奇幻村", "color": Color(0.9, 0.4, 1.0)},
		{"id": "lith_harbor", "name": "⛵ 維多利亞港", "color": Color(0.4, 0.8, 1.0)},
		{"id": "nautilus", "name": "⚓ 鯨魚號", "color": Color(0.3, 0.8, 1.0)},
		{"id": "florina", "name": "🏖️ 黃金海岸", "color": Color(1.0, 0.9, 0.3)},
		{"id": "pq", "name": "👥 組隊任務", "color": Color(0.2, 1.0, 0.8)},
		{"id": "event", "name": "🏆 全怪特訓場", "color": Color(1.0, 0.3, 0.3)}
	]
	
	for r in region_tabs:
		var r_id = r.id
		var t_btn = Button.new()
		t_btn.text = r.name
		t_btn.add_theme_font_size_override("font_size", 12)
		if r_id == selected_region_id:
			t_btn.modulate = Color.WHITE
			t_btn.add_theme_color_override("font_color", r.color)
		else:
			t_btn.modulate = Color(0.75, 0.75, 0.75)
			
		t_btn.pressed.connect(func():
			render_tabbed_map_browser(r_id)
		)
		tab_bar.add_child(t_btn)
		
	main_vbox.add_child(tab_bar)
	
	# Filter maps belonging to this region
	var matched_maps: Array[Dictionary] = []
	for mid in MapDatabase.MAPS.keys():
		var m = MapDatabase.MAPS[mid]
		var theme = m.get("terrain_theme", "")
		var r_name = m.get("region", "")
		var m_name = m.get("name", "")
		var is_match = false
		
		match selected_region_id:
			"perion":
				is_match = (theme == "perion" or "勇士" in r_name or "石巨人" in m_name or "岩山" in m_name or "峽谷" in m_name or "黑石頭人" in m_name)
			"ellinia":
				is_match = (theme == "ellinia" or "魔法森林" in r_name or "大木林" in m_name or "樹林" in m_name or "猴子" in m_name or "巫婆" in m_name)
			"henesys":
				is_match = (theme == "henesys" or "弓箭手" in r_name or "肥肥" in m_name or "東部" in m_name or "菇菇" in m_name)
			"kerning":
				is_match = (theme in ["kerning", "subway"] or "墮落" in r_name or "地鐵" in m_name or "沼澤" in m_name or "幽靈" in m_name)
			"sleepywood":
				is_match = (theme == "sleepywood" or "奇幻" in r_name or "螞蟻洞" in m_name or "幽靈樹" in m_name or "神殿" in m_name or "龍穴" in m_name)
			"lith_harbor":
				is_match = (theme == "lith_harbor" or "維多利亞港" in r_name or "海岸草叢" in m_name or "三叉路" in m_name)
			"nautilus":
				is_match = (theme == "nautilus" or "鯨魚號" in r_name or "航海" in m_name or "甲板" in m_name)
			"florina":
				is_match = (theme == "florina" or "黃金海岸" in r_name or "沙灘" in m_name or "椰子" in m_name or "螃蟹" in m_name)
			"pq":
				is_match = ("9910000" in mid or "組隊" in r_name or "組隊" in m_name or "第一次同行" in m_name)
			"event":
				is_match = ("活動" in r_name or "9900000" in mid or "特別" in m_name or "特訓" in m_name)
			_:
				is_match = (selected_region_id in theme or selected_region_id in r_name)
				
		if is_match:
			matched_maps.append(m)
			
	if matched_maps.is_empty():
		matched_maps = [MapDatabase.MAPS.get("100000000", {})]
		
	# Region Summary Banner
	var sum_box = HBoxContainer.new()
	var sum_lbl = Label.new()
	sum_lbl.text = "📜 該分區收錄共 %d 張地圖 (點擊右側【⚡ 進入地圖】秒傳進圖)" % matched_maps.size()
	sum_lbl.add_theme_font_size_override("font_size", 12)
	sum_lbl.modulate = Color(0.4, 0.9, 1.0)
	sum_box.add_child(sum_lbl)
	main_vbox.add_child(sum_box)
	
	# Scrollable Map Cards List
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, 440)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 6)
	
	var render_map_cards = func(filter_text: String):
		for ch in list_vbox.get_children():
			ch.queue_free()
			
		var displayed_count = 0
		for m in matched_maps:
			var m_name = m.get("name", "未命名地圖")
			var s_name = m.get("street", "維多利亞島")
			var mobs = m.get("monsters", [])
			var portals = m.get("normal_portals", [])
			
			# Monster string
			var mob_str_list = []
			for mob in mobs:
				mob_str_list.append("%s (Lv.%d)" % [mob.get("name", ""), mob.get("level", 1)])
			var mob_display = "、".join(mob_str_list) if not mob_str_list.is_empty() else "無野怪出沒 (城鎮安全區)"
			
			# Filter matching
			if filter_text != "" and not (filter_text in m_name or filter_text in s_name or filter_text in mob_display):
				continue
				
			displayed_count += 1
			var card = PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var card_vbox = VBoxContainer.new()
			card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card_vbox.add_theme_constant_override("separation", 3)
			
			# Row 1: Title (left, expand) + Enter Button (right, fixed)
			var row1 = HBoxContainer.new()
			row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var map_title = Label.new()
			map_title.text = "📍 %s  [%s]" % [m_name, s_name]
			map_title.add_theme_font_size_override("font_size", 14)
			map_title.modulate = Color.GOLD
			map_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			map_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row1.add_child(map_title)
			
			var enter_btn = Button.new()
			enter_btn.text = "⚡ 進入地圖"
			enter_btn.custom_minimum_size = Vector2(110, 28)
			enter_btn.modulate = Color(0.3, 1.0, 0.5)
			var target_id = str(m.get("map_id", m.get("id", "100000000")))
			enter_btn.pressed.connect(func():
				Global.change_map(target_id)
				map_select_modal.visible = false
			)
			row1.add_child(enter_btn)
			card_vbox.add_child(row1)
			
			# Row 2: Monsters info (Full width)
			var mob_lbl = Label.new()
			mob_lbl.text = "👾 出沒怪物: %s" % mob_display
			mob_lbl.add_theme_font_size_override("font_size", 11)
			mob_lbl.modulate = Color(1.0, 0.85, 0.6)
			mob_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mob_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_vbox.add_child(mob_lbl)
			
			# Row 3: Portals info (Full width, formatted)
			if not portals.is_empty():
				var portal_lbl = Label.new()
				var p_names = []
				for p in portals:
					var p_title = p.get("title", "傳送點")
					if p_title.begins_with("前往"):
						p_title = p_title.substr(2)
					p_names.append(p_title)
				var p_summary = ""
				if p_names.size() > 4:
					p_summary = "、".join(p_names.slice(0, 4)) + " 等共 %d 個傳送點" % p_names.size()
				else:
					p_summary = "、".join(p_names)
				portal_lbl.text = "🚪 連接: %s" % p_summary
				portal_lbl.add_theme_font_size_override("font_size", 10)
				portal_lbl.modulate = Color(0.5, 0.8, 1.0)
				portal_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				portal_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				card_vbox.add_child(portal_lbl)
				
			card.add_child(card_vbox)
			list_vbox.add_child(card)
			
		if displayed_count == 0:
			var no_res = Label.new()
			no_res.text = "沒有找到符合條件的地圖或怪物。"
			no_res.modulate = Color.GRAY
			list_vbox.add_child(no_res)
			
	render_map_cards.call("")
	search_input.text_changed.connect(func(new_text: String):
		render_map_cards.call(new_text.strip_edges())
	)
	
	scroll.add_child(list_vbox)
	main_vbox.add_child(scroll)
	map_select_modal.add_child(main_vbox)

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


# =========================================================================
# 🎴 ROGUELIKE 3-CHOICE SKILL DRAFT MODAL (EVERY 5 LEVELS)
# =========================================================================
func show_skill_draft_modal(cards: Array):
	if is_instance_valid(skill_draft_modal):
		skill_draft_modal.queue_free()
		
	skill_draft_modal = PanelContainer.new()
	skill_draft_modal.custom_minimum_size = Vector2(720, 420)
	skill_draft_modal.anchors_preset = Control.PRESET_CENTER
	skill_draft_modal.position = Vector2(100, 70)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.14, 0.96)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.GOLD
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	skill_draft_modal.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	skill_draft_modal.add_child(vbox)
	
	# Header
	var title_lbl = Label.new()
	title_lbl.text = "🎴 等級達成！請選擇你的覺醒天賦 / 技能卡牌 (3 選 1)"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.modulate = Color.GOLD
	vbox.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "【每 5 級自選強化】包含全新職業技能解鎖、奧義升級、流派被動與超凡全域增益！"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.modulate = Color(0.8, 0.9, 1.0)
	vbox.add_child(sub_lbl)
	
	# 3 Cards Container
	var card_row = HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 16)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(card_row)
	
	for c in cards:
		var card_panel = PanelContainer.new()
		card_panel.custom_minimum_size = Vector2(210, 270)
		
		var c_style = StyleBoxFlat.new()
		var rarity = c.get("rarity", "Epic")
		var b_color = Color.GOLD if rarity == "Legendary" else (Color(0.8, 0.4, 1.0) if rarity == "Epic" else Color(0.3, 0.7, 1.0))
		c_style.bg_color = Color(0.12, 0.14, 0.22, 0.95)
		c_style.border_width_left = 2
		c_style.border_width_right = 2
		c_style.border_width_top = 2
		c_style.border_width_bottom = 2
		c_style.border_color = b_color
		c_style.corner_radius_top_left = 8
		c_style.corner_radius_top_right = 8
		c_style.corner_radius_bottom_left = 8
		c_style.corner_radius_bottom_right = 8
		card_panel.add_theme_stylebox_override("panel", c_style)
		
		var c_vbox = VBoxContainer.new()
		c_vbox.add_theme_constant_override("separation", 8)
		card_panel.add_child(c_vbox)
		
		# Rarity Badge
		var badge = Label.new()
		badge.text = "★ %s 卡牌" % rarity
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 11)
		badge.modulate = b_color
		c_vbox.add_child(badge)
		
		# Icon
		var icon_lbl = Label.new()
		icon_lbl.text = c.get("icon", "⚔️")
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 36)
		c_vbox.add_child(icon_lbl)
		
		# Name
		var name_lbl = Label.new()
		name_lbl.text = c.get("name", "覺醒技能")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.modulate = Color.WHITE
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c_vbox.add_child(name_lbl)
		
		# Description
		var desc_lbl = Label.new()
		desc_lbl.text = c.get("desc", "")
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.85, 0.85, 0.85)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c_vbox.add_child(desc_lbl)
		
		# Select Button
		var sel_btn = Button.new()
		sel_btn.text = "✨ 覺醒選擇"
		sel_btn.custom_minimum_size = Vector2(0, 32)
		sel_btn.modulate = b_color
		var captured_card = c
		sel_btn.pressed.connect(func():
			Global.apply_draft_card(captured_card)
			if is_instance_valid(skill_draft_modal):
				skill_draft_modal.visible = false
				skill_draft_modal.queue_free()
		)
		c_vbox.add_child(sel_btn)
		
		card_row.add_child(card_panel)
		
	add_child(skill_draft_modal)

# =========================================================================
# ⌨️ CUSTOM KEYBINDINGS SETTINGS MODAL
# =========================================================================
func build_keybinding_modal():
	keybinding_modal = PanelContainer.new()
	keybinding_modal.name = "KeybindingModal"
	keybinding_modal.custom_minimum_size = Vector2(620, 520)
	keybinding_modal.set_anchors_preset(Control.PRESET_CENTER)
	keybinding_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	keybinding_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.96)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.3, 0.8, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	keybinding_modal.add_theme_stylebox_override("panel", style)
	keybinding_modal.visible = false
	add_child(keybinding_modal)

func show_keybinding_modal():
	if not is_instance_valid(keybinding_modal):
		build_keybinding_modal()
	toggle_modal(keybinding_modal)

func refresh_keybinding_modal():
	if not is_instance_valid(keybinding_modal):
		return
		
	for child in keybinding_modal.get_children():
		child.queue_free()
		
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	keybinding_modal.add_child(vbox)
	
	# Header Row
	var head_row = HBoxContainer.new()
	var title = Label.new()
	title.text = "⌨️ 自定義按鍵與技能配置 (Custom Keybindings)"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(0.3, 0.8, 1.0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "✕ 關閉"
	close_btn.pressed.connect(func(): keybinding_modal.visible = false)
	head_row.add_child(close_btn)
	vbox.add_child(head_row)
	
	var hint = Label.new()
	hint.text = "點擊任意按鍵按鈕後，按下鍵盤上的新按鍵即可完成自定義綁定！"
	hint.modulate = Color(0.7, 0.85, 1.0)
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)
	
	# Scroll area with actions
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var action_list = VBoxContainer.new()
	action_list.add_theme_constant_override("separation", 6)
	action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(action_list)
	vbox.add_child(scroll)
	
	var action_defs = [
		{"id": "attack", "name": "🗡️ 普通攻擊 (Basic Attack)", "desc": "揮砍/射箭/魔法彈/投標"},
		{"id": "jump", "name": "🚀 跳躍 / 二段跳 (Jump)", "desc": "跳躍與空中二段跳"},
		{"id": "skill_1", "name": "⚡ 技能 1", "desc": "職業一階核心主力技能"},
		{"id": "skill_2", "name": "💥 技能 2", "desc": "範圍攻擊 / 突進位移"},
		{"id": "skill_3", "name": "🌪️ 技能 3", "desc": "多段爆發 / 廣域轟炸"},
		{"id": "skill_4", "name": "🔥 技能 4", "desc": "高階職業覺醒技"},
		{"id": "skill_5", "name": "🌟 技能 5", "desc": "超大範圍召喚/神獸技"},
		{"id": "skill_6", "name": "👑 技能 6", "desc": "終極連殺/機關槍掃射"},
		{"id": "ultimate", "name": "🌌 全螢幕終極奧義", "desc": "全螢幕毀滅性絕殺"},
		{"id": "potion_hp", "name": "💊 快速喝生命藥水 (HP)", "desc": "秒喝紅水/白水/超級藥水"},
		{"id": "potion_mp", "name": "🧪 快速喝魔力藥水 (MP)", "desc": "秒喝藍水/超級藥水"},
		{"id": "tame_monster", "name": "🐾 捕捉附近怪物為寵物", "desc": "捕捉殘血怪物"},
		{"id": "summon_pet", "name": "🐕 召喚 / 召回寵物", "desc": "寵物出戰切換"}
	]
	
	for a in action_defs:
		var act_id = a.id
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_lbl = Label.new()
		name_lbl.text = a.name
		name_lbl.custom_minimum_size = Vector2(240, 26)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.modulate = Color.WHITE
		row.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = a.desc
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.6, 0.7, 0.8)
		row.add_child(desc_lbl)
		
		var key_btn = Button.new()
		var key_str = Global.get_action_key_name(act_id)
		key_btn.text = "【 %s 】" % (key_str if currently_rebinding_action != act_id else "請按鍵盤...")
		key_btn.custom_minimum_size = Vector2(130, 28)
		key_btn.modulate = Color.GOLD if currently_rebinding_action == act_id else Color(0.4, 0.9, 1.0)
		
		key_btn.pressed.connect(func():
			currently_rebinding_action = act_id
			refresh_keybinding_modal()
		)
		row.add_child(key_btn)
		
		action_list.add_child(row)
		
	# Footer row: Reset to defaults
	var foot = HBoxContainer.new()
	var reset_btn = Button.new()
	reset_btn.text = "🔄 恢復預設鍵位 (Reset to Defaults)"
	reset_btn.pressed.connect(func():
		Global.custom_keybindings = {
			"attack": KEY_Z, "jump": KEY_SPACE,
			"skill_1": KEY_X, "skill_2": KEY_C, "skill_3": KEY_V,
			"skill_4": KEY_B, "skill_5": KEY_N, "skill_6": KEY_M,
			"ultimate": KEY_F, "tame_monster": KEY_E, "summon_pet": KEY_R,
			"potion_hp": KEY_1, "potion_mp": KEY_2
		}
		Global.save_keybindings()
		refresh_keybinding_modal()
		Global.broadcast_message("按鍵已恢復為經典預設配置！", Color.GREEN)
	)
	foot.add_child(reset_btn)
	vbox.add_child(foot)

func _input(event: InputEvent):
	if currently_rebinding_action != "" and event is InputEventKey and event.pressed and not event.echo:
		var code_val = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		Global.rebind_key(currently_rebinding_action, code_val)
		Global.broadcast_message("成功將【%s】綁定至按鍵【%s】！" % [currently_rebinding_action, OS.get_keycode_string(code_val)], Color.GOLD)
		currently_rebinding_action = ""
		refresh_keybinding_modal()
		get_viewport().set_input_as_handled()
