# Room Viewer Panel Design — La Abadía del Crimen

## Overview

Add a right-side panel to the interactive map with floor/room navigation controls and an element slider for progressive painting, replicating the room viewer at https://visor.abadiadelcrimenextensum.com/

## Architecture

### Scene Tree

```
Main (HSplitContainer)
├── LeftPanel (VBoxContainer) — 70% width
│   └── SubViewportContainer
│       └── SubViewport (256×160)
│           ├── RoomTiles (RoomRenderer)
│           └── Player (Jugador)
├── RightPanel (VBoxContainer) — 30% width
│   ├── FloorPlan (CanvasItem) — 256×224 mini floor map
│   ├── Controls (VBoxContainer)
│   │   ├── FloorSelect (OptionButton)
│   │   ├── RoomInput (LineEdit)
│   │   └── GoButton (Button)
│   └── Info (Label)
└── BottomBar (VBoxContainer)
    ├── ElementSlider (HBoxContainer)
    │   ├── Label "Elementos"
    │   ├── Slider (0 → max_blocks)
    │   └── Label "X/Y"
    └── StatusBar (Label)
```

### Components

#### 1. Floor Plan Canvas (256×224)

- Renders the current floor's room grid as a mini map
- Each room is a colored rectangle (tan for walkable, dark for empty)
- Current room highlighted in red
- Click on a room → navigates to that room
- Updates when floor changes

**Implementation:** `FloorPlan.gd` extends `Control`, draws using `_draw()` method with `draw_rect()` for each room.

#### 2. Floor Selector

- `OptionButton` with 3 items: Iglesia (0), Scriptorium (1), Biblioteca (2)
- On change: updates floor plan, re-renders current room if floor changed

#### 3. Room Input

- `LineEdit` for room number (0-115)
- `Button` "Ir a habitación"
- On click: parses number, validates, navigates to room

#### 4. Element Slider

- `HSlider` with range 0 → max_blocks (per room)
- Default value: max_blocks (all elements visible)
- On change: re-renders room with only that many blocks
- Label shows "X/Y" (current/total)

**Implementation:** `RoomRenderer.gd` gets new method `build_room_partial(fl, rx, ry, max_elements)` that only executes the first N blocks.

#### 5. Status Bar

- Label: "Habitación: X — Elementos: Y — Planta Z"
- Updates on room/floor change

### Data Flow

```
User clicks floor plan / changes floor selector / enters room number
    → FloorPlan.gd / Controls.gd emits signal
    → Main.gd receives signal
    → RoomRenderer.build_room(fl, rx, ry) called
    → FloorPlan redraws with new current room
    → Status bar updates
    → Player repositioned to room center

User moves element slider
    → Slider value_changed signal
    → RoomRenderer.build_room_partial(fl, rx, ry, slider_value) called
    → Only N blocks rendered
```

### Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `scripts/FloorPlan.gd` | Create | Floor plan canvas with click navigation |
| `scripts/Main.gd` | Rewrite | Layout management, signal handling |
| `scripts/RoomRenderer.gd` | Modify | Add `build_room_partial()`, store blocks |
| `scenes/MainNew.tscn` | Rewrite | HSplitContainer layout with all components |

### Visual Design

- Dark background (matching visor: #1a1a2e or similar)
- Tan/brown rooms on floor plan (#c4a882)
- Red highlight for current room (#ff4444)
- Teal background for SubViewport (existing)
- Panel width: ~300px (resizable via HSplitContainer)

### Constraints

- Godot 4.7, GDScript
- Tab indentation, no comments unless requested
- SubViewport remains 256×160 (native CPC)
- Player keyboard movement continues to work
- Room transitions at edges still function
- Element slider only affects rendering, not collision

## Success Criteria

1. Right panel shows floor plan with clickable rooms
2. Floor selector switches between Iglesia/Scriptorium/Biblioteca
3. Room input navigates to specific room
4. Element slider progressively reveals room blocks
5. Player can still walk and transition between rooms
6. Layout matches the reference visor design
