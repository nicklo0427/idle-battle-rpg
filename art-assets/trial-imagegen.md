# Trial Image Generation Prep

This document prepares the 3-shot art trial for the current repo plan:

- `launch_bg.webp`
- `region_wildland.webp`
- `npc_blacksmith.webp`

The visual direction is a flat cartoon style (confirmed by user on 2026-05-04):

- flat design illustration, solid color shapes
- no outlines, no linework, no black stroke
- clean cartoon style, vibrant colors
- simple geometric shapes, minimal shading
- no photorealism, no text, no UI, no watermark, no gradients

## Verified environment

Checked from `/Users/lowhaijer/projects/idle-battle-rpg` on 2026-04-13:

- `python3` is available
- `uv` is not installed
- `PIL` is available
- `openai` is available in the active `python3` environment
- `OPENAI_API_KEY` is not set

`OPENAI_API_KEY` is only required for live image generation.
The dry-run commands below do not require `OPENAI_API_KEY` and have already been validated successfully.
Only the live generation step is currently blocked by the missing key.

## Prompt files

- `art-assets/prompts/launch_bg.txt`
- `art-assets/prompts/region_wildland.txt`
- `art-assets/prompts/npc_blacksmith.txt`

These files are already fully structured, so the CLI should be called with `--no-augment`.

## Common setup

```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export IMAGE_GEN="$CODEX_HOME/skills/imagegen/scripts/image_gen.py"
mkdir -p tmp/imagegen art-assets/generated
```

## Dry-run commands

These commands do not call the live image API and do not require `OPENAI_API_KEY`.

```bash
python3 "$IMAGE_GEN" generate \
  --prompt-file art-assets/prompts/launch_bg.txt \
  --no-augment \
  --size 1024x1536 \
  --quality high \
  --background opaque \
  --output-format webp \
  --output-compression 90 \
  --out tmp/imagegen/launch_bg.source.webp \
  --dry-run

python3 "$IMAGE_GEN" generate \
  --prompt-file art-assets/prompts/region_wildland.txt \
  --no-augment \
  --size 1536x1024 \
  --quality high \
  --background opaque \
  --output-format webp \
  --output-compression 90 \
  --out tmp/imagegen/region_wildland.source.webp \
  --dry-run

python3 "$IMAGE_GEN" generate \
  --prompt-file art-assets/prompts/npc_blacksmith.txt \
  --no-augment \
  --size 1024x1024 \
  --quality high \
  --background opaque \
  --output-format webp \
  --output-compression 90 \
  --out tmp/imagegen/npc_blacksmith.source.webp \
  --dry-run
```

## Live generation commands

Run these only after:

1. `OPENAI_API_KEY` is set
2. `openai` is installed for `python3`

Suggested install:

```bash
python3 -m pip install --user openai
```

Generation:

```bash
python3 "$IMAGE_GEN" generate \
  --prompt-file art-assets/prompts/launch_bg.txt \
  --no-augment \
  --size 1024x1536 \
  --quality high \
  --background opaque \
  --output-format webp \
  --output-compression 90 \
  --out tmp/imagegen/launch_bg.source.webp

python3 "$IMAGE_GEN" generate \
  --prompt-file art-assets/prompts/region_wildland.txt \
  --no-augment \
  --size 1536x1024 \
  --quality high \
  --background opaque \
  --output-format webp \
  --output-compression 90 \
  --out tmp/imagegen/region_wildland.source.webp

python3 "$IMAGE_GEN" generate \
  --prompt-file art-assets/prompts/npc_blacksmith.txt \
  --no-augment \
  --size 1024x1024 \
  --quality high \
  --background opaque \
  --output-format webp \
  --output-compression 90 \
  --out tmp/imagegen/npc_blacksmith.source.webp
```

## Final asset targets

Raw generation size and final delivery size differ, so the raw outputs should be post-processed before being treated as final assets.

- `launch_bg`: generate `1024x1536`, then center-crop to `708x1536`, then resize to `1290x2796`, save as `art-assets/generated/launch_bg.webp`
- `region_wildland`: generate `1536x1024`, then center-crop to `1536x768`, then resize to `240x120`, save as `art-assets/generated/region_wildland.webp`
- `npc_blacksmith`: generate `1024x1024`, then resize to `80x80`, save as `art-assets/generated/npc_blacksmith.webp`

## Review checklist

After live generation, check:

- correct subject for each image
- JRPG / anime game illustration feel with clean cel shading
- light adventure fantasy mood rather than dark fantasy
- region soul color is obvious
- `npc_blacksmith` reads clearly as a chibi blacksmith even at 80×80
- no text, no logos, no UI, no watermark
- final file format is `webp`
- final output sizes match the asset contract
