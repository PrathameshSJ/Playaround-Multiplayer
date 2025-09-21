extends Node3D

@export var target_pos = Vector3(0,0,0)
@export var speed = 74.0 #m/s
@export var tracer_length = 1

@onready var bullet_tracer = $"."

const MAX_LIFETIME_MS = 5000

@onready var spawn_time = Time.get_ticks_msec()

func _process(delta: float) -> void:
	logic(target_pos,delta)

func logic(target_pos: Vector3,delta):
	var diff = target_pos - self.global_position
	var add = diff.normalized() * speed * delta
	add = add.limit_length(diff.length())
	self.global_position += add
	if (target_pos - self.global_position).length() <= tracer_length or Time.get_ticks_msec() - spawn_time > MAX_LIFETIME_MS:
		bullet_tracer.queue_free()
