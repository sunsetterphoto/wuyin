# Wuyin – Game Design Dokument

Oct 27, 2026 · @Samu

## Name und Pitch

Titel: **Wuyin: Das Lied des Phönix** (Englisch: Wuyin: Song of the Phoenix, Chinesisch: 五音：凤凰之歌). Wǔyīn (五音) sind die fünf Töne der chinesischen Pentatonik: Gong, Shang, Jue, Zhi und Yu, jeder einem der fünf Elemente zugeordnet. Ohne Tonzeichen lässt sich „Wuyin“ auch als 无音 lesen, „ohne Klang“. Der Titel trägt damit beide Seiten der Geschichte: die fünf Töne und die Stille, die Wusheng über die Welt bringen will.

**Pitch:** Ein retro Monster-RPG im HD-2D-Look durch Fantasielandschaften nach chinesischem Vorbild. Du zähmst Geisttiere, die dir aus Vertrauen folgen, und bringst dem sterbenden Phönix die fünf gestohlenen Töne seines Liedes zurück.

**Begriffe im Spiel:**

- **Lingshou** (灵兽, Geisttiere): die Monster.
- **Fengling** (风铃, Windspiel): der zentrale Gegenstand. Das Windspiel des Phönixtempels, an dem jedes Glöckchen einem Lingshou erlaubt, dir zu folgen.
- **Yunhai** (云海, Wolkenmeer): der Name der Spielwelt.

**Namensprüfung:** Eine kurze Websuche fand kein Spiel namens Wuyin. Ähnlich klingt ein kleines RPG-Maker-Spiel auf itch.io (叶无音, „Ye Wuyin“); in China gibt es eine Musik-App namens 五音助手. Vor der Festlegung Marken bei DPMA und EUIPO (Klassen 9 und 41), im Steam-Store und bei Domains prüfen. Der Untertitel macht den Namen eigenständiger.

Verworfene Titel: Fengling, Fengming, Yunhai, Echoling.

## Eckdaten

Wuyin erscheint zuerst als Einmalkauf auf Android für Oberklasse-Handys, mit lokalem Sprachmodell und ohne Online-Zwang; Steam folgt später. Entwickelt wird solo mit Claude Code, mit über 20 Stunden pro Woche.

| Bereich | Entscheidung |
| --- | --- |
| Plattform | Android zuerst (Google Play), danach Steam (Windows, Linux, Steam Deck), iOS optional |
| Bezahlmodell | Einmalkauf für 4,99 € auf Android, keine In-App-Käufe, keine Werbung; Steam-Preis später separat |
| Zielgeräte | Android-Oberklasse ab 8 GB RAM |
| Sprachmodell | Nur auf dem Gerät, offline; Vorlagen als Ersatz |
| Ruf-Eingabe | Vorgeschlagene Rufe zum Antippen (Standard), dazu Spracheingabe und Tastatur |
| Zielgruppe | Leicht zugänglich für Kinder und Familien, mit Tiefe für Ältere; Altersfreigabe ab etwa 6 bis 12 |
| Spielzeit | 20 Stunden und mehr, dazu Hof und Zucht als Langzeitmotivation |
| Kampf | Wilde Lingshou 1 gegen 1, Bosse, Orden und Himmelswächter 2 gegen 2 |
| Niederlage | Zurück zur letzten Unterkunft, ein Teil der Münzen geht verloren |
| Zeit | Eigene Spieluhr wie Stardew Valley, ein Tag etwa 15 bis 20 echte Minuten |
| Online | Zum Start keine; Tausch und Kämpfe gegen Freunde technisch vorbereiten |
| Kunststil | SNES- und HD-2D-Stil, 32-Pixel-Raster |
| Spielfigur | Junger Erwachsener, etwa 20; Charakter-Editor für Körper, Frisur, Kleidung, Farben, eigener Name |
| Musik | Guzheng, Erhu und Dizi über Chiptune-Bass, pentatonisch |
| Story | Mehrere Enden, abhängig von Entscheidungen über das ganze Spiel |
| Team | Solo mit Claude Code, mehr als 20 Stunden pro Woche |
| Einstieg | Laternenfest in Weidendorf, mitten im Lied fällt die Stille |
| Erste Lingshou | Selbst gezähmt im Prolog, Jinli führt hin; dient als Tutorial fürs Zähmen |
| Anzahl Lingshou | 60 bis 80 in der Vollversion, 15 im Vertical Slice |
| Humor | Ausgewogen: Witz und ernste Momente |
| Stimmen | Nur Brabbel-Klänge, keine Sprachausgabe |
| Speichern | Automatisch plus manuell |
| Lexikon | Bestiarium-Buch mit Zeichnungen, Einträge teils vom LLM formuliert |
| Barrierefreiheit | Große Schrift, Farbmodi für Farbenblinde, Einhandbedienung |
| Erfolge | Google Play Games, später Steam |

## Roter Faden

Alle 500 Jahre verbrennt der Phönix und wird aus seinem eigenen Lied neu geboren. Diesmal hat jemand die fünf Töne dieses Liedes gestohlen, und ohne Wiedergeburt erstarrt das ganze Reich in Stille.

**Die Welt Yunhai:** Ein Reich über einem Wolkenmeer, aufgeteilt in fünf Regionen. Jede steht für eines der fünf Elemente (Wu Xing) und einen der fünf klassischen Töne (Wu Yin). Über der Mitte thront der Phönix Fenghuang.

| Region | Vorbild in China | Element | Ton | Himmelswächter |
| --- | --- | --- | --- | --- |
| Bambusmeer (Osten) | Bambuswälder in Sichuan, Reisterrassen von Longji | Holz | Jue | Azurdrache (Qinglong) |
| Nebelfluss (Norden) | Karstkegel am Li-Fluss bei Guilin | Wasser | Yu | Schwarze Schildkröte (Xuanwu) |
| Regenbogengrat (Süden) | Danxia-Felsen bei Zhangye | Feuer | Zhi | Bifang, einbeiniger Feuervogel |
| Singende Dünen (Westen) | Mingsha-Dünen und Mondsichelquelle bei Dunhuang | Metall | Shang | Weißer Tiger (Baihu) |
| Wolkensäulen (Mitte) | Sandsteinsäulen von Zhangjiajie, Wolkenmeer am Huangshan | Erde | Gong | Qilin |

Die Zuordnung von Element und Ton folgt der klassischen chinesischen Lehre. Die Orte sind Vorbilder für Landschaft und Stimmung, im Spiel tragen sie nur die Fantasienamen.

