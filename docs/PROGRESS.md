# Fortschritt

## Phase 0: LLM-Prototyp

| Meilenstein | Stand | Notiz |
| --- | --- | --- |
| M0.1 Projektgerüst | fast fertig | Godot 4.7.2, Mobile-Renderer. Tests 3/3, Boot headless (macOS) ok. Exporte Android, Linux arm64/x86_64, Windows ok. Android-Emulator (AVD `wuyin_test`, GLES3-Preset) startet. **Offen:** Start unter Linux (Fedora-VM braucht Zugang), echtes Android-Gerät (Vulkan) |
| M0.2 Kampfkern | fertig | Kampf 1v1/2v2 nur Menü (`scripts/battle/`), Wu-Xing-Vorteil und Teambonus, Klang-Status (verstummt, Echo, Dissonanz, taub, Resonanz), Stufen 1–50 mit EP, 8 Lingshou und 20 Attacken als JSON, Texte en/de/zh-Hans. 36 Tests inkl. jedes Typvorteils und Reproduzierbarkeit per Startwert. Testkampf im Hauptmenü, auf Desktop und Emulator geprüft. |
| M0.3 LLM-Dienst | teilweise (Laufzeit-Entscheidung gefallen) | `LlmService` mit Rollen, Streaming, Grammatik/JSON-Schema, Zeitlimit 3 s und Rückfall auf Vorlagen; läuft ohne Modell. Backend für Desktop: `llama-server` per HTTP. **Offen:** llama.cpp als GDExtension im Spiel (Android), Latenz-Abnahme auf echtem Gerät |
| M0.4 Ruf | fertig (Desktop) | Ruf als Freitext oder vorgeschlagene Rufe zum Antippen, Übersetzer mit GBNF-Grammatik pro Zug, Validator, Stichwort-Vorlage als Rückfall, Gehorsamsprobe nach Bindung und Temperament, Situationsbonus vom Code geprüft (max. 15 %), Atem (3, +1 alle 3 Züge). 55 Testsätze (25 de, 25 en, 5 zh): 55/55 gültig mit Gemma 4 E2B und mit Vorlage; Absicht getroffen 53/55 (Modell) bzw. 39/55 (Vorlage). Spracheingabe fehlt noch |
| M0.5 Stimme | fertig (Desktop) | Charakterkarten für 8 Lingshou in en/de/zh-Hans (`data/cards/`), Stimme im Kampf gestreamt, Verstummte in Fragmenten. `TextGuard` prüft Länge pro Rolle (140 bzw. 48 Zeichen), Wortfilter, KI-Floskeln und Schrift (Chinesisch vs. Latein); sonst Vorlage nach Temperament und Ereignis (`data/templates/voice.json`). Rollen-Prioritäten: Ruf unterbricht laufende Stimme. Live mit Gemma 4 E2B: 350–600 ms je Satz |
| M0.6 Kameramodi | fertig (Desktop, Emulator) | Testkarte mit Blöcken und Billboard-Sprites (`scenes/world/test_map.tscn`), Umschaltung zur Laufzeit mit Kamerafahrt (Dolly-Zoom). HD-2D: Perspektive 38°, Tilt-Shift, Bloom, Schatten, Laternen, Glühwürmchen. Klassisch: orthografisch 60°, 640×360 ganzzahlig skaliert, Kamera auf Texel gerastert. Desktop (Mobile-Renderer) und Emulator (GLES3, ohne Tiefenunschärfe) je 60 FPS in beiden Modi. **Offen:** Messung auf echtem Gerät mit Vulkan |

## Entscheidungen

