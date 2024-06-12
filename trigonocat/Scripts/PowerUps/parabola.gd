extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body is PlayerCat:
		body.parabolas = body.how_many_power_up_usages
		if !body.has_parabola:
			body.angle_speed *= 0.8
		body.has_parabola = true


func _on_camera_zoom_in_body_entered(body):
	if body is PlayerCat:
		body.camera.zoom = Vector2(0.8, 0.8)
