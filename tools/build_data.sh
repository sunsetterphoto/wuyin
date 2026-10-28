#!/bin/zsh
# Rebuilds all generated game data (maps, story, content, texts) and reimports
# the translation CSVs so Godot sees the new texts.
set -e
cd "${0:A:h}/.."
python3 tools/maps/build_maps.py
python3 tools/story/build.py
godot --headless --path game --import >/dev/null 2>&1 || true
