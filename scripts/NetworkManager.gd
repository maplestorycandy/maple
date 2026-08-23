# NetworkManager.gd
extends Node

signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_disconnected()
signal connection_succeeded()
signal connection_failed()
signal chat_message_received(sender_name: String, message: String, color: Color)

const DEFAULT_PORT: int = 8910
const MAX_PLAYERS: int = 8

var peer: MultiplayerPeer = null
var is_multiplayer_active: bool = false
var is_host: bool = false
var local_player_name: String = "勇者"

# Dict of peer_id -> player_info
var players: Dictionary = {}

# Dict of net_id (int) -> BaseMonster instance
var monsters: Dictionary = {}
var next_mob_net_id: int = 1000

var sync_timer: float = 0.0
const SYNC_INTERVAL: float = 0.05 # 20 Hz sync rate

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func is_web_client() -> bool:
	return OS.has_feature("web")

func host_game(port: int = DEFAULT_PORT, player_name: String = "房主勇者") -> Error:
	var ws_peer = WebSocketMultiplayerPeer.new()
	var err = ws_peer.create_server(port)
	if err == OK:
		peer = ws_peer
	else:
		var enet_peer = ENetMultiplayerPeer.new()
		err = enet_peer.create_server(port, MAX_PLAYERS)
		peer = enet_peer
		
	if err != OK:
		Global.broadcast_message("創建房間失敗: 錯誤碼 %d (Port %d)" % [err, port], Color.RED)
		return err
		
	multiplayer.multiplayer_peer = peer
	is_multiplayer_active = true
	is_host = true
	local_player_name = player_name
	
	players[1] = {
		"name": local_player_name,
		"job_id": Global.player_job_id,
		"level": Global.player_level,
		"hp": Global.player_hp,
		"max_hp": Global.player_max_hp
	}
	
	Global.broadcast_message("★ 多人伺服器已建立！(支援 Web / PC 跨端連線) ★", Color(0.2, 1.0, 0.4))
	return OK

func join_game(address: String = "127.0.0.1", port: int = DEFAULT_PORT, player_name: String = "冒險者") -> Error:
	var clean_addr = address.strip_edges()
	var target_url = clean_addr
	
	# If running on HTTPS Web and user didn't specify protocol, auto-select WSS/WS
	if not target_url.begins_with("ws://") and not target_url.begins_with("wss://"):
		if target_url.contains("trycloudflare.com") or target_url.contains("ngrok") or target_url.contains("onrender.com") or target_url.contains("glitch.me"):
			target_url = "wss://" + target_url
		elif target_url.contains(":"):
			target_url = "ws://" + target_url
		else:
			target_url = "ws://" + target_url + ":" + str(port)
			
	var ws_peer = WebSocketMultiplayerPeer.new()
	var err = ws_peer.create_client(target_url)
	
	if err != OK and not is_web_client():
		var enet_peer = ENetMultiplayerPeer.new()
		var host_ip = clean_addr.replace("ws://", "").replace("wss://", "").split(":")[0]
		err = enet_peer.create_client(host_ip, port)
		peer = enet_peer
	else:
		peer = ws_peer
		
	if err != OK:
		Global.broadcast_message("連線失敗: 錯誤碼 %d" % err, Color.RED)
		return err
		
	multiplayer.multiplayer_peer = peer
	is_multiplayer_active = true
	is_host = false
	local_player_name = player_name
	
	Global.broadcast_message("正在連線至: %s ..." % target_url, Color(0.4, 0.8, 1.0))
	return OK

func leave_game():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_multiplayer_active = false
	is_host = false
	players.clear()
	monsters.clear()
	Global.broadcast_message("已退出多人連線房間", Color.GRAY)

func _process(delta):
	# Only Host broadcasts batch monster states
	if is_multiplayer_active and is_host:
		sync_timer += delta
		if sync_timer >= SYNC_INTERVAL:
			sync_timer = 0.0
			broadcast_monsters_state()

