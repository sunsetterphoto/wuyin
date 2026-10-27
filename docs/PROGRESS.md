# Fortschritt

## Phase 0: LLM-Prototyp

| Meilenstein | Stand | Notiz |
| --- | --- | --- |
| M0.1 Projektgerüst | fast fertig | Godot 4.7.2, Mobile-Renderer. Tests 3/3, Boot headless (macOS) ok. Exporte Android, Linux arm64/x86_64, Windows ok. Android-Emulator (AVD `wuyin_test`, GLES3-Preset) startet. **Offen:** Start unter Linux (Fedora-VM braucht Zugang), echtes Android-Gerät (Vulkan) |
| M0.2 Kampfkern | fertig | Kampf 1v1/2v2 nur Menü (`scripts/battle/`), Wu-Xing-Vorteil und Teambonus, Klang-Status (verstummt, Echo, Dissonanz, taub, Resonanz), Stufen 1–50 mit EP, 8 Lingshou und 20 Attacken als JSON, Texte en/de/zh-Hans. 36 Tests inkl. jedes Typvorteils und Reproduzierbarkeit per Startwert. Testkampf im Hauptmenü, auf Desktop und Emulator geprüft. |
| M0.3 LLM-Dienst | teilweise | `LlmService` mit Rollen, Streaming, Grammatik/JSON-Schema, Zeitlimit 3 s und Rückfall auf Vorlagen; läuft ohne Modell. Backend für Desktop: `llama-server` per HTTP. **Offen:** llama.cpp als GDExtension im Spiel (Android), Latenz-Abnahme auf echtem Gerät |
| M0.4 Ruf | fertig (Desktop) | Ruf als Freitext oder vorgeschlagene Rufe zum Antippen, Übersetzer mit GBNF-Grammatik pro Zug, Validator, Stichwort-Vorlage als Rückfall, Gehorsamsprobe nach Bindung und Temperament, Situationsbonus vom Code geprüft (max. 15 %), Atem (3, +1 alle 3 Züge). 55 Testsätze (25 de, 25 en, 5 zh): 55/55 gültig mit Gemma 4 E2B und mit Vorlage; Absicht getroffen 53/55 (Modell) bzw. 39/55 (Vorlage). Spracheingabe fehlt noch |
| M0.5 Stimme | offen | |
| M0.6 Kameramodi | offen | |

## Entscheidungen

- 2026-10-27: Erst Emulator, echtes Testgerät später (Samuel). Latenz-Abnahme von M0.3 bleibt bis dahin offen.
- 2026-10-27: Eigener Testrunner (`game/tests/run_tests.gd`) statt Add-on, keine Fremdabhängigkeit.
- 2026-10-27: Android-Emulatoren auf dem Mac können Godots Vulkan-Ausgabe nicht anzeigen (schwarzer Bildschirm). Preset „Android Emulator“ setzt das Feature-Tag `emulator` und nutzt GLES3; das echte Android-Build bleibt bei Vulkan.
- 2026-10-27: Paketname vorläufig `com.wuyin.game`, vor dem Store-Eintrag festlegen.
- 2026-10-27: Schadensformel mit Wurzel aus Angriff/Verteidigung, `DAMAGE_SCALE` 0.4. Simulation (200 Kämpfe je Modus, KI gegen KI, Stufe 10): 1v1 Median 4 Züge, 2v2 mit je 3 Lingshou Median 7 Züge. Werkzeug: `game/tests/tools/balance_probe.gd`.
- 2026-10-27: Englische und chinesische Lingshou-Namen sind vorläufig (z. B. Wailamander, Bambear, Cinderfowl); Chinesisch muss von Muttersprachlern geprüft werden.
- 2026-10-27: Lingshou-JSON nutzt für `name` einen Übersetzungsschlüssel (`LS_*`) statt Klartext wie im GDD-Beispiel (Grundregel 4).
- 2026-10-28: Ruf-Übersetzer gibt nur Aktion, Ziel, Haltung und `fits_situation` aus, keinen Antwortsatz (wie noch im GDD-Beispiel). Grund: Latenz; der Satz kommt über die Rolle `lingshou_voice` gestreamt. GBNF-Grammatik statt JSON-Schema, weil sie kompakter ist und nur erlaubte Werte zulässt.
- 2026-10-28: Testmodell für die Entwicklung: Gemma 4 E2B (unsloth, Q4_K_XL, 3,2 GB) aus dem lokalen HF-Cache über `llama-server`. Lizenz (Gemma Terms) vor Auslieferung prüfen; Kandidaten mit Apache 2.0 vergleichen.
- 2026-10-28: Attacken haben ein `llm_hint` (nur für Prompts, nicht für Spieler), Lingshou eine Tierart als Übersetzungsschlüssel. Das hob die Trefferquote des Modells von 46/55 auf 53/55.
