# 8-bit Music Clip Maker (Godot) — Full Solution Plan

## 1) Project purpose
Create a desktop app that helps you make **music video clips that look like classic pixel/8-bit games** (inspired by retro platformers/shooters/ RPGs **without copying any copyrighted IP**).

The app will let you:
- Import a song.
- Build a **timeline of scenes** (you decide exactly what happens; no audio analysis required).
- For each scene, place **backgrounds / tilemaps / parallax layers**, characters, props, camera moves, and effects.
- Preview in real-time.
- Export a final **MP4 video with audio**.
- Reuse templates and asset packs across many songs.

Non-goals (v1):
- Automated beat detection / audio-driven choreography.
- A fully-featured game editor. This is a **video scene editor** with game-like rendering.

---

## 2) High-level design

### Core concept
Treat every clip as a **"recording" of a tiny scripted 2D pixel scene**.

You author:
- Scene blocks on a timeline
- Key actions per scene

The app does:
- Rendering (pixel-perfect)
- Playback synchronized to audio time
- Video export

### Main user mental model
- **Project** = one song + timeline + asset references.
- **Scene** = a shot (forest run, bedroom sleep, city rain, etc.).
- **Actors** = sprites that can animate and move.
- **Background** = tilemap and/or parallax layers.

---

## 3) Tech stack

### Engine / language
- **Godot 4.x (stable)**
- **GDScript** for most code (fast iteration)
- Optionally **C#** if you prefer stricter typing; v1 can be GDScript-only.

### Video export
Use one of these approaches (recommended order):
1. **Frame sequence export (PNG)** from Godot + **FFmpeg** encode to MP4.
2. Optional later: direct FFmpeg piping / integration.

Why frame sequence first?
- Maximum reliability
- Easy to debug
- Works on any machine with FFmpeg installed

### Storage formats
- Project file: **JSON** (human-editable)
- Asset packs: folder structure + JSON metadata

---

## 4) Pixel rendering rules ("style bible")
Lock these early to keep all outputs consistent.

Recommended defaults:
- Internal render resolution: **320×180 (16:9)**
- Output scale: **6×** (final frames 1920×1080)
- Filter mode: **Nearest-neighbor** only
- Tile size: **16×16**
- Character base size: **32×32** (or 48×48 if you want more detail)
- Palette discipline: per-scene 16–32 colors (optional but helps)

Godot settings:
- Project Settings → Rendering → Textures → Default Texture Filter = **Nearest**
- Use a **Viewport** at internal resolution, then scale up.

---

## 5) App architecture

### 5.1 Main subsystems
1. **Project Manager**
   - Create/open/save projects
   - Manage relative paths to assets

2. **Timeline / Playback Engine**
   - Master clock driven by audio time
   - Activates scenes and keyframes

3. **Scene Composer**
   - Loads a scene definition
   - Instantiates background layers, actors, props

4. **Renderer / Preview**
   - Pixel-perfect viewport
   - Scene switching and transitions

5. **Exporter**
   - Deterministic frame stepping
   - Writes PNG frames
   - Calls FFmpeg to mux audio and encode MP4

6. **Asset Library**
   - Browser for characters, tilesets, backgrounds
   - Imports metadata

---

## 6) Data model (recommended JSON)

### 6.1 Project file structure
```
MySongProject/
  project.json
  audio/song.wav
  scenes/
    scene_001.json
    scene_002.json
  exports/
  assets/   (optional local copies or symlinks)
```

### 6.2 project.json (example)
```json
{
  "project_name": "Lonely Runner",
  "fps": 60,
  "internal_resolution": [320, 180],
  "output_resolution": [1920, 1080],
  "audio_path": "audio/song.wav",
  "timeline": [
    {"scene_id": "scene_001", "start": 0.0, "duration": 18.0, "transition_out": "cut"},
    {"scene_id": "scene_002", "start": 18.0, "duration": 20.0, "transition_out": "fade"}
  ]
}
```

