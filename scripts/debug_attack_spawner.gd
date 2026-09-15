class_name DebugAttackSpawner
extends Node2D

const ArenaScript = preload("res://scripts/arena.gd")
const SWORD_ATTACK_SCENE: PackedScene = preload("res://scenes/attacks/sword_attack.tscn")
const BOMB_ATTACK_SCENE: PackedScene = preload("res://scenes/attacks/bomb_attack.tscn")
const LASER_ATTACK_SCENE: PackedScene = preload("res://scenes/attacks/laser_attack.tscn")
const ATTACK_SCENES: Array[PackedScene] = [
	SWORD_ATTACK_SCENE,
	BOMB_ATTACK_SCENE,
	LASER_ATTACK_SCENE,
]

@export var arena_p1_path: NodePath
@export var arena_p2_path: NodePath

@onready var arena_p1: ArenaScript = get_node_or_null(arena_p1_path) as ArenaScript
@onready var arena_p2: ArenaScript = get_node_or_null(arena_p2_path) as ArenaScript
@onready var spawn_timer: Timer = $AttackSpawnTimer


func _ready() -> void:
	if arena_p1 == null or arena_p2 == null:
		push_error("DebugAttackSpawner requires valid paths to both arenas.")
		spawn_timer.stop()
		return

	spawn_timer.timeout.connect(_spawn_attacks)


func _spawn_attacks() -> void:
	_spawn_random_attack(arena_p1)
	_spawn_random_attack(arena_p2)


func _spawn_random_attack(arena: ArenaScript) -> void:
	var attack_scene: PackedScene = ATTACK_SCENES.pick_random()
	var spawn_position: Vector2

	if attack_scene == BOMB_ATTACK_SCENE:
		spawn_position = arena.get_random_position()
	else:
		var random_position := arena.get_random_position()
		spawn_position = Vector2(arena.arena_size.x * 0.5, random_position.y)

	arena.spawn_attack(attack_scene, spawn_position)
