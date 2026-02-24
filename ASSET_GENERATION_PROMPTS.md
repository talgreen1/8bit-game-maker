# Asset Generation Prompts (Background + Character Sprites)

This project currently runs at:
- Internal resolution: `640x480` (4:3)
- Output/window: `1600x1200` (4:3)

Use this guide to generate:
- Forest background layers
- Character sprite sheet (for walk/run)

## 1) Background Art Spec

### Target files
- `sample_project/assets/bg/forest_layer_01_sky.png`
- `sample_project/assets/bg/forest_layer_02_far_trees.png`
- `sample_project/assets/bg/forest_layer_03_mid_trees.png`
- `sample_project/assets/bg/forest_layer_04_foreground.png`

### Required format
- PNG with transparency where needed
- Final size per layer: `640x480`
- Pixel-art style (no anti-aliasing)
- Side-view, camera locked, 2D game background

### Prompt (base)
Use this exact base prompt, then adjust layer notes per layer:

```text
2D pixel art forest background for a side-scrolling game, retro 16-bit look, clean readable silhouettes, high contrast depth separation, limited color palette, no text, no logos, no characters, no UI, no watermark, crisp pixel edges, orthographic side view, game-ready background layer
```

### Layer-specific add-ons
- Layer 01 sky:
```text
bright fantasy sky gradient, soft clouds only, very distant atmosphere, minimal detail
```
- Layer 02 far trees:
```text
distant pine forest silhouettes, desaturated greens, low contrast, sparse detail
```
- Layer 03 mid trees:
```text
midground tree trunks and leaf masses, medium contrast, readable shapes, moderate detail
```
- Layer 04 foreground:
```text
foreground bushes, grass clumps, rocks, high contrast, darkest values, transparent upper areas where possible
```

### Negative prompt
```text
blurry, smooth shading, painterly, photorealistic, 3D render, anti-aliased edges, text, logo, watermark, character, UI frame, perspective camera
```

## 2) Character Sprite Sheet Spec

### Target file
- `sample_project/assets/sprites/forest_hero_walk.png`

### Required format
- PNG, transparent background
- Side-view character facing right
- Frame size: `20x28` pixels
- 8 frames in one row (walk cycle)
- Sheet size: `160x28` pixels
- Consistent feet baseline across all frames

If generator cannot output exact size cleanly:
1. Generate larger pixel art (for example 5x scale).
2. Downscale with nearest-neighbor to exact frame size.

### Prompt (character)
```text
2D pixel art fantasy forest adventurer, side view facing right, full body, readable silhouette, simple tunic and boots, small backpack, 16-bit retro game style, walk cycle sprite sheet, 8 frames, consistent proportions, transparent background, crisp pixel edges, no text, no UI, no watermark
```

### Negative prompt
```text
front view, top-down, isometric, extra limbs, inconsistent face, blurry, anti-aliased, painterly, realistic shading, text, logo, watermark, background scene
```

## 3) Recommended Generator Settings

Use equivalents for your tool:
- Aspect ratio:
  - Background layers: `4:3`
  - Sprite sheet: custom ratio close to `160:28` (or generate larger then resize)
- Guidance/Prompt strength: medium-high
- Steps/Quality: medium-high
- Style: pixel art / retro game
- Seed: lock one seed per asset set for consistency

## 4) Consistency Rules

- Keep one shared palette across all forest layers and character.
- Light direction should stay consistent.
- Avoid noisy textures that flicker in motion/export.
- Keep character outline readable against darker forest tones.

## 5) JSON Integration Notes (current runtime)

Background layers can be used with parallax scene JSON:

```json
"background": {
  "type": "parallax",
  "layers": [
    {"image_path": "assets/bg/forest_layer_01_sky.png", "alpha": 1.0, "stretch": true},
    {"image_path": "assets/bg/forest_layer_02_far_trees.png", "alpha": 1.0, "stretch": true},
    {"image_path": "assets/bg/forest_layer_03_mid_trees.png", "alpha": 1.0, "stretch": true},
    {"image_path": "assets/bg/forest_layer_04_foreground.png", "alpha": 1.0, "stretch": true}
  ]
}
```

Current runtime uses color-generated actor frames from `animation.colors`.
If you want true sprite-sheet animation in runtime, next step is to extend `SceneRuntime.gd` to load frame regions from `forest_hero_walk.png`.