**Aufbau der Karte:** Eine feste, handgebaute Karte. Man reist von Stadt zu Stadt, dazwischen liegt jeweils ein Landschaftsabschnitt, und die Landschaft wechselt von Abschnitt zu Abschnitt: Bambuswald, Reisterrassen, Karstfluss, Regenbogenfelsen, Dünen, Steinsäulen. Jede Region hat zwei bis drei Städte. Weidendorf ist die Heimatstadt mit eigenem Haus; unterwegs gibt es keine feste Basis, nur eine eigene Unterkunft als Nebenbasis in jeder Stadt.

**Der Bösewicht:** Großkanzler Wusheng (无声, „ohne Laut“), einst Hüter des Phönixtempels. Bei jeder Wiedergeburt erneuert sich das Land, und das Alte geht mit dem alten Phönix ins Feuer. Diesmal würde auch Wushengs Gefährte gehen, ein uralter Kranich. Um ihn zu halten, stiehlt Wusheng die fünf Töne: Nichts soll je wieder enden. Der Preis: Flüsse stehen still, Geisttiere verstummen und gehorchen nur noch ihm.

**Sein Verbündeter:** Der Nian (年), das Ungeheuer aus der Neujahrslegende. Es fürchtet Lärm und die Farbe Rot und wird in der Stille immer stärker. Gegen den Nian helfen Trommeln, Feuerwerk und rote Banner, nicht rohe Kraft.

**Die Hauptfigur:** Etwa 20 Jahre alt, Lehrling eines Windspielmachers aus Weidendorf im Bambusmeer; Aussehen und Name wählt der Spieler im Charakter-Editor. Der Meister vertraut ihr oder ihm das Windspiel des Tempels an, an dem nur zwei Glöckchen hängen. Jedes Glöckchen erlaubt einem Lingshou, dir zu folgen.

**Der Meister:** Der alte Windspielmacher, der dir das Windspiel anvertraut. Am Ende des Prologs nimmt ihm Wusheng die Stimme. Ihn zurückzuholen wird dein persönliches Ziel; es gelingt erst mit dem dritten Ton.

**Der Rivale Yao:** Gleichaltrig, aus Weidendorf, zähmt im Prolog ebenfalls Lingshou. Er hat einen Verlust nie verwunden und glaubt Wushengs Versprechen, dass es keine Abschiede mehr geben muss. In Akt 3 schließt er sich dem Orden an. Mehrere Kämpfe gegen ihn; ob du ihn zurückholst, zählt für das Ende.

**Jinli, die Katze:** Eine kleine dreifarbige Schildpatt-Katze, sehr lieb und fest entschlossen, dir den Weg zu zeigen. Sie lebt mit dir in Weidendorf und kann als Einzige die gestohlenen Töne noch hören. Daher weiß sie immer, wohin es weitergeht.

- **Führt, zwingt aber nicht:** Sie läuft zum nächsten Ziel voraus, setzt sich hin, schaut zurück und maunzt. Gehst du woanders hin, wartet sie kurz und trottet dir dann nach. Der Spieler bleibt frei.
- **Hinweise auf Wunsch:** Sprichst du sie an, gibt sie einen Tipp zur Hauptaufgabe. Das LLM bekommt nur den Stand im Aufgabenbuch; je öfter du fragst, desto deutlicher wird der Tipp. Sie maunzt, die Untertitel zeigen, was sie meint.
- **Kein Lingshou:** Sie kämpft nicht, zählt nicht zum Gefolge und kommt in kein Gehege. Im Kampf sitzt sie am Rand und warnt vor Schattenmotten.
- **Kleine Gesten:** Findet versteckte Gegenstände, schläft im Bett der Unterkunft, lässt sich streicheln.
- **Koi-Motiv:** Ihr Name Jǐnlǐ (锦鲤) heißt Koi und steht in China auch für Glück. An ihrem Halsband hängt ein Glöckchen in Koi-Form, das klingt, wenn sie den Weg weist. Es erinnert an die Legende vom Karpfen, der das Drachentor überspringt: Wer nicht aufgibt, kommt ans Ziel.
- **Design:** Nach Fotos der echten Jinli gestalten, Schildpatt-Muster in Schwarz, Rot-Orange und Weiß, im Pixel-Raster gut lesbar.

**Die Akte:**

1. **Prolog: Die Stille fällt.** Beim Laternenfest in Weidendorf bricht mitten im Lied die Musik ab, der Fluss hört auf zu rauschen, die Dorftiere verstummen. Jinli führt dich zu vier scheuen wilden Lingshou am Fluss; zwei davon zähmst du selbst. Das ist zugleich das Tutorial fürs Zähmen.
2. **Die fünf Töne.** Nach dem Bambusmeer geht es halb frei weiter: erst Nebelfluss und Regenbogengrat in beliebiger Reihenfolge, dann Singende Dünen und Wolkensäulen in beliebiger Reihenfolge. In jeder ist ein Himmelswächter verstummt. Wer ihn befreit, bekommt einen Ton zurück, und neue Glöckchen erscheinen am Windspiel.
3. **Der Orden der Stille.** Wushengs Anhänger. Grauzone: Viele Dorfbewohner mögen die Stille, denn ohne Wandel gibt es keine Stürme, Fluten und Abschiede. Der Nian greift an; ein Dorffest mit Trommeln und Rot muss ihn vertreiben.
4. **Die Wiedergeburt.** Phönixtempel auf den Wolkensäulen. Wusheng lässt sich besiegen oder überzeugen. Überzeugen gelingt nur mit dem, was du auf der Reise über Abschied und Erneuerung erfahren hast. Der Phönix wird neu geboren und folgt dir als zwölftes Geisttier.

**Twist:** Wushengs Kranich ist nicht verstummt. Er schweigt freiwillig, aus Treue zu ihm. Bringt der Spieler ihn zum Singen, versteht Wusheng, dass sein Gefährte den Abschied längst angenommen hat. Das öffnet das friedliche Ende.

**Mehrere Enden:** Entscheidungen über das ganze Spiel zählt der Code mit, zum Beispiel: wie viele Verstummte befreit statt besiegt wurden, ob Ordensmitglieder überzeugt oder bekämpft wurden, ob du den Dorfbewohnern hilfst, die die Stille wollen, ob Wushengs Kranich wieder singt und ob du Yao aus dem Orden zurückholst.

- **Versöhnung:** Wusheng nimmt Abschied von seinem Kranich, der Phönix wird neu geboren, der Orden löst sich auf.
- **Sieg:** Wusheng wird besiegt und verbannt, der Phönix wird neu geboren, aber einige Verstummte bleiben stumm.
- **Bittere Stille:** Zu viele Verstummte wurden besiegt statt befreit. Der Phönix wird neu geboren, doch eine Region bleibt still und muss nach dem Abspann befreit werden.
- Die genaue Liste der Entscheidungen und Enden wird vor der Story-Produktion festgelegt.

**Nach dem Abspann:** Der Nian ist geflohen und kehrt jedes Jahr zurück, als wiederkehrende Jagd zum Neujahrsfest.

