class_name GameManager
extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const PhaseManagerScript = preload("res://scripts/phase_manager.gd")
const AttackCoordinatorScript = preload("res://scripts/attack_coordinator.gd")
const EconomyManagerScript = preload("res://scripts/economy_manager.gd")

enum MatchResult {
	PLAYER_ONE_WINS,
	PLAYER_TWO_WINS,
	DRAW,
}

signal match_finished(result: MatchResult)

@export var player_one_path: NodePath
@export var player_two_path: NodePath
@export var phase_manager_path: NodePath
@export var attack_coordinator_path: NodePath
@export var economy_manager_path: NodePath

@onready var player_one: PlayerScript = get_node_or_null(player_one_path) as PlayerScript
@onready var player_two: PlayerScript = get_node_or_null(player_two_path) as PlayerScript
@onready var phase_manager: PhaseManagerScript = (
	get_node_or_null(phase_manager_path) as PhaseManagerScript
)
@onready var attack_coordinator: AttackCoordinatorScript = (
	get_node_or_null(attack_coordinator_path) as AttackCoordinatorScript
)
@onready var economy_manager: EconomyManagerScript = (
	get_node_or_null(economy_manager_path) as EconomyManagerScript
)

var _match_finished: bool = false
var _death_resolution_pending: bool = false
var _restart_requested: bool = false


func _ready() -> void:
	if (
		player_one == null
		or player_two == null
		or phase_manager == null
		or attack_coordinator == null
		or economy_manager == null
	):
		push_error(
			"GameManager requires both players, PhaseManager, AttackCoordinator, and EconomyManager."
		)
		return

	player_one.died.connect(_on_player_died)
	player_two.died.connect(_on_player_died)
	economy_manager.configure(player_one, player_two, phase_manager)
	phase_manager.configure(player_one, player_two, attack_coordinator)


func is_match_finished() -> bool:
	return _match_finished


func restart_match() -> void:
	if (
		not _match_finished
		or phase_manager.current_phase != PhaseManagerScript.Phase.MATCH_OVER
		or _restart_requested
	):
		return

	_restart_requested = true
	get_tree().reload_current_scene()


func _on_player_died() -> void:
	if _match_finished or _death_resolution_pending:
		return

	_death_resolution_pending = true
	_resolve_deaths.call_deferred()


func _resolve_deaths() -> void:
	_death_resolution_pending = false
	if _match_finished:
		return

	var player_one_dead := player_one.current_hp <= 0
	var player_two_dead := player_two.current_hp <= 0
	if not player_one_dead and not player_two_dead:
		return

	var result: MatchResult
	if player_one_dead and player_two_dead:
		result = MatchResult.DRAW
	elif player_one_dead:
		result = MatchResult.PLAYER_TWO_WINS
	else:
		result = MatchResult.PLAYER_ONE_WINS

	_match_finished = true
	phase_manager.enter_match_over()
	match_finished.emit(result)
