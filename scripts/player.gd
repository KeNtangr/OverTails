class_name Player
extends CharacterBody2D

const ArenaScript = preload("res://scripts/arena.gd")

signal health_changed(current_hp: int, max_hp: int)
signal died

@export_range(1.0, 1000.0, 1.0) var move_speed: float = 360.0
@export_range(1.0, 64.0, 1.0) var body_radius: float = 16.0
@export_range(1, 1000, 1) var max_hp: int = 150
@export var input_left: StringName = &"move_left"
@export var input_right: StringName = &"move_right"
@export var input_up: StringName = &"move_up"
@export var input_down: StringName = &"move_down"

var current_hp: int

@onready var arena: ArenaScript = get_parent() as ArenaScript


func _ready() -> void:
	current_hp = max_hp

	if arena == null:
		push_error("Player must be a direct child of an Arena.")
		set_physics_process(false)
		return

	position = arena.clamp_position_to_bounds(position, body_radius)


func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector(
		input_left,
		input_right,
		input_up,
		input_down
	)

	velocity = input_direction * move_speed
	position += velocity * delta
	position = arena.clamp_position_to_bounds(position, body_radius)


func take_damage(amount: int) -> void:
	if amount <= 0 or current_hp <= 0:
		return

	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)

	if current_hp == 0:
		died.emit()