## Lingshou: die Geisttiere

Jedes Lingshou basiert auf einem echten Tier Chinas und hat einen fantastischen Zug. Man fängt sie nicht, man gewinnt ihr Vertrauen, dann folgen sie einem freiwillig. Gesinnung, Temperament, Element und Bindung liegen fest im Code; das LLM gibt ihnen nur die Stimme.

**Gesinnung:**

- **Frei:** Hilfsbereit, mit eigener Stimme. Folgen dir, wenn das Vertrauen reicht.
- **Wild:** Neutral und scheu oder territorial. Lassen sich beruhigen und zähmen.
- **Verstummt:** Von Wusheng gebunden, feindlich, sprechen nur in Fragmenten. Werden befreit, nicht gezähmt; danach entscheiden sie selbst, ob sie folgen.
- **Schattenmotten:** Die wirklich bösen Geschöpfe des Nian, sie fressen Klänge. Nicht zähmbar, die Gegner ohne Grauzone.

**Temperamente:**

| Temperament | Im Kampf | Sprechweise | Vertrauen wächst durch |
| --- | --- | --- | --- |
| Mutig | Greift gern an, ignoriert Rückzugsbefehle | Kurz, laut | Siege, riskante Befehle |
| Ängstlich | Weicht aus, flieht bei wenig Leben | Zögerlich, leise | Schutz, Ruhe, Lob |
| Stur | Folgt Befehlen nur bei hoher Bindung | Knapp, widerspricht | Eigene Ideen zulassen |
| Verspielt | Improvisiert kleine Bonusaktionen | Albern, Wortspiele | Erkundung, Minispiele |
| Sanft | Bevorzugt Heilung und Unterstützung | Warm, tröstend | Anderen helfen |
| Launisch | Stimmung wechselt pro Kampf | Sprunghaft | Futter, Wetter, Geduld |

**Elemente nach den Fünf Wandlungen (Wu Xing):**

- **Überwindung = Typvorteil:** Holz schlägt Erde, Erde schlägt Wasser, Wasser schlägt Feuer, Feuer schlägt Metall, Metall schlägt Holz.
- **Erzeugung = Teambonus:** Holz nährt Feuer, Feuer nährt Erde, Erde nährt Metall, Metall nährt Wasser, Wasser nährt Holz. Kämpfen zwei Lingshou zusammen, deren Elemente aufeinander folgen, gibt es einen kleinen Bonus. Das macht die 2-gegen-2-Kämpfe taktisch.

**Beispiel-Lingshou:**

| Name | Vorbild | Element | Temperament | Fantastischer Zug |
| --- | --- | --- | --- | --- |
| Wawalurch | Chinesischer Riesensalamander | Wasser | Ängstlich | Weint wie ein Kind und kann damit Strömungen umlenken (im Prolog zähmbar) |
| Bambär | Großer Panda | Holz | Sanft | Lässt Bambus wachsen, wo es sitzt (im Prolog zähmbar) |
| Glutfasan | Goldfasan | Feuer | Mutig | Schwanzfedern glühen wie Kohle |
| Rollschupp | Schuppentier | Metall | Stur | Rollt sich zur eisernen Kugel |
| Zirpo | Singgrille | Erde | Launisch | Sein Zirpen stärkt Verbündete |
| Nebelaffe | Goldstumpfnase | Holz | Verspielt | Verschwindet in selbst gemachtem Nebel |
| Firnleopard | Schneeleopard | Metall | Mutig | Krallen aus Raureif und Silber |
| Silberkranich | Mandschurenkranich | Metall | Sanft | Wushengs Gefährte, singt nur für ihn |

**Zähmen statt Fangen:** Kein geworfener Gegenstand. Du gewinnst Vertrauen durch Füttern, Beruhigen, Schonen im Kampf und einen passenden Satz an das Tier. Das LLM bewertet nur, ob der Satz zum Temperament passt; die Vertrauensschwelle prüft der Code. Ist sie erreicht, folgt dir das Lingshou.

**Das Gefolge wächst mit dem Windspiel:**

| Zeitpunkt | Glöckchen am Windspiel | Lingshou im Gefolge |
| --- | --- | --- |
| Spielstart | 2 | 2 |
| Ende Prolog | 3 | 3 |
| 1. Ton zurück | 4 | 4 |
| 2. Ton zurück | 6 | 6 |
| 3. Ton zurück | 8 | 8 |
| 4. Ton zurück | 10 | 10 |
| 5. Ton zurück | 11 | 11 |
| Phönix wiedergeboren | 12 | 12 |

Im Kampf sind je nach Gegner ein oder zwei Lingshou aktiv, Wechsel aus dem Gefolge kostet einen Zug. In der Oberwelt läuft das erste Lingshou sichtbar hinter dir. Alle Lingshou, die gerade nicht im Gefolge sind, leben in den Gehegen auf deinem Hof in Weidendorf.

**Bindung:** Ein Wert von 0 bis 100 pro Lingshou, nur im Code. Er steigt durch passende Handlungen laut Temperament und bestimmt, wie zuverlässig freie Befehle befolgt werden.

**Wandlung:** Bei hoher Bindung und einem passenden Ereignis verwandelt sich ein Lingshou einmal in eine stärkere Form, deren fantastischer Zug deutlicher wird.

**Der Phönix:** Das Übertier. Nur durch das Ende der Geschichte erhältlich, einmalig, mit allen fünf Tönen als Fähigkeiten.

## Heimat: Hof, Gehege und Zucht

In Weidendorf hast du einen eigenen Hof, der wie in Stardew Valley von der Hütte zum Anwesen wächst. Dort leben alle Lingshou, die nicht im Gefolge sind, je zwei pro Gehege, und dort können sie sich vermehren.

**Ausbaustufen:**

| Stufe | Freigeschaltet durch | Gehegeplätze | Neu |
| --- | --- | --- | --- |
| Hütte | Spielstart | 2 | Bett, Kochstelle, Truhe |
| Haus | Ende Prolog | 4 | Einrichten mit Möbeln und Deko |
| Hof | 2. Ton zurück | 8 | Werkstatt, Futtergarten |
| Gutshof | 4. Ton zurück | 12 | Brutstube, zweites Stockwerk |
| Anwesen | Phönix wiedergeboren | 16 | Teehaus, Phönixnest als Schmuckstück |

Ausbau kostet Münzen und Materialien aus den Regionen (Bambus, Flusskiesel, Danxia-Ton, Wüstenkupfer, Wolkenjade). Der Zimmermann in Weidendorf baut, Möbel und Deko gibt es in den Städten unterwegs.

**Gehege:**

