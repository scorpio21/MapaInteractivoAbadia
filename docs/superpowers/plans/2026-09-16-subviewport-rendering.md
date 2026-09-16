# SubViewport Native CPC Rendering — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replicate the room viewer's pixel-perfect rendering in Godot 4.7 using SubViewport at native CPC resolution (256×160).

**Architecture:** SubViewport at 256×160 holds tiles + player at native pixel coords. SubViewportContainer scales up with NEAREST filtering. RoomRenderer replaces TileRenderer+MapaPisos. Player uses AnimatedSprite2D for 4-dir walking.

**Tech Stack:** Godot 4.7, GDScript, SubViewportContainer, AnimatedSprite2D, AtlasTexture

## Global Constraints

- Godot 4.7 (Steam), GDScript
- Viewport: 1280×720 window
- Tile size: 16×8 px (native CPC)
- Room buffer: 16×20 tiles = 256×160 px
- No comments in code unless requested
- Tab indentation
- Commit after each task

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `scripts/RoomRenderer.gd` | Parse scripts, fill buffer, render tiles to SubViewport |
| Create | `scenes/MainNew.tscn` | SubViewportContainer + SubViewport scene tree |
| Rewrite | `scripts/Jugador.gd` | Native coord movement + walking animation |
| Rewrite | `scenes/Jugador.tscn` | AnimatedSprite2D + CollisionShape2D (native size) |
| Keep | `scripts/ScriptInterpreter.gd` | Already works (32,207 sprites, 0 errors) |
| Keep | `data/scripts.abs`, `data/floors.json`, `data/rooms.json` | Room data |
| Keep | `assets/tiles_day.png`, `assets/sprites/guillermo_day.png` | Graphics |
| Keep | `scripts/Reloj.gd`, `scripts/UI.gd` | Hour system |
| Delete | `scripts/TileRenderer.gd` | Replaced by RoomRenderer |
| Delete | `scripts/MapaPisos.gd` | Merged into RoomRenderer |
| Delete | `scripts/AbbeyMap.gd` | Not used |
| Delete | `scenes/MapaPisos.tscn` | Replaced by MainNew |

---

### Task 1: Create RoomRenderer.gd

**Files:**
- Create: `scripts/RoomRenderer.gd`

**Interfaces:**
- Consumes: `ScriptInterpreter` (already working), `data/tiles.json` (tile atlas definitions)
- Produces: `build_room(floor, room_x, room_y)` — clears old tiles, executes blocks, creates new tile sprites

- [ ] **Step 1: Create RoomRenderer.gd with constants and setup**

```gdscript
extends Node2D
class_name RoomRenderer

const TILE_W: int = 16
const TILE_H: int = 8
const BUFFER_W: int = 16
const BUFFER_H: int = 20

var tile_atlas: Texture2D
var tile_frames: Dictionary = {}
var interpreter  # ScriptInterpreter instance
var floors_data: Array = []
var rooms_data: Array = []
var current_floor: int = 0
var current_room_x: int = -1
var current_room_y: int = -1
var current_sprites: Array = []
var room_cache: Dictionary = {}

func _init() -> void:
	pass

func setup(interp, floors: Array, rooms: Array) -> void:
	interpreter = interp
	floors_data = floors
	rooms_data = rooms
	_load_tileset()

func _load_tileset() -> void:
	tile_atlas = load("res://assets/tiles_day.png")
	if tile_atlas == null:
		print("ERROR: No se pudo cargar tiles_day.png")
		return
	var tile_file = FileAccess.open("res://data/tiles.json", FileAccess.READ)
	if tile_file:
		var json = JSON.new()
		var err = json.parse(tile_file.get_as_text())
		if err == OK:
			var data = json.data
			for key in data.get("frames", {}).keys():
				var frame_data = data["frames"][key]["frame"]
				var tile_id = int(key.replace("tile", ""))
				tile_frames[tile_id] = Rect2(frame_data["x"], frame_data["y"], frame_data["w"], frame_data["h"])
		tile_file.close()
		print("RoomRenderer: ", tile_frames.size(), " tiles cargados")
```

- [ ] **Step 2: Add build_room method**

