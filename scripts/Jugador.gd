extends CharacterBody2D

const TILE_W: int = 16
const TILE_H: int = 8
const SCREEN_OFFSET_X: int = 32
const SPEED: float = 50.0

var audio: AudioStreamPlayer
var current_floor: int = 0
var current_room_x: int = 0
var current_room_y: int = 0

var facing: int = 0
var anim_frame: float = 0.0
var anim_playing: bool = false
var sprite_frames: SpriteFrames

func _ready():
	add_to_group("jugador")
	_setup_sprite()
	await get_tree().process_frame
	audio = _find_audio()
	if not audio:
		audio = AudioStreamPlayer.new()
		audio.name = "Audio"
		get_tree().root.add_child(audio)

func _setup_sprite():
	sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 0)
	sprite_frames.set_animation_loop("idle", true)

	var dir_names = ["south", "west", "north", "east"]
	var dir_rows = [0, 0, 1, 1]
	var dir_cols = [0, 4, 4, 0]

	for dir in range(4):
		var anim_name = "walk_" + dir_names[dir]
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, 8)
		sprite_frames.set_animation_loop(anim_name, true)

		for frame_idx in range(4):
			var col = dir_cols[dir] + frame_idx
			var row = dir_rows[dir]
			var rect = Rect2(col * 20, row * 36, 20, 36)
			var atlas = AtlasTexture.new()
			atlas.atlas = load("res://assets/sprites/guillermo_day.png")
			atlas.region = rect
			sprite_frames.add_frame(anim_name, atlas)

		sprite_frames.add_frame("idle", sprite_frames.get_frame(anim_name, 0))

	var old_sprite = get_node_or_null("Sprite")
	if old_sprite:
		old_sprite.queue_free()

	var anim_sprite = AnimatedSprite2D.new()
	anim_sprite.name = "Sprite"
	anim_sprite.sprite_frames = sprite_frames
	anim_sprite.animation = "idle"
	anim_sprite.frame = 0
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(anim_sprite)

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

	velocity = dir.normalized() * SPEED
	move_and_slide()

	if dir != Vector2.ZERO:
		_update_facing(dir)
		_play_walk_animation()
		_reproducir_pasos()
		_check_room_transition()
	else:
		_play_idle_animation()

func _update_facing(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			facing = 3
		else:
			facing = 1
	else:
		if dir.y > 0:
			facing = 0
		else:
			facing = 2

var _dir_names = ["south", "west", "north", "east"]

func _play_walk_animation():
	var anim = get_node_or_null("Sprite")
	if anim and anim is AnimatedSprite2D:
		var anim_name = "walk_" + _dir_names[facing]
		if anim.animation != anim_name or not anim.playing:
			anim.play(anim_name)

func _play_idle_animation():
	var anim = get_node_or_null("Sprite")
	if anim and anim is AnimatedSprite2D:
		if anim.animation != "idle":
			anim.stop()
			anim.animation = "idle"
			anim.frame = 0

func _check_room_transition() -> void:
	var mapa = _get_mapa_pisos()
	if mapa == null:
		return

	var tile_x = int((position.x - SCREEN_OFFSET_X) / TILE_W)
	var tile_y = int(position.y / TILE_H)

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
	position.x = SCREEN_OFFSET_X + new_tile_x * TILE_W + TILE_W / 2
	position.y = new_tile_y * TILE_H + TILE_H / 2

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