- Jedes Lingshou braucht ein Gehege, in jedes passen höchstens zwei.
- Fünf Gehegetypen nach Element: Teich (Wasser), Bambushain (Holz), Glutgrube (Feuer), Erzgrotte (Metall), Felsgarten (Erde). Im falschen Gehege sinkt die Zufriedenheit.
- Zufriedenheit (0 bis 100, im Code) steigt durch Futter, Spielzeug, passenden Gehegepartner und Besuche.
- Kein Pflegezwang: Lingshou werden nie krank und sterben nicht, wenn du lange unterwegs bist. Die Zufriedenheit sinkt nur langsam bis zu einem Mindestwert.

**Zucht:**

- Jedes Lingshou ist Männchen oder Weibchen. Ein Paar derselben Art oder desselben Elements im selben Gehege mit hoher Zufriedenheit bekommt nach einigen Spieltagen ein Ei.
- Bei gleicher Art erbt das Junge Art und Element. Bei zwei Arten desselben Elements entsteht eine Mischform aus einer festen Liste (anfangs 10 bis 15, jede mit eigenem Sprite). In beiden Fällen gilt: das Temperament kommt von einem Elternteil oder ist mit kleiner Chance neu. Die Werte schwanken leicht um den Durchschnitt der Eltern; selten gibt es eine Farbvariante.
- Himmelswächter, Silberkranich und Phönix sind einzigartig und vermehren sich nicht.

**Entwicklung:**

1. **Wachstum:** Ei, Jungtier, ausgewachsen, über Spieltage auf dem Hof oder durch Kämpfe im Gefolge.
2. **Wandlung:** Ausgewachsene Lingshou mit hoher Bindung verwandeln sich bei einem passenden Ereignis einmal in ihre stärkere Form (siehe oben).

**Zeit:** Eigene Spieluhr wie in Stardew Valley: Ein Spieltag dauert etwa 15 bis 20 echte Minuten, mit Tag und Nacht. Schlafen im eigenen Bett oder im Gasthaus beendet den Tag; Zucht und Wachstum rechnen in Spieltagen.

**Unterwegs:** An den Windspiel-Schreinen jeder Stadt tauschst du Lingshou zwischen Gefolge und Hof. Schnellreise zwischen besuchten Städten gibt es nach dem Prolog, zurück nach Weidendorf jederzeit.

**Rolle des LLM auf dem Hof:** Lingshou im selben Gehege unterhalten sich miteinander, ein Hoftagebuch fasst die Nacht zusammen („Bambär hat Zirpo beim Zirpen ausgelacht“). Diese Texte werden beim Schlafen im Voraus erzeugt, damit keine Wartezeit entsteht.

**Hofarbeit:** Neben den Gehegen gibt es Felder für Futter und Zutaten, eine Werkstatt für Handwerk (Möbel, Spielzeug, Laternen) und eine Küche; gekochte Gerichte wirken wie im Restaurant. Lingshou helfen nach Element mit: Wasser gießt, Holz lässt Pflanzen schneller wachsen, Erde lockert den Boden, Feuer heizt Küche und Brennofen, Metall hilft in der Werkstatt.

**Freilassen:** Jedes Lingshou kann freigelassen werden, mit einer kleinen Abschiedsszene. Es lebt danach sichtbar in seiner Heimatregion weiter.

## Städte, Reisen und Welt

Jede Stadt hat dieselben Grundgebäude: Shop, Bar, Restaurant, Unterkunft und einige NPC-Häuser. Was es zu kaufen gibt und wohin du reisen kannst, wächst mit dem Spielfortschritt.

**Gebäude in jeder Stadt:**

| Gebäude | Funktion | Rolle des LLM |
| --- | --- | --- |
| Shop | Futter, Heilmittel, Gehege-Material, Möbel, Reiseausrüstung; Sortiment wächst mit den zurückgeholten Tönen | Händler kommentiert Einkäufe, lässt mit sich handeln |
| Bar (Teehaus) | Gerüchte, Nebenaufgaben, Stammgäste mit eigener Geschichte | Gerüchte aus echten Spielfakten (Sichtungen, seltene Lingshou, Wetter) |
| Restaurant | Regionale Gerichte mit Wirkung für einen Spieltag, z. B. mehr Vertrauen beim Zähmen oder Schutz vor Kälte | Wirt empfiehlt passend zu Gefolge und Wetter |
| Unterkunft | Eigenes Zimmer als Nebenbasis: schlafen, speichern, Truhe, Windspiel-Schrein zum Tauschen mit dem Hof. Nicht ausbaubar | Vermieterin begrüßt dich, erzählt vom Ort |
| NPC-Häuser | Bewohner mit Alltag, Aufgaben und Tauschangeboten | Gespräche mit Charakterkarten |

**Gelände:** Wiesen, Täler, Berge, Höhlen, Flüsse, Seen und Küste. Jedes Gelände hat eigene wilde Lingshou. Höhlen sind dunkel und brauchen Licht (Laterne aus dem Shop oder ein Feuer-Lingshou).

**Reisemittel, nach und nach freigeschaltet:**

| Reisemittel | Woher | Öffnet |
| --- | --- | --- |
| Zu Fuß | Spielstart | Wege, Wiesen, Täler |
| Fahrrad | Shop, nach dem 1. Ton | Doppelte Geschwindigkeit auf Wegen und Wiesen |
| Boot | Shop oder Aufgabe am Nebelfluss | Flüsse und Seen, Inseln |
| Reiten auf Wasser-Lingshou | Bindung und Größe des Tiers | Schwimmen gegen Strömungen, Unterwasserhöhlen |
| Klettern | Gegenstand oder Erd-Lingshou | Steilwände in den Bergen |
| Fliegen auf Flug-Lingshou | Bindung und Größe, später im Spiel | Freies Fliegen zwischen besuchten Städten, Gipfel der Wolkensäulen |

Die Karte ist fest, aber Gebiete hinter Flüssen, Felswänden und Wolken bleiben verschlossen, bis das passende Reisemittel da ist. So entsteht Fortschritt ohne harte Levelsperren.

**Wetter:**

- Sonne, Regen, Gewitter, Nebel, Schnee in den Bergen, Sandsturm in den Dünen. Wechselt pro Spieltag und Region.
- Beeinflusst, welche wilden Lingshou erscheinen, und gibt Elementen im Kampf kleine Boni (Regen stärkt Wasser, Sonne stärkt Feuer).
- Manche Wege sind nur bei bestimmtem Wetter passierbar, etwa ein Flussbett bei Trockenheit.
- Fliegen ist bei Gewitter nicht möglich, Boot fahren bei Sturm gefährlich.

## Spielablauf und Kampf

Das Herzstück ist der Ruf: Im Kampf kannst du statt einer Menüattacke einen freien Befehl geben, und dein Lingshou reagiert darauf passend zu Temperament und Bindung.

**Spielschleife pro Region:**

