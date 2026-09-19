class_name PhaseManager
extends Node

const PlayerScript = preload("res://scripts/player.gd")
const WeaponDefinitionScript = preload("res://scripts/weapon_definition.gd")
const AttackCoordinatorScript = preload("res://scripts/attack_coordinator.gd")

enum Phase {
	PREPARATION,
	ATTACK,
}

signal phase_changed(previous_phase: Phase, current_phase: Phase)
signal player_ready_changed(player_index: int, is_ready: bool)

var current_phase: Phase = Phase.PREPARATION
var _players: Array[PlayerScript] = []
var _player_ready: Array[bool] = [false, false]
var _attack_coordinator: AttackCoordinatorScript


func configure(
	player_one: PlayerScript,
	player_two: PlayerScript,
	attack_coordinator: AttackCoordinatorScript
) -> void:
	_players = [player_one, player_two]
	_attack_coordinator = attack_coordinator

	player_one.loadout_changed.connect(_on_player_loadout_changed.bind(0))
	player_two.loadout_changed.connect(_on_player_loadout_changed.bind(1))

	_apply_phase_state()
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
	if current_phase == Phase.PREPARATION:
		return "PREPARATION"
	return "ATTACK"


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


func _try_start_attack_phase() -> void:
	if not _player_ready[0] or not _player_ready[1]:
		return
	if not _players[0].has_equipped_weapon() or not _players[1].has_equipped_weapon():
		return

	_change_phase(Phase.ATTACK)


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

	if _attack_coordinator != null:
		_attack_coordinator.set_spawning_enabled(attack_active)


func _is_valid_player_index(player_index: int) -> bool:
	return player_index >= 0 and player_index < _players.size()
