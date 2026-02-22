# Repository Guidelines

## Project Structure & Module Organization
This repository currently contains planning documents and no source code yet.
- `8_bit_music_clip_maker_godot_app_plan.md`: product and architecture plan
- `EXECUTION_PLAN.md`: milestone breakdown
- `README.md`: short project overview

When implementation starts, expect a standard Godot layout (e.g., `res://scenes/`, `res://scripts/`, `res://assets/`). Please keep new files under a clear top-level folder and update this section when the structure changes.

## Build, Test, and Development Commands
No build/test automation is defined yet.
- Run the project from the Godot editor once the Godot project is created.
- If you add CLI tooling (e.g., `godot --headless`, export scripts, or formatters), document exact commands here with examples.

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
