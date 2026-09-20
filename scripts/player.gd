class_name Player
extends CharacterBody2D

const ArenaScript = preload("res://scripts/arena.gd")
const WeaponDefinitionScript = preload("res://scripts/weapon_definition.gd")

const LOADOUT_SIZE: int = 3

signal health_changed(current_hp: int, max_hp: int)
signal died
signal loadout_changed(slot_index: int, weapon: WeaponDefinitionScript)
signal money_changed(current_money: int)
signal inventory_changed

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
var _money: int = 0
var _owned_weapons: Array[WeaponDefinitionScript] = []

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


func reset_progression(starting_money: int, starting_weapon: WeaponDefinitionScript) -> void:
	_money = maxi(starting_money, 0)
	_owned_weapons.clear()
	for slot_index: int in range(LOADOUT_SIZE):
		_loadout[slot_index] = null

	if starting_weapon != null:
		_owned_weapons.append(starting_weapon)
		_loadout[0] = starting_weapon

	money_changed.emit(_money)
	inventory_changed.emit()
	for slot_index: int in range(LOADOUT_SIZE):
		loadout_changed.emit(slot_index, _loadout[slot_index])


func get_money() -> int:
	return _money


func grant_money(amount: int) -> bool:
	if amount <= 0:
		return false
	_money += amount
	money_changed.emit(_money)
	return true


func get_owned_weapons() -> Array[WeaponDefinitionScript]:
	return _owned_weapons.duplicate()


func get_owned_weapon_types() -> Array[WeaponDefinitionScript]:
	var unique_weapons: Array[WeaponDefinitionScript] = []
	for weapon: WeaponDefinitionScript in _owned_weapons:
		if not unique_weapons.has(weapon):
			unique_weapons.append(weapon)
	return unique_weapons


func get_owned_count(weapon: WeaponDefinitionScript) -> int:
	if weapon == null:
		return 0
	var count: int = 0
	for owned_weapon: WeaponDefinitionScript in _owned_weapons:
		if owned_weapon == weapon:
			count += 1
	return count


func get_equipped_count(weapon: WeaponDefinitionScript) -> int:
	if weapon == null:
		return 0
	var count: int = 0
	for equipped_weapon: WeaponDefinitionScript in _loadout:
		if equipped_weapon == weapon:
			count += 1
	return count


func get_available_count(weapon: WeaponDefinitionScript) -> int:
	return maxi(get_owned_count(weapon) - get_equipped_count(weapon), 0)


func add_owned_weapon(weapon: WeaponDefinitionScript) -> bool:
	if weapon == null:
		return false
	_owned_weapons.append(weapon)
	inventory_changed.emit()
	return true


func try_purchase_weapon(weapon: WeaponDefinitionScript) -> bool:
	if (
		weapon == null
		or weapon.weapon_id == &""
		or weapon.display_name.strip_edges().is_empty()
		or weapon.attack_scene == null
		or not weapon.purchasable
		or weapon.purchase_price < 0
		or _money < weapon.purchase_price
	):
		return false

	_money -= weapon.purchase_price
	_owned_weapons.append(weapon)
	money_changed.emit(_money)
	inventory_changed.emit()
	return true


func try_equip_weapon(slot_index: int, weapon: WeaponDefinitionScript) -> bool:
	if not _is_valid_loadout_slot(slot_index) or weapon == null:
		return false
	if _loadout[slot_index] == weapon:
		return true
	if get_available_count(weapon) <= 0:
		return false

	_set_loadout_slot(slot_index, weapon)
	return true


func try_unequip_slot(slot_index: int) -> bool:
	if not _is_valid_loadout_slot(slot_index):
		return false
	if _loadout[slot_index] == null:
		return true

	_set_loadout_slot(slot_index, null)
	return true


func try_swap_loadout_slots(first_slot: int, second_slot: int) -> bool:
	if not _is_valid_loadout_slot(first_slot) or not _is_valid_loadout_slot(second_slot):
		return false
	if first_slot == second_slot:
		return true

	var first_weapon := _loadout[first_slot]
	_loadout[first_slot] = _loadout[second_slot]
	_loadout[second_slot] = first_weapon
	loadout_changed.emit(first_slot, _loadout[first_slot])
	loadout_changed.emit(second_slot, _loadout[second_slot])
	return true


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


func _set_loadout_slot(slot_index: int, weapon: WeaponDefinitionScript) -> void:
	_loadout[slot_index] = weapon
	loadout_changed.emit(slot_index, weapon)


func take_damage(amount: int) -> void:
	if amount <= 0 or current_hp <= 0:
		return

	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)

	if current_hp == 0:
		died.emit()
