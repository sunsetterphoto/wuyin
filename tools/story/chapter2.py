"""Act 2, first half: the Crossroads, the Misty River (water, tone Yu, the
Black Tortoise Xuanwu) and Rainbow Ridge (fire, tone Zhi, the fire bird
Bifang), in any order. Part of tools/story/build.py."""
from common import *

E = {}

# --- people -------------------------------------------------------------------------
person("rast_wirt", "Mönch Ruo", "Monk Ruo", "若和尚", "shang", "gentle", -1)
person("order_west", "Bruder Kai", "Brother Kai", "凯师兄", "shang", "stubborn", 0)
person("order_north", "Schwester Mei", "Sister Mei", "梅师姐", "shang", "gentle", 0)
person("kreuz_haendler", "Wanderhändlerin Lin", "Pedlar Lin", "林货郎", "zhi", "playful", 0)
person("fischer", "Fischer Zhou", "Fisher Zhou", "周渔翁", "yu", "gentle", -1)
person("bootsfrau", "Bootsfrau Lan", "Boatwoman Lan", "兰船娘", "yu", "brave", 0)
person("hafen_kind", "Xiao Yu", "Xiao Yu", "小鱼", "jue", "playful", 1)
person("hafen_alter", "Großvater Pan", "Grandpa Pan", "潘爷爷", "gong", "gentle", -1)
person("order_bucht", "Bruder Mo", "Brother Mo", "默师兄", "shang", "stubborn", 0)
person("muschelfrau", "Muschelsammlerin Pei", "Shell Gatherer Pei", "佩拾贝人", "yu", "gentle", 0)
person("xuanwu", "Xuanwu", "Xuanwu", "玄武", "yu", "stubborn", -1)
person("xuanwu_free", "Xuanwu", "Xuanwu", "玄武", "yu", "stubborn", -1)
person("foerster", "Förster Ah Mu", "Forester Ah Mu", "阿木", "jue", "gentle", 0)
person("buergermeisterin", "Bürgermeisterin Hong", "Mayor Hong", "洪镇长", "zhi", "stubborn", 0)
person("toepfer", "Töpfer Shi", "Potter Shi", "石陶匠", "gong", "stubborn", -1)
person("rotfels_kind", "Huo Huo", "Huo Huo", "火火", "zhi", "playful", 1)
person("order_gipfel", "Schwester Yun", "Sister Yun", "云师姐", "shang", "gentle", 0)
person("einsiedler", "Einsiedler Feng", "Hermit Feng", "风隐士", "zhi", "gentle", -1)
person("bifang", "Bifang", "Bifang", "毕方", "zhi", "brave", 0)
person("bifang_free", "Bifang", "Bifang", "毕方", "zhi", "brave", 0)

# --- after a tone: what's next (any order) ----------------------------------------------
E["after_tone"] = [
    {"if_tones": 5, "then": [
        {"set": "five_tones"},
        quest("QUEST_TEMPLE", "Alle fünf Töne sind zurück! Steig in Kiefernhang die Wolkentreppe hinauf zum Phönixtempel.",
              "All five tones are back! Climb the cloud stairs in Pinecliff up to the Phoenix Temple.",
              "五音全部找回了！从松崖村登上云梯，前往凤凰庙。"),
        {"goal": ["kiefernhang", 16, 2]},
    ], "else": [
        {"if_tones": 4, "then": [
            {"if": "tone_shang",
             "then": [quest("QUEST_LAST_GONG", "Ein Ton fehlt noch: Gong bei den Wolkensäulen. Der Weg führt vom Kreuzweg nach Norden die Steintreppe hinauf.",
                            "One tone is still missing: Gong at the Cloud Pillars. The way leads north from the Crossroads, up the stone stairs.",
                            "还差一个音：云柱的“宫”。从十字路口往北，登上石阶。"), {"goal": ["kiefernhang", 17, 12]}],
             "else": [quest("QUEST_LAST_SHANG", "Ein Ton fehlt noch: Shang in den Singenden Dünen. Der Weg führt vom Kreuzweg nach Westen.",
                            "One tone is still missing: Shang in the Singing Dunes. The way leads west from the Crossroads.",
                            "还差一个音：鸣沙丘的“商”。从十字路口往西走。"), {"goal": ["mondquell", 16, 18]}]},
        ], "else": [
            {"if_tones": 3, "then": [
                {"set": "three_tones"},
                quest("QUEST_HOME_VOICE", "Drei Töne sind zurück. Jinli spitzt die Ohren: In Weidendorf ist etwas geschehen. Kehr heim!",
                      "Three tones are back. Jinli pricks up her ears: something has happened in Willowdale. Go home!",
                      "已经找回了三个音。锦鲤竖起了耳朵：柳村出事了。快回家！"),
                {"goal": ["weidendorf", 16, 11]},
            ], "else": [
                {"if": "tone_yu",
                 "then": [quest("QUEST_ZHI", "Yu ist zurück. Jetzt fehlt Zhi im Süden: vom Kreuzweg nach Süden zum Regenbogengrat.",
                                "Yu is back. Now Zhi is missing in the south: from the Crossroads south to Rainbow Ridge.",
                                "“羽”回来了。现在还差南方的“徵”：从十字路口往南去彩虹岭。"), {"goal": ["rotfels", 16, 10]}],
                 "else": [quest("QUEST_YU", "Zhi ist zurück. Jetzt fehlt Yu im Norden: vom Kreuzweg nach Norden zum Nebelfluss.",
                                "Zhi is back. Now Yu is missing in the north: from the Crossroads north to the Misty River.",
                                "“徵”回来了。现在还差北方的“羽”：从十字路口往北去雾河。"), {"goal": ["nebelhafen", 16, 20]}]},
            ]},
        ]},
    ]},
    {"save": True},
]
for name, de, en, zh in [
    ("TEMPLE", ["Miau! (Jinli schaut hoch hinauf, zu den Wolken.)", "Miau, miau! (In Kiefernhang führt eine Wolkentreppe nach oben.)", "Miaaau! (Kiefernhang, ganz oben in der Mitte: die Wolkentreppe zum Phönixtempel. Alle fünf Töne klingen!)"],
     ["Mew! (Jinli looks high up, at the clouds.)", "Mew, mew! (In Pinecliff a cloud staircase leads upwards.)", "Meeew! (Pinecliff, top middle: the cloud stairs to the Phoenix Temple. All five tones are ringing!)"],
     ["喵！（锦鲤抬头望向高高的云端。）", "喵喵！（松崖村有一道云梯通往上方。）", "喵——！（松崖村正上方：通往凤凰庙的云梯。五音齐鸣！）"]),
    ("LAST_GONG", ["Miau! (Jinli schaut zu den großen Steinsäulen.)", "Miau, miau! (Vom Kreuzweg die Steintreppe nach Norden hinauf.)", "Miaaau! (Kreuzweg, oben in der Mitte: die Treppe zum Säulenpfad, dann nach Kiefernhang und rechts zum Qilin-Plateau.)"],
     ["Mew! (Jinli looks at the great stone pillars.)", "Mew, mew! (From the Crossroads, up the stone stairs to the north.)", "Meeew! (Crossroads, top middle: the stairs to the Pillar Path, then to Pinecliff and right to the Qilin Plateau.)"],
     ["喵！（锦鲤望着巨大的石柱。）", "喵喵！（从十字路口沿石阶往北走。）", "喵——！（十字路口正上方的石阶通往石柱道，再到松崖村，往右就是麒麟台。）"]),
    ("LAST_SHANG", ["Miau! (Jinli schaut nach Westen.)", "Miau, miau! (Vom Kreuzweg nach Westen, über den Dünenweg nach Mondquell.)", "Miaaau! (Kreuzweg, ganz links: der Dünenweg. In Mondquell geht es oben zum Singenden Kamm.)"],
     ["Mew! (Jinli looks west.)", "Mew, mew! (From the Crossroads west, along the Dune Road to Moonspring.)", "Meeew! (Crossroads, far left: the Dune Road. In Moonspring the way to the Singing Crest is at the top.)"],
     ["喵！（锦鲤望向西方。）", "喵喵！（从十字路口往西，沿沙丘路去月泉镇。）", "喵——！（十字路口最左边是沙丘路。月泉镇上方通往鸣沙脊。）"]),
    ("HOME_VOICE", ["Miau! (Jinli zieht dich Richtung Heimat.)", "Miau, miau! (Zurück nach Weidendorf – am schnellsten mit dem Windspiel einer Unterkunft.)", "Miaaau! (Reise mit dem Windspiel-Schrein einer Unterkunft nach Weidendorf. Etwas wartet auf dem Festplatz.)"],
     ["Mew! (Jinli pulls you towards home.)", "Mew, mew! (Back to Willowdale - fastest with an inn's wind chime.)", "Meeew! (Travel to Willowdale with an inn's wind chime shrine. Something waits on the festival square.)"],
     ["喵！（锦鲤拉着你往家的方向走。）", "喵喵！（回柳村——用客栈的风铃最快。）", "喵——！（用客栈的风铃神龛回柳村。节日广场上有什么在等着。）"]),
    ("ZHI", ["Miau! (Jinli schaut nach Süden.)", "Miau, miau! (Vom Kreuzweg nach Süden, den Danxia-Pfad hinunter.)", "Miaaau! (Kreuzweg, unten in der Mitte: der Danxia-Pfad nach Rotfels. Hinter Rotfels liegt der Feuergipfel.)"],
     ["Mew! (Jinli looks south.)", "Mew, mew! (From the Crossroads south, down the Danxia Trail.)", "Meeew! (Crossroads, bottom middle: the Danxia Trail to Redrock. Beyond Redrock is the Fire Peak.)"],
     ["喵！（锦鲤望向南方。）", "喵喵！（从十字路口往南，走丹霞小径。）", "喵——！（十字路口正下方是去赤岩镇的丹霞小径。赤岩镇后面就是火峰。）"]),
    ("YU", ["Miau! (Jinli schaut nach Norden.)", "Miau, miau! (Vom Kreuzweg nach Norden, links an den Säulen vorbei.)", "Miaaau! (Kreuzweg, oben links: der Weg zum Karstufer und nach Nebelhafen.)"],
     ["Mew! (Jinli looks north.)", "Mew, mew! (From the Crossroads north, left past the pillars.)", "Meeew! (Crossroads, top left: the road to the Karst Bank and Misthaven.)"],
     ["喵！（锦鲤望向北方。）", "喵喵！（从十字路口往北，从石柱左边绕过去。）", "喵——！（十字路口左上方是去岩溶河岸和雾港的路。）"]),
]:
    hints(name, de, en, zh)

