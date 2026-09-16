# Room Viewer Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a right-side panel with floor/room navigation and element slider to the interactive map, replicating the room viewer design.

**Architecture:** HSplitContainer splits screen into left (SubViewportContainer with room+player) and right (floor plan + controls). Bottom bar has element slider and status. FloorPlan.gd draws clickable room grid. RoomRenderer.gd gets partial rendering support.

**Tech Stack:** Godot 4.7, GDScript, SubViewportContainer, Control nodes, CanvasItem._draw()

## Global Constraints

- Godot 4.7, GDScript
- Tab indentation, no comments unless requested
- SubViewport remains 256×160 (native CPC)
- Player keyboard movement continues to work
- Room transitions at edges still function
- Element slider only affects rendering, not collision

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `scripts/FloorPlan.gd` | Floor plan canvas with click navigation |
| Rewrite | `scripts/Main.gd` | Layout management, signal handling |
| Modify | `scripts/RoomRenderer.gd` | Add `build_room_partial()`, store blocks |
| Rewrite | `scenes/MainNew.tscn` | HSplitContainer layout with all components |

---

### Task 1: Add partial rendering to RoomRenderer

**Files:**
- Modify: `scripts/RoomRenderer.gd`

**Interfaces:**
- Consumes: existing `build_room(fl, rx, ry)` method
- Produces: `build_room_partial(fl, rx, ry, max_elements)` — renders only N blocks, `get_block_count(fl, rx, ry)` — returns total blocks

- [ ] **Step 1: Add block storage to RoomRenderer**

Add new property to store room blocks:

```gdscript
var current_blocks: Array = []
```

- [ ] **Step 2: Store blocks in build_room**

Modify `build_room()` to store blocks after executing:

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

	var room = rooms_data[room_id - 1]
	current_blocks = room.get("blocks", [])
	_render_blocks(current_blocks.size())
	print("Room %d at (%d,%d): rendered" % [room_id, rx, ry])
```

- [ ] **Step 3: Extract rendering to _render_blocks method**

```gdscript
func _render_blocks(max_elements: int) -> void:
	_clear_sprites()
	if current_blocks.size() == 0:
		return
	interpreter.clear_tile_buffer()
	var count = mini(max_elements, current_blocks.size())
	for i in range(count):
		interpreter.execute_block(current_blocks[i])
	var buffer = interpreter.get_tile_buffer()
	_render_buffer(buffer)
```

- [ ] **Step 4: Add build_room_partial method**

```gdscript
func build_room_partial(fl: int, rx: int, ry: int, max_elements: int) -> void:
	if fl != current_floor or rx != current_room_x or ry != current_room_y:
		current_floor = fl
		current_room_x = rx
		current_room_y = ry
		if fl >= floors_data.size():
			return
		var room_grid = floors_data[fl].get("room", [])
		if ry >= room_grid.size() or rx >= room_grid[ry].size():
			return
		var room_id = room_grid[ry][rx]
		if room_id < 1 or room_id > rooms_data.size():
			return
		current_blocks = rooms_data[room_id - 1].get("blocks", [])
	_render_blocks(max_elements)
```

- [ ] **Step 5: Add get_block_count method**

```gdscript
func get_block_count() -> int:
	return current_blocks.size()
```

- [ ] **Step 6: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors, "Room 40 at (8,1): rendered"

- [ ] **Step 7: Commit**

```bash
git add scripts/RoomRenderer.gd
git commit -m "feat: RoomRenderer - partial rendering support for element slider"
```

---

### Task 2: Create FloorPlan.gd

**Files:**
- Create: `scripts/FloorPlan.gd`

**Interfaces:**
- Consumes: floors_data from RoomRenderer, current floor/room
- Produces: `room_selected` signal(rx, ry), `setup(floors, current_fl, current_rx, current_ry)`, `update_floor(fl)`, `update_room(rx, ry)`

- [ ] **Step 1: Create FloorPlan.gd with setup**

```gdscript
extends Control
class_name FloorPlan

signal room_selected(rx: int, ry: int)

const ROOM_COLOR = Color(0.769, 0.659, 0.510)
const EMPTY_COLOR = Color(0.102, 0.102, 0.180)
const CURRENT_COLOR = Color(1.0, 0.267, 0.267)
const BORDER_COLOR = Color(0.2, 0.2, 0.2)

var floors_data: Array = []
var current_floor: int = 0
var current_rx: int = 0
var current_ry: int = 0
var room_rects: Array = []

func setup(floors: Array, fl: int, rx: int, ry: int) -> void:
	floors_data = floors
	current_floor = fl
	current_rx = rx
	current_ry = ry
	queue_redraw()

func update_floor(fl: int) -> void:
	current_floor = fl
	queue_redraw()

func update_room(rx: int, ry: int) -> void:
	current_rx = rx
	current_ry = ry
	queue_redraw()
