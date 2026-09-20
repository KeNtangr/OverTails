class_name WeaponDefinition
extends Resource

enum SpawnPlacement {
	RANDOM_POINT,
	HORIZONTAL_LANE,
}

@export var weapon_id: StringName
@export var display_name: String
@export_range(0, 10000, 1) var purchase_price: int = 0
@export var purchasable: bool = false
@export var attack_scene: PackedScene
@export var spawn_placement: SpawnPlacement = SpawnPlacement.RANDOM_POINT
@export_range(0.0, 512.0, 1.0) var spawn_margin: float = 80.0
