class_name PreparationPanel
extends PanelContainer

const PlayerScript = preload("res://scripts/player.gd")
const PhaseManagerScript = preload("res://scripts/phase_manager.gd")
const EconomyManagerScript = preload("res://scripts/economy_manager.gd")
const WeaponDefinitionScript = preload("res://scripts/weapon_definition.gd")

@export_range(0, 1, 1) var player_index: int = 0
@export var player_title: String = "P1"
@export var player_path: NodePath
@export var phase_manager_path: NodePath
@export var economy_manager_path: NodePath
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
var _preparation_active: bool = true
var _owned_weapon_types: Array[WeaponDefinitionScript] = []
var _shop_weapons: Array[WeaponDefinitionScript] = []

@onready var player: PlayerScript = get_node_or_null(player_path) as PlayerScript
@onready var phase_manager: PhaseManagerScript = (
	get_node_or_null(phase_manager_path) as PhaseManagerScript
)
@onready var economy_manager: EconomyManagerScript = (
	get_node_or_null(economy_manager_path) as EconomyManagerScript
)
@onready var title_label: Label = $MarginContainer/Content/TitleLabel
@onready var preparation_content: VBoxContainer = $MarginContainer/Content/PreparationContent
@onready var money_label: Label = $MarginContainer/Content/PreparationContent/MoneyLabel
@onready var shop_buttons: Array[Button] = [
	$MarginContainer/Content/PreparationContent/ShopButtons/ShopButton1,
	$MarginContainer/Content/PreparationContent/ShopButtons/ShopButton2,
]
@onready var inventory_labels: Array[Label] = [
	$MarginContainer/Content/PreparationContent/InventoryList/InventoryLabel1,
	$MarginContainer/Content/PreparationContent/InventoryList/InventoryLabel2,
	$MarginContainer/Content/PreparationContent/InventoryList/InventoryLabel3,
]
@onready var selected_weapon_label: Label = (
	$MarginContainer/Content/PreparationContent/SelectedWeaponRow/SelectedWeaponLabel
)
@onready var previous_weapon_button: Button = (
	$MarginContainer/Content/PreparationContent/SelectedWeaponRow/PreviousWeaponButton
)
@onready var next_weapon_button: Button = (
	$MarginContainer/Content/PreparationContent/SelectedWeaponRow/NextWeaponButton
)
@onready var selected_slot_label: Label = (
	$MarginContainer/Content/PreparationContent/SelectedSlotLabel
)
@onready var slot_buttons: Array[Button] = [
	$MarginContainer/Content/PreparationContent/SlotButtons/Slot1Button,
	$MarginContainer/Content/PreparationContent/SlotButtons/Slot2Button,
	$MarginContainer/Content/PreparationContent/SlotButtons/Slot3Button,
]
@onready var equip_button: Button = (
	$MarginContainer/Content/PreparationContent/LoadoutActions/EquipButton
)
@onready var unequip_button: Button = (
	$MarginContainer/Content/PreparationContent/LoadoutActions/UnequipButton
)
@onready var swap_left_button: Button = (
	$MarginContainer/Content/PreparationContent/RearrangeActions/SwapLeftButton
)
@onready var swap_right_button: Button = (
	$MarginContainer/Content/PreparationContent/RearrangeActions/SwapRightButton
)
@onready var ready_state_label: Label = (
	$MarginContainer/Content/PreparationContent/ReadyRow/ReadyStateLabel
)
@onready var ready_button: Button = (
	$MarginContainer/Content/PreparationContent/ReadyRow/ReadyButton
)
@onready var feedback_label: Label = (
	$MarginContainer/Content/PreparationContent/FeedbackLabel
)
@onready var instructions_label: Label = (
	$MarginContainer/Content/PreparationContent/InstructionsLabel
)
@onready var attack_summary_label: Label = $MarginContainer/Content/AttackSummaryLabel


func _ready() -> void:
	if (
		player == null
		or phase_manager == null
		or economy_manager == null
		or weapon_catalog.is_empty()
	):
		push_error(
			"PreparationPanel requires a Player, PhaseManager, EconomyManager, and weapon catalog."
		)
		set_process(false)
		return

	_build_shop_catalog()
	_connect_controls()
	player.money_changed.connect(_on_money_changed)
	player.inventory_changed.connect(_on_inventory_changed)
	player.loadout_changed.connect(_on_loadout_changed)
	phase_manager.player_ready_changed.connect(_on_player_ready_changed)
	phase_manager.phase_changed.connect(_on_phase_changed)

	title_label.text = "%s SHOP & LOADOUT" % player_title
	instructions_label.text = instruction_text
	_on_phase_changed(phase_manager.current_phase, phase_manager.current_phase)


