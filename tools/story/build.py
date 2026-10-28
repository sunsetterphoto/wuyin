#!/usr/bin/env python3
"""Builds all story and content data of the game from the chapter modules:

  game/data/events/<chapter>.json   events per chapter
  game/data/npcs.json               people (name key, babble voice)
  game/data/i18n/story.csv          every text in en/de/zh-Hans
  game/data/{lingshou,moves,items,cards,farm}/   content (content.py)

The game reads only the generated files (rule 4).  python3 tools/story/build.py
"""
import csv, json, os, sys

sys.path.insert(0, os.path.dirname(__file__))
from common import ROOT, TEXT, NPCS  # noqa: E402
import content, systems, chapter1, chapter2, chapter3, chapter4  # noqa: E402

CHAPTERS = {"chapter1": chapter1, "chapter2": chapter2, "chapter3": chapter3, "chapter4": chapter4, "systems": systems}

content.write()
seen = {}
for name, mod in CHAPTERS.items():
    for eid in mod.E:
        assert eid not in seen, f"event {eid} in {name} and {seen[eid]}"
        seen[eid] = name
    with open(os.path.join(ROOT, "events", name + ".json"), "w") as f:
        json.dump({"note": f"Generiert von tools/story/{name}.py – dort bearbeiten.", "events": mod.E}, f, ensure_ascii=False, indent=1)
with open(os.path.join(ROOT, "npcs.json"), "w") as f:
    json.dump(NPCS, f, ensure_ascii=False, indent=1)
with open(os.path.join(ROOT, "i18n", "story.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["keys", "en", "de", "zh_Hans"])
    for k in sorted(TEXT):
        en, de, zh = TEXT[k]
        w.writerow([k, en, de, zh])
print(f"{len(seen)} events, {len(TEXT)} texts, {len(NPCS)} people")
