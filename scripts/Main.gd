# Main.gd
extends Node2D

@onready var map_manager = $MapManager
@onready var wave_controller = $WaveDefenseController
@onready var goddess = $Goddess
@onready var player = $Player
@onready var outer_gate = $OuterGate

func _ready():
	RenderingServer.set_default_clear_color(Color(0.4, 0.7, 1.0))
	
	NetworkManager.player_connected.connect(_on_remote_player_connected)
	NetworkManager.player_disconnected.connect(_on_remote_player_disconnected)

func _on_remote_player_connected(peer_id: int, player_info: Dictionary):
	if peer_id == multiplayer.get_unique_id():
		return
		
	var existing = get_node_or_null("RemotePlayer_%d" % peer_id)
	if is_instance_valid(existing):
		existing.queue_free()
		
	var remote_scene = load("res://scenes/RemotePlayer.tscn")
	if remote_scene:
		var r_player = remote_scene.instantiate()
		r_player.name = "RemotePlayer_%d" % peer_id
		r_player.global_position = player.global_position + Vector2(randf_range(-40, 40), 0)
		r_player.setup_remote_player(peer_id, player_info)
		add_child.call_deferred(r_player)

func _on_remote_player_disconnected(peer_id: int):
	var remote_node = get_node_or_null("RemotePlayer_%d" % peer_id)
	if is_instance_valid(remote_node):
		remote_node.queue_free()