# --- Kreuzweg -------------------------------------------------------------------------
E["kreuzweg_arrive"] = [
    {"set": "kreuzweg_arrived"},
    say("narrator", "EV_KW_1", "Der Kreuzweg am Fuß der Wolkensäulen. Hier treffen sich die Straßen aller fünf Regionen. Über dir ragen Steinsäulen bis in die Wolken.",
        "The Crossroads at the foot of the Cloud Pillars. The roads of all five regions meet here. Stone pillars tower above you into the clouds.",
        "云柱脚下的十字路口。五个地区的道路在这里交汇。头顶上，石柱直插云霄。"),
    say("narrator", "EV_KW_2", "Vor der Steintreppe nach Norden und am Weg nach Westen stehen Gestalten in grauen Kutten, ein geschlossenes Auge auf der Schärpe.",
        "In front of the stone stairs to the north and on the road west stand figures in grey robes, a closed eye on their sashes.",
        "往北的石阶前和往西的路上，站着身穿灰袍的人，腰带上绣着一只闭着的眼睛。"),
    say("jinli", "EV_KW_3", "Miau! (Jinli dreht sich im Kreis: Sie hört zwei Töne – einen im Norden, links an den Säulen vorbei, und einen tief im Süden.)",
        "Mew! (Jinli turns in a circle: she hears two tones - one in the north, left past the pillars, and one deep in the south.)",
        "喵！（锦鲤原地转了一圈：她听到了两个音——一个在北边，从石柱左边绕过去；一个在遥远的南方。）"),
    say("narrator", "EV_KW_TUT", "Im Rasthaus kannst du schlafen, speichern und mit dem Windspiel reisen. Nachts flattern Schattenmotten durchs Gras.",
        "At the rest house you can sleep, save and travel with the wind chime. At night shadow moths flutter through the grass.",
        "在驿站可以睡觉、存档，也可以乘风铃旅行。夜里会有影蛾在草丛中飞舞。"),
    {"set_inn": ["kreuzweg", "inn"]},
]
E["kreuzweg_inn"] = [
    say("rast_wirt", "EV_KW_INN", "Ein Lager, eine Schale Reis und das Windspiel des Rasthauses. Mehr braucht kein Wanderer.", "A bed, a bowl of rice and the rest house's wind chime. No traveller needs more.", "一张床、一碗饭，还有驿站的风铃。旅人不需要更多了。"),
    {"set_inn": ["kreuzweg", "inn"]}, {"inn": True},
]
E["kreuzweg_sign"] = [say("narrator", "EV_KW_SIGN", "Wegweiser: Norden (links) – Nebelfluss. Norden (Treppe) – Wolkensäulen. Westen – Singende Dünen. Süden – Regenbogengrat. Osten – Teeufer.",
                          "Signpost: North (left) - Misty River. North (stairs) - Cloud Pillars. West - Singing Dunes. South - Rainbow Ridge. East - Teabank.",
                          "路牌：北（左）——雾河。北（石阶）——云柱。西——鸣沙丘。南——彩虹岭。东——茶岸镇。")]
E["kreuzweg_trader"] = [
    say("kreuz_haendler", "EV_KW_TRADER", "Bambus, Kiesel, Ton, Kupfer – ich hab von allem ein bisschen. Für deinen Hof, Lehrling?", "Bamboo, pebbles, clay, copper - I've got a little of everything. For your farm, apprentice?", "竹子、卵石、陶土、铜——我什么都有一点。给你的农庄用吗，学徒？"),
    {"shop": ["bambus", "flusskiesel", "danxia_ton", "reisbaellchen", "jasmintee", "flussmuscheln", "chilischoten"]},
]
for eid, who, de, en, zh in [
    ("order_block_west", "order_west", "Die Singenden Dünen schweigen, und das ist gut so. Niemand geht dorthin, bis die Ordensmeisterin es erlaubt.",
     "The Singing Dunes are silent, and that's good. Nobody goes there until the Grand Mistress allows it.",
     "鸣沙丘沉默了，这很好。在教团大师允许之前，谁也不许去。"),
    ("order_block_north", "order_north", "Die Wolkensäulen sind gesperrt. Oben wartet der Großkanzler auf das Ende aller Enden. Kehr um, Kind – es ist friedlicher so.",
     "The Cloud Pillars are closed. Up there the Grand Chancellor waits for the end of all endings. Turn back, child - it's more peaceful this way.",
     "云柱封闭了。大司仪在上面等待一切终结的终结。回去吧，孩子——这样更安宁。"),
]:
    E[eid] = [say(who, "EV_" + eid.upper(), de, en, zh),
              say("jinli", "EV_" + eid.upper() + "_J", "Miau. (Jinli zieht dich weg. Erst die anderen Töne.)", "Mew. (Jinli pulls you away. The other tones first.)", "喵。（锦鲤把你拉走了。先去找其他的音。）")]

# --- Nebelfluss ------------------------------------------------------------------------
E["karstufer_arrive"] = [
    {"set": "karstufer_arrived"},
    say("narrator", "EV_KU_1", "Grüne Kegelberge wachsen aus dem Nebel. Der Fluss liegt still wie ein Spiegel – kein Plätschern, kein Ruf eines Vogels.",
        "Green cone mountains rise out of the mist. The river lies still as a mirror - no splashing, no bird calling.",
        "青翠的锥形山峰从雾中升起。河面静如明镜——没有水声，没有鸟鸣。"),
    rquest("river", "QUEST_RIVER_1", "Folge dem Ufer nach Norden bis Nebelhafen.", "Follow the bank north to Misthaven.", "沿河岸往北走到雾港。"),
    {"goal": ["nebelhafen", 16, 20], "region": "river"},
]
hints("RIVER_1", ["Miau! (Jinli schaut flussaufwärts.)", "Miau, miau! (Über die Holzbrücke oben rechts geht es nach Nebelhafen.)", "Miaaau! (Den Weg in der Mitte hinauf, dann rechts über die Brücke nach Nebelhafen.)"],
      ["Mew! (Jinli looks upstream.)", "Mew, mew! (Over the wooden bridge at the top right to Misthaven.)", "Meeew! (Up the path in the middle, then right over the bridge to Misthaven.)"],
      ["喵！（锦鲤望向上游。）", "喵喵！（从右上方的木桥过去就是雾港。）", "喵——！（沿中间的路往上走，再往右过桥就到雾港了。）"])