- 2026-10-27: Erst Emulator, echtes Testgerät später (Samuel). Latenz-Abnahme von M0.3 bleibt bis dahin offen.
- 2026-10-27: Eigener Testrunner (`game/tests/run_tests.gd`) statt Add-on, keine Fremdabhängigkeit.
- 2026-10-27: Android-Emulatoren auf dem Mac können Godots Vulkan-Ausgabe nicht anzeigen (schwarzer Bildschirm). Preset „Android Emulator“ setzt das Feature-Tag `emulator` und nutzt GLES3; das echte Android-Build bleibt bei Vulkan.
- 2026-10-27: Paketname vorläufig `com.wuyin.game`, vor dem Store-Eintrag festlegen.
- 2026-10-27: Schadensformel mit Wurzel aus Angriff/Verteidigung, `DAMAGE_SCALE` 0.4. Simulation (200 Kämpfe je Modus, KI gegen KI, Stufe 10): 1v1 Median 4 Züge, 2v2 mit je 3 Lingshou Median 7 Züge. Werkzeug: `game/tests/tools/balance_probe.gd`.
- 2026-10-27: Englische und chinesische Lingshou-Namen sind vorläufig (z. B. Wailamander, Bambear, Cinderfowl); Chinesisch muss von Muttersprachlern geprüft werden.
- 2026-10-27: Lingshou-JSON nutzt für `name` einen Übersetzungsschlüssel (`LS_*`) statt Klartext wie im GDD-Beispiel (Grundregel 4).
- 2026-10-28: Ruf-Übersetzer gibt nur Aktion, Ziel, Haltung und `fits_situation` aus, keinen Antwortsatz (wie noch im GDD-Beispiel). Grund: Latenz; der Satz kommt über die Rolle `lingshou_voice` gestreamt. GBNF-Grammatik statt JSON-Schema, weil sie kompakter ist und nur erlaubte Werte zulässt.
- 2026-10-28: Testmodell für die Entwicklung: Gemma 4 E2B (unsloth, Q4_K_XL, 3,2 GB) aus dem lokalen HF-Cache über `llama-server`. Lizenz laut Model-Card Apache 2.0 (korrigiert am 28.10.).
- 2026-10-28: Attacken haben ein `llm_hint` (nur für Prompts, nicht für Spieler), Lingshou eine Tierart als Übersetzungsschlüssel. Das hob die Trefferquote des Modells von 46/55 auf 53/55.
- 2026-10-28: Rollen haben Prioritäten (`data/llm/roles.json`); ein Ruf bricht eine laufende Stimme ab, die dann ihre Vorlage zeigt. Grund: ein Modell, eine Warteschlange; sonst verdoppelt sich die Ruf-Latenz.
- 2026-10-28: Ein Ruf, der mit dem Namen eines eigenen Lingshou beginnt, geht an dieses, wenn es in dem Zug noch einen Befehl braucht.
- 2026-10-28: Klassischer Modus nutzt 60° Neigung; Kachel-Oberseiten werden dadurch vertikal um ca. 13 % gestaucht. Für echte 1:1-Texel wäre eine oblique Projektion nötig; Entscheidung in Phase 1 mit echten Tiles.
- 2026-10-28: Platzhalter-Pixelgrafik wird im Code erzeugt (`scripts/world/pixel_art.gd`); die Asset-Pipeline mit ComfyUI folgt in Phase 1.

## Messungen M0.3 auf dem Samsung Galaxy S24 Ultra (28.10. nachts)

Snapdragon 8 Gen 3, 12 GB, Android 16, am Ladekabel, Gehäuse 37–45 °C. Messwerkzeug: `llama-bench` (llama.cpp v0.7.0, selbst gebaut mit NDK 30, `-march=armv8.7a`) und die Dev-Szenen `scenes/dev/llm_perf.tscn` und `llm_bench.tscn`.

| Laufzeit / Modell (6 Threads, CPU) | Prompt Tok/s | Generierung Tok/s |
| --- | --- | --- |
| NobodyWho 12.1 + Gemma 4 E2B UD-Q4_K_XL | 22 | 9 |
| llama.cpp direkt + Gemma 4 E2B UD-Q4_K_XL (3,2 GB) | 66–84 | 17–20 |
| llama.cpp direkt + **Gemma 4 E2B QAT UD-Q4_K_XL (2,6 GB)** | **169** | **26** |
| llama.cpp direkt + Qwen3-1.7B Q4_K_M | 149 | 35 |
| llama.cpp direkt + Qwen3-0.6B Q4_K_M | 396 | 96 |

Qualität Ruf-Übersetzer (Absicht getroffen; Hauptsatz 55 / neue Prüfsätze 20, Mac):

| Modell | Hauptsatz | Prüfsätze |
| --- | --- | --- |
| Gemma 4 E2B QAT | 54/55 | 20/20 (17/20 vor Ergänzung allgemeiner Synonyme) |
| Gemma 4 E2B | 54/55 | 19/20 |
| Qwen3-1.7B | 51/55 | 10/20 |
| Qwen3.5-2B | 54/55 | nicht gemessen (Cache-Problem, s. u.) |
| nur Vorlage | 41/55 | 8/20 |

- 2026-10-28: **NobodyWho ist funktional ausreichend** (Grammatik pro Anfrage, Streaming, Abbruch, Android arm64), auf Android aber 3× langsamer beim Prompt und 2× beim Generieren als direkt gebautes llama.cpp; nicht einstellbar. Dazu 140 MB Bibliothek. **Entscheidung: eigene GDExtension** (laut Samuel: „Wenn es zu beschränkt ist, nutzen wir eine eigen gebaute GDExtension“).
- 2026-10-28: **Modell: Gemma 4 E2B QAT UD-Q4_K_XL** (Apache 2.0, 2,6 GB). Beste Verallgemeinerung auf neue Formulierungen, auf ARM doppelt so schnell wie die normale Q4-Version.
- 2026-10-28: Qwen3.5 (Hybridmodell) kann in llama.cpp den Prompt-Cache nicht teilweise kürzen und rechnet jeden Ruf komplett neu; ungeeignet.
- 2026-10-28: Qwen3-1.7B ist schnell, versteht neue Formulierungen aber schlecht (10/20) – die guten Werte im Hauptsatz kamen vor allem aus den Stichwortregeln.
- 2026-10-28: Die 20 Prüfsätze (`data/llm/eval/call_sentences_holdout.json`) wurden einmal zur Ergänzung allgemeiner Synonyme (Freund/buddy, ausruhen/rest) genutzt; für künftige ehrliche Messungen einen neuen Satz schreiben.
- 2026-10-28: Thermik: Am Ladekabel kühlt das S24 kaum unter 37 °C; ab 38 °C Gehäuse drosselt Samsung. Akkutest ohne Kabel steht aus.
