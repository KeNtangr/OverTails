class_name PhaseDisplay
extends Label

const PhaseManagerScript = preload("res://scripts/phase_manager.gd")

@export var phase_manager_path: NodePath

@onready var phase_manager: PhaseManagerScript = (
	get_node_or_null(phase_manager_path) as PhaseManagerScript
)


func _ready() -> void:
	if phase_manager == null:
		push_error("PhaseDisplay requires a valid PhaseManager path.")
		return

	phase_manager.phase_changed.connect(_on_phase_changed)
	_update_text(phase_manager.current_phase)


func _on_phase_changed(_previous_phase: int, current_phase: int) -> void:
	_update_text(current_phase)


func _update_text(current_phase: int) -> void:
	if current_phase == PhaseManagerScript.Phase.PREPARATION:
		text = "PREPARATION — CONFIGURE LOADOUTS"
	else:
		text = "ATTACK — DODGE!"
