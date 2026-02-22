# Repository Guidelines

## Project Structure & Module Organization
This repository contains planning docs plus an initial Godot 4 milestone scaffold.
- `project.godot`: Godot project config
- `scenes/`: app scene(s), currently `App.tscn`
- `scripts/models/`: JSON models (`ProjectModel`, `SceneModel`)
- `scripts/runtime/`: runtime systems (`PlaybackClock`, `TimelineController`, `SceneRuntime`)
- `sample_project/`: minimal project + scene JSON used for validation
- `8_bit_music_clip_maker_godot_app_plan.md`: product and architecture plan
- `EXECUTION_PLAN.md`: milestone breakdown

## Build, Test, and Development Commands
No test automation is defined yet.
- Run from editor: open folder in Godot 4.x and run `res://scenes/App.tscn`.
- Optional CLI run (if Godot CLI is installed): `godot4 --path .`
- Optional headless smoke check: `godot4 --headless --path . --quit`

## Coding Style & Naming Conventions
Target runtime is Godot 4.x with GDScript.
- Indentation: 2 spaces in Markdown, 4 spaces (or tabs) in GDScript per Godot defaults.
- Naming: `PascalCase` for classes/files, `snake_case` for variables/functions, and `SCREAMING_SNAKE_CASE` for constants.
- Prefer explicit, short names that match plan terminology (`ProjectModel`, `SceneRuntime`, `TimelineController`).

## Testing Guidelines
No tests are defined yet.
- When tests are added, document the framework and how to run them.
- Name tests to match the unit under test (e.g., `test_project_model_load.gd`).

## Commit & Pull Request Guidelines
Recent commits use short, imperative messages such as “Add …” and “Delete …”.
- Follow that pattern and keep messages scoped to one change.
- PRs should include a brief summary, list of changes, and a note on how to validate (or why no validation applies). Screenshots are recommended for UI changes.

## Agent-Specific Notes
If you introduce new tools, scripts, or project settings, update this file so future contributors and agents can follow the same workflow.
