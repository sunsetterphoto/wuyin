# Wuyin – Version 0.9 (Vollversion zum Testen)

Stand 29.10.2026. Das ganze Spiel ist von Anfang bis Ende spielbar: Prolog, vier Akte, fünf Regionen, drei Enden.

## Was drin ist

| Bereich | Inhalt |
| --- | --- |
| Geschichte | Prolog in Weidendorf, Akt 1 Bambusmeer (Azurdrache, Ton Jue), Akt 2 Nebelfluss und Regenbogengrat in beliebiger Reihenfolge (Xuanwu, Bifang), Akt 3 Meister Lu spricht wieder, Nian greift Weidendorf an, Yao tritt dem Orden bei, Singende Dünen und Wolkensäulen in beliebiger Reihenfolge (Baihu, Qilin), Akt 4 Phönixtempel mit Wusheng, seinem Kranich und dem Nian |
| Enden | Versöhnung (Wusheng überzeugt und der Kranich singt), Sieg (Wusheng besiegt), Bittere Stille (mehr Verstummte besiegt als befreit; die Dünen bleiben still und lassen sich nach dem Abspann befreien) |
| Orte | 21 Außenkarten, 30 begehbare Innenräume (Gasthäuser, Läden, Teehäuser, Restaurants, Zuhause, Werkstatt, Wohnhäuser, Halle der Stille), Hof mit bis zu 16 Gehegen |
| Lingshou | 36 Arten: 5 Himmelswächter, Phönix, Nian, Schattenmotte, Silberkranich, 5 Mischformen nur aus der Zucht |
| Systeme | Zähmen, Befreien, Ruf (Freitext), Überreden (Logik, Mitgefühl, Beweis, Bestechung, Drohung), Spieluhr mit Tag und Nacht, Wetter pro Region, Schnellreise mit dem Windspiel, Restaurant-Gerichte, Hof mit Ausbau, Gehegen, Zufriedenheit, Zucht, Farbvarianten, Hoftagebuch, Lexikon, Weltkarte, neue Attacken per Stufe, Fahrrad, Boot |
| Grafik | HD-2D: chinesische Häuser mit geschwungenen Dächern, Terrassen und Treppen, Pflanzen im Wind, Wasser mit Uferschaum, Wolkenschatten, Glühwürmchen, Blätter, Blüten, Nebel, Glut; klassischer 2D-Modus in den Optionen |
| Klang | Musik pro Region (gedämpft, solange die Region verstummt ist), Geräuschkulisse aus Wind, Vögeln, Wasser und Grillen (in stillen Regionen: nichts), Brabbel-Stimmen |
| Sprachmodell | Gemma 4 E2B auf dem Handy: Rufe, Stimmen der Lingshou, Jinlis Hinweise, Gerüchte, Zureden, Überreden, Hoftagebuch. Alles hat Vorlagen, das Spiel läuft auch ohne Modell |

Etwa 6 bis 10 Stunden Spielzeit, je nachdem, wie viel du zähmst, züchtest und erkundest.

## Bedienung (Handy)

- Laufen: linke Bildschirmhälfte gedrückt halten und ziehen.
- Sprechen, Türen öffnen: A (oder gegen eine Tür laufen). Eine kleine Sprechblase zeigt, wer ansprechbar ist.
- Menü: ☰ oben rechts (Gefolge, Beutel, Karte, Lexikon, Optionen, Speichern, Spiel bewerten).
- Jinli ansprechen: Hinweis zur Aufgabe – oder streicheln.
- Gefolge-Menü: „…“ neben einem Lingshou öffnet Beschreibung und Attacken (bis zu vier aktiv).
- Hof: westlich von Weidendorf. Gehege-Schilder antippen; schlafen in der Hütte lässt die Nacht vergehen.

## Testen und Rückmeldung

- App „Wuyin“ öffnen, „Neues Spiel“.
- Bewerten: im Menü „Spiel bewerten“ oder nach dem Abspann. KI-Texte im Dialog mit ⚑ melden.
- Rückmeldung am Mac abholen: `tools/pull_feedback.sh` → `build/feedback/<Zeit>/`.
- Sprung zu einer Stelle (nur Debug-Build): `adb shell run-as com.wuyin.game sh -c 'echo map=kiefernhang > files/dev_jump.txt; echo res://scenes/dev/beta_jump.tscn > files/dev_autorun.txt'` (jede Karten-ID; alte Stufen river, bamboo, terraces, shrine gibt es weiter).

## Automatische Prüfungen

- `tools/check.sh`: 103 Unit-Tests (Kampf, Zucht, Spielstand, Karten, Ereignisse, Texte in drei Sprachen, Erreichbarkeit über Treppen).
- `godot --headless --path game -s res://tests/tools/autoplay_full.gd` spielt das ganze Spiel durch (Ende Versöhnung); mit `-- --ending=victory` bzw. `-- --ending=bitter` die anderen Enden. Ergebnis: alle drei Enden erreichbar, rund 120 Kämpfe, Stufe am Ende etwa 35.
- Bildschirmfotos: `tests/tools/capture_full.gd` und `capture_beta.gd`.
- Daten neu erzeugen: `tools/build_data.sh` (Karten, Innenräume, Story, Inhalte, Übersetzungen).

## Bekannte Grenzen

- Figuren nur von vorn, keine echten Laufbilder (Wackel-Gang als Ersatz).
- Wandlung ist als Leuchten in der Elementfarbe plus 12 % Werte umgesetzt, nicht mit eigenen Bildern. Futtergarten, Werkstatt und Möbel des Hofs fehlen noch.
- Chinesisch ist maschinennah formuliert und braucht eine Muttersprachler-Prüfung.
- Auf dem Mac fehlen chinesische Schriftzeichen in der Systemschrift (Handy: in Ordnung); für Steam braucht es eine Pixelschrift mit CJK.
