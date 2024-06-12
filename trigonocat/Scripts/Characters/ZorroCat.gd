class_name PlayerCat extends CharacterBody2D

@onready var jump_force_bar = $Control/JumpForce
@onready var angle_bar = $Control/Angle
@onready var arrov_pivot = $Control/Coordinates/Pivot
@onready var arrow_stem = $Control/Coordinates/Pivot/Stem
@onready var arrow_head = $Control/Coordinates/Pivot/Arrowhead
@onready var sprite = $IddleSprite
@onready var collision = $CollisionPolygon2D
@onready var head_position = $Control/Coordinates/Pivot/Stem/HeadPosition
@onready var camera = $Camera2D
@onready var particles = $GPUParticles2D

# For power ups:
@onready var root = get_parent()
@onready var trajectory = root.get_node("Trajectory")
@onready var trajectory_pos = $TrajectoryPoint
var max_points = 250

var has_parabola = false
var has_double_force = false
## Self explanatory, how many usages will a power up have
@export var how_many_power_up_usages = 3
var parabolas = 0
var double_forces = 0
#---

const ANGLE_MULTIPLIER = 200

var jumped = false

var jump_force_increasing = true
@export var max_jump_force = 67500.0
@export var min_jump_force = 5000
@export var jump_force_inc = 750
@export var angle_speed = 1.5
var original_angle_speed

# as global var for parabola
var calculated_jump_force = 0

var jump_angle_increasing = true
var min_angle = 10
var max_angle = 170

var starting_stem_scale
var starting_head_position

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	jump_force_bar.max_value = max_jump_force
	jump_force_bar.min_value = min_jump_force
	jump_force_bar.value = jump_force_bar.min_value
	angle_bar.min_value = min_angle
	angle_bar.max_value = max_angle
	angle_bar.value = angle_bar.min_value
	starting_head_position = arrow_head.position
	starting_stem_scale = arrow_stem.scale
	original_angle_speed = angle_speed
	sprite.play("Iddle")
	particles.emitting = true
	particles.amount_ratio = 0.2
	# Load math images to sprite array

	pass
	
func _process(delta):
	if Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()
	
	arrow_head.global_position = head_position.global_position

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_on_floor() and !Input.is_action_pressed("Jump"):
		# Set the jump_force_bar to zero when landing from a jump
		if jumped:
			particles.emitting = true
			particles.amount_ratio = 0.2
			jump_force_bar.value = jump_force_bar.min_value
			if sprite.flip_h:
				angle_bar.value = angle_bar.max_value
				arrov_pivot.rotation_degrees = -170
			else:
				angle_bar.value = angle_bar.min_value
				arrov_pivot.rotation_degrees = -10	
				
			arrow_stem.scale = starting_stem_scale
			jumped = false
			velocity = Vector2.ZERO
			trajectory.global_position = trajectory_pos.global_position
			trajectory.clear_points()
			if parabolas >= 0 and has_parabola:
				parabolas -= 1
			# -1 so the max amout matches. it takes one off when parabola is collected, 
			# because it happens before landing
			if parabolas == -1 and has_parabola:
				angle_speed = original_angle_speed
				has_parabola = false
				
			if double_forces >= 0 and has_double_force:
				double_forces -= 1
			if double_forces == -1 and has_double_force:
				has_double_force = false
		# if jump force is increasig
		if jump_force_increasing:
			jump_force_bar.value += jump_force_inc
			arrow_stem.scale.x += 0.1
		
		# and if decreasing
		if !jump_force_increasing:
			jump_force_bar.value -= jump_force_inc
			arrow_stem.scale.x -= 0.1
			#arrow_head.position.x -= 1
		
		# When reached max, make it decrease
		if jump_force_bar.value == max_jump_force:
			jump_force_increasing = false;
		
		# when zero, make it increase again.
		if jump_force_bar.value == min_jump_force:
			jump_force_increasing = true
			
	
	if Input.is_action_pressed("Jump") and is_on_floor():
		sprite.play("Calculating")
		particles.amount_ratio = 0.6
		if jump_angle_increasing:
			angle_bar.value += angle_speed
			arrov_pivot.rotation_degrees -= angle_speed
			
		if !jump_angle_increasing:
			angle_bar.value -= angle_speed
			arrov_pivot.rotation_degrees += angle_speed
		
		if angle_bar.value == angle_bar.max_value:
			jump_angle_increasing = false
		
		if angle_bar.value == angle_bar.min_value:
			jump_angle_increasing = true
		
	# Calculate the jump here, because we want to pass this to parabola always.
	var angle = angle_bar.value * PI /180
	var jump_dir = Vector2(-cos(angle), sin(angle))
	calculated_jump_force = jump_dir * -jump_force_bar.value * delta
	if has_double_force:
		calculated_jump_force *= 2
	
	# Handle jump.
	if Input.is_action_just_released("Jump") and is_on_floor():
		particles.emitting = false
		sprite.play("Iddle")
		velocity = calculated_jump_force
		if jump_dir.x > 0 and !sprite.flip_h:
			sprite.flip_h = true
		if jump_dir.x < 0 and sprite.flip_h:
			sprite.flip_h = false
		jumped = true
	
	move_and_slide()
	
	if is_on_floor() && has_parabola:
		calculate_trajectory(delta)
	
func calculate_trajectory(delta):
	trajectory.clear_points()
	var pos = trajectory_pos.position
	var vel = calculated_jump_force
	for i in max_points:
		trajectory.add_point(pos)
		vel.y += gravity * delta
		# Cannot figure why the parabola wont exactly match so the multiplier 
		# is for manual adjustment
		pos += (vel * 0.70) * delta 
		
