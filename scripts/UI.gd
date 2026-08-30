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

# Pause & Ready UI
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

func _on_chat_gui_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if chat_input:
				chat_input.text = ""
				chat_input.release_focus()
				get_viewport().set_input_as_handled()

func _on_chat_text_submitted(_new_text: String):
	_on_chat_send_pressed()

func _unhandled_input(event: InputEvent):
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
		
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner is LineEdit or focus_owner is TextEdit:
		if event.keycode == KEY_ENTER:
			_on_chat_send_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			focus_owner.release_focus()
			get_viewport().set_input_as_handled()
		return
		
	if event.keycode == KEY_ESCAPE:
		if has_any_modal_open():
			close_all_modals()
		else:
			toggle_pause()
		return
		
	if event.keycode == KEY_F1:
		toggle_pause()
		return
		
	if event.keycode == KEY_N:
		toggle_modal(network_modal)
		return
		
	if event.keycode == KEY_J:
		toggle_modal(job_select_modal)
		return
		
	if event.keycode == KEY_M:
		toggle_modal(map_select_modal)
		return
		
	if event.keycode == KEY_P:
		toggle_modal(pet_bag_modal)
		return
		
	if event.keycode == KEY_ENTER:
		if chat_input:
			chat_input.grab_focus()

func has_any_modal_open() -> bool:
	return (network_modal and network_modal.visible) or \
		   (job_select_modal and job_select_modal.visible) or \
		   (pet_bag_modal and pet_bag_modal.visible) or \
		   (map_select_modal and map_select_modal.visible) or \
		   (pause_modal and pause_modal.visible)

func close_all_modals():
	if network_modal: network_modal.visible = false
	if job_select_modal: job_select_modal.visible = false
	if pet_bag_modal: pet_bag_modal.visible = false
	if map_select_modal: map_select_modal.visible = false
	if pause_modal and get_tree().paused:
		resume_game()

func toggle_modal(modal: Control):
	if not modal:
		return
	var target_vis = not modal.visible
	close_all_modals()
	modal.visible = target_vis

func toggle_pause():
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	close_all_modals()
	get_tree().paused = true
	if pause_modal:
		pause_modal.visible = true
	Global.broadcast_message("⏸ 遊戲已暫停", Color.YELLOW)

func resume_game():
	get_tree().paused = false
	if pause_modal:
		pause_modal.visible = false
	Global.broadcast_message("▶ 遊戲繼續！", Color.GREEN)

func update_player_hp(cur: int, max_val: int):
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = cur
		hp_bar.get_node("Label").text = "HP: %d / %d" % [cur, max_val]

func update_player_mp(cur: int, max_val: int):
	if mp_bar:
		mp_bar.max_value = max_val
		mp_bar.value = cur
		mp_bar.get_node("Label").text = "MP: %d / %d" % [cur, max_val]

func update_player_exp(cur: int, max_val: int, lvl: int):
	if exp_bar:
		exp_bar.max_value = max_val
		exp_bar.value = cur
		var pct = float(cur) / float(max_val) * 100.0
		exp_bar.get_node("Label").text = "EXP: %d / %d (%.1f%%)" % [cur, max_val, pct]
	if level_label:
		level_label.text = "Lv. %d 【%s】" % [lvl, Global.player_job_data.get("name", "勇者")]

func update_player_job_display(job_data: Dictionary):
	if level_label:
		level_label.text = "Lv. %d 【%s】" % [Global.player_level, job_data.get("name", "勇者")]
		level_label.modulate = job_data.get("color", Color.WHITE)

func open_job_selection():
	toggle_modal(job_select_modal)

