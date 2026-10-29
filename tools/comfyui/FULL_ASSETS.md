# Voll-Assets (Kapitel 2–5), 2026-10-29

Alle Prompts, Seeds, verworfenen Seeds und Gründe stehen in `full_assets.json` (Feld `tried`).
Gleiche Pipeline und Stil-Strings wie die Beta (`BETA_ASSETS.md`); Befehle: `tools/postprocess/README.md`, Abschnitt „Voll-Assets“.
Vorschau: `build/full_preview_lingshou.png`, `build/full_preview_chars.png`, `build/full_preview_backgrounds.png`
(Rohbilder: `build/full_preview_raw_*.png`). Rohdateien: `build/full_raw/`.
Kein neues Modell, keine LoRA: Z-Image Turbo (Apache 2.0) und ACE-Step 1.5 turbo (MIT) stehen schon in `LICENSES.md`.

## Was erzeugt wurde

| Gruppe | Dateien | Größe |
| --- | --- | --- |
| Lingshou Regionen (13) | perlkormoran, stromdelfin, nebelbueffel, goldkroete, glutpanda, funkenechse, lampionfalter, glockenkamel, duenenspringer, messingadler, felstakin, wolkenpfeifer, steinloewe | 48x48 |
| Bosse / besondere (6 + 5) | xuanwu, bifang, baihu, qilin, nian, fenghuang; xuanwu_silenced, bifang_silenced, baihu_silenced, qilin_silenced, fenghuang_ashes | 96x96 (Rohbild 1024²) |
| Zucht-Mischformen (5) | blattbaer, perllurch, glutfalter, glockenleopard, zirpkroete | 48x48 |
| Figuren (12) | order_a, order_b, yao_order, fisher, boatwoman, trader, carpenter, cook, elder, girl_c, man_c, meister_free | 32x48 |
| Hintergründe (8) | karst, danxia, dunes, pillars, phoenix_temple, village_day, farm, order_hall | 640x360 (320x180-Raster, 64 Farben) |
| Musik (9) | river, ridge, dunes, pillars, order, nian, finale, ending, farm | OGG Vorbis, 44,1 kHz Stereo |

Ziele: `game/assets/sprites/lingshou/`, `game/assets/sprites/chars/`, `game/assets/backgrounds/`, `game/assets/audio/music/`.

Seeds der Übernahme: perlkormoran 761, stromdelfin 702, nebelbueffel 703, goldkroete 704, glutpanda 705, funkenechse 746,
lampionfalter 707, glockenkamel 748, duenenspringer 749, messingadler 710, felstakin 751, wolkenpfeifer 712, steinloewe 713,
xuanwu 791, bifang 794, baihu 785, qilin 796, nian 725, fenghuang 798, blattbaer 731, perllurch 732, glutfalter 753,
glockenleopard 734, zirpkroete 735. Figuren 801, 822 (order_b), 803–810, meister_free 302 (Seed von meister, Prompt
angepasst). Hintergründe 901, 902, 903, 914 (pillars), 905, 906, 907, 908. Musik 1001–1009.

### Nachbearbeitung, die nicht aus einem eigenen Bild kommt

- `*_silenced`: Funktion `silence` aus der Beta (Steingrau, goldene Augen → Lidlinie, Fadenlinien), Silhouette identisch.
  Bei baihu wurden keine Augenpixel geschlossen (blaue Augen fallen nicht unter die Gold-Regel), die Augen sind nur grau.
  Bei qilin_silenced trifft die Gold-Regel auch das goldene Horn: es bekommt dunkle Querstreifen (liest sich als gedrehtes Horn).
- `fenghuang_ashes`: neue Funktion `ashes` (`beta_postprocess.py`): dunkle Aschegrau-Rampe nach Helligkeitsrang, Glut
  (Ember-Orange) an hellen Rändern, verstreute Glutfunken (fester Zufallsstartwert 7), gleiche Silhouette wie fenghuang.
- `yao_order`: neue Funktion `order_robe`: yao.png umgefärbt (rote Jacke und schwarze Kleidung → graue Robe, Beine zum
  Robenrock geschlossen, weiße Schärpe mit dunklem Punkt), Kopf unverändert, daher sofort als Yao erkennbar.
- Neue Optionen in `pixelize.sprite` / `beta_postprocess.py`: `trim_shadow` (xuanwu, glutfalter, goldkroete, cook,
  meister_free: blasser Bodenschatten entfernt), `bg_thresh`, `tint` (order_a, order_b: kühles Grau leicht gewärmt,
  sonst wird die Robe nach der Palette Nebelblau statt Stein).
- Musik `dunes`, `pillars`, `finale`: `cut_quiet` in `beta_music.py` schneidet fast stille Stellen (unter -45 dBFS,
  ab 1,5 s) heraus (0,25 s bleiben stehen, 150 ms Crossfade), danach `loop_crossfade` (die ersten 0,5 s werden in das
  Ende überblendet, damit Ende → Anfang ohne Lücke und ohne Knacken schleift). Herausgeschnitten: dunes 4,0 s bei 64 s
  und 1,3 s bei 1,4 s; pillars 6,9 s bei 5,4 s; finale 2,7 s bei 10,5 s. Danach findet `silencedetect` (-45 dB, 1 s)
  nichts mehr; Sprung an der Loop-Naht ≤ 0,02 (kleiner als der übliche Schritt zwischen zwei Samples).

## Verworfen (Auswahl; vollständig in `tried`)

