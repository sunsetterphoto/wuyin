# Beta „Kapitel 1“ (Ziel: auf dem S24 durchspielbar und bewertbar)

Auftrag von Samuel (2026-10-28): „eine komplett spielbare Beta, die ich auf dem S24 testen und bewerten kann“.
Umfang ist eine verkleinerte Fassung des Vertical Slice aus dem GDD (Phase 2): Prolog plus erste Region, etwa 45–90 Minuten.

## Inhalt

| Bereich | In der Beta | Bewusst nicht |
| --- | --- | --- |
| Story | Prolog „Die Stille fällt“ (Laternenfest, Jinli, Zähmen am Fluss, Wusheng nimmt dem Meister die Stimme), Bambusmeer bis zum Azurdrachen, erster Ton (Jue) kehrt zurück, Abschluss mit Bewertungsbogen | Akte 2–4, Enden |
| Karten | Weidendorf, Flussufer, Bambuspfad, Teeufer (Stadt), Reisterrassen, Drachenschrein | Innenräume (Türen öffnen Menüs), Reisemittel |
| Lingshou | 12 Arten, davon 10 zähmbar; Azurdrache (Boss), Schattenmotte (nicht zähmbar) | Wandlung, Zucht |
| Kampf | 1v1 wild, Yao als Rivale, Verstummte mit Herzklang-Leiste, Boss 2v2, Ruf, Stimmen, Niederlage → Unterkunft | Lehrmeister, Schriftrollen |
| Zähmen | Beruhigen, Füttern, Zureden (LLM ordnet den Satz einer Tonart zu, der Code bewertet nach Temperament), Vertrauen 0–100, Glöckchen am Windspiel | Hof und Gehege |
| Welt | Freies Laufen mit virtuellem Stick, NPCs, sichtbare Lingshou und hohes Gras, Jinli folgt und gibt Hinweise (LLM mit Vorlagen) | Spieluhr, Wetter |
| Stadt | Shop (Futter, Heilmittel), Unterkunft (heilen, speichern), Teehaus mit Gerücht aus Spielfakten (LLM, vorab erzeugt) | Restaurant, Bar-Aufgaben |
| System | Titel, Name und Aussehen (Farben), Speichern automatisch und manuell, Optionen (Sprache, Sprachmodell an/aus, HD-2D/2D, Textgeschwindigkeit), Feedback jederzeit im Menü, Melden-Knopf für KI-Texte | Erfolge, Barrierefreiheit über Textgröße hinaus |

## Rückmeldung

- Bewertungsbogen am Ende und jederzeit im Menü: Sterne pro Bereich plus Freitext → `user://feedback.jsonl`.
- KI-Texte melden (Google-Play-Vorgabe) → `user://reports.jsonl`.
- Spieltest-Log wie bisher → `user://playtest.jsonl`.
- Abholen: `tools/pull_feedback.sh` (adb, `run-as`).

## Stand 2026-10-28 (v0.1.0-beta)

Gebaut und auf dem S24 Ultra installiert. Alles oben unter „In der Beta“ ist umgesetzt.

**Technik:**
- Spielstand `GameState` (versioniertes JSON, `user://save_0.json`), automatisch bei Kartenwechsel, nach Kämpfen und wenn die App in den Hintergrund geht; manuell im Menü und in Unterkünften.
- Karten als JSON aus `tools/maps/build_maps.py`, Story und alle Texte (en/de/zh-Hans) aus `tools/story/chapter1.py`. Nur die erzeugten Dateien liest das Spiel.
- Ereignisse als Schrittlisten (`EventRunner`), Kampf als Überlagerung (`BattleView`), Zähmen im Prolog ohne Kampf (`BefriendView`).
- Neue LLM-Rollen: `tame_judge` (Tonart eines Satzes, Grammatik erzwingt ein Wort; Vertrauen rechnet der Code), `jinli_hint` (Untertitel für Jinlis Hinweis, Vorlage pro Aufgabe in drei Deutlichkeitsstufen), `rumor` (Teehaus, nur aus Spielfakten). Alle mit Vorlagen als Ersatz.
- Prüfen: `tools/check.sh` (Unit-Tests inkl. Karten, Ereignisse, Texte in allen Sprachen) und `godot --headless --path game -s res://tests/tools/autoplay_beta.gd` (spielt das ganze Kapitel automatisch durch und prüft alle Story-Flags).
- Bildschirmfotos aller Karten und Kämpfe: `godot --path game --resolution 1560x720 -s res://tests/tools/capture_beta.gd -- build/screens`.

**Gemessen auf dem S24 (am Kabel):** Oberwelt HD-2D 60 FPS bei 1560×720 intern; Zureden-Tonart 0,7 s; Ruf 1,5 s; Jinli-Hinweis 1,3–1,8 s.

**Autoplay-Bilanz:** Das Kapitel ist mit etwa 17 Kämpfen schaffbar (Stufen am Ende ca. 9–10), Boss 2 gegen 2 mit Befreiung des Azurdrachen.

**Bekannte Grenzen:** Figuren nur von vorn (keine Laufrichtungen), keine Innenräume, keine Spieluhr und kein Wetter, Chinesisch maschinennah formuliert, Pixel-Schrift fehlt (Systemschrift).

## Testen und Rückmeldung holen

- Auf dem Handy die App „Wuyin“ öffnen, „Neues Spiel“.
- Bewerten: im Menü (☰) „Beta bewerten“ oder am Ende des Kapitels. KI-Texte im Dialogfenster lassen sich mit ⚑ melden.
- Abholen am Mac: `tools/pull_feedback.sh` → `build/feedback/<Zeit>/`.
- Entwickler-Sprung zu einer Story-Stelle (nur Debug-Build): `adb shell run-as com.wuyin.game sh -c 'echo shrine > files/dev_jump.txt; echo res://scenes/dev/beta_jump.tscn > files/dev_autorun.txt'`, Stufen: river, bamboo, terraces, shrine.