E["chest_karst"] = [say("narrator", "EV_CHEST_KARST", "Zwischen den Felsen klemmt eine Kiste mit Fischernetz-Knoten.", "A chest with fishing-net knots is wedged between the rocks.", "岩石间卡着一个打着渔网结的箱子。"),
                    {"give_item": "flusskiesel", "n": 3}, {"give_item": "jasmintee", "n": 1}, {"set": "chest_karst"}, {"refresh": True}]

E["nebelhafen_arrive"] = [
    {"set": "nebelhafen_arrived"},
    say("narrator", "EV_NH_1", "Nebelhafen. Boote liegen reglos am Steg, Netze hängen trocken. Ohne Strömung fährt kein Boot, ohne Kormorane fängt niemand Fisch.",
        "Misthaven. Boats lie motionless at the pier, nets hang dry. Without a current no boat sails, without cormorants nobody catches fish.",
        "雾港。船只一动不动地靠在码头，渔网晾着。没有水流就开不了船，没有鸬鹚就打不到鱼。"),
    say("jinli", "EV_NH_2", "Miau. (Jinli schaut über den See. Irgendwo dort draußen, im Nebel, liegt der Ton Yu.)", "Mew. (Jinli looks across the lake. Somewhere out there, in the mist, lies the tone Yu.)", "喵。（锦鲤望着湖面。在那片雾的某处，藏着“羽”音。）"),
    rquest("river", "QUEST_RIVER_2", "Du brauchst ein Boot. Frag den alten Fischer Zhou (unten links).", "You need a boat. Ask old Fisher Zhou (bottom left).", "你需要一条船。去问问老渔翁周（左下方）。"),
    {"goal": ["nebelhafen", 6, 18], "region": "river"},
    {"set_inn": ["nebelhafen", "inn"]},
]
hints("RIVER_2", ["Miau! (Jinli schaut zur Fischerhütte.)", "Miau, miau! (Die kleine Hütte unten links gehört dem Fischer.)", "Miaaau! (Unten links in Nebelhafen: Fischer Zhou. Er hat ein Boot.)"],
      ["Mew! (Jinli looks at the fisher's hut.)", "Mew, mew! (The little hut at the bottom left belongs to the fisher.)", "Meeew! (Bottom left in Misthaven: Fisher Zhou. He has a boat.)"],
      ["喵！（锦鲤望向渔夫的小屋。）", "喵喵！（左下方的小屋是渔夫的。）", "喵——！（雾港左下方：周渔翁。他有船。）"])
E["fischer"] = [
    {"if": "has_boat", "then": [say("fischer", "EV_FI_DONE", "Das Boot liegt am Steg. Fahr nur, und grüß mir die alte Schildkröte.", "The boat is at the pier. Off you go, and say hello to the old tortoise for me.", "船在码头。去吧，替我向老玄龟问好。")],
     "else": [{"if": "kormoran_done", "then": [
         {"if": "kormoran_freed",
          "then": [say("fischer", "EV_FI_FREED_1", "Bai! Mein Bai ist wieder da – und er ruft wieder! Kind, du hast ihm seine Stimme zurückgegeben.", "Bai! My Bai is back - and he's calling again! Child, you gave him back his voice.", "小白！我的小白回来了——又会叫了！孩子，是你让它找回了声音。"),
                   say("fischer", "EV_FI_FREED_2", "Weißt du, jeden Herbst lasse ich ihn ziehen. Er fliegt nach Süden, und ich denke jedes Mal, das war's. Aber jeden Frühling kommt er zurück. Festhalten hätte ihn nie zu mir zurückgebracht.",
                       "You know, every autumn I let him go. He flies south, and every time I think that's it. But every spring he comes back. Holding on would never have brought him back to me.",
                       "你知道吗，每年秋天我都放它走。它飞去南方，每次我都以为再也见不到了。可每年春天它都会回来。抓着不放，是永远换不回它的。"),
                   {"set": "lesson_fisher"}],
          "else": [say("fischer", "EV_FI_DEF", "Bai sitzt wieder hier, aber seine Augen bleiben grau. Er ist erschöpft … und stumm. Trotzdem danke, dass du ihn hergebracht hast.",
                       "Bai sits here again, but his eyes stay grey. He's exhausted... and mute. Thank you anyway for bringing him here.",
                       "小白又回来了，可它的眼睛还是灰的。它累坏了……也不会叫了。不过还是谢谢你把它带回来。")]},
         say("fischer", "EV_FI_BOAT", "Nimm mein Boot. Ohne Strömung musst du rudern, aber bis zur Schildkrötenbucht schaffst du es. Lauf einfach den Steg hinauf.",
             "Take my boat. Without a current you'll have to row, but you'll make it to Tortoise Bay. Just walk up the pier.",
             "用我的船吧。没有水流得自己划，不过划到玄龟湾没问题。沿着码头往前走就行。"),
         {"give_item": "boot", "n": 1}, {"set": "has_boat"},
         rquest("river", "QUEST_RIVER_4", "Fahr mit dem Boot vom Steg zur Schildkrötenbucht und wecke Xuanwu.", "Take the boat from the pier to Tortoise Bay and wake Xuanwu.", "从码头乘船去玄龟湾，唤醒玄武。"),
         {"goal": ["nebelhafen", 16, 2], "region": "river"},
     ], "else": [
         say("fischer", "EV_FI_1", "Ein Boot willst du? Das Boot ist nicht das Problem, Kind. Mein Kormoran Bai ist es. Seit die Stille kam, ist er fort.",
             "You want a boat? The boat isn't the problem, child. My cormorant Bai is. Since the silence came, he's gone.",
             "你想要船？船不是问题，孩子。问题是我的鸬鹚小白。寂静降临后，它就不见了。"),
         say("fischer", "EV_FI_2", "Er sitzt oben auf der Klippe am Karstufer und starrt ins Leere. Grau, stumm. Bring ihn zurück – aber sei sanft mit ihm. Dann leihe ich dir mein Boot.",
             "He sits up on the cliff at the Karst Bank and stares into nothing. Grey, mute. Bring him back - but be gentle with him. Then I'll lend you my boat.",
             "它蹲在岩溶河岸的悬崖上，呆呆地望着远方。灰扑扑的，不出声。把它带回来——但要温柔。然后我就把船借给你。"),
         {"set": "quest_kormoran"},
         rquest("river", "QUEST_RIVER_3", "Befreie Fischer Zhous Kormoran auf der Klippe am Karstufer (oben links).", "Free Fisher Zhou's cormorant on the cliff at the Karst Bank (top left).", "解放岩溶河岸悬崖上（左上方）周渔翁的鸬鹚。"),
         {"goal": ["karstufer", 9, 6], "region": "river"}, {"refresh": True},
     ]}]},
]
hints("RIVER_3", ["Miau. (Jinli schaut zurück zum Karstufer.)", "Miau, miau! (Auf der Klippe oben links im Karstufer sitzt der Kormoran.)", "Miaaau! (Karstufer, oben links am Wasser. Sprich ihm gut zu – Mutige mögen Ermutigung, Verstummte Ruhe und Respekt.)"],
      ["Mew. (Jinli looks back towards the Karst Bank.)", "Mew, mew! (The cormorant sits on the cliff at the top left of the Karst Bank.)", "Meeew! (Karst Bank, top left by the water. Talk to it kindly - silenced ones like calm and respect.)"],
      ["喵。（锦鲤回头望向岩溶河岸。）", "喵喵！（鸬鹚蹲在岩溶河岸左上方的悬崖上。）", "喵——！（岩溶河岸左上方的水边。好好跟它说话——失声的灵兽喜欢平静和尊重。）"])
