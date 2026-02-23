# 8-bit Music Clip Maker (Godot)

Milestones 1 and 2 are implemented as a Godot 4 project.

## Run
- Open this repository folder in Godot 4.x.
- Run the main scene (`res://scenes/App.tscn`).

The app loads `res://sample_project/project.json` and provides:
- `ProjectModel` / `SceneModel` JSON loading + validation
- `PlaybackClock` play/pause/seek/time flow
- `TimelineController` active-scene selection
- `SceneRuntime` static background + single animated actor
- Internal render viewport (`320x180`) preview
- Editing UI panels:
  - `ProjectPanel`: open/save project path
  - `TimelinePanel`: add/remove timeline blocks, edit start/duration, scrub time
  - `SceneEditorPanel`: edit actor position
  - `InspectorPanel`: edit background color, actor velocity, and camera mode

## Current structure
- `project.godot`: Godot project config and render settings
- `scenes/`: main scene(s)
- `scripts/models/`: project/scene data models
- `scripts/runtime/`: playback/timeline/runtime code
- `scripts/ui/`: milestone 2 editor panels
- `sample_project/`: minimal JSON sample project and scene
- `tools/smoke_test.ps1`: CLI smoke test script