### 6.3 scene_###.json (example)
```json
{
  "scene_name": "Forest Run",
  "background": {
    "type": "parallax",
    "layers": [
      {"path": "packs/forest/layer_0_sky.png", "speed": 0.05},
      {"path": "packs/forest/layer_1_far_trees.png", "speed": 0.15},
      {"path": "packs/forest/layer_2_mid_trees.png", "speed": 0.35},
      {"path": "packs/forest/layer_3_near.png", "speed": 0.60}
    ]
  },
  "actors": [
    {
      "id": "boy",
      "sprite_sheet": "packs/characters/boy.png",
      "animations": {
        "run": {"frames": [0,1,2,3,4,5,6,7], "fps": 10, "loop": true},
        "idle": {"frames": [8,9,10,11], "fps": 6, "loop": true}
      },
      "initial": {"pos": [40, 135], "scale": 1, "anim": "run", "flip_h": false},
      "tracks": [
        {"t": 0.0, "type": "move_to", "to": [220, 135], "seconds": 18.0}
      ]
    }
  ],
  "camera": {
    "mode": "follow",
    "target": "boy",
    "deadzone": [40, 20],
    "zoom": 1.0
  },
  "effects": [
    {"type": "crt", "strength": 0.2},
    {"type": "scanlines", "strength": 0.3}
  ]
}
```

---

## 7) Main classes (Godot nodes / scripts)

### 7.1 Project layer
- **ProjectModel**
  - Fields: name, fps, resolutions, audio path, timeline entries
  - Methods: load/save, validate, resolve asset paths

- **SceneModel**
  - Fields: background, actors, camera, effects
  - Methods: load/save, validate

### 7.2 Runtime / playback
- **PlaybackClock**
  - Source of truth: audio playback time
  - Methods: play/pause/seek, get_time()

- **TimelineController**
  - Holds ordered timeline entries
  - Chooses active scene for time t
  - Handles transitions

- **SceneRuntime**
  - Instantiated from SceneModel
  - Spawns nodes for background/actors/camera
  - Applies keyframes / tracks over local time

- **ActorNode**
  - Wraps AnimatedSprite2D / SpriteFrames
  - Applies movement tracks
  - Properties: anchor point (feet), z-index, flip, tint

### 7.3 Editing UI
- **AssetBrowserPanel**
  - Lists asset packs, previews sprites

- **TimelinePanel**
  - Scene blocks, drag to change start/duration

- **SceneEditorPanel**
  - Canvas view with selection/move/resize
  - Inspector for properties

- **InspectorPanel**
  - Edits JSON-like properties for selected item

### 7.4 Export
- **ExportController**
  - Deterministic frame stepping
  - Renders each frame to image
  - Writes PNG sequence
  - Calls FFmpeg to encode

---

## 8) Workflow (end-to-end)

### 8.1 One-time setup (your “studio setup”)
1. Decide your style bible (resolution, tile size, character size, palette rules).
2. Create a few **asset packs**:
   - Forest pack (parallax or tileset)
   - Bedroom pack
   - City/night pack
   - Main character pack (boy)
3. Create 2–3 **scene templates** (runner, calm bedroom, rain city).

### 8.2 Creating a clip for a song
1. **New Project**
   - Set FPS (60 recommended)
   - Set internal/output resolution
   - Import audio (prefer WAV for stability)

2. **Build Timeline**
   - Add Scene blocks (start time + duration)
   - Choose transitions (cut/fade/wipe)

3. **Design each Scene**
   - Choose background type:
     - Parallax (cinematic)
     - Tilemap (game-authentic)
   - Add actors:
     - Choose character sprite sheet
     - Choose animation state (run/sleep/etc.)
     - Place on stage
   - Add tracks:
     - Move A→B
     - Loop run cycle
     - Camera follow / pan
     - Add props & effects

4. **Preview**
   - Play with audio
   - Scrub timeline
   - Tweak durations and transitions

5. **Export**
   - Choose output path
   - Export PNG sequence
   - Encode MP4 with FFmpeg + mux audio

### 8.3 Scaling to many songs
- Reuse templates: duplicate project, swap audio, adjust scenes.
- Reuse asset packs: consistent art style across your channel.
- Keep a library of common scenes: “forest run”, “bedroom calm”, “rooftop night”, etc.

