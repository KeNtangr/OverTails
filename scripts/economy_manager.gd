class_name EconomyManager
extends Node

const PlayerScript = preload("res://scripts/player.gd")
const PhaseManagerScript = preload("res://scripts/phase_manager.gd")
const WeaponDefinitionScript = preload("res://scripts/weapon_definition.gd")

enum OperationResult {
	SUCCESS,
	NOT_EDITABLE,
	INVALID_WEAPON,
	NOT_PURCHASABLE,
	NOT_ENOUGH_MONEY,
	NO_AVAILABLE_COPY,
	INVALID_SLOT,
}

signal match_economy_initialized
signal round_income_granted(round_number: int, amount: int)

@export_range(0, 10000, 1) var starting_money: int = 120
@export var starting_weapon: WeaponDefinitionScript
@export var round_income_by_round: PackedInt32Array = PackedInt32Array([
	0,
	130,
	140,
	160,
	120,
	80,
	40,
])

var _players: Array[PlayerScript] = []
var _phase_manager: PhaseManagerScript
var _configured: bool = false
var _last_awarded_round: int = 0


func configure(
	player_one: PlayerScript,
	player_two: PlayerScript,
	phase_manager: PhaseManagerScript
) -> void:
	if _configured:
		return

	_players = [player_one, player_two]
	_phase_manager = phase_manager
	_configured = true
	_last_awarded_round = 1

	phase_manager.phase_changed.connect(_on_phase_changed)
	for player: PlayerScript in _players:
		player.reset_progression(starting_money, starting_weapon)
	match_economy_initialized.emit()


func try_purchase_weapon(player_index: int, weapon: WeaponDefinitionScript) -> int:
	var edit_result := _validate_edit_request(player_index)
	if edit_result != OperationResult.SUCCESS:
		return edit_result
	if (
		weapon == null
		or weapon.weapon_id == &""
		or weapon.display_name.strip_edges().is_empty()
		or weapon.attack_scene == null
	):
		return OperationResult.INVALID_WEAPON
	if not weapon.purchasable or weapon.purchase_price < 0:
		return OperationResult.NOT_PURCHASABLE

	var player := _players[player_index]
	if player.get_money() < weapon.purchase_price:
		return OperationResult.NOT_ENOUGH_MONEY
	if not player.try_purchase_weapon(weapon):
		return OperationResult.INVALID_WEAPON
	return OperationResult.SUCCESS


func try_equip_weapon(
	player_index: int,
	slot_index: int,
	weapon: WeaponDefinitionScript
) -> int:
	var edit_result := _validate_edit_request(player_index)
	if edit_result != OperationResult.SUCCESS:
		return edit_result
	if slot_index < 0 or slot_index >= PlayerScript.LOADOUT_SIZE:
		return OperationResult.INVALID_SLOT
	if weapon == null:
		return OperationResult.INVALID_WEAPON
	if (
		_players[player_index].get_loadout_slot(slot_index) != weapon
		and _players[player_index].get_available_count(weapon) <= 0
	):
		return OperationResult.NO_AVAILABLE_COPY
	if not _players[player_index].try_equip_weapon(slot_index, weapon):
		return OperationResult.NO_AVAILABLE_COPY
	return OperationResult.SUCCESS


func try_unequip_slot(player_index: int, slot_index: int) -> int:
	var edit_result := _validate_edit_request(player_index)
	if edit_result != OperationResult.SUCCESS:
		return edit_result
	if slot_index < 0 or slot_index >= PlayerScript.LOADOUT_SIZE:
		return OperationResult.INVALID_SLOT
	_players[player_index].try_unequip_slot(slot_index)
	return OperationResult.SUCCESS


func try_swap_slots(player_index: int, first_slot: int, second_slot: int) -> int:
	var edit_result := _validate_edit_request(player_index)
	if edit_result != OperationResult.SUCCESS:
		return edit_result
	if (
		first_slot < 0
		or first_slot >= PlayerScript.LOADOUT_SIZE
		or second_slot < 0
		or second_slot >= PlayerScript.LOADOUT_SIZE
	):
		return OperationResult.INVALID_SLOT
	_players[player_index].try_swap_loadout_slots(first_slot, second_slot)
	return OperationResult.SUCCESS


func get_result_message(result: int) -> String:
	match result:
		OperationResult.SUCCESS:
			return ""
		OperationResult.NOT_EDITABLE:
			return "Cancel Ready before editing"
		OperationResult.INVALID_WEAPON:
			return "Invalid weapon"
		OperationResult.NOT_PURCHASABLE:
			return "Weapon is not purchasable"
		OperationResult.NOT_ENOUGH_MONEY:
			return "Not enough money"
		OperationResult.NO_AVAILABLE_COPY:
			return "No unequipped copy available"
		OperationResult.INVALID_SLOT:
			return "Invalid loadout slot"
	return "Action failed"


func _validate_edit_request(player_index: int) -> int:
	if (
		not _configured
		or player_index < 0
		or player_index >= _players.size()
		or _phase_manager.current_phase != PhaseManagerScript.Phase.PREPARATION
		or _phase_manager.is_player_ready(player_index)
	):
		return OperationResult.NOT_EDITABLE
	return OperationResult.SUCCESS


func _on_phase_changed(_previous_phase: int, current_phase: int) -> void:
	if current_phase != PhaseManagerScript.Phase.PREPARATION:
		return
	_award_income_for_round(_phase_manager.current_round)


func _award_income_for_round(round_number: int) -> void:
	if round_number <= _last_awarded_round:
		return

	var income: int = 0
	var schedule_index := round_number - 1
	if schedule_index >= 0 and schedule_index < round_income_by_round.size():
		income = maxi(round_income_by_round[schedule_index], 0)

	_last_awarded_round = round_number
	if income > 0:
		for player: PlayerScript in _players:
			player.grant_money(income)
	round_income_granted.emit(round_number, income)