hints("RIVER_4", ["Miau! (Jinli schaut zum Steg.)", "Miau, miau! (Den langen Steg in der Mitte hinauf – das Boot wartet.)", "Miaaau! (Nebelhafen, oben in der Mitte: der Steg. Von dort geht es zur Schildkrötenbucht.)"],
      ["Mew! (Jinli looks at the pier.)", "Mew, mew! (Up the long pier in the middle - the boat is waiting.)", "Meeew! (Misthaven, top middle: the pier. From there you go to Tortoise Bay.)"],
      ["喵！（锦鲤望向码头。）", "喵喵！（沿着中间的长码头往前走——船在等着。）", "喵——！（雾港正上方的码头。从那里去玄龟湾。）"])
E["silent_kormoran"] = [
    say("narrator", "EV_KOR_1", "Auf der Klippe hockt ein Kormoran mit grauem Gefieder. Sein Kehlsack, der einmal wie eine Perle leuchtete, ist stumpf.", "A cormorant with grey plumage crouches on the cliff. Its throat pouch, which once glowed like a pearl, is dull.", "悬崖上蹲着一只羽毛灰暗的鸬鹚。它曾像珍珠一样发光的喉囊，如今黯淡无光。"),
    {"battle": {"enemies": [{"id": "perlkormoran", "level": 13, "role": "silenced"}], "active": 1, "no_join": True, "bg": "karst"},
     "win": [{"set": "kormoran_done"}, {"set": "kormoran_defeated"}, {"refresh": True},
             say("narrator", "EV_KOR_WIN", "Der Kormoran sinkt erschöpft zusammen. Du trägst ihn vorsichtig nach Nebelhafen – seine Augen bleiben grau.", "The cormorant collapses, exhausted. You carefully carry it to Misthaven - its eyes stay grey.", "鸬鹚精疲力竭地倒下。你小心地把它抱回雾港——它的眼睛依旧灰暗。")],
     "freed": [{"set": "kormoran_done"}, {"set": "kormoran_freed"}, {"refresh": True},
               say("narrator", "EV_KOR_FREED", "Der Kehlsack des Kormorans leuchtet auf, und er fliegt mit einem lauten Ruf zurück nach Nebelhafen.", "The cormorant's throat pouch lights up, and with a loud call it flies back to Misthaven.", "鸬鹚的喉囊亮了起来，它大叫一声，飞回了雾港。")]},
    {"if": "kormoran_done", "then": [
        rquest("river", "QUEST_RIVER_3B", "Geh zurück zu Fischer Zhou in Nebelhafen.", "Go back to Fisher Zhou in Misthaven.", "回雾港找周渔翁。"),
        {"goal": ["nebelhafen", 6, 18], "region": "river"}]},
]
hints("RIVER_3B", ["Miau! (Jinli trabt Richtung Nebelhafen.)", "Miau, miau! (Zurück zum Fischer, unten links in Nebelhafen.)", "Miaaau! (Fischer Zhou wartet in seiner Hütte unten links in Nebelhafen.)"],
      ["Mew! (Jinli trots towards Misthaven.)", "Mew, mew! (Back to the fisher, bottom left in Misthaven.)", "Meeew! (Fisher Zhou waits in his hut at the bottom left of Misthaven.)"],
      ["喵！（锦鲤朝雾港小跑。）", "喵喵！（回到雾港左下方找渔翁。）", "喵——！（周渔翁在雾港左下方的小屋里等你。）"])
E["bootsfrau"] = [
    {"if": "has_boat", "then": [say("bootsfrau", "EV_BF_2", "Rudern ohne Strömung ist harte Arbeit. Wenn der Ton zurück ist, trägt dich der Fluss wieder von allein.", "Rowing without a current is hard work. When the tone is back, the river will carry you by itself again.", "没有水流，划船可辛苦了。等音回来了，河水又会自己载着你走。")],
     "else": [say("bootsfrau", "EV_BF_1", "Ohne Strömung kein Boot, ohne Kormoran kein Fisch. Nur der alte Zhou hat ein Boot, das man rudern kann – aber der rührt sich nicht, seit sein Bai fort ist.",
                  "No current, no boat; no cormorant, no fish. Only old Zhou has a boat you can row - but he hasn't moved since his Bai left.",
                  "没有水流就没有船，没有鸬鹚就没有鱼。只有老周有条能划的船——可自从他的小白走了，他就一动不动了。")]},
]
E["boat_missing"] = [say("jinli", "EV_BOAT_MISSING", "Miau? (Jinli schaut aufs Wasser, dann zu dir. Ohne Boot kommt ihr nicht weiter.)", "Mew? (Jinli looks at the water, then at you. Without a boat you can't go on.)", "喵？（锦鲤看看水面，又看看你。没有船过不去。）")]
E["hafen_kind"] = [
    {"if": "tone_yu", "then": [say("hafen_kind", "EV_XY_2", "Die Fische springen wieder! Opa sagt, ich darf morgen mit aufs Boot!", "The fish are jumping again! Grandpa says I can come on the boat tomorrow!", "鱼又跳起来了！爷爷说明天可以带我上船！")],
     "else": [say("hafen_kind", "EV_XY_1", "Ich werfe Steine in den See, aber sie machen kein Platsch. Langweilig!", "I throw stones into the lake, but they don't go splash. Boring!", "我往湖里扔石头，可它们都不扑通。真没劲！")]},
]
E["hafen_alter"] = [
    say("hafen_alter", "EV_PAN_1", "Als ich jung war, kam ein Tempelhüter mit einem Silberkranich hierher. Der Kranich sang für die alte Schildkröte – so schön, dass der ganze See zuhörte.",
        "When I was young, a temple keeper came here with a silver crane. The crane sang for the old tortoise - so beautifully that the whole lake listened.",
        "我年轻的时候，有个庙祝带着一只银鹤来过这里。那只鹤为老玄龟唱歌——唱得那么美，整个湖都在听。"),
    say("hafen_alter", "EV_PAN_2", "Der Hüter hieß Wusheng. Damals lachte er noch.", "The keeper's name was Wusheng. Back then he still laughed.", "那个庙祝叫无声。那时候他还会笑。"),
    {"set": "heard_crane_story"},
]
town(E, "nebelhafen",
     {"wirt": ("Wirt Tang", "Innkeeper Tang", "唐掌柜"), "haendler": ("Händlerin Ma", "Merchant Ma", "马大姐"),
      "teemeister": ("Teemeisterin Qiu", "Tea Mistress Qiu", "邱茶娘"), "koch": ("Koch Fu", "Cook Fu", "富厨子")},
     {"inn": ("Ein trockenes Bett im feuchten Nebel. Ruh dich aus.", "A dry bed in the damp mist. Rest a while.", "潮湿雾气里的一张干床。歇歇吧。"),
      "shop": ("Muscheln, Tee, Kiesel vom Fluss – greif zu!", "Clams, tea, river pebbles - help yourself!", "河蚌、茶叶、河卵石——随便挑！"),
      "tea": ("Im Nebel hört man die besten Geschichten. Setz dich.", "In the mist you hear the best stories. Sit down.", "雾里能听到最好的故事。坐吧。"),
      "food": ("Nebelfisch-Suppe! Na ja, Fisch von gestern. Aber die Suppe macht klug.", "Mist fish soup! Well, yesterday's fish. But the soup makes you clever.", "雾鱼汤！嗯，昨天的鱼。不过这汤能让人变聪明。")},
     ["reisbaellchen", "kraeutertee", "jasmintee", "glockenbluete", "flussmuscheln", "silbertau", "flusskiesel"],
     [("Man sagt, Xuanwu schläft in der Schildkrötenbucht und träumt von einem Lied, das ein Kranich ihm einst sang.", "They say Xuanwu sleeps in Tortoise Bay and dreams of a song a crane once sang to it.", "听说玄武在玄龟湾沉睡，梦见一只鹤曾为它唱过的歌。"),
      ("Im Nebel am Karstufer sollen Stromdelfine schwimmen. Wer sie hört, verirrt sich nie.", "Streamfins are said to swim in the mist at the Karst Bank. Whoever hears them never gets lost.", "听说岩溶河岸的雾里有流豚在游。听见它们的人永远不会迷路。"),
      ("Ein Mann in Grau war hier, vom Orden der Stille. Er sagte, ohne Strömung gäbe es auch keine Fluten mehr. Manche fanden das gut.", "A man in grey was here, from the Order of Silence. He said without currents there'd be no more floods. Some liked that.", "来过一个灰衣人，是寂静教团的。他说没有水流就不会再有洪水。有些人觉得这样挺好。")],
     ["fischsuppe"])

