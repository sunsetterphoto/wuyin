# Asset-Nachbearbeitung (Phase-1-Experiment)

Generierte Bilder (ComfyUI, `tools/comfyui/`) werden hier spieltauglich gemacht.
Python aus der ComfyUI-Umgebung verwenden (Pillow + numpy):

```bash
PY=~/Documents/ComfyUI/.venv/bin/python
python3 ~/.claude/skills/comfyui/scripts/comfy.py start
python3 tools/comfyui/generate.py tools/comfyui/assets_phase1_test.json build/assets_raw
$PY tools/postprocess/pixelize.py sprite build/assets_raw/sprite_bambaer_00001_.png build/assets_px/bambaer.png --size 48
$PY tools/postprocess/pixelize.py tile build/assets_raw/tile_grass_00001_.png build/assets_px/tile_grass.png --size 32
$PY tools/postprocess/preview_sheet.py build/assets_px build/assets_px/px_sheet.png --sprites bambaer --tiles grass
```

- **Sprites:** weißen Hintergrund entfernen, lose Teile (< 20 % der Hauptfläche) verwerfen, zuschneiden, auf 48 px verkleinern, auf die Palette `palette_wuyin32.hex` reduzieren, harte Alpha-Kante, 1 px Umriss.
- **Tiles:** Ausschnitt (37,5 % des Bildes = eine Kachel), nahtlos machen (versetzte Kopie, weich überblendet), auf 32 px verkleinern, Palette; wenn weniger als 4 Farben übrig bleiben: Helligkeitsrampe aus der Farbfamilie.
- Erkenntnisse aus dem ersten Lauf (2026-10-28): Sprites wirken nach der Bearbeitung einheitlich. Weg-Textur wird zu orange (Rohbild zu warm), Steinmauer zeigt das Überblendmuster. Nächste Schritte: Palette pro Region, Prompts für Tiles schärfen, eventuell Pixel-Art-LoRA (Lizenz prüfen).

## Beta-Assets (2026-10-28)

Batch mit allen Prompts und Seeds: `tools/comfyui/beta_assets.json`. Bericht: `tools/comfyui/BETA_ASSETS.md`.

```bash
PY=~/Documents/ComfyUI/.venv/bin/python
python3 tools/comfyui/beta_generate.py                    # Rohbilder + Musik nach build/beta_raw/
$PY tools/postprocess/beta_postprocess.py                 # Sprites, Figuren, Hintergründe, Titel, Icon nach game/assets/
~/.unsloth/studio/unsloth_studio/bin/python tools/postprocess/beta_music.py   # Musik: trimmen, -16 LUFS, OGG Vorbis
python3 tools/postprocess/beta_vocal_check.py             # Whisper-Prüfung auf ungewollten Gesang
$PY tools/postprocess/beta_preview.py sprites             # build/beta_preview_sprites.png
$PY tools/postprocess/beta_preview.py backgrounds         # build/beta_preview_backgrounds.png
```

- `pixelize.py sprite ... --size 32 --height 48` erzeugt nicht-quadratische Figuren (Füße unten).
- Hintergründe: 320x180 mit eigener 64-Farben-Palette (leicht zur Wuyin-Palette gezogen), dann 2x Nearest auf 640x360.
- Die brew-ffmpeg hier hat kein libvorbis; OGG schreibt libsndfile (soundfile im Unsloth-venv), blockweise (ein großer Schreibaufruf stürzt ab).

## Umgebungs-Assets (2026-10-29)

Batch: `tools/comfyui/env_assets.json`, Bericht: `tools/comfyui/ENV_ASSETS.md`. Palette: `palette_env64.hex`
(die 32 Wuyin-Farben plus Türkis/Jade-Rampe, Gras- und Moosgrün, Erd- und Danxia-Rot, Schiefergrau, Wasser-Türkis,
Pastell, Schnee; 64 Farben).

```bash
PY=~/Documents/ComfyUI/.venv/bin/python
python3 tools/comfyui/env_generate.py props portraits       # Rohbilder nach build/env_raw/ (Tiles brauchen keine)
$PY tools/postprocess/env_postprocess.py                     # tiles, props, portraits nach game/assets/
$PY tools/postprocess/env_preview.py tiles                   # build/env_preview_tiles.png (3x3 gekachelt)
$PY tools/postprocess/env_preview.py props                   # build/env_preview_props.png (3x und 1x)
$PY tools/postprocess/env_preview.py portraits               # build/env_preview_portraits.png (mit Overworld-Sprite)
$PY tools/postprocess/env_preview.py scene                   # build/env_preview_scene.png (Probedorf)
```

- **Tiles** (64x64) malt `env_tiles_proc.py` prozedural: alle Rauschfelder, Voronoi-Zellen, Stempel und Reihen
  laufen über den Rand, daher nahtlos ohne Überblendung. Fester Seed je Tile.
- **Props und Porträts**: Hintergrund = Medianfarbe des Bildrands, alles Ähnliche mit Randkontakt wird
  transparent; Herunterskalieren mit vormultipliziertem Alpha (kein weißer Saum); k Cluster (Median-Cut) je Bild,
  jeder Cluster auf die nächste Palettenfarbe (CIE Lab, Helligkeit stärker gewichtet); Einzelpixel bekommen die
  häufigste Nachbarfarbe; 1-px-Umriss in Tinte (`1a1620`). Weiße Objekte werden auf blauem Grund erzeugt (`prop_key`).
