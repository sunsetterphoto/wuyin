# Wuyin: Das Lied des Phönix

Retro-Monster-RPG (HD-2D, chinesische Mythologie) mit lokalem Sprachmodell. Vollständiges Design: [docs/GDD.md](docs/GDD.md). Bei Widersprüchen gilt das GDD; Änderungen am Design zuerst dort eintragen.

Solo-Projekt von Samuel, entwickelt mit Claude Code. Antworten und Commit-Texte auf Deutsch, Code und Bezeichner auf Englisch.

## Grundregeln (gelten für jede Änderung)

1. Der Spielzustand lebt nur im Code. Das LLM liest Fakten, schreibt aber nie direkt Werte.
2. Jede LLM-Ausgabe läuft durch JSON-Schema oder Grammatik und danach durch einen Validator.
3. Jede LLM-Rolle hat Textvorlagen als Ersatz. Mit `llm_enabled = false` ist das Spiel vollständig spielbar.
4. Inhalte sind Daten: Lingshou, Attacken, Charakterkarten, Dialogvorlagen, Karten als JSON in `game/data/`, nicht im Code. Alle Texte über Übersetzungsschlüssel (en, de, zh-Hans).
5. Kein Pokémon-Vokabular in Code, Daten oder Texten: kein Pokéball, Pokédex, Arenaleiter, „Trainer“ als Titel, keine Namen auf „-mon“, kein Fangen mit Wurfobjekt (siehe GDD, Lizenzen und Rechte).
6. Spiellogik hat automatisierte Tests; Kampf und Zucht sind mit festem Zufallsstartwert reproduzierbar.
7. Plattformen von Anfang an: Android zuerst, Windows und Linux für Steam später, iOS optional; Touch, Controller und Tastatur.

## Begriffe

Lingshou (Geisttiere, nie „Monster“ im Spiel), Fengling (Windspiel), Yunhai (Welt), Ruf (Freitext-Befehl), Atem (Ressource für Rufe), Bindung (0–100), Gesinnung (frei, wild, verstummt, Schattenmotte), Herzklang-Leiste (Befreien von Verstummten).

## Repo

```
game/            Godot-4-Projekt (scenes/, scripts/, data/, assets/, tests/)
addons/llama/    GDExtension für llama.cpp
models/          GGUF-Dateien (Git LFS, nicht im Spielordner)
tools/comfyui/   Asset-Workflows (API-Format) und Aufrufskripte
tools/postprocess/  Python: Palette, Herunterskalieren, Spritesheets
tools/blender/   Skripte für Tiles und Kameratests
LICENSES.md      Lizenzen aller Modelle, LoRAs und Assets (bei jedem neuen Modell/Asset pflegen)
```

## Werkzeuge auf dieser Maschine

Mac Studio M1 Max, 64 GB. Lokale Skills nutzen statt Platzhaltern: `mac-studio-toolkit` (Übersicht), `comfyui` (Bilder, Musik, Video, 3D), `blender` (Tiles, Kameratests, Normal-Maps), `local-audio` (Brabbel-Klänge, Effekte), `local-llm` (Modelltests für Dialoge), `android-cli`.

- Godot 4.7.2 (`godot`, Export-Vorlagen installiert). Android-SDK: `$ANDROID_HOME` = `/opt/homebrew/share/android-commandlinetools`, NDK 30, Java 21 (`/opt/homebrew/opt/openjdk@21`).
- Prüfen: `tools/check.sh` (Tests + Boot), `tools/check.sh --export` (alle Presets nach `build/`), `tools/android_run.sh` (Emulator: installieren, starten, Boot-Marker, Screenshot nach `build/screens/`).
- Android-Emulator: eigenes AVD `wuyin_test` auf Port 5556 mit `-gpu host` starten (siehe Kopf von `tools/android_run.sh`) und danach mit `adb -s emulator-5556 emu kill` beenden. Den Emulator auf 5554 (`medium_phone`) nutzen andere Projekte, nicht anfassen. Im Emulator nur das Preset „Android Emulator“ (GLES3) verwenden, Vulkan zeigt dort schwarz. Latenz, Akku und Wärme nur auf echtem Gerät messen.
- Generierte Assets vor der Übernahme ansehen; Workflows mit festen Seeds in `tools/comfyui/` versionieren, Modell-Lizenzen in `LICENSES.md` eintragen.

## Arbeitsweise

- Meilensteine aus dem GDD (Abschnitt „Übergabe an Claude Code“) der Reihe nach; einer ist erst fertig, wenn alle Abnahmekriterien erfüllt und geprüft sind. Stand in [docs/PROGRESS.md](docs/PROGRESS.md) festhalten.
- Tests vor dem Abschluss eines Meilensteins headless ausführen.