func broadcast_monsters_state():
	if monsters.is_empty():
		return
	var batch: Array = []
	var to_clean: Array = []
	
	for net_id in monsters.keys():
		var mob = monsters[net_id]
		if not is_instance_valid(mob):
			to_clean.append(net_id)
			continue
		batch.append([
			net_id,
			mob.global_position.x,
			mob.global_position.y,
			mob.velocity.x,
			mob.velocity.y,
			mob.hp,
			mob.facing_direction
		])
		
	for c_id in to_clean:
		monsters.erase(c_id)
		
	if not batch.is_empty():
		rpc("sync_monsters_batch", batch)

@rpc("any_peer", "unreliable_ordered")
func sync_monsters_batch(batch: Array):
	if is_host and is_multiplayer_active:
		return # Host already has authoritative state
		
	for data in batch:
		var net_id = data[0]
		if monsters.has(net_id):
			var mob = monsters[net_id]
			if is_instance_valid(mob):
				mob.network_sync_position(
					Vector2(data[1], data[2]),
					Vector2(data[3], data[4]),
					data[5],
					data[6]
				)

# Spawning Synchronization
func spawn_network_monster(db_id: int, spawn_pos: Vector2, target_pos: Vector2 = Vector2.ZERO, is_boss: bool = false) -> Node2D:
	var mob_scene = load("res://scenes/monsters/BaseMonster.tscn")
	if not mob_scene:
		return null
		
	var mob = mob_scene.instantiate()
	var net_id = next_mob_net_id
	next_mob_net_id += 1
	mob.net_id = net_id
	
	var data = MonsterDatabaseFull.get_monster(db_id)
	mob.setup(data, target_pos)
	mob.global_position = spawn_pos
	
	monsters[net_id] = mob
	var scene = get_tree().current_scene
	scene.add_child.call_deferred(mob)
	
	if is_multiplayer_active and is_host:
		rpc("sync_spawn_mob", net_id, db_id, spawn_pos, target_pos, is_boss)
		
	return mob

@rpc("any_peer", "call_local", "reliable")
func sync_spawn_mob(net_id: int, db_id: int, spawn_pos: Vector2, target_pos: Vector2, is_boss: bool):
	if is_host and is_multiplayer_active:
		return # Host already spawned locally
		
	var mob_scene = load("res://scenes/monsters/BaseMonster.tscn")
	if not mob_scene:
		return
		
	var mob = mob_scene.instantiate()
	mob.net_id = net_id
	var data = MonsterDatabaseFull.get_monster(db_id)
	mob.setup(data, target_pos)
	mob.global_position = spawn_pos
	mob.is_boss = is_boss
	
	monsters[net_id] = mob
	var scene = get_tree().current_scene
	scene.add_child.call_deferred(mob)

# Damage Request & Synchronization
func request_damage_on_monster(net_id: int, amount: int, is_crit: bool = false, hit_idx: int = 0):
	if not is_multiplayer_active or is_host:
		# Directly apply locally
		if monsters.has(net_id):
			var mob = monsters[net_id]
			if is_instance_valid(mob):
				mob.take_damage_authoritative(amount, is_crit, hit_idx)
	else:
		# Client requests Host to apply damage
		rpc_id(1, "host_apply_damage", net_id, amount, is_crit, hit_idx, multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "reliable")
func host_apply_damage(net_id: int, amount: int, is_crit: bool, hit_idx: int, attacker_id: int):
	if not is_host and is_multiplayer_active:
		return
	if monsters.has(net_id):
		var mob = monsters[net_id]
		if is_instance_valid(mob):
			mob.take_damage_authoritative(amount, is_crit, hit_idx)

@rpc("any_peer", "call_local", "reliable")
func broadcast_mob_hit(net_id: int, amount: int, is_crit: bool, hit_idx: int, cur_hp: int):
	if monsters.has(net_id):
		var mob = monsters[net_id]
		if is_instance_valid(mob):
			mob.hp = cur_hp
			mob.hurt_flash = 1.0
			mob.spawn_damage_text(amount, is_crit, hit_idx)