```

- [ ] **Step 2: Add _draw method**

```gdscript
func _draw() -> void:
	room_rects.clear()
	if current_floor >= floors_data.size():
		return
	var room_grid = floors_data[current_floor].get("room", [])
	if room_grid.size() == 0:
		return
	var rows = room_grid.size()
	var cols = room_grid[0].size()
	var cell_w = size.x / cols
	var cell_h = size.y / rows
	for ry in range(rows):
		for rx in range(cols):
			var room_id = room_grid[ry][rx]
			var rect = Rect2(rx * cell_w, ry * cell_h, cell_w - 1, cell_h - 1)
			room_rects.append({"rect": rect, "rx": rx, "ry": ry})
			var color = ROOM_COLOR if room_id > 0 else EMPTY_COLOR
			if rx == current_rx and ry == current_ry:
				color = CURRENT_COLOR
			draw_rect(rect, color)
			draw_rect(rect, BORDER_COLOR, false, 1.0)
```

- [ ] **Step 3: Add _gui_input for click detection**

```gdscript
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = event.position
		for room_data in room_rects:
			if room_data["rect"].has_point(click_pos):
				room_selected.emit(room_data["rx"], room_data["ry"])
				break
```

- [ ] **Step 4: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors

- [ ] **Step 5: Commit**

```bash
git add scripts/FloorPlan.gd
git commit -m "feat: FloorPlan - clickable floor plan canvas"
```

---

### Task 3: Rewrite MainNew.tscn with HSplitContainer layout

**Files:**
- Rewrite: `scenes/MainNew.tscn`

**Interfaces:**
- Consumes: FloorPlan.gd, RoomRenderer.gd, Jugador.tscn, UI.gd
- Produces: Full layout with left panel, right panel, bottom bar

- [ ] **Step 1: Create MainNew.tscn**

```
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/RoomRenderer.gd" id="1_rr"]
[ext_resource type="Script" path="res://scripts/UI.gd" id="2_ui"]
[ext_resource type="PackedScene" path="res://scenes/Jugador.tscn" id="3_player"]
[ext_resource type="Script" path="res://scripts/Main.gd" id="4_main"]
[ext_resource type="Script" path="res://scripts/FloorPlan.gd" id="5_fp"]

[node name="Main" type="HSplitContainer"]
script = ExtResource("4_main")
split_offset = 900

[node name="LeftPanel" type="VBoxContainer" parent="."]
custom_minimum_size = Vector2(800, 0)
size_flags_horizontal = 3

[node name="SubViewportContainer" type="SubViewportContainer" parent="LeftPanel"]
custom_minimum_size = Vector2(800, 600)
size_flags_vertical = 3
stretch = true
stretch_mode = 2
stretch_aspect = 0

[node name="SubViewport" type="SubViewport" parent="LeftPanel/SubViewportContainer"]
size = Vector2(256, 160)
render_target_update_mode = 3
transparent_bg = false

[node name="RoomTiles" type="Node2D" parent="LeftPanel/SubViewportContainer/SubViewport"]
script = ExtResource("1_rr")

[node name="Player" parent="LeftPanel/SubViewportContainer/SubViewport" instance=ExtResource("3_player")]
position = Vector2(128, 64)

[node name="RightPanel" type="VBoxContainer" parent="."]
custom_minimum_size = Vector2(300, 0)
size_flags_horizontal = 3

[node name="FloorPlan" type="Control" parent="RightPanel"]
custom_minimum_size = Vector2(280, 224)
size_flags_horizontal = 3
script = ExtResource("5_fp")

[node name="Controls" type="VBoxContainer" parent="RightPanel"]
custom_minimum_size = Vector2(280, 0)
size_flags_horizontal = 3

[node name="FloorLabel" type="Label" parent="RightPanel/Controls"]
text = "Planta:"

[node name="FloorSelect" type="OptionButton" parent="RightPanel/Controls"]
item_count = 3
popup/item_0 = "Iglesia"
popup/item_1 = "Scriptorium"
popup/item_2 = "Biblioteca"

[node name="RoomLabel" type="Label" parent="RightPanel/Controls"]
text = "Habitación:"

[node name="RoomInput" type="LineEdit" parent="RightPanel/Controls"]
placeholder_text = "0-115"

[node name="GoButton" type="Button" parent="RightPanel/Controls"]
text = "Ir a habitación"

[node name="Info" type="Label" parent="RightPanel"]
custom_minimum_size = Vector2(280, 0)
text = "Habitación: 0 — Elementos: 0 — Iglesia"

[node name="BottomBar" type="VBoxContainer" parent="."]
custom_minimum_size = Vector2(0, 80)

[node name="ElementSlider" type="HBoxContainer" parent="BottomBar"]

[node name="SliderLabel" type="Label" parent="BottomBar/ElementSlider"]
text = "Elementos"

[node name="Slider" type="HSlider" parent="BottomBar/ElementSlider"]
custom_minimum_size = Vector2(200, 0)
size_flags_horizontal = 3
min_value = 0.0
max_value = 32.0
value = 32.0

[node name="SliderValue" type="Label" parent="BottomBar/ElementSlider"]
text = "32/32"