- **perlkormoran**: 701 realistischer Vogel ohne Perle, nach der Palette fast schwarz; 741 eher eine Ente. 761 mit langem Hals und Perle.
- **funkenechse** 706 grünes Cartoon-Krokodil; **duenenspringer** 709 eher Hase; **felstakin** 711 braune Widderhörner;
  **glockenkamel** 708 nur eine Glocke am Hals (748: Glocke auf dem Rücken, aber nur ein Höcker als Glocke).
- **lampionfalter**: 747 (neuer Prompt) liest sich schlechter als 707 (Laterne als Körper), daher 707 behalten.
- **xuanwu**: 721 Schlange wie ein langer Hals, 781 keine Schlange, 792 kleinere Schlange → 791 (Schlange auf dem Panzer).
- **bifang**: 722 und 782 zweibeinig; Formulierung „standing on one leg, the other leg tucked up“ wirkte (793, 794).
- **baihu**: 723 weißes Gesicht ohne geschlossenen Umriss, die Hintergrund-Füllung fraß den Kopf (auch mit niedriger
  Toleranz); 783 fleckiges Gesicht; 785 sauber.
- **qilin**: 724 und 784 Hirschgeweih; 795 lose Wolke; 796 mit einem kurzen goldenen Horn und Wolkenmähne.
- **fenghuang**: 726 Regenbogenflügel (zu nah an bekannten Phönix-Designs); 786 auf einem Ast; 797 Spiralschweif;
  798: blassgoldene Flügel, fünf Schweifbänder in Grün, Rot, Gelb, Weiß, Dunkelblau.
- **glutfalter** 733 ohne Laternenflügel. **order_b**: 802 Schleier wie medizinische Maske, 812 Schleierhut als heller
  Klumpen, 832 fleckiger als 822. **meister_free**: erster Prompt mit erhobenem Arm machte die Figur kleiner als meister.
- **pillars** 904: Vordergrund eine sich wiederholende Mauer/Kistenreihe. **phoenix_temple** 915: fast gleich wie 905.
- **Musik**: Regeneration von dunes/pillars/finale begonnen und abgebrochen; stattdessen Stille herausgeschnitten (siehe oben).

## Prüfungen

- Jedes übernommene Bild als Vorschau angesehen (Sprites 4x bzw. 96er 2x und 1x, Hintergründe mit zwei Lingshou in Spielgröße).
- Musik: Dauer und Lautheit (EBU R128), Spitze ≤ -1 dBFS, `silencedetect` -40/-45 dB, Gesangsprüfung
  `beta_vocal_check.py` (Whisper, zwei Läufe): in keinem der 9 Stücke Gesang gefunden. Whisper erfindet wie in der
  Beta „Thank you.“ oder ein Wort hundertfach; bei ridge „Yeah Yeah“, bei nian „Ale Ale“ – nicht zeitlich passend,
  aber nicht angehört. Heuristik, kein Hörtest.

| Stück | Dauer | Lautheit | Spitze |
| --- | --- | --- | --- |
| river | 68,8 s | -16,0 LUFS | -1,1 dBFS |
| ridge | 67,3 s | -16,0 LUFS | -3,4 dBFS |
| dunes | 62,9 s | -16,2 LUFS | -1,3 dBFS |
| pillars | 63,2 s | -15,9 LUFS | -1,1 dBFS |
| order | 63,4 s | -16,0 LUFS | -4,1 dBFS |
| nian | 56,9 s | -15,9 LUFS | -1,4 dBFS |
| finale | 79,0 s | -16,3 LUFS | -1,1 dBFS |
| ending | 86,7 s | -15,9 LUFS | -1,3 dBFS |
| farm | 65,4 s | -15,9 LUFS | -2,8 dBFS |

## Bekannte Schwächen

- Palette ohne Türkis beibehalten (keine Rampe ergänzt): stromdelfin verliert das Rosa und wird grau mit blauen
  Wellen; lampionfalter wird eher orange als rot.
- glockenkamel: ein großer Glocken-Höcker statt zwei Glocken. duenenspringer eher Maus mit Riesenohren als Springmaus.
  messingadler hat einen weißen Kopf (Seeadler-Anmutung). steinloewe bei 1x etwas unruhig. funkenechse: Funken gingen
  als lose Teile verloren.
- fenghuang blickt nach rechts (alle anderen schräg nach links); falls nötig im Spiel spiegeln. Windspiel-Kamm nur
  ein kleiner Kamm. bifang mit gelbem statt weißem Schnabel.
- Sprites, deren Schatten entfernt wurde, stehen auf einer geraden Unterkante; xuanwu-Kopf ausdruckslos.
- order_b: der Schal über Mund und Nase wirkt bei 1x immer noch maskenhaft; das geschlossene-Auge-Emblem ist bei
  32 px nicht darstellbar (order_a und yao_order: nur Schärpe).
- boatwoman wirkt bei 1x eher jungenhaft. meister_free: Windspiel als grüne Laterne vor der Brust.
- Hintergründe: karst ohne erkennbares Bambusfloß; pillars hat einen Gras-/Erdstreifen im Plattformer-Stil, das
  hintere Lingshou steht dort auf Wolken; phoenix_temple ist flächiger als die anderen (Banner = Säulen);
  village_day eher von oben, der vordere Platz liegt unten, der Fluss in der Mitte.
- Musik: nian 57 s (unter 60 s); dunes beginnt leise (erste Sekunde -36 dB RMS gegenüber -22 dB am Ende), schleift
  aber ohne Lücke. Nur dunes/pillars/finale haben den Loop-Crossfade, die anderen sind wie in der Beta nur getrimmt
  mit 10 ms Ein-/Ausblendung. Nicht angehört.
- Optionale Laufrichtungen (hero_back/side, jinli_back/side) auf Wunsch der Hauptsitzung übersprungen.
