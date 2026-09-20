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
	phase_manager.round_changed.connect(_on_round_changed)
	_update_text(phase_manager.current_phase)


func _on_phase_changed(_previous_phase: int, current_phase: int) -> void:
	_update_text(current_phase)


func _on_round_changed(_current_round: int) -> void:
	_update_text(phase_manager.current_phase)


func _update_text(current_phase: int) -> void:
	match current_phase:
		PhaseManagerScript.Phase.PREPARATION:
			text = "ROUND %d — PREPARATION — CONFIGURE LOADOUTS" % phase_manager.current_round
		PhaseManagerScript.Phase.ATTACK:
			text = "ROUND %d — ATTACK — DODGE!" % phase_manager.current_round
		PhaseManagerScript.Phase.RESULTS:
			text = "ROUND %d — RESULTS" % phase_manager.current_round
		PhaseManagerScript.Phase.MATCH_OVER:
			text = "MATCH OVER"
		_:
			text = "UNKNOWN PHASE"