E["bucht_arrive"] = [
    {"set": "bucht_arrived"},
    say("narrator", "EV_BU_1", "Die Schildkrötenbucht. Auf einer Steinterrasse liegt ein Panzer, so groß wie ein Haus, bemoost und grau. Um ihn windet sich eine schlafende Schlange.",
        "Tortoise Bay. On a stone terrace lies a shell as big as a house, mossy and grey. A sleeping serpent coils around it.",
        "玄龟湾。石台上躺着一副房子那么大的龟甲，长满青苔，灰扑扑的。一条沉睡的蛇缠绕着它。"),
    rquest("river", "QUEST_RIVER_5", "Wecke Xuanwu auf der Terrasse und hol den Ton Yu zurück.", "Wake Xuanwu on the terrace and bring back the tone Yu.", "唤醒石台上的玄武，找回“羽”音。"),
    {"goal": ["schildkroetenbucht", 14, 8], "region": "river"},
]
hints("RIVER_5", ["Miau! (Jinli schaut zur Terrasse.)", "Miau, miau! (Den Weg hinauf zur großen Schildkröte.)", "Miaaau! (Oben auf der Terrasse: Xuanwu. Ruh dich vorher bei der Muschelsammlerin aus.)"],
      ["Mew! (Jinli looks at the terrace.)", "Mew, mew! (Up the path to the great tortoise.)", "Meeew! (Up on the terrace: Xuanwu. Rest with the shell gatherer first.)"],
      ["喵！（锦鲤望向石台。）", "喵喵！（沿路走上去，到大龟那里。）", "喵——！（石台上就是玄武。去之前先在拾贝人那里休息一下。）"])
order_guard(E, "order_bucht", "order_bucht",
            t("PER_BUCHT_INTRO", "Lass die alte Schildkröte schlafen. Solange sie schweigt, steht das Wasser still – keine Flut wird je wieder ein Dorf fortreißen.",
              "Let the old tortoise sleep. As long as she is silent, the water stands still - no flood will ever sweep away a village again.",
              "让老玄龟睡吧。只要她沉默，水就静止不动——再也不会有洪水冲走村庄了。"),
            {"logic": 2, "compassion": 1, "proof": 2, "threat": -1}, 2, ["tone_jue"],
            [{"id": "nebelbueffel", "level": 14, "role": "silenced"}], "order_bucht_done",
            ("Stilles Wasser fault … Vielleicht hast du recht. Geh. Ich werde dich nicht aufhalten.", "Still water goes stale... Maybe you're right. Go. I won't stop you.", "静水会腐……也许你是对的。去吧，我不拦你。"),
            ("Worte ändern nichts. Mein Büffel wird dich aufhalten.", "Words change nothing. My buffalo will stop you.", "说什么都没用。我的水牛会拦住你。"), "karst")
E["muschelfrau"] = [
    say("muschelfrau", "EV_PEI", "Du willst zur Schildkröte? Dann ruh dich erst aus. Sie ist alt und stur – und stark.", "You want to go to the tortoise? Then rest first. She's old and stubborn - and strong.", "你要去找玄龟？那先歇歇吧。她又老又倔——还很强。"),
    {"heal": True}, {"set_inn": ["schildkroetenbucht", "from_boat"]}, {"save": True},
    say("narrator", "EV_PEI_2", "Dein Gefolge ist geheilt. Gespeichert.", "Your companions are healed. Saved.", "同伴已恢复。已存档。"),
]
E["boss_xuanwu"] = [
    {"if_not": "xuanwu_seen", "then": [
        {"set": "xuanwu_seen"},
        say("narrator", "EV_XW_1", "Die Schlange hebt den Kopf. Der riesige Panzer bewegt sich. Zwei uralte, graue Augen öffnen sich.", "The serpent raises its head. The huge shell moves. Two ancient grey eyes open.", "巨蛇抬起了头，巨大的龟甲动了。两只古老的灰色眼睛睁开了。"),
        say("xuanwu", "EV_XW_2", "… Winter … ewig … nichts … taut …", "... winter... forever... nothing... thaws...", "……冬天……永远……什么……都不融……"),
        say("narrator", "EV_XW_TUT", "Zwei gegen zwei! Fülle Xuanwus Herzklang, um sie zu befreien. Sture hören auf Respekt – und Geduld.", "Two against two! Fill Xuanwu's heartsong to free her. Stubborn ones listen to respect - and patience.", "二对二！唤醒玄武的心音来解放她。倔强的灵兽听得进尊重——和耐心。"),
    ]},
    {"if_party_min": 2, "then": [
        {"battle": {"enemies": [{"id": "xuanwu", "level": 18, "role": "silenced", "scale": 1}, {"id": "schattenmotte", "level": 15, "scale": -2}],
                    "active": 2, "music": "boss", "bg": "karst", "no_join": True},
         "win": [{"run": "tone_yu_returns"}],
         "lose": [say("muschelfrau", "EV_XW_LOSE", "Ruh dich aus und versuch es noch einmal. Sie läuft nicht weg – sie ist eine Schildkröte.", "Rest and try again. She won't run away - she's a tortoise.", "休息一下再试吧。她跑不了的——她可是乌龟。")]}],
     "else": [say("muschelfrau", "EV_XW_ALONE", "Allein? Du brauchst mindestens zwei Gefährten.", "Alone? You need at least two companions.", "一个人？你至少需要两个同伴。")]},
]
E["tone_yu_returns"] = [
    {"music": "tone_returns"},
    {"if": "freed_xuanwu",
     "then": [say("narrator", "EV_YU_1", "Xuanwus Herzklang schwillt an wie eine Welle – und da ist er: ein tiefer, kühler Ton. Yu.", "Xuanwu's heartsong swells like a wave - and there it is: a deep, cool tone. Yu.", "玄武的心音像波浪一样涌起——它来了：一个深沉、清凉的音。羽。")],
     "else": [say("narrator", "EV_YU_1B", "Die Schildkröte zieht den Kopf ein, erschöpft. Leise, fast zögernd, erklingt ein Ton: Yu.", "The tortoise pulls in her head, exhausted. Quietly, almost hesitantly, a tone sounds: Yu.", "玄龟疲惫地缩回了头。轻轻地、几乎是犹豫地，一个音响起：羽。")]},
    {"tone": "tone_yu"},
    {"refresh": True},
    say("narrator", "EV_YU_2", "Der See atmet. Wellen schlagen gegen den Steg, der Nebel beginnt zu wandern. Irgendwo ruft ein Kormoran.", "The lake breathes. Waves slap against the landing, the mist begins to drift. Somewhere a cormorant calls.", "湖水在呼吸。波浪拍打着码头，雾开始流动。远处传来鸬鹚的叫声。"),
    {"voice": "xuanwu", "event": "freed"},
    say("xuanwu", "EV_YU_3", "Zehntausend Winter habe ich gesehen, kleiner Mensch. Jeder ging. Jeder kam wieder. Das Wasser hält nicht fest – darum ist es stark.",
        "Ten thousand winters I have seen, little one. Each one left. Each one returned. Water does not hold on - that is why it is strong.",
        "我见过一万个冬天，小家伙。每一个都离开了，每一个都回来了。水从不紧抓不放——所以它强大。"),
    {"set": "lesson_water"},
    say("xuanwu", "EV_YU_4", "Einst kam Wusheng mit einem Silberkranich hierher. Der Kranich sang für mich, und Wusheng lachte. Nimm diese Feder, die er hier verlor. Vielleicht erinnert sie ihn an sein Lied.",
        "Once Wusheng came here with a silver crane. The crane sang for me, and Wusheng laughed. Take this feather it lost here. Perhaps it will remind him of his song.",
        "从前无声带着一只银鹤来过这里。鹤为我唱歌，无声在笑。拿着这根它落在这里的羽毛吧。也许它能让他想起自己的歌。"),
    {"give_item": "kranichfeder", "n": 1},
    {"give_item": "flusskiesel", "n": 3},
    {"clear_region": "river"},
    {"run": "after_tone"},
]
E["xuanwu_free"] = [say("xuanwu_free", "EV_XW_FREE", "Geh, kleiner Mensch. Und wenn du müde wirst: Auch ich bin langsam. Ich komme trotzdem an.", "Go, little one. And if you grow tired: I am slow too. I still arrive.", "去吧，小家伙。累了的时候想想：我也很慢，可我总会到达。")]

