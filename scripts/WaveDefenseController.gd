# WaveDefenseController.gd
extends Node2D

@export var goddess_node: Node2D
@export var outer_gate_spawn_point: Marker2D

var current_wave: int = 1
var is_spawning: bool = false
var is_wave_active: bool = false
var active_wave_monsters: int = 0
var auto_next_wave: bool = true

func _ready():
	Global.wave_changed.connect(_on_global_wave_changed)
	Global.broadcast_message("【準備階段】請先選擇職業或按 N 等待好友加入！按【F2】開始進攻防守！", Color(0.2, 0.9, 1.0))

func _process(_delta):
	# F2 to start wave manually
	if Input.is_key_pressed(KEY_F2) and not is_wave_active and not is_spawning and not Global.is_game_over:
		start_wave_from_host(current_wave)

func _on_global_wave_changed(wave_num: int, _max_wave: int):
	current_wave = wave_num

func start_wave_from_host(wave_num: int):
	if NetworkManager.is_multiplayer_active:
		if NetworkManager.is_host:
			rpc("sync_start_wave", wave_num)
		else:
			Global.broadcast_message("只有房主可以點擊開啟波次！", Color.ORANGE)
			return
	else:
		start_wave(wave_num)

@rpc("any_peer", "call_local", "reliable")
func sync_start_wave(wave_num: int):
	start_wave(wave_num)

func start_wave(wave_num: int):
	if Global.is_game_over:
		return
		
	current_wave = wave_num
	is_wave_active = true
	Global.current_wave = current_wave
	Global.emit_signal("wave_changed", current_wave, Global.MAX_WAVES)
	
	var is_boss_wave = (current_wave % 5 == 0)
	if is_boss_wave:
		Global.broadcast_message("⚠ 警告！第 %d 波 BOSS 級強敵正在由城外進攻！ ⚠" % current_wave, Color(1.0, 0.2, 0.2))
	else:
		Global.broadcast_message(">>> 第 %d / 50 波 怪物大軍由城外湧出！ <<<" % current_wave, Color(1.0, 0.7, 0.2))
		
	# If in multiplayer and NOT host, do not spawn local duplicate enemies! Host will sync them!
	if NetworkManager.is_multiplayer_active and not NetworkManager.is_host:
		return
		
	var wave_info = MonsterDatabaseFull.get_wave_data(current_wave)
	is_spawning = true
	
	# Rapid spawn through concentrated outer gate (每 0.3 秒一隻)
	for i in range(wave_info.count):
		if Global.is_game_over or not is_wave_active:
			break
		spawn_enemy(wave_info.monster_id, false)
		await get_tree().create_timer(0.3).timeout
	
	# If BOSS wave, spawn corresponding boss
	if wave_info.has("boss_id") and not Global.is_game_over and is_wave_active:
		await get_tree().create_timer(0.5).timeout
		spawn_enemy(wave_info.boss_id, true)
		
	is_spawning = false

func spawn_enemy(monster_id: int, is_boss: bool):
	var mob_data = MonsterDatabaseFull.get_monster(monster_id)
	if mob_data.is_empty():
		return
		
	var spawn_pos = Vector2(1450, 360) # Outer Gate Default
	if is_instance_valid(outer_gate_spawn_point):
		spawn_pos = outer_gate_spawn_point.global_position
		
	var offset = Vector2(randf_range(-30, 30), randf_range(-10, 10))
	var target_goddess_pos = Vector2.ZERO
	if is_instance_valid(goddess_node):
		target_goddess_pos = goddess_node.global_position
		
	var mob = NetworkManager.spawn_network_monster(monster_id, spawn_pos + offset, target_goddess_pos, is_boss)
	if is_instance_valid(mob):
		mob.add_to_group("wave_attackers")
		if is_boss:
			mob.add_to_group("bosses")
		mob.tree_exited.connect(_on_monster_defeated)
		active_wave_monsters += 1

func restart_defense_loop():
	# Clear previous wave attackers
	var mobs = get_tree().get_nodes_in_group("wave_attackers")
	for m in mobs:
		if is_instance_valid(m):
			m.queue_free()
			
	current_wave = 1
	active_wave_monsters = 0
	is_wave_active = false
	is_spawning = false
	start_wave_from_host(1)

func _on_monster_defeated():
	active_wave_monsters = max(0, active_wave_monsters - 1)
	if active_wave_monsters <= 0 and not is_spawning and not Global.is_game_over:
		is_wave_active = false
		if current_wave < Global.MAX_WAVES:
			Global.broadcast_message("✔ 第 %d 波防守成功！下一波將在 3 秒後自動抵達 (或按 F2 手動開啟)..." % current_wave, Color(0.3, 1.0, 0.4))
			if auto_next_wave:
				await get_tree().create_timer(3.5).timeout
				if not is_wave_active and not Global.is_game_over:
					start_wave_from_host(current_wave + 1)
		else:
			Global.broadcast_message("🎉 恭喜通關 50 波攻城！守護了楓之谷的和平！", Color.GOLD)
			Global.trigger_game_over(true)
