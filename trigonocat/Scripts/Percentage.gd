extends Control

@onready var root = get_parent().get_parent()
@onready var start_point = root.get_node("Start")
@onready var end_point = root.get_node("End")
@onready var player_root = root.get_node("Player")
@onready var player = player_root.get_child(1)
@onready var percentage = $CompletionPercentage

var map_distance
var distance_to_end

# Called when the node enters the scene tree for the first time.
func _ready():
	map_distance = start_point.global_position.distance_to(end_point.global_position)
	print(map_distance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	distance_to_end = player.global_position.distance_to(end_point.global_position)
	print(100 - snappedf(distance_to_end / map_distance * 100, 1))
	percentage.text = str(100 - snappedf(distance_to_end / map_distance * 100, 1)) + "%"