# --- Regenbogengrat -----------------------------------------------------------------
E["danxiapfad_arrive"] = [
    {"set": "danxiapfad_arrived"},
    say("narrator", "EV_DX_1", "Rote, gelbe und orangefarbene Felsbänder ziehen sich durch die Berge wie ein erstarrter Regenbogen. Ohne den Ton Zhi wirken sie stumpf, wie Asche.",
        "Bands of red, yellow and orange rock run through the mountains like a frozen rainbow. Without the tone Zhi they look dull, like ash.",
        "红、黄、橙色的岩层贯穿群山，像一道凝固的彩虹。没有“徵”音，它们显得暗淡，像灰烬一样。"),
    rquest("ridge", "QUEST_RIDGE_1", "Folge dem Danxia-Pfad nach Süden bis Rotfels.", "Follow the Danxia Trail south to Redrock.", "沿丹霞小径往南走到赤岩镇。"),
    {"goal": ["rotfels", 16, 10], "region": "ridge"},
]
hints("RIDGE_1", ["Miau! (Jinli schaut den Pfad hinunter.)", "Miau, miau! (Immer den Weg in der Mitte nach Süden.)", "Miaaau! (Der Weg in der Mitte führt ganz unten nach Rotfels.)"],
      ["Mew! (Jinli looks down the trail.)", "Mew, mew! (Keep south along the path in the middle.)", "Meeew! (The path in the middle leads to Redrock at the very bottom.)"],
      ["喵！（锦鲤望着小径的尽头。）", "喵喵！（沿着中间的路一直往南。）", "喵——！（中间的路一直走到底就是赤岩镇。）"])
E["chest_danxia"] = [say("narrator", "EV_CHEST_DANXIA", "In einer Felsnische steht eine Kiste aus rotem Ton.", "A chest of red clay stands in a rock niche.", "岩洞里放着一个红陶箱子。"),
                     {"give_item": "danxia_ton", "n": 2}, {"give_item": "chilischoten", "n": 2}, {"set": "chest_danxia"}, {"refresh": True}]
E["foerster"] = [
    {"if": "lesson_forest", "then": [say("foerster", "EV_MU_2", "Wenn Bifang wieder ruft, wird es hier wieder grün. Ganz bestimmt.", "When Bifang calls again, it will turn green here again. I'm sure of it.", "等毕方再次鸣叫，这里又会变绿的。一定会的。")],
     "else": [
         say("foerster", "EV_MU_1", "Letzten Sommer brannte hier der ganze Wald. Bifangs Feuer. In Rotfels sind alle froh, dass der Vogel jetzt schweigt.",
             "Last summer the whole forest burned here. Bifang's fire. In Redrock everyone is glad the bird is silent now.",
             "去年夏天，这里整片树林都烧了。是毕方的火。赤岩镇的人都庆幸这只鸟现在不叫了。"),
         say("foerster", "EV_MU_1B", "Aber schau her: die kleinen Triebe. Die Feuerkiefer öffnet ihre Zapfen nur in der Hitze. Ohne Brand gäbe es keinen einzigen neuen Baum.",
             "But look here: the little shoots. The fire pine opens its cones only in the heat. Without the fire there wouldn't be a single new tree.",
             "可你看这里：这些小嫩芽。火松的松果只有在高温下才会张开。没有那场火，一棵新树都长不出来。"),
         {"set": "lesson_forest"},
         say("foerster", "EV_MU_1C", "Hier, Danxia-Ton. Der Töpfer in Rotfels kann ihn brauchen.", "Here, Danxia clay. The potter in Redrock can use it.", "给，丹霞陶土。赤岩镇的陶匠用得上。"),
         {"give_item": "danxia_ton", "n": 2}]},
]
E["rotfels_arrive"] = [
    {"set": "rotfels_arrived"},
    say("narrator", "EV_RF_1", "Rotfels, ein Dorf aus rotem Stein. Die Brennöfen sind kalt. Die Leute schauen dich misstrauisch an – niemand hier vermisst das Feuer.",
        "Redrock, a village of red stone. The kilns are cold. The people eye you suspiciously - nobody here misses the fire.",
        "赤岩镇，一座红石砌成的村子。窑炉都冷了。人们疑惑地打量着你——这里没有人怀念那火。"),
    rquest("ridge", "QUEST_RIDGE_2", "Sprich mit Bürgermeisterin Hong (unten links), bevor du zum Feuergipfel gehst.", "Talk to Mayor Hong (bottom left) before you go to the Fire Peak.", "去火峰之前，先和洪镇长（左下方）谈谈。"),
    {"goal": ["rotfels", 6, 16], "region": "ridge"},
    {"set_inn": ["rotfels", "inn"]},
]
hints("RIDGE_2", ["Miau! (Jinli schaut zum roten Haus unten links.)", "Miau, miau! (Die Bürgermeisterin wohnt unten links.)", "Miaaau! (Rotfels, unten links: Bürgermeisterin Hong. Danach geht es unten in der Mitte zum Feuergipfel.)"],
      ["Mew! (Jinli looks at the red house at the bottom left.)", "Mew, mew! (The mayor lives at the bottom left.)", "Meeew! (Redrock, bottom left: Mayor Hong. Then the way to the Fire Peak is at the bottom middle.)"],
      ["喵！（锦鲤望向左下方的红房子。）", "喵喵！（镇长住在左下方。）", "喵——！（赤岩镇左下方：洪镇长。之后从正下方去火峰。）"])
