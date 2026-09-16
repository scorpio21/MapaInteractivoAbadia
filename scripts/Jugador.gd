extends CharacterBody2D

const TILE_W: int = 16
const TILE_H: int = 8
const SPEED: float = 50.0

var audio: AudioStreamPlayer
var current_floor: int = 0
var current_room_x: int = 0
var current_room_y: int = 0
var facing: int = 0
var sprite_frames: SpriteFrames

func _ready():
	add_to_group("jugador")
	_setup_sprite()
	await get_tree().process_frame
	audio = _find_audio()

func _setup_sprite():
	sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("idle")
	sprite_frames.set_animation_speed("idle", 0)
	sprite_frames.set_animation_loop("idle", true)

	var dir_names = ["south", "west", "north", "east"]
	var dir_rows = [0, 0, 1, 1]
	var dir_cols = [0, 4, 4, 0]
	var tex = load("res://assets/sprites/guillermo_day.png")

	for dir in range(4):
		var anim_name = "walk_" + dir_names[dir]
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, 8)
		sprite_frames.set_animation_loop(anim_name, true)
		for frame_idx in range(4):
			var col = dir_cols[dir] + frame_idx
			var row = dir_rows[dir]
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * 20, row * 36, 20, 36)
			sprite_frames.add_frame(anim_name, atlas)
		sprite_frames.add_frame("idle", sprite_frames.get_frame(anim_name, 0))

	var anim_sprite = AnimatedSprite2D.new()
	anim_sprite.name = "Sprite"
	anim_sprite.sprite_frames = sprite_frames
	anim_sprite.animation = "idle"
	anim_sprite.frame = 0
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(anim_sprite)

func _find_audio() -> AudioStreamPlayer:
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("Audio")
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
		_play_walk()
		_check_room_transition()
	else:
		_play_idle()

func _update_facing(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		facing = 3 if dir.x > 0 else 1
	else:
		facing = 0 if dir.y > 0 else 2

var _dir_names = ["south", "west", "north", "east"]

func _play_walk():
	var s = get_node_or_null("Sprite")
	if s and s is AnimatedSprite2D:
		var a = "walk_" + _dir_names[facing]
		if s.animation != a or not s.playing:
			s.play(a)

func _play_idle():
	var s = get_node_or_null("Sprite")
	if s and s is AnimatedSprite2D:
		if s.animation != "idle":
			s.stop()
			s.animation = "idle"
			s.frame = 0

func _check_room_transition() -> void:
	var mapa = _get_room_renderer()
	if mapa == null:
		return

	var tile_x = int(position.x / TILE_W)
	var tile_y = int(position.y / TILE_H)

	var new_rx = current_room_x
	var new_ry = current_room_y
	var new_tx = tile_x
	var new_ty = tile_y
	var moved = false

	if tile_x < 0:
		new_rx -= 1; new_tx = 15; moved = true
	elif tile_x > 15:
		new_rx += 1; new_tx = 0; moved = true
	if tile_y < 0:
		new_ry -= 1; new_ty = 15; moved = true
	elif tile_y > 15:
		new_ry += 1; new_ty = 0; moved = true

	if not moved:
		return

	if mapa.get_room_at(current_floor, new_rx, new_ry) <= 0:
		return

	current_room_x = new_rx
	current_room_y = new_ry
	position = Vector2(new_tx * TILE_W + TILE_W / 2, new_ty * TILE_H + TILE_H / 2)
	mapa.build_room(current_floor, current_room_x, current_room_y)

func _get_room_renderer():
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		var container = main.get_node_or_null("SubViewportContainer")
		if container:
			return container.get_node_or_null("SubViewport/RoomTiles")
	return null
