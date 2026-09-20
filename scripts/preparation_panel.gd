class_name PreparationPanel
extends PanelContainer

const PlayerScript = preload("res://scripts/player.gd")
const PhaseManagerScript = preload("res://scripts/phase_manager.gd")
const WeaponDefinitionScript = preload("res://scripts/weapon_definition.gd")

@export_range(0, 1, 1) var player_index: int = 0
@export var player_title: String = "P1"
@export var player_path: NodePath
@export var phase_manager_path: NodePath
@export var weapon_catalog: Array[Resource] = []
@export var previous_weapon_action: StringName
@export var next_weapon_action: StringName
@export var select_slot_one_action: StringName
@export var select_slot_two_action: StringName
@export var select_slot_three_action: StringName
@export var equip_action: StringName
@export var ready_action: StringName
@export_multiline var instruction_text: String

var selected_weapon_index: int = 0
var selected_slot_index: int = 0
var _editing_enabled: bool = true

@onready var player: PlayerScript = get_node_or_null(player_path) as PlayerScript
@onready var phase_manager: PhaseManagerScript = (
	get_node_or_null(phase_manager_path) as PhaseManagerScript
)
@onready var title_label: Label = $MarginContainer/Content/TitleLabel
@onready var preparation_content: VBoxContainer = $MarginContainer/Content/PreparationContent
@onready var selected_weapon_label: Label = (
	$MarginContainer/Content/PreparationContent/SelectedWeaponLabel
)
@onready var selected_slot_label: Label = (
	$MarginContainer/Content/PreparationContent/SelectedSlotLabel
)
@onready var slot_labels: Array[Label] = [
	$MarginContainer/Content/PreparationContent/Slot1Label,
	$MarginContainer/Content/PreparationContent/Slot2Label,
	$MarginContainer/Content/PreparationContent/Slot3Label,
]
@onready var ready_state_label: Label = (
	$MarginContainer/Content/PreparationContent/ReadyStateLabel
)
@onready var instructions_label: Label = (
	$MarginContainer/Content/PreparationContent/InstructionsLabel
)
@onready var attack_summary_label: Label = $MarginContainer/Content/AttackSummaryLabel


func _ready() -> void:
	if player == null or phase_manager == null or weapon_catalog.is_empty():
		push_error("PreparationPanel requires a Player, PhaseManager, and weapon catalog.")
		set_process(false)
		return

	player.loadout_changed.connect(_on_loadout_changed)
	phase_manager.player_ready_changed.connect(_on_player_ready_changed)
	phase_manager.phase_changed.connect(_on_phase_changed)

	title_label.text = "%s LOADOUT" % player_title
	instructions_label.text = instruction_text
	_on_phase_changed(phase_manager.current_phase, phase_manager.current_phase)


func _process(_delta: float) -> void:
	if not _editing_enabled:
		return

	if Input.is_action_just_pressed(previous_weapon_action):
		select_previous_weapon()
	if Input.is_action_just_pressed(next_weapon_action):
		select_next_weapon()
	if Input.is_action_just_pressed(select_slot_one_action):
		select_slot(0)
	if Input.is_action_just_pressed(select_slot_two_action):
		select_slot(1)
	if Input.is_action_just_pressed(select_slot_three_action):
		select_slot(2)
	if Input.is_action_just_pressed(equip_action):
		equip_selected_weapon()
	if Input.is_action_just_pressed(ready_action):
		toggle_ready()


func select_previous_weapon() -> void:
	if not _editing_enabled:
		return
	selected_weapon_index = (
		selected_weapon_index - 1 + weapon_catalog.size()
	) % weapon_catalog.size()
	_refresh()


func select_next_weapon() -> void:
	if not _editing_enabled:
		return
	selected_weapon_index = (selected_weapon_index + 1) % weapon_catalog.size()
	_refresh()


func select_slot(slot_index: int) -> void:
	if not _editing_enabled or slot_index < 0 or slot_index >= PlayerScript.LOADOUT_SIZE:
		return
	selected_slot_index = slot_index
	_refresh()


func equip_selected_weapon() -> void:
	if not _editing_enabled:
		return

	var weapon := _get_selected_weapon()
	player.set_loadout_slot(selected_slot_index, weapon)


func toggle_ready() -> void:
	if not _editing_enabled:
		return
	phase_manager.toggle_player_ready(player_index)
	_refresh()


func _get_selected_weapon() -> WeaponDefinitionScript:
	return weapon_catalog[selected_weapon_index] as WeaponDefinitionScript


func _on_loadout_changed(
	_slot_index: int,
	_weapon: WeaponDefinitionScript
) -> void:
	_refresh()


func _on_player_ready_changed(changed_player_index: int, _is_ready: bool) -> void:
	if changed_player_index == player_index:
		_refresh()


func _on_phase_changed(_previous_phase: int, current_phase: int) -> void:
	var preparation_active := current_phase == PhaseManagerScript.Phase.PREPARATION
	var attack_active := current_phase == PhaseManagerScript.Phase.ATTACK
	_editing_enabled = preparation_active
	visible = preparation_active or attack_active
	preparation_content.visible = preparation_active
	attack_summary_label.visible = attack_active
	var panel_height := 224.0 if _editing_enabled else 54.0
	custom_minimum_size.y = panel_height
	size.y = panel_height
	set_process(_editing_enabled)
	_refresh()


func _refresh() -> void:
	if player == null or phase_manager == null or weapon_catalog.is_empty():
		return

	var selected_weapon := _get_selected_weapon()
	selected_weapon_label.text = "Selected weapon: %s" % selected_weapon.display_name
	selected_slot_label.text = "Target slot: %d" % (selected_slot_index + 1)

	for slot_index: int in range(PlayerScript.LOADOUT_SIZE):
		var weapon := player.get_loadout_slot(slot_index)
		var weapon_name := "Empty" if weapon == null else weapon.display_name
		var selection_marker := ">" if slot_index == selected_slot_index else " "
		slot_labels[slot_index].text = "%s Slot %d: %s" % [
			selection_marker,
			slot_index + 1,
			weapon_name,
		]

	if phase_manager.is_player_ready(player_index):
		ready_state_label.text = "State: READY"
	elif player.has_equipped_weapon():
		ready_state_label.text = "State: EDITING"
	else:
		ready_state_label.text = "State: EDITING — equip at least one weapon"

	attack_summary_label.text = "%s: %s" % [player_title, _build_loadout_summary()]


func _build_loadout_summary() -> String:
	var names := PackedStringArray()
	for slot_index: int in range(PlayerScript.LOADOUT_SIZE):
		var weapon := player.get_loadout_slot(slot_index)
		names.append("Empty" if weapon == null else weapon.display_name)
	return " | ".join(names)