1. Erkunden: Orte, Gerüchte, Nebenaufgaben, wilde Lingshou.
2. Begegnen: reden, beruhigen, bekämpfen oder ausweichen.
3. Zähmen oder befreien: neue Lingshou ins Gefolge holen.
4. Bindung vertiefen: Hof, Gespräche, gemeinsame Aufgaben.
5. Himmelswächter befreien: Bosskampf, ein Ton des Phönixliedes kehrt zurück, nächste Region öffnet sich.

**Kampfsystem:**

- Rundenbasiert. Wilde Lingshou kämpfen 1 gegen 1, Bosse, Orden und Himmelswächter 2 gegen 2; dort zählt auch der Teambonus nach Wu Xing.
- **Menü:** Jedes Lingshou hat vier aktive Attacken aus einem größeren Pool, außerhalb des Kampfes austauschbar, klassisch auswählbar. Damit ist das Spiel komplett ohne Texteingabe spielbar.
- **Ruf (Freitext):** Etwa „Kieselkopf, stell dich vor Tropfling und halt durch“. Das LLM übersetzt das in eine Aktion aus der erlaubten Liste, ein Ziel und eine Haltung (offensiv, defensiv, schützend).
- **Gehorsamsprobe:** Der Code würfelt mit Bindung und Temperament. Ein stures Lingshou mit wenig Bindung macht vielleicht sein eigenes Ding und sagt dir das auch.
- **Situationsbonus:** Passt der Ruf zur Lage (Deckung hinter einem Felsen in der Arena, Schwäche des Gegners), gibt es einen kleinen Bonus. Gedeckelt auf etwa 15 %, damit kreative Eingaben belohnt, aber nicht ausnutzbar sind.
- **Rufe kosten Atem:** Eine kleine Ressource pro Kampf, damit Freitext etwas Besonderes bleibt und nicht jede Runde getippt werden muss.

**Verstummte befreien:** Statt Lebenspunkte auf null zu bringen, füllst du die Herzklang-Leiste. Schaden senkt den Widerstand, Zureden und passende Rufe füllen die Leiste schneller. Bei voller Leiste spricht das Lingshou wieder mit eigener Stimme, die erste Zeile ist ein kleiner Belohnungsmoment.

**Reden außerhalb von Kämpfen:** Wächter, Händler und Ordensmitglieder lassen sich überreden. Das LLM ordnet deine Aussage einer Kategorie zu (Logik, Mitgefühl, Drohung, Bestechung, Beweis), der Code entscheidet über den Erfolg.

**Niederlage:** Sind alle Lingshou erschöpft, wachst du in der letzten Unterkunft auf, und ein Teil der Münzen ist weg. Jinli liegt neben dir und führt dich zurück zum Ort des Kampfes.

**Fortschritt:** Level von 1 bis 50 mit Erfahrung für die Werte, dazu Bindung für Gehorsam, Rufe und Wandlung. Neue Attacken kommen über Level, Lehrmeister in den Städten und Schriftrollen aus dem Shop.

**Statuseffekte rund um Klang:**

- **Verstummt:** nur Grundangriff, keine Elementattacken.
- **Echo:** die nächste Attacke wiederholt sich mit halber Stärke.
- **Dissonanz:** Befehle werden mit einer gewissen Chance falsch ausgeführt.
- **Taub:** reagiert nicht auf Rufe, nur auf Menübefehle.
- **Resonanz (positiv):** der Teambonus nach Wu Xing verdoppelt sich.

**Begegnungen:** Lingshou sind in der Welt sichtbar und lassen sich umgehen oder ansteuern; zusätzlich gibt es zufällige Begegnungen im hohen Gras und in Höhlen. Kämpfe laufen immer manuell, ohne Automodus.

## LLM-Integration

Das LLM formuliert und interpretiert, der Spielcode entscheidet. Jede Ausgabe des Modells läuft durch ein festes Format und einen Validator, und für jede Rolle gibt es eine Vorlage als Ersatz.

&#91;embedded content: LLM-Architektur · vom Ruf bis zur Aktion\]

Was das Modell liefert, kommt nur über den Validator in die Spiellogik; scheitert er oder fehlt das Modell, springen die Vorlagen ein.

| Rolle | Eingabe ans Modell | Ausgabe | Ausgabelänge |
| --- | --- | --- | --- |
| Lingshou-Stimme | Charakterkarte, Bindung, aktuelles Ereignis | 1 bis 2 Sätze Kommentar | ca. 40 Tokens |
| Ruf-Übersetzer | Freitext, erlaubte Aktionen, Kampflage | JSON: Aktion, Ziel, Haltung, Passt-zur-Lage | ca. 30 Tokens |
| NPC-Dialog | NPC-Karte, Fakten aus dem Spielzustand, Spielersatz | Antwort plus Kategorie der Spieleraussage | ca. 80 Tokens |
| Gerüchte und Lexikon | Fakten aus der Welt (Sichtungen, Fundorte) | kurzer Text, beim Laden vorab erzeugt | ca. 60 Tokens |
| Verstummte | Charakterkarte mit Status verstummt | Satzfragmente | ca. 15 Tokens |

**Charakterkarten:** Jedes Lingshou und jeder wichtige NPC hat eine Karte mit 5 bis 10 Zeilen: Temperament, Sprechstil, zwei Beispielsätze, verbotene Themen. Kurz halten, kleine Modelle verlieren sich in langen Prompts.

**Fakten statt Gedächtnis:** Das Modell bekommt pro Anfrage nur die Fakten, die es braucht, aus dem Spielzustand. Es erinnert sich an nichts selbst, deshalb kann es auch nichts Falsches über die Welt behaupten.

**Modell und Plattformen:**

- **Windows und Linux:** Modell mit 1 bis 3 Milliarden Parametern, 4-Bit-quantisiert, etwa 1 bis 2 GB. Läuft auf der GPU, notfalls auf der CPU.
- **Android und iOS:** Zielgeräte sind Oberklasse-Handys ab 8 GB RAM. Ein Modell mit 1 bis 3 Milliarden Parametern in 4 Bit ist dort machbar; Akku und Wärme bleiben die Grenzen, daher kurze Ausgaben und Vorab-Erzeugung. Das Modell als optionalen Download nach der Installation anbieten, das hält die App klein.
- **Feinabstimmung:** Später ein LoRA auf eigenen Beispieldialogen im Stil von Yunhai trainieren. Das hebt kleine Modelle deutlich, besonders für deutschen Text.

**Latenz:** Antworten werden gestreamt, Wort für Wort im Textfeld. Ein Klang-Effekt pro Silbe wie in klassischen RPGs kaschiert die Wartezeit. Ziel: erste Wörter unter einer Sekunde, Ruf-Übersetzung unter einer Sekunde.

**Schutz und Ersatz:**