E["buergermeisterin"] = [
    {"if": "helped_rotfels", "then": [say("buergermeisterin", "EV_HONG_DONE", "Die Schneise hält. Geh zu Bifang, Kind. Und … sag ihm, wir haben keine Angst mehr.", "The firebreak holds. Go to Bifang, child. And... tell him we're not afraid anymore.", "防火带很牢固。去找毕方吧，孩子。还有……告诉他，我们不再害怕了。")],
     "else": [{"if": "met_hong", "then": [say("buergermeisterin", "EV_HONG_AGAIN", "Töpfer Shi braucht drei Klumpen Danxia-Ton für die Schneise. Dann reden wir weiter.", "Potter Shi needs three lumps of Danxia clay for the firebreak. Then we'll talk.", "石陶匠需要三块丹霞陶土来修防火带。到时候我们再谈。")],
               "else": [
         {"set": "met_hong"},
         say("buergermeisterin", "EV_HONG_1", "Du willst Bifang wecken? Weißt du, was letzten Sommer passiert ist? Sein Feuer hat das halbe Dorf verbrannt. Mein Haus. Die Schule.",
             "You want to wake Bifang? Do you know what happened last summer? His fire burned half the village. My house. The school.",
             "你要唤醒毕方？你知道去年夏天发生了什么吗？他的火烧掉了半个村子。我的房子。学堂。"),
         say("buergermeisterin", "EV_HONG_2", "Der Orden sagt, in der Stille brennt nichts mehr. Ich weiß nicht, ob sie recht haben. Ich weiß nur, dass ich keine Angst mehr haben will.",
             "The Order says nothing burns in the silence. I don't know if they're right. I only know I don't want to be afraid anymore.",
             "教团说，寂静中什么都不会再烧起来。我不知道他们说得对不对。我只知道我不想再害怕了。"),
         choice([("CH_HONG_A", "Ich helfe euch, eine Feuerschneise zu bauen. Dann ist das Dorf sicher, wenn Bifang wieder ruft.", "I'll help you build a firebreak. Then the village is safe when Bifang calls again.", "我帮你们修一条防火带。这样等毕方再叫的时候，村子也安全。"),
                 ("CH_HONG_B", "Ohne Feuer wächst nichts Neues. Ich gehe trotzdem.", "Without fire nothing new grows. I'm going anyway.", "没有火，就长不出新东西。我还是要去。")],
                [[say("buergermeisterin", "EV_HONG_3", "… Das würdest du tun? Töpfer Shi weiß, wie man eine Schneise brennt. Er braucht drei Klumpen Danxia-Ton.",
                      "... You'd do that? Potter Shi knows how to burn a firebreak. He needs three lumps of Danxia clay.",
                      "……你愿意这么做？石陶匠懂得怎么烧防火带。他需要三块丹霞陶土。"),
                  {"set": "rotfels_task"},
                  rquest("ridge", "QUEST_RIDGE_3", "Bring Töpfer Shi drei Danxia-Ton für die Feuerschneise – oder geh gleich zum Feuergipfel (unten).", "Bring Potter Shi three Danxia clay for the firebreak - or go straight to the Fire Peak (bottom).", "给石陶匠送三块丹霞陶土修防火带——或者直接去火峰（下方）。"),
                  {"goal": ["rotfels", 19, 16], "region": "ridge"}],
                 [say("buergermeisterin", "EV_HONG_4", "Dann geh. Aber wenn es wieder brennt, war es deine Schuld.", "Then go. But if it burns again, it's your fault.", "那你去吧。但要是再烧起来，那就是你的错。"),
                  rquest("ridge", "QUEST_RIDGE_4", "Steig zum Feuergipfel (unten in Rotfels) und wecke Bifang.", "Climb the Fire Peak (bottom of Redrock) and wake Bifang.", "登上火峰（赤岩镇下方），唤醒毕方。"),
                  {"goal": ["feuergipfel", 12, 8], "region": "ridge"}]]),
     ]}]},
]
hints("RIDGE_3", ["Miau! (Jinli schnuppert an rotem Ton.)", "Miau, miau! (Ton gibt es in Kisten, beim Förster und im Laden.)", "Miaaau! (Drei Danxia-Ton zum Töpfer am alten Ofen, unten in der Mitte von Rotfels.)"],
      ["Mew! (Jinli sniffs at red clay.)", "Mew, mew! (Clay can be found in chests, from the forester and in the shop.)", "Meeew! (Three Danxia clay to the potter at the old kiln, bottom middle of Redrock.)"],
      ["喵！（锦鲤嗅了嗅红陶土。）", "喵喵！（箱子里、护林人那里和商店都有陶土。）", "喵——！（把三块丹霞陶土交给赤岩镇中下方老窑边的陶匠。）"])
hints("RIDGE_4", ["Miau! (Jinli schaut zum Gipfel.)", "Miau, miau! (Unten in der Mitte von Rotfels geht es hinauf.)", "Miaaau! (Rotfels, unten in der Mitte: der Weg zum Feuergipfel. Ganz oben wartet Bifang.)"],
      ["Mew! (Jinli looks up at the peak.)", "Mew, mew! (The way up is at the bottom middle of Redrock.)", "Meeew! (Redrock, bottom middle: the path to the Fire Peak. Bifang waits at the very top.)"],
      ["喵！（锦鲤望着山顶。）", "喵喵！（赤岩镇正下方有路上山。）", "喵——！（赤岩镇正下方是去火峰的路。毕方在最高处等着。）"])
E["toepfer"] = [
    {"if": "helped_rotfels", "then": [say("toepfer", "EV_SHI_DONE", "Die Schneise steht. Jetzt soll der Vogel ruhig singen.", "The firebreak stands. Now let the bird sing.", "防火带修好了。现在就让那只鸟尽情地唱吧。")],
     "else": [{"if": "rotfels_task",
               "then": [{"if_items": ["danxia_ton", 3],
                         "then": [{"take_item": "danxia_ton", "n": 3},
                                  say("toepfer", "EV_SHI_2", "Drei Klumpen, sauber. Gib mir einen Tag – nein, eine Stunde. Ein Graben, gebrannter Ton, keine Funken kommen mehr ins Dorf.", "Three lumps, nice. Give me a day - no, an hour. A trench, fired clay, no sparks will reach the village anymore.", "三块，不错。给我一天——不，一个时辰。挖条沟，烧上陶土，火星就再也飞不进村子了。"),
                                  {"wait": 0.6},
                                  say("narrator", "EV_SHI_3", "Gemeinsam mit den Leuten aus Rotfels zieht ihr eine Schneise aus gebranntem Ton um das Dorf. Die Bürgermeisterin schaut zu – und nickt.", "Together with the people of Redrock you build a firebreak of fired clay around the village. The mayor watches - and nods.", "你和赤岩镇的人一起，在村子周围修了一条烧陶防火带。镇长在一旁看着——点了点头。"),
                                  {"set": "helped_rotfels"}, {"count": "helped_villagers"}, {"coins": 150},
                                  rquest("ridge", "QUEST_RIDGE_4", "Steig zum Feuergipfel (unten in Rotfels) und wecke Bifang.", "Climb the Fire Peak (bottom of Redrock) and wake Bifang.", "登上火峰（赤岩镇下方），唤醒毕方。"),
                                  {"goal": ["feuergipfel", 12, 8], "region": "ridge"}],
                         "else": [say("toepfer", "EV_SHI_1", "Drei Klumpen Danxia-Ton brauche ich. Kisten, der Förster am Pfad, der Laden – irgendwo findest du welchen.", "I need three lumps of Danxia clay. Chests, the forester on the trail, the shop - you'll find some somewhere.", "我需要三块丹霞陶土。箱子里、小径上的护林人、商店——总能找到的。")]}],
               "else": [say("toepfer", "EV_SHI_0", "Kalte Öfen, kalte Hände. Schöne Stille, was?", "Cold kilns, cold hands. Lovely silence, eh?", "冷窑炉，冷手。好安静啊，是吧？")]}]},
]
E["rotfels_kind"] = [
    {"if": "tone_zhi", "then": [say("rotfels_kind", "EV_HH_2", "Die Felsen leuchten wieder! Rot, gelb, orange – wie ein Regenbogen, der eingeschlafen ist!", "The rocks are glowing again! Red, yellow, orange - like a rainbow that fell asleep!", "石头又亮起来了！红的、黄的、橙的——像一道睡着的彩虹！")],
     "else": [say("rotfels_kind", "EV_HH_1", "Mama sagt, ich darf nicht mehr mit Feuer spielen. Jetzt gibt's gar kein Feuer mehr. Doof.", "Mum says I can't play with fire anymore. Now there's no fire at all. Dumb.", "妈妈说我不能再玩火了。现在根本没有火了。真没劲。")]},
]
town(E, "rotfels",
     {"wirt": ("Wirtin Zhu", "Innkeeper Zhu", "朱老板娘"), "haendler": ("Händler Lü", "Merchant Lü", "吕掌柜"),
      "teemeister": ("Teemeister Bai", "Tea Master Bai", "白茶师"), "koch": ("Köchin La", "Cook La", "辣厨娘")},
     {"inn": ("Die Betten sind warm, auch ohne Ofen. Schlaf gut.", "The beds are warm, even without a stove. Sleep well.", "就算没有炉子，床也是暖的。睡个好觉。"),
      "shop": ("Chili, Ton, Tee. Alles, was ein Feuer nicht braucht – noch nicht.", "Chili, clay, tea. Everything a fire doesn't need - not yet.", "辣椒、陶土、茶叶。都是火用不上的东西——暂时还用不上。"),
      "tea": ("Tee ohne heißes Wasser ist schwer zu machen. Aber Gerüchte sind immer heiß.", "Tea without hot water is hard to make. But rumours are always hot.", "没有热水很难泡茶。不过传闻总是热乎的。"),
      "food": ("Feuertopf! Kalt serviert, leider. Er macht trotzdem stark.", "Fire pot! Served cold, sadly. It still makes you strong.", "火锅！可惜是凉的。不过照样让人有劲。")},
     ["reisbaellchen", "kraeutertee", "jasmintee", "glockenbluete", "chilischoten", "suessreis", "danxia_ton"],
     [("Auf dem Feuergipfel steht Bifang auf einem Bein und starrt in die Asche. Eine Frau in Grau bewacht den Weg.", "On the Fire Peak Bifang stands on one leg, staring into the ashes. A woman in grey guards the path.", "毕方单足立在火峰上，盯着灰烬。一个灰衣女子守着上山的路。"),
      ("Glutpandas spielen am Danxia-Pfad Fangen. Mit etwas Spaß gewinnt man sie für sich.", "Emberpandas play tag on the Danxia Trail. A bit of fun wins them over.", "火团团在丹霞小径上玩捉人游戏。陪它们玩玩就能交上朋友。"),
      ("Die Bürgermeisterin hat Angst vor dem Feuer. Wer kann es ihr verdenken?", "The mayor is afraid of the fire. Who can blame her?", "镇长怕火。谁能怪她呢？")],
     ["feuertopf"])