func _process(_delta: float) -> void:
	if not _preparation_active:
		return

	if Input.is_action_just_pressed(ready_action):
		toggle_ready()
		return

	var edit_requested := (
		Input.is_action_just_pressed(previous_weapon_action)
		or Input.is_action_just_pressed(next_weapon_action)
		or Input.is_action_just_pressed(select_slot_one_action)
		or Input.is_action_just_pressed(select_slot_two_action)
		or Input.is_action_just_pressed(select_slot_three_action)
		or Input.is_action_just_pressed(equip_action)
	)
	if phase_manager.is_player_ready(player_index):
		if edit_requested:
			_set_feedback("Cancel Ready before editing")
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


func select_previous_weapon() -> void:
	if not _can_edit() or _owned_weapon_types.is_empty():
		_show_edit_blocked_feedback()
		return
	selected_weapon_index = (
		selected_weapon_index - 1 + _owned_weapon_types.size()
	) % _owned_weapon_types.size()
	_refresh()


func select_next_weapon() -> void:
	if not _can_edit() or _owned_weapon_types.is_empty():
		_show_edit_blocked_feedback()
		return
	selected_weapon_index = (selected_weapon_index + 1) % _owned_weapon_types.size()
	_refresh()


func select_slot(slot_index: int) -> void:
	if not _can_edit() or slot_index < 0 or slot_index >= PlayerScript.LOADOUT_SIZE:
		_show_edit_blocked_feedback()
		return
	selected_slot_index = slot_index
	_refresh()


func equip_selected_weapon() -> void:
	if _owned_weapon_types.is_empty():
		_set_feedback("No owned weapon available")
		return
	var result := economy_manager.try_equip_weapon(
		player_index,
		selected_slot_index,
		_get_selected_weapon()
	)
	_show_operation_result(result, "Weapon equipped")


func unequip_selected_slot() -> void:
	var result := economy_manager.try_unequip_slot(player_index, selected_slot_index)
	_show_operation_result(result, "Slot unequipped")


func swap_selected_slot(offset: int) -> void:
	var target_slot := selected_slot_index + offset
	var result := economy_manager.try_swap_slots(
		player_index,
		selected_slot_index,
		target_slot
	)
	if result == EconomyManagerScript.OperationResult.SUCCESS:
		selected_slot_index = target_slot
	_show_operation_result(result, "Slots rearranged")


func purchase_weapon(weapon: WeaponDefinitionScript) -> void:
	var result := economy_manager.try_purchase_weapon(player_index, weapon)
	_show_operation_result(result, "Purchased %s" % weapon.display_name)


func toggle_ready() -> void:
	if not _preparation_active:
		return
	if not phase_manager.toggle_player_ready(player_index):
		_set_feedback("Equip at least one weapon before Ready")
	else:
		_set_feedback("")
	_refresh()


func _build_shop_catalog() -> void:
	_shop_weapons.clear()
	for resource: Resource in weapon_catalog:
		var weapon := resource as WeaponDefinitionScript
		if weapon != null and weapon.purchasable:
			_shop_weapons.append(weapon)

	for button_index: int in range(shop_buttons.size()):
		var button := shop_buttons[button_index]
		if button_index >= _shop_weapons.size():
			button.visible = false
			continue
		var weapon := _shop_weapons[button_index]
		button.text = "Buy %s  $%d" % [weapon.display_name, weapon.purchase_price]
		button.pressed.connect(purchase_weapon.bind(weapon))


func _connect_controls() -> void:
	previous_weapon_button.pressed.connect(select_previous_weapon)
	next_weapon_button.pressed.connect(select_next_weapon)
	for slot_index: int in range(slot_buttons.size()):
		slot_buttons[slot_index].pressed.connect(select_slot.bind(slot_index))
	equip_button.pressed.connect(equip_selected_weapon)
	unequip_button.pressed.connect(unequip_selected_slot)
	swap_left_button.pressed.connect(swap_selected_slot.bind(-1))
	swap_right_button.pressed.connect(swap_selected_slot.bind(1))
	ready_button.pressed.connect(toggle_ready)


func _get_selected_weapon() -> WeaponDefinitionScript:
	if _owned_weapon_types.is_empty():
		return null
	selected_weapon_index = clampi(selected_weapon_index, 0, _owned_weapon_types.size() - 1)
	return _owned_weapon_types[selected_weapon_index]


func _can_edit() -> bool:
	return _preparation_active and not phase_manager.is_player_ready(player_index)