- Grammatik oder JSON-Schema erzwingt das Ausgabeformat.
- Validator prüft Aktionen gegen die erlaubte Liste und filtert unpassende Wörter.
- Längenlimit pro Rolle.
- Ohne Modell (schwaches Gerät, Option aus) laufen alle Rollen über Textvorlagen. Das Spiel bleibt vollständig spielbar.
- Steam verlangt eine Offenlegung von KI-Inhalten. Für live erzeugte Inhalte müssen die Schutzmaßnahmen beschrieben werden; die Liste oben ist dafür die Grundlage.

## Grafik: HD-2D mit Umschaltung auf 2D

Beide Modi nutzen dieselbe Welt und dieselben Assets. Die Welt ist intern 3D aus Pixel-Tiles, die Figuren sind flache Sprites. Umgeschaltet werden nur Kamera und Effekte, jederzeit im Optionsmenü.

| Einstellung | HD-2D | Klassisch 2D |
| --- | --- | --- |
| Kamera | Perspektivisch, etwa 35 bis 45 Grad geneigt | Orthografisch, Draufsicht im 3/4-Winkel |
| Tiefenunschärfe (Tilt-Shift) | An, Stärke per Regler | Aus |
| Licht | Dynamische Lichter, Schatten, Bloom, Partikel | Flach, gebackenes Licht |
| Pixel | Sprites scharf, Umgebung leicht weich | Pixelgenau, Raster auf niedriger Auflösung (z. B. 640 × 360), ganzzahlig hochskaliert |
| Wirkung | Diorama, Miniaturwelt | GBA-Ära, klar und ruhig |
| Mobil | Standard auf Oberklasse-Handys | Wählbar, spart Akku |

Zusätzlich einzeln schaltbar: Unschärfe, Bloom, Partikel. Ein weicher Kameraübergang beim Umschalten macht den Wechsel selbst zum kleinen Effekt.

**Asset-Vorgaben:** Tiles 32 × 32 Pixel, Figuren 32 × 48 aus Editor-Teilen (Körper, Frisur, Kleidung, Farben), Lingshou 48 × 48 (Himmelswächter und Phönix 96 × 96). Vier Laufrichtungen, eine begrenzte Palette pro Region. Die Welt-Geometrie bleibt blockig und einfach, damit sie in der Draufsicht wie eine klassische Tilemap aussieht.

**Pipeline auf der Workstation:**

- **ComfyUI, gesteuert über Claude Code:** Konzeptbilder, Lingshou-Entwürfe, Tile-Texturen, Portraits für Dialoge. Für saubere Pixel-Art ein Pixel-Art-LoRA plus Nachbearbeitung (Palette reduzieren, auf Raster herunterskalieren, Kanten säubern). Feste Seeds und Workflows pro Asset-Typ speichern, damit der Stil über Hunderte Assets gleich bleibt.
- **Blender:** Blockige 3D-Tiles und Szenen für HD-2D, Kamerawinkel vorab testen, Normal-Maps für die Sprite-Beleuchtung erzeugen.
- **Ton:** Musik und Effekte ebenfalls über ComfyUI-Audio-Workflows. Für Lingshou-Stimmen eignet sich ein Brabbel-Prinzip wie in Animal Crossing: Silbenklänge pro Lingshou, in Tonhöhe und Tempo nach Temperament verändert. Das passt zum Klang-Thema und braucht kein Sprachausgabe-Modell.
- Pro Asset-Typ einen Prüfschritt von Hand einplanen. Generierte Sprites brauchen fast immer Korrekturen bei Animationen und Konsistenz.

**Musik:** Pentatonisch, mit Guzheng, Erhu und Dizi über Chiptune-Bass und -Schlagwerk. Jede Region hat ein Leitmotiv in ihrem Ton (Jue, Yu, Zhi, Shang, Gong); im Finale erklingen alle fünf zusammen. Verstummte Gebiete klingen gedämpft und lückenhaft, befreite Gebiete voll.

## Technik und Plattformen

Empfehlung: Godot 4 mit llama.cpp als eingebundene Bibliothek. Godot exportiert nach Windows, Linux, Android und iOS aus einem Projekt, ist kostenlos und kommt mit HD-2D-Effekten mit.

| Bereich | Wahl | Begründung |
| --- | --- | --- |
| Engine | Godot 4 | Ein Projekt für alle vier Plattformen, Sprite3D mit Billboard, Tiefenunschärfe über Kamera-Attribute, keine Lizenzkosten |
| LLM-Laufzeit | llama.cpp per GDExtension | Läuft auf Windows, Linux, Android und iOS, nutzt GPU (CUDA, Vulkan, Metal) oder CPU; vorhandene Community-Plugins prüfen, sonst eigene Bindung |
| Modellformat | GGUF, 4-Bit | Eine Datei pro Plattformklasse: größeres Modell für PC, kleineres für Mobil |
| Spieldaten | JSON oder Godot-Resources | Lingshou, Attacken, Charakterkarten und Dialogvorlagen als Daten, nicht im Code |
| Asset-Erzeugung | ComfyUI über Claude Code, Blender | Auf der Workstation, Workflows versioniert im Repository |
| Versionierung | Git mit LFS | Große Asset-Dateien und Modelle außerhalb des normalen Repos |

**Plattform-Fahrplan:**

- **Android zuerst:** Google Play, Einmalkauf, Oberklasse ab 8 GB RAM. Touch ist die Hauptsteuerung, Controller werden unterstützt. Das Modell wird beim ersten Start heruntergeladen oder über Play Asset Delivery ausgeliefert, damit die App klein bleibt.
- **Google-Play-Regeln:** Für KI-generierte Inhalte verlangt Google eine Meldefunktion im Spiel; ein Melden-Knopf im Dialogfenster gehört deshalb zur ersten Version. Dazu kommt die Altersfreigabe über den IARC-Fragebogen.
- **Steam danach:** Windows, Linux und Steam Deck aus demselben Projekt, mit Tastatur und Controller. Die Steam-Seite schon während der Android-Entwicklung anlegen, um Wunschlisten zu sammeln.
- **iOS optional:** Apple-Richtlinien für generierte Inhalte beachten, die Prüfung dauert länger.

**Sprachen:** Englisch, Deutsch und vereinfachtes Chinesisch (zh-Hans) von Anfang an einplanen, zuerst Englisch und Deutsch ausliefern.