[node name="StatusBar" type="Label" parent="BottomBar"]
text = "Habitación: 0 — Elementos: 0 — Iglesia"

[node name="UI" type="CanvasLayer" parent="."]
layer = 10
visible = false

[node name="Audio" type="AudioStreamPlayer" parent="."]
```

- [ ] **Step 2: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add scenes/MainNew.tscn
git commit -m "feat: MainNew.tscn - HSplitContainer layout with panels"
```

---

### Task 4: Rewrite Main.gd for layout management

**Files:**
- Rewrite: `scripts/Main.gd`

**Interfaces:**
- Consumes: RoomRenderer.build_room(), RoomRenderer.build_room_partial(), RoomRenderer.get_block_count(), FloorPlan signals
- Produces: Coordinates all components, handles signals

- [ ] **Step 1: Rewrite Main.gd**

```gdscript
extends HSplitContainer

var floor_plan: FloorPlan
var room_renderer: RoomRenderer
var floor_select: OptionButton
var room_input: LineEdit
var go_button: Button
var info_label: Label
var slider: HSlider
var slider_value_label: Label
var status_label: Label
var player: CharacterBody2D

const FLOOR_NAMES = ["Iglesia", "Scriptorium", "Biblioteca"]

func _ready() -> void:
	floor_plan = $RightPanel/FloorPlan
	room_renderer = $LeftPanel/SubViewportContainer/SubViewport/RoomTiles
	floor_select = $RightPanel/Controls/FloorSelect
	room_input = $RightPanel/Controls/RoomInput
	go_button = $RightPanel/Controls/GoButton
	info_label = $RightPanel/Info
	slider = $BottomBar/ElementSlider/Slider
	slider_value_label = $BottomBar/ElementSlider/SliderValue
	status_label = $BottomBar/StatusBar
	player = $LeftPanel/SubViewportContainer/SubViewport/Player

	floor_plan.setup(room_renderer.floors_data, 0, 8, 1)
	floor_plan.room_selected.connect(_on_room_selected)
	floor_select.item_selected.connect(_on_floor_selected)
	go_button.pressed.connect(_on_go_pressed)
	slider.value_changed.connect(_on_slider_changed)

	_update_ui()

func _on_room_selected(rx: int, ry: int) -> void:
	var fl = floor_select.selected
	room_renderer.build_room(fl, rx, ry)
	floor_plan.update_room(rx, ry)
	_position_player()
	_update_ui()

func _on_floor_selected(index: int) -> void:
	floor_plan.update_floor(index)
	_update_ui()

func _on_go_pressed() -> void:
	var room_num = room_input.text.to_int()
	if room_num < 0 or room_num > 115:
		return
	var fl = floor_select.selected
	var room_grid = room_renderer.floors_data[fl].get("room", [])
	for ry in range(room_grid.size()):
		for rx in range(room_grid[ry].size()):
			if room_grid[ry][rx] == room_num:
				room_renderer.build_room(fl, rx, ry)
				floor_plan.update_room(rx, ry)
				_position_player()
				_update_ui()
				return

func _on_slider_changed(value: float) -> void:
	var fl = floor_select.selected
	room_renderer.build_room_partial(fl, room_renderer.current_room_x, room_renderer.current_room_y, int(value))
	slider_value_label.text = "%d/%d" % [int(value), room_renderer.get_block_count()]

func _position_player() -> void:
	player.position = Vector2(8 * 16, 8 * 8)

func _update_ui() -> void:
	var fl = floor_select.selected
	var rx = room_renderer.current_room_x
	var ry = room_renderer.current_room_y
	var room_grid = room_renderer.floors_data[fl].get("room", [])
	var room_id = 0
	if ry >= 0 and ry < room_grid.size() and rx >= 0 and rx < room_grid[ry].size():
		room_id = room_grid[ry][rx]
	var block_count = room_renderer.get_block_count()
	slider.max_value = block_count
	slider.value = block_count
	slider_value_label.text = "%d/%d" % [block_count, block_count]
	var text = "Habitación: %d — Elementos: %d — %s" % [room_id, block_count, FLOOR_NAMES[fl]]
	info_label.text = text
	status_label.text = text
```

- [ ] **Step 2: Run headless test**

Run: `& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path "I:\MapaInteractivoAbadia" --quit-after 5`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add scripts/Main.gd
git commit -m "feat: Main.gd - layout management, signal handling, UI updates"
```

---

### Task 5: Verify and polish

**Files:**
- Modify: scripts as needed for visual fixes

**Interfaces:**
- All previous tasks complete

- [ ] **Step 1: Run project visually**

Run project in Godot editor. Verify:
- HSplitContainer divides screen correctly
- Floor plan shows rooms as colored rectangles
- Clicking a room navigates to it
- Floor selector switches floor plan
- Room input + Go button navigates to room
- Element slider progressively reveals blocks
- Player can still walk with arrow keys
- Room transitions work at edges
- Status bar updates correctly

- [ ] **Step 2: Fix any visual issues**

Adjust colors, sizes, spacing as needed.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: Room Viewer Panel complete with floor plan and element slider"
```