E["gipfel_arrive"] = [
    {"set": "gipfel_arrived"},
    say("narrator", "EV_GI_1", "Der Feuergipfel. Oben, auf einem verkohlten Felsen, steht ein großer Vogel auf einem einzigen Bein. Seine Federn sind grau wie kalte Asche.",
        "The Fire Peak. Up on a charred rock, a great bird stands on a single leg. Its feathers are grey as cold ash.",
        "火峰。山顶一块烧焦的岩石上，一只大鸟单足而立，羽毛灰得像冷却的灰烬。"),
    rquest("ridge", "QUEST_RIDGE_5", "Wecke Bifang auf dem Gipfel und hol den Ton Zhi zurück.", "Wake Bifang on the peak and bring back the tone Zhi.", "唤醒峰顶的毕方，找回“徵”音。"),
    {"goal": ["feuergipfel", 12, 8], "region": "ridge"},
]
hints("RIDGE_5", ["Miau! (Jinli schaut zur Spitze.)", "Miau, miau! (Den Weg hinauf zu Bifang.)", "Miaaau! (Ganz oben: Bifang. Der Einsiedler heilt dein Gefolge vorher.)"],
      ["Mew! (Jinli looks at the summit.)", "Mew, mew! (Up the path to Bifang.)", "Meeew! (At the very top: Bifang. The hermit heals your companions first.)"],
      ["喵！（锦鲤望向峰顶。）", "喵喵！（沿路上去找毕方。）", "喵——！（最上面就是毕方。先让隐士给同伴疗伤。）"])
order_guard(E, "order_gipfel", "order_gipfel",
            t("PER_GIPFEL_INTRO", "Du willst das Feuer zurückholen? Ich habe gesehen, wie es Häuser fraß. In der Stille brennt nichts. Warum willst du den Leuten ihre Ruhe nehmen?",
              "You want to bring the fire back? I saw it devour houses. In the silence nothing burns. Why would you take away people's peace?",
              "你要把火带回来？我亲眼见过它吞噬房屋。寂静中什么都不会燃烧。你为什么要夺走人们的安宁？"),
            {"compassion": 2, "logic": 1, "proof": 1, "threat": -1}, 2, ["helped_rotfels", "lesson_forest", "tone_yu", "tone_jue"],
            [{"id": "glutpanda", "level": 15, "role": "silenced"}], "order_gipfel_done",
            ("Du hast an die Menschen gedacht … nicht nur an den Vogel. Geh. Ich gehe zurück zu meiner Familie.", "You thought of the people... not only of the bird. Go. I'm going back to my family.", "你想到了人……而不只是那只鸟。去吧。我要回家人身边了。"),
            ("Dann muss mein Glutpanda dich aufhalten. Es tut mir leid.", "Then my Emberpanda must stop you. I'm sorry.", "那就只能让我的火团团拦住你了。对不起。"), "danxia")
E["einsiedler"] = [
    say("einsiedler", "EV_FENG", "Ich lebe hier oben, weil das Feuer mich nicht schreckt. Setz dich, ruh dich aus.", "I live up here because the fire doesn't scare me. Sit, rest.", "我住在这上面，因为火吓不倒我。坐吧，歇一歇。"),
    {"heal": True}, {"set_inn": ["feuergipfel", "from_town"]}, {"save": True},
    say("narrator", "EV_FENG_2", "Dein Gefolge ist geheilt. Gespeichert.", "Your companions are healed. Saved.", "同伴已恢复。已存档。"),
]
E["boss_bifang"] = [
    {"if_not": "bifang_seen", "then": [
        {"set": "bifang_seen"},
        say("narrator", "EV_BI_1", "Bifang dreht den Kopf. Aus seinem grauen Gefieder stieben keine Funken – nur Staub.", "Bifang turns its head. No sparks fly from its grey plumage - only dust.", "毕方转过头来。灰色的羽毛里没有迸出火星——只有灰尘。"),
        say("bifang", "EV_BI_2", "… kein … Feuer … kein … Morgen …", "... no... fire... no... morning...", "……没有……火……没有……明天……"),
        say("narrator", "EV_BI_TUT", "Zwei gegen zwei! Mutige mögen Ermutigung – sprich Bifang Mut zu, um seinen Herzklang zu füllen.", "Two against two! Brave ones like encouragement - give Bifang courage to fill its heartsong.", "二对二！勇敢的灵兽喜欢鼓励——给毕方打气，唤醒它的心音。"),
    ]},
    {"if_party_min": 2, "then": [
        {"battle": {"enemies": [{"id": "bifang", "level": 18, "role": "silenced", "scale": 1}, {"id": "funkenechse", "level": 15, "role": "silenced", "scale": -2}],
                    "active": 2, "music": "boss", "bg": "danxia"},
         "win": [{"run": "tone_zhi_returns"}],
         "lose": [say("einsiedler", "EV_BI_LOSE", "Feuer braucht Geduld. Ruh dich aus und versuch es noch einmal.", "Fire takes patience. Rest and try again.", "火需要耐心。休息一下再试吧。")]}],
     "else": [say("einsiedler", "EV_BI_ALONE", "Allein? Du brauchst mindestens zwei Gefährten.", "Alone? You need at least two companions.", "一个人？你至少需要两个同伴。")]},
]
E["tone_zhi_returns"] = [
    {"music": "tone_returns"},
    {"if": "freed_bifang",
     "then": [say("narrator", "EV_ZHI_1", "Bifangs Herzklang lodert auf wie eine Flamme – und da ist er: ein heller, warmer Ton. Zhi.", "Bifang's heartsong blazes up like a flame - and there it is: a bright, warm tone. Zhi.", "毕方的心音像火焰一样燃起——它来了：一个明亮、温暖的音。徵。")],
     "else": [say("narrator", "EV_ZHI_1B", "Der Feuervogel sinkt in die Asche. Ein Ton glimmt auf, schwach wie ein letzter Funke: Zhi.", "The fire bird sinks into the ashes. A tone glows, faint as a last spark: Zhi.", "火鸟沉入灰烬。一个音亮了起来，微弱得像最后一粒火星：徵。")]},
    {"tone": "tone_zhi"},
    {"refresh": True},
    say("narrator", "EV_ZHI_2", "Die Felsbänder leuchten auf, rot, gelb und orange. Unten in Rotfels steigt Rauch aus den Öfen – zum ersten Mal seit Langem.", "The rock bands light up, red, yellow and orange. Down in Redrock smoke rises from the kilns - for the first time in a long while.", "岩层亮了起来，红的、黄的、橙的。山下赤岩镇的窑炉冒起了烟——这是很久以来的第一次。"),
    {"voice": "bifang", "event": "freed"},
    say("bifang", "EV_ZHI_3", "Ein Wald, der nie brennt, wird nie jung, kleiner Mensch. Doch ein Feuer ohne Grenzen ist kein Segen. Danke, dass du an die Menschen unten gedacht hast.",
        "A forest that never burns never grows young, little one. But a fire without limits is no blessing. Thank you for thinking of the people below.",
        "从不燃烧的森林，永远不会年轻，小家伙。可没有边界的火也不是福气。谢谢你想着山下的人。"),
    {"set": "lesson_fire"},
    {"give_item": "danxia_ton", "n": 3},
    {"clear_region": "ridge"},
    {"run": "after_tone"},
]
E["bifang_free"] = [say("bifang_free", "EV_BI_FREE", "Steh fest, auch wenn du nur ein Bein hast! Ha!", "Stand firm, even if you only have one leg! Ha!", "站稳了，哪怕你只有一条腿！哈！")]