- Alle Texte laufen über Übersetzungsschlüssel (Godot-Übersetzungssystem mit CSV- oder PO-Dateien), nie fest im Code.
- Charakterkarten und Textvorlagen gibt es pro Sprache; das LLM antwortet in der gewählten Spielsprache.
- Chinesisch ist für das LLM kein Nachteil: Kleine Modelle aus der Qwen-Familie sind in Chinesisch besonders stark.
- Pixel-Schrift mit chinesischen Zeichen früh testen, z. B. eine quelloffene Pixel-Schrift unter OFL-Lizenz. Chinesische Zeichen brauchen mehr Pixelhöhe; Textboxen müssen das aushalten.
- Die chinesische Übersetzung von Muttersprachlern prüfen lassen, besonders Namen und mythologische Begriffe.
- Für den Verkauf in Festlandchina ist eine staatliche Spielelizenz nötig. Über Steam erreicht ein chinesischsprachiges Spiel trotzdem viele Spieler.

**Online vorbereiten:** Zum Start ist das Spiel komplett offline. Damit Tausch und Kämpfe gegen Freunde später nachrüstbar sind: eindeutige IDs für jedes Lingshou, ein versioniertes Spielstandformat und ein deterministischer Kampf mit Startwert.

## Roadmap und Umfang

Zuerst beweisen, dass der Ruf Spaß macht, dann erst Inhalte bauen. Die Phasen enden jeweils mit einer klaren Prüfung, Zeiten sind grobe Schätzungen bei über 20 Stunden pro Woche.

1. **Phase 0, LLM-Prototyp auf Android (3 bis 4 Wochen):** Graue Kästen auf einem Oberklasse-Testgerät, Kampf 1 gegen 1 und 2 gegen 2, Ruf per Antippen, Sprache und Tastatur, Lingshou-Stimme.
   - Prüfung: Macht der Ruf mehr Spaß als das Menü? Antwort unter 1 s? Akku und Wärme nach 30 Minuten Spiel in Ordnung?
2. **Phase 1, Grafik-Prototyp (3 bis 4 Wochen):** Testkarte im 32-Pixel-Raster, HD-2D und 2D umschaltbar, Grundgerüst des Charakter-Editors, ComfyUI-Workflows für Tiles und Sprites.
   - Prüfung: Sehen generierte Assets nach Nachbearbeitung einheitlich aus?
3. **Phase 2, Vertical Slice (2 bis 3 Monate):** Weidendorf mit Hütte und Gehegen, Bambusmeer mit zwei Städten, 15 Lingshou, erster Himmelswächter, Spieluhr und Wetter, etwa zwei Stunden Spielzeit.
   - Prüfung: Fünf fremde Testspieler spielen ohne Hilfe durch.
4. **Phase 3, geschlossener Test auf Google Play:** Store-Eintrag, IARC-Altersfreigabe, Meldefunktion für KI-Inhalte, Test mit ausgewählten Spielern.
   - Prüfung: Absturzrate, Akku, Rückmeldungen.
5. **Phase 4, Vollversion Android (12 bis 18 Monate):** Fünf Regionen mit je zwei bis drei Städten, 60 bis 80 Lingshou, mehrere Enden, 20 Stunden und mehr, Hof bis zum Anwesen, Zucht.
6. **Phase 5, Steam:** Windows, Linux, Steam Deck, Tastatur und Controller, HD-2D-Feinschliff für große Bildschirme.
7. **Phase 6, optional:** iOS, Tausch und Kämpfe gegen Freunde.

**Bewusst nicht im ersten Release:** Mehrspieler, Tausch, Sprachausgabe mit echter Stimme, offene Welt ohne Regionen.

## Risiken und offene Fragen

Das größte Risiko ist nicht die Technik, sondern dass der Ruf nach der ersten Stunde zur Spielerei wird. Deshalb steht er in Phase 0 auf dem Prüfstand.

| Risiko | Folge | Gegenmaßnahme |
| --- | --- | --- |
| Freitext nutzt sich ab | Spieler tippen nur noch ins Menü | Atem-Ressource, vorgeschlagene Rufe, Rufe in Bosskämpfen wichtiger machen |
| Kleine Modelle schreiben schwächeres Deutsch | Holprige Dialoge | Englisch als Hauptsprache testen, LoRA auf deutschen Beispielen, kurze Ausgaben |
| Unpassende oder seltsame Ausgaben | Bruch der Atmosphäre, Ärger bei Stores | Format-Zwang, Validator, Wortfilter, Vorlagen als Ersatz |
| Schwache Hardware, vor allem Mobil | Lange Wartezeiten, Akku, Hitze | Kleineres Modell, Vorab-Erzeugung beim Laden, Modell abschaltbar |
| Uneinheitliche KI-Assets | Spiel wirkt zusammengewürfelt | Feste Workflows und Paletten, Prüfschritt von Hand |
| Zu großer Umfang für ein Nebenprojekt | Spiel wird nie fertig | Vertical Slice zuerst, Liste „nicht im ersten Release“ einhalten |

**Offene Fragen:**

- [ ] Markenprüfung für Wuyin (DPMA, EUIPO, Google Play, Steam, Domains)
- [ ] Welches lokale Modell liefert auf dem Testgerät die besten kurzen Dialoge in Deutsch, Englisch und Chinesisch?
- [ ] Konkretes Testgerät und Android-Mindestversion festlegen
- [ ] Preis 4,99 € nach dem geschlossenen Test noch einmal prüfen; Steam-Preis festlegen
- [ ] Liste der Entscheidungen, die zu den Enden führen
- [ ] Altersfreigabe: Ziel ab 6 oder ab 12?

## Lizenzen und Rechte

Klassische chinesische Mythologie ist gemeinfrei und frei nutzbar. Geschützt sind moderne Umsetzungen: konkrete Designs, Namen und Begriffe aus heutigen Spielen, Filmen und Serien. Dies ist eine Planungshilfe, keine Rechtsberatung; vor dem Release Marken und Patente von einer Fachkanzlei prüfen lassen.

**Frei nutzbar:**

- Wesen und Motive aus klassischen Quellen: Shanhaijing („Klassiker der Berge und Meere“), die Vier Symbole, Qilin, Fenghuang, Bifang, die Nian-Legende.
- Lehren und Ordnungen: Fünf Wandlungen (Wu Xing), fünf Töne (Wu Yin), Himmelsrichtungen.
- Klassische Literatur wie „Die Reise nach Westen“ (16. Jahrhundert), sofern nur das Original genutzt wird, nicht moderne Adaptionen.
- Echte Landschaften als Vorbild; im Spiel nur Fantasienamen.

**Bewusst meiden:**

- Pokémon-Begriffe und -Gegenstände: Pokéball, Pokédex, Arenaleiter, „Trainer“ als Titel, Namen auf „-mon“.
- Designs, die an bekannte Monster erinnern. Besonders Phönix, Drache, Fuchs und Karpfen haben bekannte Vorbilder in anderen Spielen; hier bewusst eigene Silhouetten und Farben wählen.
- Figuren, Stil und Begriffe aus Black Myth: Wukong, Genshin Impact, Kung Fu Panda und ähnlichen Werken.
- Fang-Mechaniken mit geworfenem Gegenstand: Nintendo hat Patente auf solche Abläufe und klagt dagegen (2024 gegen den Entwickler von Palworld). Zähmen durch Vertrauen ohne Wurfobjekt ist auch rechtlich die bessere Wahl.
- Reale religiöse Gottheiten als Bösewichte. Der Gegenspieler Wusheng ist eine erfundene menschliche Figur.

