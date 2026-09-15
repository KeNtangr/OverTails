class_name Arena
extends Node2D

@export var arena_size: Vector2 = Vector2(960.0, 540.0)
@export_range(1.0, 32.0, 1.0) var border_width: float = 4.0
@export var background_color: Color = Color(0.07, 0.09, 0.14, 1.0)
@export var border_color: Color = Color(0.55, 0.65, 0.85, 1.0)


func _ready() -> void:
	queue_redraw()


func clamp_position_to_bounds(local_position: Vector2, margin: float = 0.0) -> Vector2:
	var inset: float = border_width + maxf(margin, 0.0)
	var minimum := Vector2(inset, inset)
	var maximum := arena_size - minimum

	return Vector2(
		clampf(local_position.x, minimum.x, maximum.x),
		clampf(local_position.y, minimum.y, maximum.y)
	)


func spawn_attack(attack_scene: PackedScene, local_position: Vector2) -> Node2D:
	var instance: Node2D = attack_scene.instantiate() as Node2D
	instance.position = local_position
	add_child(instance)
	return instance


func get_random_position(margin: float = 80.0) -> Vector2:
	var safe_margin := clampf(
		margin,
		0.0,
		minf(arena_size.x, arena_size.y) * 0.5
	)
	var minimum := Vector2(safe_margin, safe_margin)
	var maximum := arena_size - minimum

	return Vector2(
		randf_range(minimum.x, maximum.x),
		randf_range(minimum.y, maximum.y)
	)


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, arena_size)
	draw_rect(bounds, background_color, true)
	draw_rect(bounds, border_color, false, border_width, true)
