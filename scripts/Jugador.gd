extends CharacterBody2D

var speed := 120.0
var audio: AudioStreamPlayer

var current_floor: int = 0
var current_room_x: int = 0
var current_room_y: int = 0

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
		var node = get_tree().root.get_node_or_null(node_name)
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
		_check_room_transition()

func _check_room_transition() -> void:
	var mapa = _get_mapa_pisos()
	if mapa == null:
		return

	var scale = int(mapa.renderer.SCALE) if mapa.renderer else 4
	var tile_w = int(mapa.renderer.TILE_W) if mapa.renderer else 16
	var tile_h = int(mapa.renderer.TILE_H) if mapa.renderer else 8
	var screen_offset_x = 32 * scale

	var tile_x = int((position.x - screen_offset_x) / (tile_w * scale))
	var tile_y = int(position.y / (tile_h * scale))

	var new_room_x = current_room_x
	var new_room_y = current_room_y
	var new_tile_x = tile_x
	var new_tile_y = tile_y
	var moved = false

	if tile_x < 0:
		new_room_x = current_room_x - 1
		new_tile_x = 15
		moved = true
	elif tile_x > 15:
		new_room_x = current_room_x + 1
		new_tile_x = 0
		moved = true

	if tile_y < 0:
		new_room_y = current_room_y - 1
		new_tile_y = 15
		moved = true
	elif tile_y > 15:
		new_room_y = current_room_y + 1
		new_tile_y = 0
		moved = true

	if not moved:
		return

	var room_id = mapa.get_room_at(current_floor, new_room_x, new_room_y)
	if room_id <= 0:
		return

	current_room_x = new_room_x
	current_room_y = new_room_y
	position.x = screen_offset_x + new_tile_x * tile_w * scale + tile_w * scale / 2
	position.y = new_tile_y * tile_h * scale + tile_h * scale / 2

	mapa.build_and_render_room(current_floor, current_room_x, current_room_y)

func _get_mapa_pisos():
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("MapaPisos")
	return null

func _reproducir_pasos():
	if audio and not audio.playing:
		if ResourceLoader.exists("res://assets/sonidos/pasos.mp3"):
			audio.stream = load("res://assets/sonidos/pasos.mp3")
			audio.play()
