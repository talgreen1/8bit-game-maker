# 8-bit Music Clip Maker (Godot)

Milestone 1 implementation is now scaffolded as a Godot 4 project.

## Run
- Open this repository folder in Godot 4.x.
- Run the main scene (`res://scenes/App.tscn`).

The app loads `res://sample_project/project.json` and renders a basic scene with:
- `ProjectModel` / `SceneModel` JSON loading + validation
- `PlaybackClock` play/pause/seek/time flow
- `TimelineController` active-scene selection
- `SceneRuntime` static background + single animated actor
- Internal render viewport (`320x180`) scaled in a container

## Current structure
- `project.godot`: Godot project config and render settings
- `scenes/`: main scene(s)
- `scripts/models/`: project/scene data models
- `scripts/runtime/`: playback/timeline/runtime code
- `sample_project/`: minimal JSON sample project and scene
