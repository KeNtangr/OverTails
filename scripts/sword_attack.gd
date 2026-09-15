class_name SwordAttack
extends Area2D

signal finished

@export_range(0.0, 5.0, 0.1) var warning_duration: float = 0.7
@export_range(0.05, 2.0, 0.05) var active_duration: float = 0.2
@export_range(1, 1000, 1) var damage: int = 10

var _damaged_body_ids: Dictionary = {}

@onready var warning_line: Polygon2D = $WarningLine
@onready var active_slash: Polygon2D = $ActiveSlash
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_run_attack()


func _run_attack() -> void:
	await get_tree().create_timer(warning_duration).timeout

	warning_line.visible = false
	active_slash.visible = true
	monitoring = true
	collision_shape.disabled = false

	await get_tree().physics_frame
	_damage_existing_overlaps()
	await get_tree().create_timer(active_duration).timeout

	monitoring = false
	collision_shape.disabled = true
	finished.emit()
	queue_free()


func _damage_existing_overlaps() -> void:
	for body: Node2D in get_overlapping_bodies():
		_try_damage(body)


func _on_body_entered(body: Node2D) -> void:
	_try_damage(body)


func _try_damage(body: Node2D) -> void:
	var body_id: int = body.get_instance_id()
	if _damaged_body_ids.has(body_id) or not body.has_method(&"take_damage"):
		return

	_damaged_body_ids[body_id] = true
	body.call(&"take_damage", damage)