```gdscript
func build_room(fl: int, rx: int, ry: int) -> void:
	if fl == current_floor and rx == current_room_x and ry == current_room_y:
		return
	current_floor = fl
	current_room_x = rx
	current_room_y = ry
	_clear_sprites()

	if fl >= floors_data.size():
		return
	var room_grid = floors_data[fl].get("room", [])
	if ry >= room_grid.size() or rx >= room_grid[ry].size():
		return
	var room_id = room_grid[ry][rx]
	if room_id < 1 or room_id > rooms_data.size():
		return

	var buffer = _get_room_buffer(room_id)
	_render_buffer(buffer)
	print("Room %d at (%d,%d): rendered" % [room_id, rx, ry])
```

- [ ] **Step 3: Add buffer management methods**

```gdscript
func _get_room_buffer(room_id: int) -> Array:
	if room_cache.has(room_id):
		return room_cache[room_id]
	var room = rooms_data[room_id - 1]
	var blocks = room.get("blocks", [])
	interpreter.clear_tile_buffer()
	for block in blocks:
		interpreter.execute_block(block)
	var raw = interpreter.get_tile_buffer()
	var copy = []
	for x in range(BUFFER_W):
		var col = []
		for y in range(BUFFER_H):
			col.append(raw[x][y].duplicate())
		copy.append(col)
	room_cache[room_id] = copy
	return copy

func _render_buffer(buffer: Array) -> void:
	for x in range(BUFFER_W):
		for y in range(BUFFER_H):
			for tile_data in buffer[x][y]:
				var tile_id = tile_data["tile"]
				if not tile_frames.has(tile_id):
					continue
				var atlas = AtlasTexture.new()
				atlas.atlas = tile_atlas
				atlas.region = tile_frames[tile_id]
				var sprite = Sprite2D.new()
				sprite.texture = atlas
				sprite.centered = false
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.position = Vector2(x * TILE_W, y * TILE_H)
				sprite.z_index = tile_data["depthX"] + tile_data["depthY"] - 16
				add_child(sprite)
				current_sprites.append(sprite)

func _clear_sprites() -> void:
	for s in current_sprites:
		if is_instance_valid(s):
			s.queue_free()
	current_sprites.clear()

func get_room_at(fl: int, rx: int, ry: int) -> int:
	if fl < 0 or fl >= floors_data.size():
		return 0
	var room_grid = floors_data[fl].get("room", [])
	if ry < 0 or ry >= room_grid.size() or rx < 0 or rx >= room_grid[ry].size():
		return 0
	return room_grid[ry][rx]
```

- [ ] **Step 4: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors, "RoomRenderer: 256 tiles cargados", "Room 40 at (8,1): rendered"

- [ ] **Step 5: Commit**

```bash
git add scripts/RoomRenderer.gd
git commit -m "feat: RoomRenderer - native CPC resolution tile rendering"
```

---

### Task 2: Create MainNew.tscn with SubViewport

**Files:**
- Create: `scenes/MainNew.tscn`

**Interfaces:**
- Consumes: RoomRenderer.gd, Jugador.tscn, UI.gd, Reloj.gd
- Produces: Main scene node tree

- [ ] **Step 1: Create MainNew.tscn**

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/RoomRenderer.gd" id="1_rr"]
[ext_resource type="Script" path="res://scripts/UI.gd" id="2_ui"]
[ext_resource type="PackedScene" path="res://scenes/Jugador.tscn" id="3_player"]

[node name="Main" type="Node2D"]

[node name="SubViewportContainer" type="SubViewportContainer" parent="."]
stretch = true
stretch_mode = 2
stretch_aspect = 2
size = Vector2(1280, 720)

[node name="SubViewport" type="SubViewport" parent="SubViewportContainer"]
size = Vector2(256, 160)
render_target_update_mode = 3
transparent_bg = false

[node name="RoomTiles" type="Node2D" parent="SubViewportContainer/SubViewport"]
script = ExtResource("1_rr")

[node name="Player" parent="SubViewportContainer/SubViewport" instance=ExtResource("3_player")]
position = Vector2(128, 64)

[node name="UI" type="CanvasLayer" parent="."]
layer = 10

[node name="HourLabel" type="Label" parent="UI"]
offset_left = 10.0
offset_top = 10.0
offset_right = 300.0
offset_bottom = 30.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
text = "Hora: Prima"

