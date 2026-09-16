extends CharacterBody2D

var speed := 120.0
var audio: AudioStreamPlayer

func _ready():
	add_to_group("jugador")
	await get_tree().process_frame
	audio = _find_audio()
	if not audio:
		audio = AudioStreamPlayer.new()
		audio.name = "Audio"
		get_tree().root.add_child(audio)

func _find_audio() -> AudioStreamPlayer:
	for node_name in ["Main"]:
		var node = get_tree().get_root().get_node_or_null(node_name)
		if node:
			var a = node.get_node_or_null("Audio")
			if a is AudioStreamPlayer:
				return a
	return null

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
	if audio and not audio.playing:
		if ResourceLoader.exists("res://assets/sonidos/pasos.mp3"):
			audio.stream = load("res://assets/sonidos/pasos.mp3")
			audio.play()
