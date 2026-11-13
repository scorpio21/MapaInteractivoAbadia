# Design: SubViewport Native CPC Rendering

## Goal

Replicate the room viewer (visor.abadiadelcrimenextensum.com) rendering approach in Godot 4.7 — pixel-perfect isometric rooms at native CPC resolution (256×160), scaled up with nearest-neighbor filtering.

## Problem

Current implementation has:
- Double scaling: tiles at SCALE=4 + Camera zoom=4x = effective 16x
- Player sprite too small (scale 0.5 at native coords)
- No walking animation
- Room doesn't fill viewport correctly

## Architecture

### Rendering Pipeline

```
scripts.abs + floors.json + rooms.json
        ↓
ScriptInterpreter.parse_scripts()
        ↓
ScriptInterpreter.execute_block() → tile_buffer[16][20]
        ↓
SubViewport (256×160 px, native resolution)
  ├── Tiles: Sprite2D at (x*16, y*8), texture from tiles_day.png
  ├── Player: AnimatedSprite2D at native coords (20×36 px)
  └── Camera2D: zoom = Vector2(1, 1)
        ↓
SubViewportContainer (scaled to window)
  └── texture_filter = TEXTURE_FILTER_NEAREST
```

### Coordinate System

All coordinates are in **native CPC pixels**:
- Tile size: 16×8 px
- Room: 16 tiles × 16 tiles = 256×128 px
- Buffer: 16×20 tiles = 256×160 px (extra 4 rows for wall decorations)
- Screen offset: SCREEN_OFFSET_X = 0 (room fills viewport horizontally)

Position formulas:
- Tile (x, y) → pixel (x * 16, y * 8)
- Room center → (128, 64)
- Player collision: 8×12 px (centered at feet)

### Scene Tree

```
Main (Node2D)
├── SubViewportContainer (fullscreen, stretch)
│   └── SubViewport (256×160, DISABLE_3D, NO_CLEAR_COLOR)
│       ├── RoomTiles (Node2D) — holds tile sprites
│       ├── Player (CharacterBody2D)
│       │   ├── AnimatedSprite2D (guillermo_day.png, 4-dir walk)
│       │   ├── CollisionShape2D (RectangleShape2D 8×12)
│       │   └── Camera2D (zoom 1,0)
│       └── UI (CanvasLayer) — canonical hour display
└── AudioStreamPlayer
```

### Components

#### RoomRenderer (replaces TileRenderer + MapaPisos)

Responsibilities:
- Parse scripts.abs via ScriptInterpreter
- Maintain tile_buffer[16][20] per room
- Create/update Sprite2D nodes for each tile
- Cache interpreted rooms (Dictionary: room_id → buffer copy)
- Clear and rebuild on room change

Key method:
```gdscript
func build_room(floor: int, room_x: int, room_y: int) -> void
```

#### Player (replaces Jugador)

Responsibilities:
- Movement at native pixel speed (~50 px/s = ~3 tiles/s)
- 4-direction walking animation (AnimatedSprite2D)
- Room transition detection (tile_x < 0 or > 15, tile_y < 0 or > 15)
- Collision with walls (via tile buffer depth data)

Sprite format (from monk.json):
- walk_{south,west,north,east}_{0-3}
- Each frame: 20×36 px from guillermo_day.png
- 4 directions × 4 frames = 16 frames total

#### SubViewportContainer

- Size: fullscreen
- Stretch mode: STRETCH_MODE_CANVAS_CONTAIN
- Stretch aspect: STRETCH_ASPECT_KEEP_WIDTH
- texture_filter: TEXTURE_FILTER_NEAREST (pixel-perfect)

### Data Flow

1. `_ready()` → parse scripts.abs, build initial room
2. `build_room()` → clear old tiles, execute blocks, create new tiles
3. `_physics_process()` → move player, check room transitions
4. Room transition → update room_x/room_y, call build_room()

### Room Transitions

When player tile position goes out of bounds:
- tile_x < 0 → move to room_x - 1, tile_x = 15
- tile_x > 15 → move to room_x + 1, tile_x = 0
- tile_y < 0 → move to room_y - 1, tile_y = 15
- tile_y > 15 → move to room_y + 1, tile_y = 0

Validate new room exists via floors_data grid before transitioning.

### What Stays the Same

- ScriptInterpreter.gd — already works (32,207 sprites, 0 errors)
- data/scripts.abs, data/floors.json, data/rooms.json
- assets/tiles_day.png (256 tiles, 16×8 each)
- assets/sprites/guillermo_day.png (4-dir × 4-frame)
- Reloj.gd (canonical hour system)
- UI.gd (hour display)

### What Gets Deleted/Replaced

- TileRenderer.gd → replaced by simpler RoomRenderer
- MapaPisos.gd → merged into RoomRenderer
- Jugador.tscn → rebuilt with AnimatedSprite2D
- Jugador.gd → rewritten for native coords + animation

### Testing

1. Headless: `godot --headless --quit-after 5` — 0 errors
2. Visual: room fills viewport, teal background visible at edges
3. Player: walking animation plays, correct size relative to tiles
4. Transitions: walking to room edge switches room
5. Performance: maintain 60fps with ~500 sprites per room

## Open Questions

- Should the UI layer be inside or outside the SubViewport?
  → Outside (CanvasLayer on Main) — UI should not scale with room
- Camera bounds: should Camera be clamped to room boundaries?
  → No — camera follows player, room fills viewport (no scrolling needed)
