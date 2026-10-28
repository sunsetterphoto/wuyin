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
