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
@onready var chat_input: LineEdit = $HUD/ChatContainer/ChatInput
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
	
	setup_job_selection_list()
	setup_map_selection_list()
	refresh_pet_bag()
	update_network_ui()

func _process(_delta):
	if meso_label:
		meso_label.text = "楓幣: %d" % Global.meso_gold
	if map_name_label and MapDatabase.MAPS.has(Global.current_map_id):
		map_name_label.text = MapDatabase.MAPS[Global.current_map_id].name

func _unhandled_input(event: InputEvent):
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
		
	# If typing inside a text input field, don't trigger game hotkeys
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner is LineEdit or focus_owner is TextEdit:
		if event.keycode == KEY_ENTER:
			_on_chat_send_pressed()
		return
		
	# ESC Key Priority: Close open modals first, otherwise toggle pause
	if event.keycode == KEY_ESCAPE:
		if has_any_modal_open():
			close_all_modals()
		else:
			toggle_pause()
		return
		
	# F1 Key: Pause Toggle
	if event.keycode == KEY_F1:
		toggle_pause()
		return
		
	# N Key: Toggle Multiplayer Network Modal
	if event.keycode == KEY_N:
		toggle_modal(network_modal)
		return
		
	# J Key: Toggle Job Selection Modal
	if event.keycode == KEY_J:
		toggle_modal(job_select_modal)
		return
		
	# M Key: Toggle Map Fast Travel Modal
	if event.keycode == KEY_M:
		toggle_modal(map_select_modal)
		return
		
	# P Key: Toggle Pet Inventory Modal
	if event.keycode == KEY_P:
		toggle_modal(pet_bag_modal)
		return
		
	# Enter Key: Focus Chat
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

# Pet Bag Modal
func refresh_pet_bag():
	if not pet_list_container:
		return
	for child in pet_list_container.get_children():
		child.queue_free()
		
	for i in range(Global.pet_inventory.size()):
		var pet = Global.pet_inventory[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(400, 45)
		var is_active = (Global.active_pet_data.get("name", "") == pet.name)
		var status_str = "[已出戰]" if is_active else "[點擊召喚出戰]"
		btn.text = "【%s】種族: %s | HP: %d | 攻擊: %d | 速度: %d  %s" % [pet.name, pet.type, pet.hp, pet.atk, pet.speed, status_str]
		var idx = i
		btn.pressed.connect(func():
			if is_active:
				Global.dismiss_active_pet()
			else:
				Global.select_active_pet(idx)
			refresh_pet_bag()
		)
		pet_list_container.add_child(btn)

# Map Selection Fast Travel
func setup_map_selection_list():
	if not map_list_container:
		return
	for child in map_list_container.get_children():
		child.queue_free()
		
	for map_info in MapDatabase.get_map_list():
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(260, 80)
		btn.text = "%s\n%s" % [map_info.name, map_info.description]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var mid = map_info.id
		btn.pressed.connect(func():
			Global.change_map(mid)
			map_select_modal.visible = false
		)
		map_list_container.add_child(btn)

func show_game_over(victory: bool):
	game_over_modal.visible = true
	if victory:
		game_over_title.text = "★ 恭喜通關 50 波攻城大獲全勝！★\n守護了女神與整個楓之谷世界！"
		game_over_title.modulate = Color.GOLD
	else:
		game_over_title.text = "☠ 守護失敗！女神結界已破碎 ☠\n再接再厲，拯救楓之谷！"
		game_over_title.modulate = Color.RED

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
	if not chat_input or chat_input.text.strip_edges() == "":
		if chat_input: chat_input.release_focus()
		return
		
	var msg = chat_input.text.strip_edges()
	chat_input.text = ""
	chat_input.release_focus()
	
	if NetworkManager.is_multiplayer_active:
		NetworkManager.rpc("broadcast_chat", NetworkManager.local_player_name, msg, "cyan")
	else:
		Global.broadcast_message("[您]: %s" % msg, Color(0.3, 0.9, 1.0))
		_on_chat_received("您", msg, Color(0.3, 0.9, 1.0))

func _on_chat_received(sender: String, msg: String, col: Color):
	if chat_log:
		chat_log.append_text("[color=#%s]★ [%s]: %s[/color]\n" % [col.to_html(false), sender, msg])

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
