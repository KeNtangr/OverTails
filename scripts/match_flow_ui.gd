class_name MatchFlowUI
extends Control

const GameManagerScript = preload("res://scripts/game_manager.gd")
const PhaseManagerScript = preload("res://scripts/phase_manager.gd")

@export var game_manager_path: NodePath
@export var phase_manager_path: NodePath

@onready var game_manager: GameManagerScript = (
	get_node_or_null(game_manager_path) as GameManagerScript
)
@onready var phase_manager: PhaseManagerScript = (
	get_node_or_null(phase_manager_path) as PhaseManagerScript
)
@onready var results_panel: PanelContainer = $ResultsPanel
@onready var results_title_label: Label = $ResultsPanel/Margin/Content/TitleLabel
@onready var results_player_one_label: Label = $ResultsPanel/Margin/Content/P1HealthLabel
@onready var results_player_two_label: Label = $ResultsPanel/Margin/Content/P2HealthLabel
@onready var match_over_panel: PanelContainer = $MatchOverPanel
@onready var match_result_label: Label = $MatchOverPanel/Margin/Content/ResultLabel
@onready var restart_button: Button = $MatchOverPanel/Margin/Content/RestartButton


func _ready() -> void:
	if game_manager == null or phase_manager == null:
		push_error("MatchFlowUI requires valid GameManager and PhaseManager paths.")
		set_process_unhandled_input(false)
		return

	phase_manager.phase_changed.connect(_on_phase_changed)
	phase_manager.results_started.connect(_on_results_started)
	game_manager.match_finished.connect(_on_match_finished)
	restart_button.pressed.connect(_on_restart_pressed)
	_on_phase_changed(phase_manager.current_phase, phase_manager.current_phase)


func _unhandled_input(event: InputEvent) -> void:
	if phase_manager.current_phase != PhaseManagerScript.Phase.MATCH_OVER:
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed(&"restart_match"):
		get_viewport().set_input_as_handled()
		game_manager.restart_match()


func _on_phase_changed(_previous_phase: int, current_phase: int) -> void:
	results_panel.visible = current_phase == PhaseManagerScript.Phase.RESULTS
	match_over_panel.visible = current_phase == PhaseManagerScript.Phase.MATCH_OVER


func _on_results_started(
	completed_round: int,
	player_one_hp: int,
	player_one_max_hp: int,
	player_two_hp: int,
	player_two_max_hp: int
) -> void:
	results_title_label.text = "ROUND %d RESULTS" % completed_round
	results_player_one_label.text = "P1 HP: %d / %d" % [
		player_one_hp,
		player_one_max_hp,
	]
	results_player_two_label.text = "P2 HP: %d / %d" % [
		player_two_hp,
		player_two_max_hp,
	]


func _on_match_finished(result: int) -> void:
	match result:
		GameManagerScript.MatchResult.PLAYER_ONE_WINS:
			match_result_label.text = "PLAYER 1 WINS"
		GameManagerScript.MatchResult.PLAYER_TWO_WINS:
			match_result_label.text = "PLAYER 2 WINS"
		GameManagerScript.MatchResult.DRAW:
			match_result_label.text = "DRAW"
		_:
			match_result_label.text = "MATCH OVER"


func _on_restart_pressed() -> void:
	game_manager.restart_match()
