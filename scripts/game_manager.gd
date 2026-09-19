class_name GameManager
extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const PhaseManagerScript = preload("res://scripts/phase_manager.gd")
const AttackCoordinatorScript = preload("res://scripts/attack_coordinator.gd")

@export var player_one_path: NodePath
@export var player_two_path: NodePath
@export var phase_manager_path: NodePath
@export var attack_coordinator_path: NodePath

@onready var player_one: PlayerScript = get_node_or_null(player_one_path) as PlayerScript
@onready var player_two: PlayerScript = get_node_or_null(player_two_path) as PlayerScript
@onready var phase_manager: PhaseManagerScript = (
	get_node_or_null(phase_manager_path) as PhaseManagerScript
)
@onready var attack_coordinator: AttackCoordinatorScript = (
	get_node_or_null(attack_coordinator_path) as AttackCoordinatorScript
)


func _ready() -> void:
	if (
		player_one == null
		or player_two == null
		or phase_manager == null
		or attack_coordinator == null
	):
		push_error("GameManager requires both players, PhaseManager, and AttackCoordinator.")
		return

	phase_manager.configure(player_one, player_two, attack_coordinator)
