class_name GameManager
extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const PhaseManagerScript = preload("res://scripts/phase_manager.gd")
const DebugAttackSpawnerScript = preload("res://scripts/debug_attack_spawner.gd")

@export var player_one_path: NodePath
@export var player_two_path: NodePath
@export var phase_manager_path: NodePath
@export var debug_attack_spawner_path: NodePath

@onready var player_one: PlayerScript = get_node_or_null(player_one_path) as PlayerScript
@onready var player_two: PlayerScript = get_node_or_null(player_two_path) as PlayerScript
@onready var phase_manager: PhaseManagerScript = (
	get_node_or_null(phase_manager_path) as PhaseManagerScript
)
@onready var debug_attack_spawner: DebugAttackSpawnerScript = (
	get_node_or_null(debug_attack_spawner_path) as DebugAttackSpawnerScript
)


func _ready() -> void:
	if (
		player_one == null
		or player_two == null
		or phase_manager == null
		or debug_attack_spawner == null
	):
		push_error("GameManager requires both players, PhaseManager, and DebugAttackSpawner.")
		return

	phase_manager.configure(player_one, player_two, debug_attack_spawner)