func setup_job_selection_list():
	if not job_card_container:
		return
	for child in job_card_container.get_children():
		child.queue_free()
		
	for j_id in ["warrior", "magician", "bowman", "thief", "pirate"]:
		var j_data = JobDatabase.get_job(j_id)
		var card = Button.new()
		card.custom_minimum_size = Vector2(230, 360)
		var is_cur = (Global.player_job_id == j_id)
		var mark = "【當前職業】\n" if is_cur else "[點擊轉職]\n"
		
		var skill_texts = ""
		for sk_key in ["skill_1", "skill_2", "skill_3"]:
			var sk = j_data.skills[sk_key]
			skill_texts += "• %s\n" % sk.name
			
		card.text = "%s\n★ %s ★\n%s\n\n主屬性: %s\nHP:%d  MP:%d\n\n【核心技能】\n%s\n%s" % [
			mark,
			j_data.name,
			j_data.title,
			j_data.primary_stat,
			j_data.base_stats.hp,
			j_data.base_stats.mp,
			skill_texts,
			j_data.desc
		]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.modulate = j_data.color.lightened(0.2)
		var sel_id = j_id
		card.pressed.connect(func():
			Global.set_player_job(sel_id)
			job_select_modal.visible = false
			setup_job_selection_list()
		)
		job_card_container.add_child(card)

func update_goddess_hp(cur: int, max_val: int):
	if goddess_hp_bar:
		goddess_hp_bar.max_value = max_val
		goddess_hp_bar.value = cur
		var pct = float(cur) / float(max_val) * 100.0
		goddess_hp_bar.get_node("Label").text = "女神神聖結界: %d / %d (%.1f%%)" % [cur, max_val, pct]

func update_wave(cur_wave: int, max_wave: int):
	if wave_label:
		wave_label.text = "第 %d / %d 波 攻城進攻" % [cur_wave, max_wave]
	if start_wave_btn:
		var wave_ctrl = get_tree().current_scene.get_node_or_null("WaveDefenseController")
		if is_instance_valid(wave_ctrl) and not wave_ctrl.is_wave_active:
			start_wave_btn.visible = true
			start_wave_btn.text = "⚔ 點擊開始防守第 %d 波 (按 F2)" % cur_wave
		else:
			start_wave_btn.visible = false

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
		card.custom_minimum_size = Vector2(240, 300)
		card.text = "\n\n★ %s ★\n\n%s\n\n[點擊選取]" % [buff.name, buff.desc]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.pressed.connect(func():
			select_buff(buff)
		)
		buff_container.add_child(card)

func select_buff(buff: Dictionary):
	var player = get_tree().get_first_node_in_group("player")
	LevelBuffManager.apply_selected_buff(buff, player)
	buff_modal.visible = false
	get_tree().paused = false

# Pet Bag Modal with Switch & Delete/Release Functions
func refresh_pet_bag():
	if not pet_list_container:
		return
	for child in pet_list_container.get_children():
		child.queue_free()
		
	if Global.pet_inventory.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "【背包目前沒有捕獲的寵物夥伴】\n靠近野怪按 E 鍵丟出封印網捕捉！"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pet_list_container.add_child(empty_lbl)
		return
		
	for i in range(Global.pet_inventory.size()):
		var pet = Global.pet_inventory[i]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		
		var is_active = (Global.active_pet_data.get("name", "") == pet.name)
		var status_str = "【出戰中】" if is_active else "[休息中]"
		
		# Info Box
		var info_lbl = Label.new()
		info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_lbl.text = "%s %s (Lv.%d) | HP:%d 攻:%d 速:%d" % [
			status_str, pet.name, pet.get("level", 1), pet.hp, pet.atk, pet.speed
		]
		if is_active:
			info_lbl.modulate = Color.GREEN
		row.add_child(info_lbl)
		
		# Action Button (Summon / Dismiss)
		var act_btn = Button.new()
		act_btn.custom_minimum_size = Vector2(100, 36)
		act_btn.text = "召回休息" if is_active else "召喚出戰"
		if is_active:
			act_btn.modulate = Color(1.0, 0.8, 0.3)
		else:
			act_btn.modulate = Color(0.3, 1.0, 0.5)
		var idx = i
		act_btn.pressed.connect(func():
			if is_active:
				Global.dismiss_active_pet()
			else:
				Global.select_active_pet(idx)
			refresh_pet_bag()
		)
		row.add_child(act_btn)
		
		# Delete / Release Button
		var del_btn = Button.new()
		del_btn.custom_minimum_size = Vector2(90, 36)
		del_btn.text = "🗑 放生"
		del_btn.modulate = Color(1.0, 0.4, 0.4)
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
		
	# Automatic countdown to restart defense (5 seconds)
	if restart_timer_tween and restart_timer_tween.is_valid():
		restart_timer_tween.kill()
		
	restart_timer_tween = create_tween()
	for sec in range(5, 0, -1):
		if restart_btn:
			restart_btn.text = "🔄 重新守護女神 (%d 秒後自動開始)" % sec
		restart_timer_tween.tween_interval(1.0)
		
	restart_timer_tween.tween_callback(func():
		if game_over_modal.visible:
			_on_restart_pressed()
	)

