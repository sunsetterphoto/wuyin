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
