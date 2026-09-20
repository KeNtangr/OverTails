class_name PhaseManager
extends Node

const PlayerScript = preload("res://scripts/player.gd")
const WeaponDefinitionScript = preload("res://scripts/weapon_definition.gd")
const AttackCoordinatorScript = preload("res://scripts/attack_coordinator.gd")

enum Phase {
	PREPARATION,
	ATTACK,
	RESULTS,
	MATCH_OVER,
}

signal phase_changed(previous_phase: Phase, current_phase: Phase)
signal player_ready_changed(player_index: int, is_ready: bool)
signal round_changed(current_round: int)
signal results_started(
	completed_round: int,
	player_one_hp: int,
	player_one_max_hp: int,
	player_two_hp: int,
	player_two_max_hp: int
)

@export_range(0.1, 300.0, 0.1) var attack_duration_seconds: float = 15.0
@export_range(0.1, 30.0, 0.1) var results_duration_seconds: float = 3.0

@onready var attack_phase_timer: Timer = $AttackPhaseTimer
@onready var results_phase_timer: Timer = $ResultsPhaseTimer

var current_phase: Phase = Phase.PREPARATION
var current_round: int = 1
var _players: Array[PlayerScript] = []
var _player_ready: Array[bool] = [false, false]
var _attack_coordinator: AttackCoordinatorScript


func _ready() -> void:
	attack_phase_timer.timeout.connect(_on_attack_phase_timer_timeout)
	results_phase_timer.timeout.connect(_on_results_phase_timer_timeout)
	_stop_phase_timers()


func configure(
	player_one: PlayerScript,
	player_two: PlayerScript,
	attack_coordinator: AttackCoordinatorScript
) -> void:
	_players = [player_one, player_two]
	_attack_coordinator = attack_coordinator

	player_one.loadout_changed.connect(_on_player_loadout_changed.bind(0))
	player_two.loadout_changed.connect(_on_player_loadout_changed.bind(1))

	current_round = 1
	current_phase = Phase.PREPARATION
	_stop_phase_timers()
	_reset_player_readiness()
	_apply_phase_state()
	round_changed.emit(current_round)
	player_ready_changed.emit(0, false)
	player_ready_changed.emit(1, false)
	phase_changed.emit(current_phase, current_phase)


func toggle_player_ready(player_index: int) -> bool:
	if current_phase != Phase.PREPARATION or not _is_valid_player_index(player_index):
		return false

	if _player_ready[player_index]:
		_set_player_ready(player_index, false)
		return true

	if not _players[player_index].has_equipped_weapon():
		return false

	_set_player_ready(player_index, true)
	_try_start_attack_phase()
	return true


func is_player_ready(player_index: int) -> bool:
	if not _is_valid_player_index(player_index):
		return false
	return _player_ready[player_index]


func get_phase_label() -> String:
	match current_phase:
		Phase.PREPARATION:
			return "PREPARATION"
		Phase.ATTACK:
			return "ATTACK"
		Phase.RESULTS:
			return "RESULTS"
		Phase.MATCH_OVER:
			return "MATCH OVER"
	return "UNKNOWN"


func enter_match_over() -> void:
	if current_phase == Phase.MATCH_OVER:
		return

	_stop_phase_timers()
	_reset_player_readiness()
	_change_phase(Phase.MATCH_OVER)


func _on_player_loadout_changed(
	_slot_index: int,
	_weapon: WeaponDefinitionScript,
	player_index: int
) -> void:
	if current_phase == Phase.PREPARATION and is_player_ready(player_index):
		_set_player_ready(player_index, false)


func _set_player_ready(player_index: int, is_ready: bool) -> void:
	if _player_ready[player_index] == is_ready:
		return

	_player_ready[player_index] = is_ready
	player_ready_changed.emit(player_index, is_ready)


func _reset_player_readiness() -> void:
	for player_index: int in range(_player_ready.size()):
		_set_player_ready(player_index, false)


func _try_start_attack_phase() -> void:
	if not _player_ready[0] or not _player_ready[1]:
		return
	if not _players[0].has_equipped_weapon() or not _players[1].has_equipped_weapon():
		return

	_change_phase(Phase.ATTACK)
	attack_phase_timer.start(attack_duration_seconds)


func _on_attack_phase_timer_timeout() -> void:
	if current_phase != Phase.ATTACK:
		return

	_stop_attack_activity()
	_reset_player_readiness()
	_change_phase(Phase.RESULTS)
	results_started.emit(
		current_round,
		_players[0].current_hp,
		_players[0].max_hp,
		_players[1].current_hp,
		_players[1].max_hp
	)
	results_phase_timer.start(results_duration_seconds)


func _on_results_phase_timer_timeout() -> void:
	if current_phase != Phase.RESULTS:
		return

	current_round += 1
	round_changed.emit(current_round)
	_change_phase(Phase.PREPARATION)


func _change_phase(next_phase: Phase) -> void:
	if current_phase == next_phase:
		return

	var previous_phase := current_phase
	current_phase = next_phase
	_apply_phase_state()
	phase_changed.emit(previous_phase, current_phase)


func _apply_phase_state() -> void:
	var attack_active := current_phase == Phase.ATTACK
	for player: PlayerScript in _players:
		player.set_movement_enabled(attack_active)

	if _attack_coordinator == null:
		return
	if attack_active:
		_attack_coordinator.set_spawning_enabled(true)
	else:
		_attack_coordinator.stop_and_clear_attacks()


func _stop_attack_activity() -> void:
	attack_phase_timer.stop()
	for player: PlayerScript in _players:
		player.set_movement_enabled(false)
	if _attack_coordinator != null:
		_attack_coordinator.stop_and_clear_attacks()


func _stop_phase_timers() -> void:
	attack_phase_timer.stop()
	results_phase_timer.stop()


func _is_valid_player_index(player_index: int) -> bool:
	return player_index >= 0 and player_index < _players.size()
