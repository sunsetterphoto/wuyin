# Beta-Assets (Kapitel 1), 2026-10-28

Alle Prompts, Seeds, verworfenen Seeds und Gründe stehen in `beta_assets.json` (Feld `tried`).
Ablauf und Befehle: `tools/postprocess/README.md`, Abschnitt „Beta-Assets“.
Vorschau: `build/beta_preview_sprites.png`, `build/beta_preview_backgrounds.png`.

## Was erzeugt wurde

| Gruppe | Dateien | Modell, Verfahren |
| --- | --- | --- |
| Lingshou (13) | `game/assets/sprites/lingshou/*.png`, 48x48; `qinglong` und `qinglong_silenced` 96x96 | Z-Image Turbo 768² (Drache 1024²), `pixelize.py sprite`: weißer Hintergrund weg, Wuyin-Palette (32 Farben), 1-px-Umriss |
| Figuren (11) | `game/assets/sprites/chars/*.png`, 32x48; `jinli` 32x32 | Z-Image 768x1152 (Seitenverhältnis 2:3), `pixelize.py --size 32 --height 48`, Füße unten |
| Hintergründe (5) | `game/assets/backgrounds/*.png`, 640x360 | Z-Image 1280x720 → 320x180, eigene 64-Farben-Palette (20 % zur Wuyin-Palette gezogen), 2x Nearest |
| Titel, Icon | `game/assets/ui/title.png` 640x360, `icon.png` 512x512 | wie Hintergründe; Icon 128 px, 32 Farben, 4x Nearest |
| Musik (9) | `game/assets/audio/music/*.ogg` | ACE-Step 1.5 turbo, `[Instrumental]`, Stille vorn/hinten weg, -16 LUFS (silence: -18), Spitze ≤ -1 dBFS, 44,1 kHz Stereo, Vorbis ~100–140 kbps |

Seeds der Übernahme: Lingshou 101–104 (Phase 1, bitgleich reproduziert), zirpo 111, nebelaffe 112, firnleopard 113,
silberkranich 114, reisquak 115, jadelibelle 116, schattenmotte 157, qinglong 118. Figuren 301–311, wusheng 324.
Hintergründe 401–404, shrine 415. Titel 521, Icon 522. Musik 601, 612, 603, 604, 615, 606, 607, 628, 609.

`qinglong_silenced` ist kein eigenes Bild, sondern Nachbearbeitung von `qinglong` (`beta_postprocess.py`, Funktion
`silence`): Graustufen aus der Steinrampe der Palette, goldene Augenpixel werden zur geschlossenen Lidlinie,
vier helle Fadenlinien über dem Körper. So bleibt die Silhouette identisch.

## Verworfen

- **schattenmotte**: Erster Prompt war fast schwarz, nach der Palette nur noch ein schwarzer Fleck. Zweiter Prompt
  (lila Flügel) mit 3 Seeds: niedlich, ohne Ringmuster. Dritter Prompt mit „konzentrischen Ringen wie Wellen“ und
  wütendem Blick, Seed 157. Die schmalen Augen gingen bei 48 px verloren, deshalb hellt `glow_eyes` sie auf und
  verbreitert sie um 1 px.
- **jadelibelle**: Erster Prompt gab blassblaue Glasflügel; neuer Prompt („undurchsichtige Bambusblätter“) mit Seed 116.
- **qinglong**: Seeds 128 und 138 probiert, 118 behalten (klarste Silhouette mit Beinen, Bambusgeweih, Blattschwanz).
- **wusheng**: Seed 304 zu schmal, Gesicht bei 32 px nicht lesbar; 324 ist breiter.
- **villager_b** (Kind): füllte die volle 48-px-Höhe wie Erwachsene; jetzt auf 80 % Höhe, gleiche Fußlinie (`fill`).
- **shrine**: Seed 405 hatte den Schrein groß in der Mitte, genau wo die Lingshou stehen. Neuer Prompt (Schrein
  hinten links, leerer Steinhof unten), Seed 415.