func _show_edit_blocked_feedback() -> void:
	if phase_manager.is_player_ready(player_index):
		_set_feedback("Cancel Ready before editing")


func _show_operation_result(result: int, success_message: String) -> void:
	if result == EconomyManagerScript.OperationResult.SUCCESS:
		_set_feedback(success_message)
	else:
		_set_feedback(economy_manager.get_result_message(result))
	_refresh()


func _set_feedback(message: String) -> void:
	feedback_label.text = message


func _on_money_changed(_current_money: int) -> void:
	_refresh()


func _on_inventory_changed() -> void:
	_refresh()


func _on_loadout_changed(
	_slot_index: int,
	_weapon: WeaponDefinitionScript
) -> void:
	_refresh()


func _on_player_ready_changed(changed_player_index: int, _is_ready: bool) -> void:
	if changed_player_index == player_index:
		_refresh()


func _on_phase_changed(_previous_phase: int, current_phase: int) -> void:
	_preparation_active = current_phase == PhaseManagerScript.Phase.PREPARATION
	var attack_active := current_phase == PhaseManagerScript.Phase.ATTACK
	visible = _preparation_active or attack_active
	preparation_content.visible = _preparation_active
	attack_summary_label.visible = attack_active
	var panel_height := 482.0 if _preparation_active else 54.0
	custom_minimum_size.y = panel_height
	size.y = panel_height
	set_process(_preparation_active)
	_refresh()


func _refresh() -> void:
	if player == null or phase_manager == null or economy_manager == null:
		return

	_owned_weapon_types = player.get_owned_weapon_types()
	if _owned_weapon_types.is_empty():
		selected_weapon_index = 0
	else:
		selected_weapon_index = clampi(
			selected_weapon_index,
			0,
			_owned_weapon_types.size() - 1
		)

	money_label.text = "Money: $%d" % player.get_money()
	_refresh_inventory()
	_refresh_loadout()

	var is_ready := phase_manager.is_player_ready(player_index)
	if is_ready:
		ready_state_label.text = "State: READY"
	elif player.has_equipped_weapon():
		ready_state_label.text = "State: EDITING"
	else:
		ready_state_label.text = "State: EDITING - equip at least one weapon"
	ready_button.text = "Cancel Ready" if is_ready else "Ready"

	var controls_editable := _preparation_active and not is_ready
	for button: Button in shop_buttons:
		button.disabled = not controls_editable
	previous_weapon_button.disabled = not controls_editable
	next_weapon_button.disabled = not controls_editable
	for button: Button in slot_buttons:
		button.disabled = not controls_editable
	equip_button.disabled = not controls_editable
	unequip_button.disabled = not controls_editable
	swap_left_button.disabled = not controls_editable or selected_slot_index <= 0
	swap_right_button.disabled = (
		not controls_editable or selected_slot_index >= PlayerScript.LOADOUT_SIZE - 1
	)
	ready_button.disabled = not _preparation_active

	attack_summary_label.text = "%s: %s" % [player_title, _build_loadout_summary()]


func _refresh_inventory() -> void:
	for label_index: int in range(inventory_labels.size()):
		var label := inventory_labels[label_index]
		if label_index >= weapon_catalog.size():
			label.visible = false
			continue
		var weapon := weapon_catalog[label_index] as WeaponDefinitionScript
		if weapon == null:
			label.visible = false
			continue
		label.visible = true
		label.text = "%s - Owned %d / Equipped %d / Available %d" % [
			weapon.display_name,
			player.get_owned_count(weapon),
			player.get_equipped_count(weapon),
			player.get_available_count(weapon),
		]


func _refresh_loadout() -> void:
	var selected_weapon := _get_selected_weapon()
	selected_weapon_label.text = (
		"Owned selection: None"
		if selected_weapon == null
		else "Owned selection: %s" % selected_weapon.display_name
	)
	selected_slot_label.text = "Target slot: %d" % (selected_slot_index + 1)

	for slot_index: int in range(PlayerScript.LOADOUT_SIZE):
		var weapon := player.get_loadout_slot(slot_index)
		var weapon_name := "Empty" if weapon == null else weapon.display_name
		var selection_marker := ">" if slot_index == selected_slot_index else " "
		slot_buttons[slot_index].text = "%s Slot %d: %s" % [
			selection_marker,
			slot_index + 1,
			weapon_name,
		]


func _build_loadout_summary() -> String:
	var names := PackedStringArray()
	for slot_index: int in range(PlayerScript.LOADOUT_SIZE):
		var weapon := player.get_loadout_slot(slot_index)
		names.append("Empty" if weapon == null else weapon.display_name)
	return " | ".join(names)