func _on_host_room_pressed():
	var name_txt = host_name_input.text.strip_edges() if host_name_input else "房主勇者"
	if name_txt == "": name_txt = "房主勇者"
	var port = int(host_port_input.text) if host_port_input and host_port_input.text.is_valid_int() else 8910
	NetworkManager.host_game(port, name_txt)
	update_network_ui()

func _on_join_room_pressed():
	var name_txt = join_name_input.text.strip_edges() if join_name_input else "冒險者"
	if name_txt == "": name_txt = "冒險者"
	var ip = join_ip_input.text.strip_edges() if join_ip_input and join_ip_input.text != "" else "127.0.0.1"
	var port = int(join_port_input.text) if join_port_input and join_port_input.text.is_valid_int() else 8910
	NetworkManager.join_game(ip, port, name_txt)
	update_network_ui()

func _on_leave_room_pressed():
	NetworkManager.leave_game()
	update_network_ui()

func _on_net_player_update(_peer_id = 0, _info = {}):
	update_network_ui()

func update_network_ui():
	if not net_status_label:
		return
	if NetworkManager.is_multiplayer_active:
		if NetworkManager.is_host:
			net_status_label.text = "連線狀態: [房主模式 - 伺服器運行中 Port: 8910]"
			net_status_label.modulate = Color.GREEN
		else:
			net_status_label.text = "連線狀態: [隊員模式 - 已連線至房主]"
			net_status_label.modulate = Color.CYAN
	else:
		net_status_label.text = "連線狀態: [單機離線模式]"
		net_status_label.modulate = Color.GRAY
		
	if party_list_label:
		var txt = "【當前房間在線隊員 (%d 人)】\n" % max(1, NetworkManager.players.size())
		if NetworkManager.is_multiplayer_active:
			for pid in NetworkManager.players.keys():
				var p = NetworkManager.players[pid]
				var host_mark = " (房主)" if pid == 1 else ""
				txt += "• [%s] Lv.%d %s%s\n" % [p.get("job_id", "warrior"), p.get("level", 1), p.get("name", "勇者"), host_mark]
		else:
			txt += "• [單人] Lv.%d %s (您)\n" % [Global.player_level, Global.player_job_data.name]
		party_list_label.text = txt

func _on_chat_send_pressed():
	if not chat_input:
		return
	var msg = chat_input.text.strip_edges()
	chat_input.text = ""
	chat_input.release_focus()
	
	if msg == "":
		return
	
	if NetworkManager.is_multiplayer_active:
		NetworkManager.rpc("broadcast_chat", NetworkManager.local_player_name, msg, "cyan")
	else:
		Global.broadcast_message("[您]: %s" % msg, Color(0.3, 0.9, 1.0))
		_on_chat_received("您", msg, Color(0.3, 0.9, 1.0))

func _on_chat_received(sender: String, msg: String, col: Color):
	if chat_log:
		chat_log.append_text("[color=#%s]★ [%s]: %s[/color]\n" % [col.to_html(false), sender, msg])

func _on_restart_pressed():
	if restart_timer_tween and restart_timer_tween.is_valid():
		restart_timer_tween.kill()
		
	get_tree().paused = false
	if game_over_modal:
		game_over_modal.visible = false
	if pause_modal:
		pause_modal.visible = false
		
	Global.reset_game_state()
	
	var wave_ctrl = get_tree().current_scene.get_node_or_null("WaveDefenseController")
	if is_instance_valid(wave_ctrl):
		wave_ctrl.restart_defense_loop()
