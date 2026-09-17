class_name Player
extends CharacterBody2D

const ArenaScript = preload("res://scripts/arena.gd")
const WeaponDefinitionScript = preload("res://scripts/weapon_definition.gd")

const LOADOUT_SIZE: int = 3

signal health_changed(current_hp: int, max_hp: int)
signal died
signal loadout_changed(slot_index: int, weapon: WeaponDefinitionScript)

@export_range(1.0, 1000.0, 1.0) var move_speed: float = 360.0
@export_range(1.0, 64.0, 1.0) var body_radius: float = 16.0
@export_range(1, 1000, 1) var max_hp: int = 150
@export var input_left: StringName = &"move_left"
@export var input_right: StringName = &"move_right"
@export var input_up: StringName = &"move_up"
@export var input_down: StringName = &"move_down"

var current_hp: int
var _movement_enabled: bool = true
var _loadout: Array[WeaponDefinitionScript] = []

@onready var arena: ArenaScript = get_parent() as ArenaScript


func _init() -> void:
	for slot_index: int in range(LOADOUT_SIZE):
		_loadout.append(null)


func _ready() -> void:
	current_hp = max_hp

	if arena == null:
		push_error("Player must be a direct child of an Arena.")
		set_physics_process(false)
		return

	position = arena.clamp_position_to_bounds(position, body_radius)


func _physics_process(delta: float) -> void:
	if not _movement_enabled:
		velocity = Vector2.ZERO
		return

	var input_direction := Input.get_vector(
		input_left,
		input_right,
		input_up,
		input_down
	)

	velocity = input_direction * move_speed
	position += velocity * delta
	position = arena.clamp_position_to_bounds(position, body_radius)


func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func is_movement_enabled() -> bool:
	return _movement_enabled


func set_loadout_slot(slot_index: int, weapon: WeaponDefinitionScript) -> bool:
	if not _is_valid_loadout_slot(slot_index):
		return false
	if _loadout[slot_index] == weapon:
		return true

	_loadout[slot_index] = weapon
	loadout_changed.emit(slot_index, weapon)
	return true


func clear_loadout_slot(slot_index: int) -> bool:
	return set_loadout_slot(slot_index, null)


func get_loadout_slot(slot_index: int) -> WeaponDefinitionScript:
	if not _is_valid_loadout_slot(slot_index):
		return null
	return _loadout[slot_index]


func get_loadout() -> Array[WeaponDefinitionScript]:
	return _loadout.duplicate()


func has_equipped_weapon() -> bool:
	for weapon: WeaponDefinitionScript in _loadout:
		if weapon != null:
			return true
	return false


func _is_valid_loadout_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < LOADOUT_SIZE


func take_damage(amount: int) -> void:
	if amount <= 0 or current_hp <= 0:
		return

	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)

	if current_hp == 0:
		died.emit()