---

## 9) Export details (reliable method)

### 9.1 Deterministic frame rendering
For export, do NOT rely on real-time playback.
- For frame i:
  - t = i / fps
  - Seek audio to t (or use t only for visuals and mux audio later)
  - Force update scene to time t
  - Render viewport to image

### 9.2 FFmpeg command (example)
- Input: `frames/frame_%06d.png` at 60fps
- Audio: `song.wav`
- Output: `final.mp4`

Keep it configurable in app settings.

---

## 10) Asset packs: backgrounds & characters

### 10.1 Asset pack folder structure
```
Packs/
  Characters/
    Boy_01/
      pack.json
      spritesheet.png
      preview.png
  Backgrounds/
    Forest_Parallax_01/
      pack.json
      layer_0.png
      layer_1.png
      layer_2.png
      layer_3.png
    Bedroom_01/
      pack.json
      background.png
  Tilesets/
    Forest_Tiles_01/
      pack.json
      tileset.png
      rules.json (optional)
```

### 10.2 pack.json (character example)
```json
{
  "type": "character",
  "name": "Boy_01",
  "frame_size": [32, 32],
  "anchor": [16, 30],
  "animations": {
    "idle": {"row": 0, "frames": 6, "fps": 6, "loop": true},
    "run": {"row": 1, "frames": 8, "fps": 10, "loop": true},
    "sleep": {"row": 2, "frames": 4, "fps": 4, "loop": true}
  }
}
```

### 10.3 pack.json (parallax background example)
```json
{
  "type": "parallax_background",
  "name": "Forest_Parallax_01",
  "resolution": [320, 180],
  "layers": [
    {"file": "layer_0.png", "speed": 0.05},
    {"file": "layer_1.png", "speed": 0.15},
    {"file": "layer_2.png", "speed": 0.35},
    {"file": "layer_3.png", "speed": 0.60}
  ]
}
```

---

## 11) Detailed guidelines for creating characters (sprite sheets)

### 11.1 Pick a standard
To be consistent across songs, choose:
- **Frame size** (e.g., 32×32)
- **Perspective**: side-view platformer OR top-down (don’t mix inside one universe unless intentional)
- **Outline rule**: always outline OR never
- **Palette discipline**: per-character 8–16 colors is common

### 11.2 Animation checklist (minimum viable)
For a main character in your clips:
- Idle (4–6 frames)
- Run (6–8 frames)
- Jump (2–4 frames)
- Fall (1–2 frames)
- Sleep / lie down (3–4 frames)
- Optional emotions: sad, happy, surprised (2–4 frames each)

### 11.3 Timing rules (looks “game authentic”)
- Idle: 4–7 fps
- Run: 8–12 fps
- Small loops are fine; classic games often use 4–8 frames.

### 11.4 Anchor / feet placement
Define one anchor point per character:
- For side view: anchor is at the **feet contact point**.
- Keep that anchor consistent across frames to prevent jitter.

### 11.5 Sprite sheet layout recommendation
Simple layout that works with any tool:
- One row per animation
- Same frame size per cell
- Transparent background

Example layout:
- Row 0: idle frames
- Row 1: run frames
- Row 2: jump frames
- Row 3: sleep frames

### 11.6 Quality checks
- Readability at 1× internal scale (320×180 preview)
- No anti-aliasing blur
- Consistent line thickness
- No stray semi-transparent pixels

---

## 12) Detailed guidelines for creating backgrounds

### 12.1 Two supported background types

#### A) Parallax backgrounds (fast, cinematic)
Create 3–6 PNG layers at internal resolution (or wider for scrolling).
- Layer 0: sky / far gradient
- Layer 1: far silhouettes
- Layer 2: mid trees/buildings
- Layer 3: near trees/foreground
- Optional overlay: fog, rain, light rays

Rules:
- Far layers move slower.
- Use strong silhouette separation for depth.

#### B) Tilemap backgrounds (most game-like)
Create a tileset PNG with fixed tile size (usually 16×16).
Then build maps using Godot TileMap.

