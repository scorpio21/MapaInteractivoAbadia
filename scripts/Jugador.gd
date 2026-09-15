extends CharacterBody2D

var speed := 150.0
@onready var audio := get_tree().get_root().get_node("Main/Audio")

func _ready():
	add_to_group("jugador")

func _physics_process(delta):
	var dir := Vector2.ZERO

	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1

	velocity = dir.normalized() * speed
	move_and_slide()

	if dir != Vector2.ZERO:
		_reproducir_pasos()

func _reproducir_pasos():
	audio.stream = load("res://assets/sonidos/pasos.mp3")
	if not audio.playing:
		audio.play()
