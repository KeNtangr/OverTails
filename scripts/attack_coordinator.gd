class_name AttackCoordinator
extends Node2D

const ArenaScript = preload("res://scripts/arena.gd")
const PlayerScript = preload("res://scripts/player.gd")
const WeaponDefinitionScript = preload("res://scripts/weapon_definition.gd")

@export var player_one_path: NodePath
@export var player_one_target_arena_path: NodePath
@export var player_two_path: NodePath
@export var player_two_target_arena_path: NodePath

@onready var player_one: PlayerScript = get_node_or_null(player_one_path) as PlayerScript
@onready var player_one_target_arena: ArenaScript = (
	get_node_or_null(player_one_target_arena_path) as ArenaScript
)
@onready var player_two: PlayerScript = get_node_or_null(player_two_path) as PlayerScript
@onready var player_two_target_arena: ArenaScript = (
	get_node_or_null(player_two_target_arena_path) as ArenaScript
)
@onready var spawn_timer: Timer = $AttackSpawnTimer

var _spawning_enabled: bool = false
var _player_one_loadout: Array[WeaponDefinitionScript] = []
var _player_two_loadout: Array[WeaponDefinitionScript] = []
var _player_one_sequence_index: int = 0
var _player_two_sequence_index: int = 0


func _ready() -> void:
	spawn_timer.timeout.connect(_spawn_next_attacks)
	spawn_timer.stop()

	if (
		player_one == null
		or player_one_target_arena == null
		or player_two == null
		or player_two_target_arena == null
	):
		push_error("AttackCoordinator requires both players and their explicit target arenas.")


func set_spawning_enabled(enabled: bool) -> void:
	if _spawning_enabled == enabled:
		return

	_spawning_enabled = enabled
	if enabled:
		if not _has_valid_dependencies():
			_spawning_enabled = false
			spawn_timer.stop()
			return

		_snapshot_loadouts()
		spawn_timer.start()
	else:
		spawn_timer.stop()


func is_spawning_enabled() -> bool:
	return _spawning_enabled


func _snapshot_loadouts() -> void:
	_player_one_loadout = _get_equipped_weapons(player_one)
	_player_two_loadout = _get_equipped_weapons(player_two)
	_player_one_sequence_index = 0
	_player_two_sequence_index = 0


func _get_equipped_weapons(player: PlayerScript) -> Array[WeaponDefinitionScript]:
	var equipped_weapons: Array[WeaponDefinitionScript] = []
	for weapon: WeaponDefinitionScript in player.get_loadout():
		if weapon != null:
			equipped_weapons.append(weapon)
	return equipped_weapons


func _spawn_next_attacks() -> void:
	if not _spawning_enabled:
		return

	_player_one_sequence_index = _spawn_next_weapon(
		_player_one_loadout,
		_player_one_sequence_index,
		player_one_target_arena
	)
	_player_two_sequence_index = _spawn_next_weapon(
		_player_two_loadout,
		_player_two_sequence_index,
		player_two_target_arena
	)


func _spawn_next_weapon(
	loadout: Array[WeaponDefinitionScript],
	sequence_index: int,
	target_arena: ArenaScript
) -> int:
	if loadout.is_empty():
		return 0

	var weapon: WeaponDefinitionScript = loadout[sequence_index]
	target_arena.spawn_weapon_attack(weapon)
	return (sequence_index + 1) % loadout.size()


func _has_valid_dependencies() -> bool:
	return (
		player_one != null
		and player_one_target_arena != null
		and player_two != null
		and player_two_target_arena != null
	)