Rules:
- Keep tiles readable; avoid noisy textures.
- Make edges tile seamlessly.
- Include: ground tiles, platform edges, decorative props.

### 12.2 Scene readability rules
- Keep horizon / ground clear.
- Use contrast: character must stand out.
- Avoid excessive detail behind the character.

---

## 13) LLM-ready prompting guide (use with any future model)
The goal: reliably generate assets that fit your style bible.

### 13.1 Always include these constraints
Include in every prompt:
- Pixel art style + nearest neighbor look
- Exact frame size (characters) or resolution (background)
- Tile size if making tilesets
- Perspective (side view/top down)
- Palette limits (optional)
- Transparent background for sprites
- “Original character, not from any existing franchise”

### 13.2 Character prompt template
Use this when generating a **sprite sheet**.

**Prompt skeleton:**
- “Create an original pixel-art character sprite sheet.”
- “Frame size: 32×32 pixels per frame.”
- “Transparent background.”
- “Rows are animations; columns are frames.”
- “Row 1: idle (6 frames). Row 2: run (8 frames). Row 3: sleep (4 frames).”
- “Consistent anchor at feet across frames.”
- “Limited palette (max 16 colors), no anti-aliasing.”
- “Side-view platformer style.”
- “Original design, not resembling any existing character.”

**Add your art direction:**
- Age, outfit, mood, props, silhouette notes.

### 13.3 Background prompt template (parallax)
**Prompt skeleton:**
- “Create a parallax pixel-art background pack.”
- “Resolution per layer: 320×180.”
- “Provide 4 layers: sky, far trees, mid trees, near foreground.”
- “Layers should loop seamlessly horizontally (tileable).”
- “Night / sunset / rainy mood (choose).”
- “Limited palette, no anti-aliasing, crisp pixels.”

### 13.4 Tileset prompt template
**Prompt skeleton:**
- “Create a pixel-art tileset PNG.”
- “Tile size: 16×16.”
- “Grid layout, clean tile edges.”
- “Include ground, platform edges, tree trunks, foliage, rocks, small props.”
- “Style consistent with 32×32 character.”

### 13.5 Post-generation checklist (always do this)
Even with good prompts, you’ll often need quick cleanup:
- Remove blur / anti-aliasing
- Enforce exact sizes
- Reduce palette consistently
- Verify transparency
- Verify loop seams for parallax layers

Tools for cleanup:
- Aseprite (best)
- LibreSprite / Piskel (free)
- ImageMagick / simple scripts for resizing with nearest-neighbor

---

## 14) IP and originality guardrails
To stay safe:
- Do not request “Mario”, “Nintendo”, or “use Mario sprites.”
- Avoid near-identical silhouettes, enemies, tiles, or fonts from famous games.
- Ask for “retro platformer vibe” with original characters.

---

## 15) Development roadmap

### Milestone 1 (MVP)
- Load audio
- Timeline with scene blocks
- Scene editor: add background + one actor + simple move track
- Preview playback synced to audio time
- Export PNG frames + FFmpeg MP4

### Milestone 2 (Usability)
- Asset browser + pack import
- Scene templates
- Transitions (fade/wipe)
- Camera modes (static/follow/pan)

### Milestone 3 (Production features)
- Props library
- Particle effects (rain, dust)
- Color grading/palette filters
- Batch export

---

## 16) How you use the system for a real song (example)
1. Create Project “Song A”, import `song.wav`.
2. Add timeline blocks:
   - 0:00–0:18 Forest Run
   - 0:18–0:35 Bedroom Sleep
   - 0:35–0:55 Rain City
3. For each scene:
   - Choose a background pack
   - Choose character pack
   - Set animation + movement tracks
   - Set camera mode
4. Preview and adjust durations.
5. Export MP4.

---

## 17) Recommended next step
Choose your fixed style bible values now:
- Internal resolution: 320×180 (recommended)
- Tile size: 16×16
- Character frame: 32×32
- Outline: yes/no
- Palette discipline: strict/loose

Once those are set, you can generate your first reusable packs:
- `Boy_01` character pack
- `Forest_Parallax_01`
- `Bedroom_01`

