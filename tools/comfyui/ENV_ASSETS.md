# Umgebungs-Assets (Tiles, Props, Porträts), 2026-10-29

Batch mit Prompts, Seeds, verworfenen Seeds und Gründen: `env_assets.json` (Feld `tried`).
Ablauf und Befehle: `tools/postprocess/README.md`, Abschnitt „Umgebungs-Assets“.
Vorschau: `build/env_preview_tiles.png` (jedes Tile 3x3 gekachelt, 2x), `build/env_preview_props.png` (3x und 1x),
`build/env_preview_portraits.png` (3x, 1x, daneben das Overworld-Sprite 4x), `build/env_preview_scene.png` (Probedorf, 2x).

## Palette

`tools/postprocess/palette_env64.hex`, 64 Farben: die 32 Wuyin-Farben unverändert, dazu Türkis/Jade-Rampe
(`1d4f4a` … `c4ecd9`), Gras- und Moosgrün, Erde, Danxia-Rot/Apricot/Creme, Schiefergrau, Wasser-Türkis, Pastell
(Rosa, Pflaumenrosa, Lavendel, Butter) und zwei Schneetöne. Alle Umgebungs-Assets nutzen nur diese Farben.
Umriss der Props und Porträts: Tinte `1a1620` wie bei den Figuren.

## Was erzeugt wurde

| Gruppe | Dateien | Verfahren |
| --- | --- | --- |
| Tiles (24) | `game/assets/tiles/<id>.png`, 64x64 | prozedural (`tools/postprocess/env_tiles_proc.py`), nahtlos durch Konstruktion |
| Props (64) | `game/assets/props/<id>.png`, Größen siehe unten | Z-Image Turbo (~0,6 MP im Seitenverhältnis des Sprites) → `env_postprocess.py`; `wind_chime`, `prayer_flags` handgezeichnet (`env_handmade.py`); fünf Tempelbanner aus einer Silhouette umgefärbt |
| Porträts (15) | `game/assets/portraits/<id>.png`, 96x96 | Z-Image Turbo 1024² → Büste, unten bündig |

### Tiles (64x64, 32 px je Spielkachel, also 2 Kacheln pro Wiederholung)

grass, grass_flowers, path, plaza, cobble, wood, plaster, wall_timber, roof_grey, roof_red, roof_green, stone,
water, sand, redrock, danxia, karst, cloudstone, paddy, moss, bamboo, leaves, pine, snow.

- `grass_flowers` hat dasselbe Grundgras wie `grass` (gleicher Seed 1001), die beiden lassen sich mischen.
- `wall_timber`: ein Geschoss Fassade: Balken oben (8 px), Pfosten links (8 px, also ein Pfosten alle 2 Kacheln),
  Kalkputz dazwischen, Spritzschmutz unten. Wiederholt sich auch senkrecht (dann Balken alle 64 px).
- Dächer: senkrechte Reihen Mönch-und-Nonne-Ziegel (11 px Wölbziegel, 5 px Rinne), alle 16 px eine Ziegellippe.
  Gedacht für Dachflächen, die von oben-vorn gesehen werden; Traufkante und Firstabschluss sind nicht enthalten.
- `bamboo`: vier senkrechte Halme à 16 px mit versetzten Knoten (Zaun, Wand, Halmdickicht).
- `danxia`: waagerechte Gesteinsbänder (Rot, Orange, Gelb, Creme), wellig, wiederholt sich auch senkrecht.

### Props (Größe in Pixeln, Fuß/Unterkante unten, binäres Alpha außer `cloud_wisp`)

| id | Größe | id | Größe | id | Größe |
| --- | --- | --- | --- | --- | --- |
| tree_willow | 96x112 | tree_plum | 80x96 | tree_pine | 72x112 |
| tree_round | 80x96 | tree_maple | 80x96 | tree_datepalm | 72x112 |
| tree_cloudpine | 96x96 | bamboo_clump | 64x128 | bush_round | 40x32 |
| bush_flowering | 40x32 | bush_tea | 40x28 | shrub_desert | 40x32 |
| fern | 32x24 | reeds | 32x40 | lotus_flower | 24x20 |
| lotus_pads | 40x24 | mushrooms | 20x16 | flowers_red | 24x16 |
| flowers_yellow | 24x16 | flowers_white | 24x16 | flowers_purple | 24x16 |
| rice_sheaf | 24x32 | rock_small | 24x16 | rock_big | 48x40 |
| rock_moss | 40x32 | rock_red | 40x32 | rock_sand | 32x20 |
| rock_karst | 32x40 | lantern_red | 16x24 | lantern_string | 64x24 |
| lantern_stone | 24x40 | signpost | 32x40 | barrel | 24x28 |
| crate | 24x24 | jar | 20x24 | jars_group | 40x28 |
| basket_veg | 28x20 | laundry_line | 64x40 | banner_red | 24x56 |
| fishing_net | 48x40 | boat_small | 64x32 | haystack | 40x36 |
| firewood | 40x24 | cart | 56x40 | incense_burner | 32x36 |
| stone_lion | 32x40 | bench | 40x24 | tea_table | 40x28 |
| stall | 64x64 | wind_chime | 16x32 | well_bucket | 24x28 |
| chicken | 20x20 | duck | 24x20 | drum | 32x36 |
| tent_yurt | 80x64 | camel_saddle_pile | 40x24 | cloud_wisp | 64x32 |
| brazier | 32x40 | banner_green | 24x64 | banner_red_tall | 24x64 |
| banner_yellow | 24x64 | banner_white | 24x64 | banner_black | 24x64 |
| prayer_flags | 64x24 | | | | |

