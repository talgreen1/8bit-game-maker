# 8-bit Music Clip Maker — Execution Plan

This document turns the product plan into an implementation roadmap for the repository.

## Assumptions
- Godot 4.x, desktop-first.
- GDScript for v1.
- Export pipeline uses PNG frame sequences + FFmpeg.
- Project and scene definitions are JSON as described in `8_bit_music_clip_maker_godot_app_plan.md`.

## Milestone 1 — Core Runtime (MVP Foundation)
Goal: Load a project, play a timeline, and render a basic scene with pixel-accurate output.

Deliverables
- Godot project structure and main scene.
- JSON models for project and scenes.
- Playback clock synced to audio time.
- Timeline controller that activates scenes based on time.
- Scene runtime that instantiates a background and one actor.
- Internal-resolution viewport with nearest-neighbor scaling.

Tasks
- Create `res://scenes/App.tscn` and set as main scene.
- Implement `ProjectModel` and `SceneModel`:
  - `load(path)`, `save(path)`
  - validation for required fields
  - resolve asset paths relative to project
- Implement `PlaybackClock`:
  - `play()`, `pause()`, `seek(t)`
  - `get_time()` returns audio time
- Implement `TimelineController`:
  - manage ordered timeline entries
  - determine active scene for `t`
- Implement `SceneRuntime`:
  - load background (parallax or static)
  - spawn a single actor with an animation
- Add a fixed internal-resolution `Viewport` scaled to output size.
- Validate with a minimal sample project JSON.

Verification
- Open project JSON and see a scene render in the viewport.
- Playback aligns with audio time in preview.
- Pixel art remains crisp at output scale.

Assets needed
- Optional. You can use placeholder textures; real assets can be added later.

## Milestone 2 — Editing UI (MVP Usability)
Goal: Let a user create and edit timelines and scene elements without manual JSON edits.

Deliverables
- Basic project browser (create/open/save).
- Timeline panel with scene blocks.
- Scene editor canvas for selecting/moving an actor.
- Inspector panel to edit key properties.

Tasks
- `ProjectPanel`: create/open/save project files.
- `TimelinePanel`:
  - add/remove scene blocks
  - set start/duration
  - scrub time
- `SceneEditorPanel`:
  - display active scene
  - select and move actor
- `InspectorPanel`:
  - edit position, animation, camera mode
- Bind UI to `ProjectModel` and `SceneModel`.

Verification
- User can add scenes, set durations, and adjust actor position from UI.
- Timeline scrub updates the viewport correctly.

Assets needed
- Optional but recommended for real testing.

## Milestone 3 — Export Pipeline (MVP Completion)
Goal: Deterministic export to PNG frame sequences and MP4 with audio.

Deliverables
- Frame-step export controller.
- PNG writer to `exports/frames`.
- FFmpeg invocation to encode MP4.
- Export settings UI.

Tasks
- Implement `ExportController`:
  - for each frame `i`: `t = i / fps`
  - update scene to time `t`
  - render and save PNG
- Add export settings:
  - output path
  - FPS
  - resolution
  - FFmpeg path/args
- Implement FFmpeg command builder.

Verification
- PNG frame sequence renders at correct resolution.
- MP4 contains synced audio and video.

Assets needed
- Recommended for meaningful exports.

## Milestone 4 — Asset Packs + Templates
Goal: Reusable asset packs and scene templates for fast production.

Deliverables
- Asset pack registry and loader.
- Asset browser UI with previews.
- Scene templates and duplication.

Tasks
- Define pack schema for characters, parallax backgrounds, tilesets.
- Implement `PackRegistry` to scan folders and parse `pack.json`.
- Asset browser UI with filters and previews.
- Scene template system:
  - save current scene as template
  - create scene from template

Verification
- Packs load without errors and show previews.
- Templates create ready-to-edit scenes.

Assets needed
- Yes. At least one character pack and one background pack.

## Milestone 5 — Quality and Polish
Goal: Production-ready features and visual polish.

Deliverables
- Scene transitions (cut, fade, wipe).
- Camera modes (static, follow, pan).
- Optional effects (CRT, scanlines).
- Guardrails that enforce style-bible settings.

Tasks
- Add transition system to timeline.
- Implement camera controller with modes and deadzones.
- Add post-process effects via shaders.
- Enforce project-level resolution and filter settings.

Verification
- Consistent output style across scenes.
- Clean transitions and stable camera behavior.

Assets needed
- Recommended for real-world output.

## Risks and Mitigations
- Audio sync drift: use deterministic frame stepping during export.
- FFmpeg availability: allow user to configure executable path and show errors.
- Asset pack inconsistencies: validate required files and metadata on load.

## Acceptance Criteria (MVP)
- Load and preview a project with audio.
- Edit timeline and scene elements via UI.
- Export MP4 with synced audio.
- Pixel-perfect output at defined internal and output resolutions.