@rpc("any_peer", "call_local", "reliable")
func broadcast_mob_death(net_id: int, exp_amt: int, meso_amt: int):
	if monsters.has(net_id):
		var mob = monsters[net_id]
		if is_instance_valid(mob):
			mob.die_synchronized(exp_amt, meso_amt)
		monsters.erase(net_id)

func _on_peer_connected(id: int):
	Global.broadcast_message("玩家 [ID: %d] 加入了冒險隊伍！" % id, Color(0.3, 1.0, 0.5))
	rpc_id(id, "register_player", multiplayer.get_unique_id(), {
		"name": local_player_name,
		"job_id": Global.player_job_id,
		"level": Global.player_level,
		"hp": Global.player_hp,
		"max_hp": Global.player_max_hp
	})
	
	# If Host, send snapshot of all active monsters to the newly joined peer!
	if is_host:
		var snapshot: Array = []
		for mob_net_id in monsters.keys():
			var mob = monsters[mob_net_id]
			if is_instance_valid(mob):
				snapshot.append({
					"net_id": mob_net_id,
					"db_id": mob.monster_id,
					"pos": mob.global_position,
					"target_pos": mob.target_position,
					"hp": mob.hp,
					"is_boss": mob.is_boss
				})
		if not snapshot.is_empty():
			rpc_id(id, "sync_snapshot_monsters", snapshot)

@rpc("any_peer", "reliable")
func sync_snapshot_monsters(snapshot: Array):
	for item in snapshot:
		var net_id = item.net_id
		if monsters.has(net_id) and is_instance_valid(monsters[net_id]):
			continue
		var mob_scene = load("res://scenes/monsters/BaseMonster.tscn")
		if mob_scene:
			var mob = mob_scene.instantiate()
			mob.net_id = net_id
			var data = MonsterDatabaseFull.get_monster(item.db_id)
			mob.setup(data, item.target_pos)
			mob.global_position = item.pos
			mob.hp = item.hp
			mob.is_boss = item.is_boss
			monsters[net_id] = mob
			get_tree().current_scene.add_child.call_deferred(mob)

func _on_peer_disconnected(id: int):
	var p_name = players.get(id, {}).get("name", "玩家 %d" % id)
	Global.broadcast_message("玩家 [%s] 離開了隊伍" % p_name, Color(1.0, 0.4, 0.4))
	players.erase(id)
	emit_signal("player_disconnected", id)

func _on_connected_to_server():
	Global.broadcast_message("✔ 成功連線進入房主世界！怪物與隊友已同步！", Color(0.2, 1.0, 0.4))
	emit_signal("connection_succeeded")
	rpc("register_player", multiplayer.get_unique_id(), {
		"name": local_player_name,
		"job_id": Global.player_job_id,
		"level": Global.player_level,
		"hp": Global.player_hp,
		"max_hp": Global.player_max_hp
	})

func _on_connection_failed():
	Global.broadcast_message("連線失敗！請檢查伺服器位址或網路狀態！", Color.RED)
	emit_signal("connection_failed")
	leave_game()

func _on_server_disconnected():
	Global.broadcast_message("與房主伺服器中斷連線！", Color.RED)
	emit_signal("server_disconnected")
	leave_game()

@rpc("any_peer", "call_local", "reliable")
func register_player(peer_id: int, info: Dictionary):
	players[peer_id] = info
	emit_signal("player_connected", peer_id, info)

@rpc("any_peer", "call_local", "reliable")
func broadcast_chat(sender_name: String, message: String, col_code: String = "yellow"):
	var col = Color.YELLOW
	match col_code:
		"cyan": col = Color(0.2, 0.9, 1.0)
		"green": col = Color(0.2, 1.0, 0.4)
		"gold": col = Color.GOLD
		"red": col = Color(1.0, 0.3, 0.3)
	emit_signal("chat_message_received", sender_name, message, col)
	Global.broadcast_message("[%s]: %s" % [sender_name, message], col)