- Namenskonflikt: Der Auftrag nennt `banner_red` zweimal (Dorfbanner 24x56 und rotes Tempelbanner 24x64).
  Das Dorfbanner heißt `banner_red`, das rote Tempelbanner `banner_red_tall`.
- `cloud_wisp` hat halbtransparente Ränder (Alpha 150 am Rand, weicher grauer Umriss mit Alpha 120).
- `prayer_flags` und `lantern_string` hängen; ihre Schnur-Enden sitzen oben links/rechts (zwischen zwei Pfosten setzen).
- `fishing_net` hat echte Löcher (transparent).

### Porträts (96x96, Büste, Blick leicht nach rechts, unten bündig ohne Umriss)

hero, jinli, meister, yao, wusheng, innkeeper, shopkeeper, teahouse, monk, villager_a, villager_b, order_a, order_b,
fisher, elder.

- `hero` behält die türkisgrüne Tunika (Türkis-Rampe der Env-Palette: `2a7d6f`, `3fa894`, `7fd1b9`), damit das
  Spiel sie umfärben kann. Das Overworld-Sprite `hero.png` ist dagegen flussblau (Beta-Palette ohne Türkis).
- Ausschnitt und Größe der Köpfe schwanken etwas zwischen den Porträts (Held und Jinli zeigen mehr Oberkörper).

## Verworfen und warum

- **KI-Tiles**: Z-Image-Texturen (Prompts stehen noch im JSON) mit Min-Cut-Naht wurden bei 64 px zu Tarnflecken:
  Grasbüschel, Mörtelfugen und Ziegelreihen lösten sich auf. Daher alle Tiles prozedural (eigener Code, Seeds fest).
  Rohbilder `grass_s1001`, `grass_flowers_s1002`, `path_s1003`, `plaza_s1004` liegen noch in `build/env_raw/tiles/`.
- **shrub_desert** 2014: graue „Brokkoli“-Baumform → neuer Prompt, 2114.
- **bush_flowering** 2012: Blüten zu klein, nach der Palette nur grün → 2112.
- **fishing_net** 2052: Maschen viel zu fein für 48 px (rauschiger Sack) → grobmaschiger Prompt 2152, Löcher werden
  freigestellt (`holes`).
- **crate** 2046: offene Kiste von oben → geschlossene Kiste 2146.
- **incense_burner** 2057: grünbraune Patina-Flecken und grauer Bodenschatten → goldene Bronze 2157.
- **camel_saddle_pile** 2072: zu viele kleine Bündel, brauner Brei → zwei Teppichrollen + Satteltasche 2172.
- **wind_chime** 2062: die drei Röhren verschmolzen bei 16 px zu einem grünen Klotz → von Hand gezeichnet
  (Holzscheibe, drei Bambusröhren mit Knoten, goldener Klöppel, rote Quaste). Es ist das Fengling der Geschichte.
- **prayer_flags** 2080: weiße Fahne auf weißem Grund, alles verschmolz → prozedural (acht Fähnchen, fünf Farben).
- **Tempelbanner** 2075/2076/2078/2079: einzeln brauchbar, aber fünf verschiedene Formen. Alle fünf nutzen jetzt die
  Silhouette von `banner_yellow` (2077) und werden umgefärbt, mit Licht- und Schattenkante, Goldborte und Emblem.
- **Porträts**: Die erste Stilzeile sprach von einer „dialog box“; das Modell zeichnete einen Klammerrahmen (hero)
  bzw. eine dunkle Textbox (jinli). Neue Stilzeile ohne das Wort (alle anderen Porträts mit Seeds 31xx).
  Für hero und jinli bleiben die Rohbilder 3001/3002, sie werden über dem Rahmen abgeschnitten (`raw_box`).
- **shopkeeper** 3107: blaue Mütze plus buschiger Schnurrbart erinnerte zu sehr an einen bekannten Spiel-Klempner →
  neuer Prompt (Käppchen, dünner Schnurrbart); 3207 grimmig und mit Pixelrauschen im Gesicht; 3307 übernommen
  (fröhlich, zwinkernd; die Kappe ist braun statt schwarz, das Overworld-Sprite trägt eine blaue Mütze).

## Bekannte Schwächen

- Tiles wiederholen sich alle 64 px sichtbar (Gras, Wasser), vor allem auf großen Flächen. Abhilfe im Spiel:
  `grass` und `grass_flowers` mischen, Props streuen; später zweite Varianten mit anderem Seed (ein Aufruf).
- `camel_saddle_pile` bleibt das schwächste Prop (dunkles Blau kippt in der Palette Richtung Violett).
- `drum` ohne sichtbares Gestell, `haystack` eher rund wie ein Kuchen, `tree_pine` schlicht.
- `lotus_pads`: Knospe und Blattadern gehen bei 40x24 verloren, flache grüne Ellipsen.
- Kleine Props (16–24 px) sind Farbflecken mit Umriss; Lesbarkeit bei 1x im Probedorf geprüft und ausreichend.
- Porträts: kein exakter Abgleich der Kopfgröße; meister hat einen grauen Fleck (Kapuze/Schal) hinter der Schulter;
  villager_a trägt Mint statt Hellgrün; order_b zeigt ein weißes Kopftuch mit Schleier statt des schwarzen Knotens;
  shopkeeper weicht vom Sprite ab (braunes Käppchen statt blauer Mütze).

## Prüfungen

- Alle Tiles 3x3 gekachelt angesehen: keine Nähte (alle Muster laufen über den Rand).
- Alle Props und Porträts 3x und 1x angesehen; Größen und Alpha per Skript geprüft (exakte Maße, nur 0/255 außer
  `cloud_wisp`, Unterkante belegt außer bei den hängenden `prayer_flags`).
- Probedorf (`env_preview_scene.png`) mit Figuren in Spielgröße: Maßstab der Props zu den 32x48-Figuren passt.
