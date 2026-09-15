extends Label

const PlayerScript = preload("res://scripts/player.gd")

@export var player_path: NodePath
@export var player_label: String = "HP"

@onready var player: PlayerScript = get_node_or_null(player_path) as PlayerScript


func _ready() -> void:
	if player == null:
		push_error("HealthDisplay requires a valid Player node path.")
		return

	player.health_changed.connect(_on_health_changed)
	_update_text(player.current_hp, player.max_hp)


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_update_text(current_hp, max_hp)


func _update_text(current_hp: int, max_hp: int) -> void:
	text = "%s: %d / %d" % [player_label, current_hp, max_hp]