**KI-Werkzeuge:**

- ComfyUI: Lizenzen der Basismodelle und LoRAs auf kommerzielle Nutzung prüfen und in einer Liste im Repo festhalten. Keine LoRAs, die auf bekannte Spiele oder Marken trainiert sind; keine Franchise-Namen in Prompts.
- Sprachmodell: Die Lizenz muss Weitergabe im Spiel und kommerzielle Nutzung erlauben (z. B. Apache 2.0). Lizenztext der Spieldatei beilegen.
- Steam und App Stores: Offenlegung vorab erzeugter und live erzeugter KI-Inhalte.

## Übergabe an Claude Code

Dieses Dokument als Markdown exportieren und als `docs/GDD.md` ins Repo legen. Eine kurze `CLAUDE.md` im Wurzelverzeichnis verweist darauf und enthält die Grundregeln unten. Claude Code arbeitet die Meilensteine der Reihe nach ab; jeder gilt erst als fertig, wenn alle Abnahmekriterien erfüllt sind.

**Grundregeln (gelten für jede Änderung):**

1. Der Spielzustand lebt nur im Code. Das LLM liest Fakten, schreibt aber nie direkt Werte.
2. Jede LLM-Ausgabe läuft durch JSON-Schema oder Grammatik und danach durch einen Validator.
3. Jede LLM-Rolle hat Textvorlagen als Ersatz. Mit `llm_enabled = false` ist das Spiel vollständig spielbar.
4. Inhalte sind Daten: Lingshou, Attacken, Charakterkarten, Dialogvorlagen, Karten als JSON, nicht im Code. Alle Texte über Übersetzungsschlüssel für Englisch, Deutsch und vereinfachtes Chinesisch.
5. Kein Pokémon-Vokabular in Code, Daten oder Texten (siehe Lizenzen und Rechte).
6. Spiellogik hat automatisierte Tests; Kampf und Zucht sind mit festem Zufallsstartwert reproduzierbar.
7. Plattformen von Anfang an: Android zuerst, Windows und Linux für Steam später, iOS optional; Touch, Controller und Tastatur von Anfang an.

**Repo-Struktur:**

```
wuyin/
  CLAUDE.md
  docs/GDD.md
  game/                  Godot-4-Projekt
    scenes/              world/, battle/, farm/, ui/
    scripts/             core/ (Zustand, Speichern), battle/, farm/, llm/
    data/                lingshou/, moves/, cards/, templates/, maps/
    assets/              sprites/, tiles/, audio/ (nur fertige Dateien)
    tests/
  addons/llama/          GDExtension für llama.cpp
  models/                GGUF-Dateien, per Git LFS, nicht im Spielordner
  tools/
    comfyui/             Workflows (JSON) und Aufrufskripte
    postprocess/         Python: Palette, Herunterskalieren, Spritesheets
    blender/             Skripte für Tiles und Kameratests
  LICENSES.md            Lizenzen aller Modelle, LoRAs und Assets
```

**Datenformat eines Lingshou:**

```json
{
  "id": "wawalurch",
  "name": "Wawalurch",
  "animal": "Chinesischer Riesensalamander",
  "element": "water",
  "temperaments": ["anxious"],
  "alignment": "wild",
  "base_stats": { "hp": 45, "atk": 30, "def": 50, "spd": 25 },
  "moves": ["strömungsruf", "kinderweinen", "schlammwand", "tauchen"],
  "habitat": "pond",
  "can_breed": true,
  "transform": { "into": "stromdrache_lurch", "min_bond": 80, "event": "flood_rescue" },
  "voice_card": "cards/wawalurch.md"
}
```

**Ausgabe des Ruf-Übersetzers (vom Validator geprüft):**

```json
{
  "action": "move:schlammwand",
  "target": "ally:0",
  "stance": "protective",
  "fits_situation": true,
  "reply": "I-ich versuch's ... bleib hinter mir!"
}
```

**Meilensteine Phase 0 (LLM-Prototyp):**

- [ ] **M0.1 Projektgerüst:** Godot-4-Projekt mit obiger Struktur, Export-Vorlagen für Android (zuerst), Windows und Linux, Testlauf in der Konsole. Abnahme: leeres Spiel startet auf einem Android-Testgerät und unter Linux, Tests laufen.
- [ ] **M0.2 Kampfkern:** Rundenbasierter Kampf 1 gegen 1 und 2 gegen 2 nur mit Menü, Level und Klang-Statuseffekte, Wu-Xing-Typvorteil und Teambonus, Lingshou aus JSON. Abnahme: Testfälle für jeden Typvorteil, gleicher Startwert ergibt gleichen Kampfverlauf.
- [ ] **M0.3 LLM-Dienst:** llama.cpp-Anbindung mit Streaming, Grammatik für JSON, Zeitlimit 3 s mit Rückfall auf Vorlagen. Abnahme: Antwort unter 1 s auf einem Oberklasse-Android-Gerät mit 1–3B-Modell, Spiel läuft ohne Modelldatei.
- [ ] **M0.4 Ruf:** Freitext im Kampf, Übersetzer plus Validator, Gehorsamsprobe nach Bindung und Temperament, Situationsbonus maximal 15 %. Abnahme: 50 Testsätze (Deutsch und Englisch) liefern nur gültige Aktionen.
- [ ] **M0.5 Stimme:** Charakterkarten, Kommentare im Kampf, Verstummte in Fragmenten. Abnahme: Ausgabe nie länger als das Limit der Rolle, Vorlagen greifen bei leerer oder ungültiger Antwort.
- [ ] **M0.6 Kameramodi:** Testkarte mit Billboard-Sprites, Umschaltung HD-2D und klassisch 2D zur Laufzeit. Abnahme: beide Modi flüssig, Pixel im 2D-Modus ganzzahlig skaliert.

**Danach (Phase 1 und 2, grob):** Asset-Pipeline per ComfyUI-API und Nachbearbeitung, Oberwelt Weidendorf und Bambusmeer, Hof mit Hütte und zwei Gehegen, Zähmen, Gefolge mit Windspiel-Glöckchen, Spielstand speichern, Tag-Nacht-Zyklus, Wetter, Städte mit Shop, Bar, Restaurant und Unterkunft, Reisemittel Fahrrad und Boot, Zucht.

**Vor dem Start zu entscheiden:** die offenen Fragen im Abschnitt Risiken.