- **title**: Seed 501 setzte den Phönix groß oben in die Mitte, die Säulen wirkten wie Burgtürme. Neuer Prompt
  (Phönix klein in der unteren Hälfte, Karstfelsen, oberes Drittel leer), Seed 521.
- **icon**: Seed 502 zeigte einen Vogel mit Schwert statt einer Feder. Neuer Prompt, Seed 522.
- **Musik victory**: Seed 608 klang nur 3 s, 618 nur 5,5 s; 628 hat gut 7 s.
- **Musik village**: Seed 602 – Whisper fand eine wiederholte, zeitlich passende Textzeile; Gesang nicht sicher
  auszuschließen, daher neu (612).
- **Musik town**: Seed 605 hatte 2 s Stille mitten im Stück (bei 54 s); neu (615).

## Prüfungen

- Alle Bilder als Vorschau angesehen (Sprites 4x und 1x, Hintergründe mit zwei Lingshou in Spielgröße).
- Musik: Dauer und Lautheit (EBU R128) per ffmpeg, Spitze ≤ -1 dBFS, keine Übersteuerung.
- Gesang: `tools/postprocess/beta_vocal_check.py` (Whisper large-v3-turbo). Whisper erfindet bei Instrumentalmusik
  Text („Thank you.“, ein Wort hundertfach); gezählt werden nur zeitlich passende Segmente mit mehreren
  verschiedenen Wörtern, und nur wenn zwei Läufe je mindestens zwei verschiedene Zeilen finden (Whisper wiederholt
  sonst manchmal eine erfundene Phrase). Gegenprobe mit einem ACE-Step-Lied mit Gesang: alle Zeilen erkannt.
  Ergebnis: in keinem der 9 Stücke Gesang gefunden. Das bleibt eine Heuristik, kein Hörtest.

| Stück | Dauer | Lautheit | Spitze |
| --- | --- | --- | --- |
| title | 76,5 s | -16,6 LUFS | -1,0 dBFS |
| village | 72,3 s | -15,9 LUFS | -3,0 dBFS |
| silence | 52,5 s | -18,4 LUFS | -1,4 dBFS |
| route | 69,8 s | -16,0 LUFS | -1,9 dBFS |
| town | 63,2 s | -15,9 LUFS | -2,1 dBFS |
| battle | 56,2 s | -15,9 LUFS | -3,4 dBFS |
| boss | 71,0 s | -16,0 LUFS | -1,3 dBFS |
| victory | 7,2 s | -16,3 LUFS | -2,0 dBFS |
| tone_returns | 23,4 s | -15,9 LUFS | -1,4 dBFS |

## Bekannte Schwächen

- Stil: Die neuen Lingshou sind aus glatten Cartoon-Vorlagen entstanden, die vier Phase-1-Sprites aus
  Pixel-Vorlagen. Nach der Palette passt es gut zusammen; die alten vier blicken frontal, die neuen schräg nach links.
- Die Palette hat kein Türkis: das Teal von Held und Azurdrache wird zu Flussblau. Für die Beta egal (Held wird
  umgefärbt), für später eine Türkis-Rampe in die Palette aufnehmen.
- schattenmotte: Körper fast schwarz, lebt von Flügelringen und den nachträglich aufgehellten Augen.
- silberkranich: dünne Beine, bei 1x knapp lesbar.
- Figuren bei 1x: Gesichter sind 2–3 Pixel; Unterscheidung über Farbe und Silhouette. wusheng ohne hohen Kragen.
- jinli: Koi-Glöckchen ist bei 32 px nur ein goldener Punkt.
- Hintergründe: river sieht eher wie eine Seitenansicht aus (Schilfwand, Fluss quer); shrine ist bewusst fast grau,
  die Jadefarbe der Statue ging in der 64-Farben-Palette verloren.
- Musik: `silence` ist nach dem Trimmen 52,5 s statt 60 s, `battle` 56 s. Nicht angehört. Ob die Stücke sauber loopen, ist ungeprüft (die Enden sind nur getrimmt und 10 ms
  ausgeblendet). `silence` hat bewusst Pausen; `boss` hat einen fast stillen Zwischenteil (~1 s bei 49 s).