[node name="Audio" type="AudioStreamPlayer" parent="."]
```

- [ ] **Step 2: Add UI.gd reference to HourLabel**

Read `scripts/UI.gd` to verify it references the correct node path. If it uses `get_node("Main/HoraLabel")`, update to `get_node("../UI/HoraLabel")` or use `get_tree().root.get_node("Main/UI/HoraLabel")`.

- [ ] **Step 3: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors, scene loads correctly

- [ ] **Step 4: Commit**

```bash
git add scenes/MainNew.tscn
git commit -m "feat: MainNew.tscn with SubViewportContainer at 256x160"
```

---

### Task 3: Rewrite Jugador.tscn for native coords

**Files:**
- Rewrite: `scenes/Jugador.tscn`

**Interfaces:**
- Consumes: guillermo_day.png (20×36 per frame, 4-dir × 4-frame)
- Produces: CharacterBody2D with AnimatedSprite2D, ready for Jugador.gd

- [ ] **Step 1: Rewrite Jugador.tscn**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Jugador.gd" id="1_script"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_col"]
size = Vector2(8, 12)

[node name="Jugador" type="CharacterBody2D"]
script = ExtResource("1_script")

[node name="Collision" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_col")

[node name="Camera" type="Camera2D" parent="."]
zoom = Vector2(1, 1)
position_smoothing_enabled = false
```

Note: AnimatedSprite2D is created in code by Jugador.gd `_setup_sprite()`.

- [ ] **Step 2: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add scenes/Jugador.tscn
git commit -m "feat: Jugador.tscn rebuilt for native CPC coords"
```

---

### Task 4: Rewrite Jugador.gd for native coords + animation

**Files:**
- Rewrite: `scripts/Jugador.gd`

**Interfaces:**
- Consumes: RoomRenderer.build_room(), RoomRenderer.get_room_at(), guillermo_day.png
- Produces: Player movement, walking animation, room transitions

- [ ] **Step 1: Rewrite Jugador.gd**

```gdscript
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
```

- [ ] **Step 2: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add scripts/Jugador.gd
git commit -m "feat: Jugador - native coords, 4-dir walking animation, room transitions"
```

---

### Task 5: Update project.godot to use MainNew

**Files:**
- Modify: `project.godot` (change main_scene to MainNew.tscn)

**Interfaces:**
- Consumes: MainNew.tscn
- Produces: Project runs MainNew scene on startup

- [ ] **Step 1: Update project.godot main scene**

Read `project.godot`, find `run/main_scene="res://scenes/Main.tscn"`, change to `run/main_scene="res://scenes/MainNew.tscn"`.

- [ ] **Step 2: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors, RoomRenderer initializes, room renders

- [ ] **Step 3: Commit**

```bash
git add project.godot
git commit -m "feat: switch main scene to MainNew.tscn"
```

---

### Task 6: Delete old files

**Files:**
- Delete: `scripts/TileRenderer.gd`
- Delete: `scripts/MapaPisos.gd`
- Delete: `scripts/AbbeyMap.gd`
- Delete: `scenes/MapaPisos.tscn`
- Delete: `scenes/Main.tscn` (old)

**Interfaces:**
- No new interfaces. Cleanup only.

- [ ] **Step 1: Verify no remaining references**

Run: `grep -r "TileRenderer\|MapaPisos\|AbbeyMap" --include="*.gd" --include="*.tscn" .`
Expected: No matches (all references removed in previous tasks)

- [ ] **Step 2: Delete old files**

```bash
git rm scripts/TileRenderer.gd scripts/MapaPisos.gd scripts/AbbeyMap.gd scenes/MapaPisos.tscn scenes/Main.tscn
```

- [ ] **Step 3: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: remove old TileRenderer, MapaPisos, AbbeyMap"
```

---

### Task 7: Visual verification and polish

**Files:**
- Modify: `scripts/RoomRenderer.gd` (if needed)
- Modify: `scripts/Jugador.gd` (if needed)

**Interfaces:**
- All previous tasks complete

- [ ] **Step 1: Run project visually**

Run project in Godot editor. Verify:
- Room fills viewport with teal background at edges
- Tiles render at correct size (each 16×8 native)
- Guillermo visible, correct size (~1.25 tiles wide, ~4.5 tiles tall)
- Walking animation plays on arrow keys
- Room transitions work at edges

- [ ] **Step 2: Fix any visual issues**

Adjust if needed:
- Player position offset
- Tile rendering order (z_index)
- Camera smoothing
- Background color (teal 0x008080)

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: SubViewport native CPC rendering complete"
```
