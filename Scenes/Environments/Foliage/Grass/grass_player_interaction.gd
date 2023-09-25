extends MultiMeshInstance3D


@onready var player = get_tree().get_nodes_in_group("Player")[0]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(_delta):
	material_override.set_shader_parameter("playerPosition", player.global_position+Vector3(0.0, 0.2, 0.0))
