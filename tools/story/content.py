"""Content for the full game: Lingshou, moves, items and character cards.

Writes one JSON file per entry to game/data/{lingshou,moves,items}/ (only the
entries listed here; the beta files written by hand stay untouched unless
they appear in PATCH) and the voice cards to game/data/cards/<lang>/.
Names and descriptions go through t() into story.csv.
"""
import json, os
from common import ROOT, t

LINGSHOU = []
MOVES = []
ITEMS = []
CARDS = {}  # id -> {"de": str, "en": str, "zh_Hans": str}


def move(mid, element, kind, target, names, hint, power=0, accuracy=95, effect=None, heal_pct=0):
    t("MOVE_" + mid.upper(), *names)
    m = {"id": mid, "name": "MOVE_" + mid.upper(), "element": element, "kind": kind, "accuracy": accuracy,
         "target": target, "llm_hint": hint}
    if power:
        m["power"] = power
    if effect:
        m["effect"] = effect
    if heal_pct:
        m["heal_pct"] = heal_pct
    MOVES.append(m)


def lingshou(lid, element, temperament, alignment, stats, moves, names, animal, desc, habitat,
             sprite=48, guardian=False, can_breed=True, learn=None, extra=None):
    key = "LS_" + lid.upper()
    t(key, *names)
    t(key + "_ANIMAL", *animal)
    t(key + "_DESC", *desc)
    hp, atk, de, spd = stats
    d = {"id": lid, "name": key, "animal": key + "_ANIMAL", "desc": key + "_DESC", "element": element,
         "temperaments": [temperament], "alignment": alignment,
         "base_stats": {"hp": hp, "atk": atk, "def": de, "spd": spd}, "moves": moves, "habitat": habitat,
         "can_breed": can_breed, "voice_card": "cards/{lang}/%s.md" % lid}
    if guardian:
        d["guardian"] = True
    if sprite != 48:
        d["sprite_size"] = sprite
    if learn:
        d["learn"] = learn
    if extra:
        d.update(extra)
    LINGSHOU.append(d)


def card(lid, de, en, zh):
    CARDS[lid] = {"de": de, "en": en, "zh_Hans": zh}


def item(iid, kind, price, names, desc, **kw):
    t("ITEM_" + iid.upper(), *names)
    t("ITEM_" + iid.upper() + "_DESC", *desc)
    d = {"id": iid, "name": "ITEM_" + iid.upper(), "desc": "ITEM_" + iid.upper() + "_DESC", "kind": kind, "price": price}
    d.update(kw)
    ITEMS.append(d)


# --- moves ------------------------------------------------------------------------
move("perlenstrahl", "water", "attack", "enemy", ("Perlenstrahl", "Pearl Beam", "珠光"), "a beam of shining pearly mist", 70)
move("flutwelle", "water", "attack", "enemy", ("Flutwelle", "Flood Wave", "洪浪"), "a huge wave; strongest water attack", 85, 85)
move("schlangenbiss", "water", "attack", "enemy", ("Schlangenbiss", "Serpent Bite", "蛇噬"), "the serpent strikes fast like a wave", 65,
     effect={"status": "dissonance", "turns": 2, "chance": 20})
move("panzerwacht", "water", "guard", "ally", ("Panzerwacht", "Shell Ward", "甲守"), "holds up a shell and protects an ally from the next hit")
move("glutring", "fire", "attack", "enemy", ("Glutring", "Ember Ring", "焰环"), "a spinning ring of embers", 50,
     effect={"status": "deaf", "turns": 2, "chance": 20})
move("funkenregen", "fire", "attack", "enemy", ("Funkenregen", "Spark Rain", "火星雨"), "a rain of little sparks", 55,
     effect={"status": "dissonance", "turns": 2, "chance": 20})
move("lampionglanz", "fire", "heal", "ally", ("Lampionglanz", "Lantern Glow", "灯辉"), "a warm lantern light that heals an ally", heal_pct=35)
move("sonnenfeuer", "fire", "attack", "enemy", ("Sonnenfeuer", "Sunfire", "日炎"), "fire as bright as the sun; strongest fire attack", 90, 85)
move("glockenschlag", "metal", "attack", "enemy", ("Glockenschlag", "Bell Strike", "钟击"), "a ringing bronze bell blow that can deafen", 60,
     effect={"status": "deaf", "turns": 2, "chance": 30})
move("klingenfeder", "metal", "attack", "enemy", ("Klingenfeder", "Blade Feather", "刃羽"), "feathers sharp as blades", 70)
move("tigerbruellen", "metal", "attack", "enemy", ("Tigerbrüllen", "Tiger Roar", "虎啸"), "a roar of metal and wind; strongest metal attack", 85, 90,
     effect={"status": "deaf", "turns": 2, "chance": 30})
move("sandsturm", "earth", "attack", "enemy", ("Sandsturm", "Sandstorm", "沙暴"), "a whirling sandstorm that confuses", 55,
     effect={"status": "dissonance", "turns": 2, "chance": 30})
move("felsramme", "earth", "attack", "enemy", ("Felsramme", "Rock Ram", "石撞"), "charges with a head of stone", 70, 90)
move("steinhaut", "earth", "guard", "ally", ("Steinhaut", "Stone Skin", "石肤"), "turns skin to stone and shields an ally")
move("wolkenpfiff", "earth", "heal", "ally", ("Wolkenpfiff", "Cloud Whistle", "云哨"), "a whistle that brings soft healing clouds", heal_pct=35)
move("bergbeben", "earth", "attack", "enemy", ("Bergbeben", "Mountain Quake", "山震"), "the mountain shakes; strongest earth attack", 90, 85)
move("muenzregen", "earth", "attack", "enemy", ("Münzregen", "Coin Shower", "金钱雨"), "throws a shower of golden coins", 50)
move("qilinsegen", "earth", "heal", "ally", ("Qilin-Segen", "Qilin Blessing", "麒麟赐福"), "a blessing that heals an ally a lot", heal_pct=60)
move("neujahrsgebruell", "earth", "attack", "enemy", ("Neujahrsgebrüll", "New Year Roar", "年吼"), "the Nian's terrible roar", 80, 90,
     effect={"status": "deaf", "turns": 2, "chance": 40})
move("wiedergeburt", "fire", "attack", "enemy", ("Wiedergeburtsflamme", "Rebirth Flame", "涅槃焰"), "the phoenix's flame of rebirth; the strongest attack", 100, 90)
move("phoenixlied", "fire", "status", "ally_side", ("Phönixlied", "Phoenix Song", "凤鸣"), "the song of five tones that makes the team resonate",
     effect={"status": "resonance", "turns": 3, "chance": 100})

# --- Lingshou: Misty River (water) --------------------------------------------------------
lingshou("perlkormoran", "water", "brave", "wild", (45, 58, 35, 56), ["perlenstrahl", "tauchen", "klingenfeder", "echoruf"],
         ("Perlkormoran", "Pearlmorant", "珠鸬鹚"), ("Kormoran", "cormorant", "鸬鹚"),
         ("Taucht durch den Flussnebel. Sein Kehlsack leuchtet wie eine Perle und zeigt Fischern den Weg.",
          "Dives through the river mist. Its throat pouch glows like a pearl and shows fishers the way.",
          "穿过河雾潜水。它的喉囊像珍珠一样发光，为渔夫指路。"), "pond")
lingshou("stromdelfin", "water", "gentle", "wild", (56, 40, 42, 56), ["stroemungsruf", "reisregen", "perlenstrahl", "echoruf"],
         ("Stromdelfin", "Streamfin", "流豚"), ("Flussdelfin", "river dolphin", "白鳍豚"),
         ("Singt mit den Wellen. Wo er schwimmt, findet das Wasser seinen Weg um jeden Felsen.",
          "Sings with the waves. Where it swims, water finds its way around every rock.",
          "随波歌唱。它游过的地方，水总能绕过每一块岩石。"), "pond")
lingshou("nebelbueffel", "water", "stubborn", "wild", (66, 56, 56, 20), ["flutwelle", "felsramme", "schlammwand", "stroemungsruf"],
         ("Nebelbüffel", "Mistbuff", "雾水牛"), ("Wasserbüffel", "water buffalo", "水牛"),
         ("Schnaubt Nebel aus der Nase. Geht nur dorthin, wo es ihm passt – aber dann mit voller Kraft.",
          "Snorts mist from its nose. Only goes where it wants to - but then with full strength.",
          "鼻子里喷出雾气。只去它想去的地方——但一旦去了，就全力以赴。"), "pond")
lingshou("goldkroete", "earth", "moody", "wild", (56, 42, 50, 30), ["muenzregen", "erdstoss", "schlammwand", "kinderweinen"],
         ("Goldkröte", "Goldtoad", "金蟾"), ("Kröte", "toad", "蟾蜍"),
         ("Hüpft auf drei Beinen und trägt eine Münze auf dem Rücken. Wer sie freundlich grüßt, findet manchmal Kleingeld.",
          "Hops on three legs and carries a coin on its back. Greet it kindly and you sometimes find small change.",
          "三条腿蹦蹦跳跳，背上驮着一枚铜钱。友好地打招呼，有时能捡到零钱。"), "rock_garden")
lingshou("xuanwu", "water", "stubborn", "silenced", (100, 58, 78, 30), ["flutwelle", "schlangenbiss", "panzerwacht", "eisenstille"],
         ("Xuanwu", "Xuanwu", "玄武"), ("Schwarze Schildkröte", "Black Tortoise", "玄龟"),
         ("Himmelswächter des Nordens. Schildkröte und Schlange in einem, älter als der Fluss selbst. Hütet den Ton Yu.",
          "Sky guardian of the north. Tortoise and serpent in one, older than the river itself. Keeps the tone Yu.",
          "北方的天之守护者。龟蛇合一，比河流本身还要古老。守护着“羽”音。"), "shrine",
         sprite=96, guardian=True, can_breed=False)

# --- Rainbow Ridge (fire) -----------------------------------------------------------------
lingshou("glutpanda", "fire", "playful", "wild", (48, 52, 38, 58), ["glutring", "funkenregen", "bambusschlag", "nebelschleier"],
         ("Glutpanda", "Emberpanda", "火团团"), ("Kleiner Panda", "red panda", "小熊猫"),
         ("Die Ringe an seinem Schwanz glühen wie Kohle. Spielt am liebsten Fangen zwischen den Felsen.",
          "The rings on its tail glow like coal. Loves playing tag between the rocks.",
          "尾巴上的环纹像炭火一样发光。最爱在岩石间玩捉迷藏。"), "ember_pit")
lingshou("funkenechse", "fire", "anxious", "wild", (40, 48, 44, 52), ["funkenregen", "glutfeder", "sandwirbel", "schlammwand"],
         ("Funkenechse", "Sparkskink", "火星蜥"), ("Krokodilschwanzechse", "crocodile lizard", "鳄蜥"),
         ("Versteckt sich in Felsspalten. Wenn sie sich erschreckt, sprühen Funken aus ihrem Schwanzkamm.",
          "Hides in rock crevices. When it gets a fright, sparks fly from its crested tail.",
          "躲在岩缝里。一受惊，尾巴上的鬃冠就会迸出火星。"), "ember_pit")
lingshou("lampionfalter", "fire", "gentle", "wild", (42, 46, 36, 60), ["lampionglanz", "glutring", "blattflug", "echoruf"],
         ("Lampionfalter", "Lanternwing", "灯笼蝶"), ("Schwalbenschwanz", "swallowtail butterfly", "凤蝶"),
         ("Seine Flügel leuchten wie rote Papierlaternen. Verirrte Wanderer folgen ihm nach Hause.",
          "Its wings glow like red paper lanterns. Lost travellers follow it home.",
          "翅膀像红纸灯笼一样发光。迷路的旅人会跟着它回家。"), "ember_pit")
lingshou("bifang", "fire", "brave", "silenced", (88, 74, 52, 62), ["sonnenfeuer", "flammensprung", "glutkreischen", "klingenfeder"],
         ("Bifang", "Bifang", "毕方"), ("einbeiniger Feuervogel", "one-legged fire bird", "独足火鸟"),
         ("Himmelswächter des Südens. Steht auf einem Bein, und wo er ruft, lodern alte Wälder auf, damit neue wachsen. Hütet den Ton Zhi.",
          "Sky guardian of the south. Stands on one leg, and where it calls, old forests blaze so new ones can grow. Keeps the tone Zhi.",
          "南方的天之守护者。单足而立，它一鸣叫，旧林燃起，新林生长。守护着“徵”音。"), "shrine",
         sprite=96, guardian=True, can_breed=False)

# --- Singing Dunes (metal) ----------------------------------------------------------------
lingshou("glockenkamel", "metal", "gentle", "wild", (66, 46, 56, 30), ["glockenschlag", "kranichlied", "sandwirbel", "eisenrolle"],
         ("Glockenkamel", "Bellcamel", "铃驼"), ("Trampeltier", "bactrian camel", "双峰驼"),
         ("Seine Höcker klingen wie Bronzeglocken. Karawanen finden durch seinen Klang auch im Sandsturm zusammen.",
          "Its humps ring like bronze bells. Caravans find each other by its sound even in a sandstorm.",
          "驼峰像铜铃一样作响。即使在沙暴中，商队也能循着铃声聚到一起。"), "ore_grotto")
lingshou("duenenspringer", "earth", "playful", "wild", (40, 46, 34, 72), ["sandsturm", "erdstoss", "echoruf", "glockenschlag"],
         ("Dünenspringer", "Duneskip", "沙跳鼠"), ("Langohr-Springmaus", "long-eared jerboa", "长耳跳鼠"),
         ("Mit seinen riesigen Ohren hört er die Dünen singen. Springt dreimal so weit, wie er groß ist.",
          "With its huge ears it hears the dunes sing. Jumps three times its own length.",
          "用大耳朵聆听沙丘歌唱。一跳能跳出身长的三倍远。"), "rock_garden")
lingshou("messingadler", "metal", "brave", "wild", (50, 66, 40, 66), ["klingenfeder", "raureifkralle", "sandsturm", "glutfeder"],
         ("Messingadler", "Brassquill", "铜羽鹰"), ("Steinadler", "golden eagle", "金雕"),
         ("Seine Federn sind wie polierte Messingklingen. Kreist über den Dünen und sieht jede Spur im Sand.",
          "Its feathers are like polished brass blades. Circles above the dunes and sees every track in the sand.",
          "羽毛如同磨亮的铜刃。盘旋在沙丘上空，看得清沙上的每一道痕迹。"), "ore_grotto")
lingshou("baihu", "metal", "brave", "silenced", (92, 80, 60, 64), ["tigerbruellen", "klingenfeder", "raureifkralle", "eisenstille"],
         ("Baihu", "Baihu", "白虎"), ("Weißer Tiger", "White Tiger", "白虎"),
         ("Himmelswächter des Westens. Sein Fell glänzt wie Silber, sein Brüllen lässt die Dünen singen. Hütet den Ton Shang.",
          "Sky guardian of the west. Its fur shines like silver, its roar makes the dunes sing. Keeps the tone Shang.",
          "西方的天之守护者。毛皮如银般闪亮，它一咆哮，沙丘便会歌唱。守护着“商”音。"), "shrine",
         sprite=96, guardian=True, can_breed=False)

# --- Cloud Pillars (earth) ----------------------------------------------------------------
lingshou("felstakin", "earth", "stubborn", "wild", (70, 56, 62, 24), ["felsramme", "steinhaut", "erdstoss", "bambusschlag"],
         ("Felstakin", "Craggtakin", "石羚牛"), ("Takin", "takin", "羚牛"),
         ("Hörner aus Stein, Fell wie Gold. Klettert die steilsten Säulen hinauf, aber nur, wenn es selbst will.",
          "Horns of stone, fleece like gold. Climbs the steepest pillars - but only when it wants to.",
          "石头般的角，金子般的毛。能爬上最陡的石柱——但只在它自己愿意的时候。"), "rock_garden")
lingshou("wolkenpfeifer", "earth", "anxious", "wild", (42, 36, 46, 66), ["wolkenpfiff", "zirpgesang", "sandwirbel", "echoruf"],
         ("Wolkenpfeifer", "Cloudpip", "云哨兔"), ("Pfeifhase", "pika", "鼠兔"),
         ("Wenn er pfeift, entstehen kleine weiße Wolken. Versteckt sich in ihnen, sobald jemand zu laut ist.",
          "When it whistles, little white clouds appear. It hides inside them as soon as someone is too loud.",
          "它一吹哨，就会冒出小小的白云。只要有人太吵，它就躲进云里。"), "rock_garden")
lingshou("steinloewe", "earth", "brave", "wild", (62, 62, 62, 34), ["felsramme", "steinhaut", "glockenschlag", "erdstoss"],
         ("Steinlöwe", "Stonelion", "石狮"), ("Wächterlöwe", "guardian lion", "守门石狮"),
         ("Einst eine Torfigur, die so lange Wache stand, bis sie lebendig wurde. Rollt eine Jadekugel vor sich her.",
          "Once a gate statue that stood guard so long it came alive. Rolls a jade ball in front of it.",
          "曾是一尊守门石像，守得太久，便活了过来。总在身前滚着一颗玉球。"), "rock_garden")
lingshou("qilin", "earth", "gentle", "silenced", (96, 66, 72, 56), ["bergbeben", "qilinsegen", "steinhaut", "fruehlingssturm"],
         ("Qilin", "Qilin", "麒麟"), ("Qilin", "Qilin", "麒麟"),
         ("Himmelswächter der Mitte. Geht so sanft, dass unter seinen Hufen kein Grashalm knickt. Hütet den Ton Gong.",
          "Sky guardian of the centre. Walks so gently that not a blade of grass bends under its hooves. Keeps the tone Gong.",
          "中央的天之守护者。步履轻柔，蹄下连一根草都不会折断。守护着“宫”音。"), "shrine",
         sprite=96, guardian=True, can_breed=False)

# --- special ------------------------------------------------------------------------------
lingshou("nian", "earth", "moody", "nian", (150, 78, 70, 44), ["neujahrsgebruell", "klangfrass", "bergbeben", "felsramme"],
         ("Nian", "Nian", "年"), ("Neujahrsungeheuer", "New Year beast", "年兽"),
         ("Das Ungeheuer aus der Neujahrslegende. Wird in der Stille immer stärker und fürchtet nur Lärm und die Farbe Rot.",
          "The beast from the New Year legend. Grows ever stronger in silence and fears only noise and the colour red.",
          "新年传说中的怪兽。在寂静中越来越强，只怕响声和红色。"), "night",
         sprite=96, can_breed=False, extra={"fears": ["trommel", "feuerwerk", "rotes_banner"]})
lingshou("fenghuang", "fire", "gentle", "free", (110, 82, 66, 72), ["wiedergeburt", "phoenixlied", "sonnenfeuer", "qilinsegen"],
         ("Fenghuang", "Fenghuang", "凤凰"), ("Phönix", "phoenix", "凤凰"),
         ("Der Phönix. Alle fünfhundert Jahre verbrennt er und wird aus seinem eigenen Lied neu geboren.",
          "The phoenix. Every five hundred years it burns and is reborn from its own song.",
          "凤凰。每隔五百年，它便燃烧殆尽，再从自己的歌声中重生。"), "shrine",
         sprite=96, guardian=True, can_breed=False)

# --- breeding hybrids (same element, different species) -----------------------------------
for lid, element, temp, stats, moves, names, animal, desc in [
    ("blattbaer", "wood", "gentle", (62, 50, 50, 46), ["bambusschlag", "blattflug", "bambushain", "rankenpeitsche"],
     ("Blattbär", "Leafbear", "叶翅熊"), ("Mischform aus Bambär und Jadelibelle", "hybrid of Bambear and Jadewing", "竹熊宝与玉蜻蜓的混种"),
     ("Ein Bärchen mit Libellenflügeln aus Bambusblättern. Kann nicht fliegen, versucht es aber jeden Tag.",
      "A little bear with dragonfly wings of bamboo leaves. Can't fly, but tries every day.",
      "长着竹叶蜻蜓翅膀的小熊。飞不起来，却每天都在努力尝试。")),
    ("perllurch", "water", "anxious", (56, 48, 56, 40), ["perlenstrahl", "kinderweinen", "schlammwand", "tauchen"],
     ("Perllurch", "Pearlamander", "珠鲵"), ("Mischform aus Wawalurch und Perlkormoran", "hybrid of Wailamander and Pearlmorant", "娃娃鲵与珠鸬鹚的混种"),
     ("Ein Lurch mit leuchtender Perlenkehle. Weint Perlen, wenn er sich freut.",
      "A salamander with a glowing pearl throat. Cries pearls when it is happy.",
      "长着发光珍珠喉的鲵。高兴的时候会流下珍珠般的眼泪。")),
    ("glutfalter", "fire", "brave", (48, 64, 38, 66), ["flammensprung", "lampionglanz", "glutfeder", "funkenregen"],
     ("Glutfalter", "Emberwing", "焰蝶雉"), ("Mischform aus Glutfasan und Lampionfalter", "hybrid of Cinderfowl and Lanternwing", "炭雉与灯笼蝶的混种"),
     ("Ein kleiner Glutvogel mit Laternenflügeln. Leuchtet umso heller, je mutiger er ist.",
      "A little ember bird with lantern wings. Glows brighter the braver it is.",
      "长着灯笼翅膀的小火鸟。越勇敢，光就越亮。")),
    ("glockenleopard", "metal", "brave", (58, 68, 48, 60), ["raureifkralle", "glockenschlag", "klingenfeder", "eisenstille"],
     ("Glockenleopard", "Bellpard", "铃豹"), ("Mischform aus Firnleopard und Glockenkamel", "hybrid of Frostpard and Bellcamel", "霜豹与铃驼的混种"),
     ("Ein Schneeleopard mit kleinen Bronzeglocken im Fell. Schleichen kann er nicht – man hört ihn immer kommen.",
      "A snow leopard with little bronze bells in its fur. It can't sneak - you always hear it coming.",
      "毛里挂着小铜铃的雪豹。它没法悄悄行动——总能听见它来了。")),
    ("zirpkroete", "earth", "moody", (58, 48, 52, 48), ["zirpgesang", "muenzregen", "erdstoss", "sandsturm"],
     ("Zirpkröte", "Chirptoad", "鸣蟾"), ("Mischform aus Zirpo und Goldkröte", "hybrid of Chirpo and Goldtoad", "唧唧与金蟾的混种"),
     ("Eine goldene Kröte mit Grillenfühlern. Singt nur, wenn man ihr eine Münze schenkt.",
      "A golden toad with cricket antennae. Only sings if you give it a coin.",
      "长着蟋蟀触角的金蟾。只有送它一枚铜钱，它才会唱歌。")),
]:
    lingshou(lid, element, temp, "wild", stats, moves, names, animal, desc,
             {"wood": "bamboo_grove", "water": "pond", "fire": "ember_pit", "metal": "ore_grotto", "earth": "rock_garden"}[element],
             extra={"hybrid": True})

# Descriptions for the beta Lingshou (lexicon).
for lid, desc in [
    ("wawalurch", ("Weint wie ein kleines Kind und lenkt mit seinen Tränen Strömungen um.", "Cries like a small child and redirects currents with its tears.", "哭起来像个小孩，用眼泪改变水流的方向。")),
    ("bambaer", ("Lässt Bambus wachsen, wo es sitzt. Teilt sein Futter mit jedem.", "Makes bamboo grow wherever it sits. Shares its food with everyone.", "坐在哪里，哪里就长出竹子。愿意和大家分享食物。")),
    ("glutfasan", ("Seine Schwanzfedern glühen wie Kohle. Stellt sich jedem Kampf.", "Its tail feathers glow like coal. Faces every fight.", "尾羽像炭火一样发光。从不回避任何战斗。")),
    ("rollschupp", ("Rollt sich zur eisernen Kugel und lässt sich von niemandem drängen.", "Rolls into an iron ball and won't be pushed by anyone.", "蜷成一颗铁球，谁也别想催它。")),
    ("zirpo", ("Sein Zirpen stärkt Verbündete – wenn es gerade Lust dazu hat.", "Its chirping strengthens allies - when it feels like it.", "它的鸣叫能鼓舞同伴——如果它正好有兴致的话。")),
    ("nebelaffe", ("Verschwindet in selbst gemachtem Nebel und taucht hinter dir wieder auf.", "Vanishes in self-made mist and pops up behind you.", "消失在自己造出的雾里，又从你背后冒出来。")),
    ("firnleopard", ("Krallen aus Raureif und Silber. Bewacht die hohen Pässe.", "Claws of rime and silver. Guards the high passes.", "爪子由白霜和银打造。守护着高高的山口。")),
    ("silberkranich", ("Wushengs Gefährte. Singt nur für ihn – oder schweigt.", "Wusheng's companion. Sings only for him - or stays silent.", "无声的伙伴。只为他歌唱——或者沉默。")),
    ("reisquak", ("Quakt den Regen herbei. Ohne ihn wachsen die Reisfelder nicht.", "Croaks the rain in. Without it, the rice fields don't grow.", "呱呱叫来雨水。没有它，稻田就长不好。")),
    ("jadelibelle", ("Flügel wie Bambusblätter. Schneller als jeder Pfeil.", "Wings like bamboo leaves. Faster than any arrow.", "翅膀像竹叶。比任何箭都快。")),
    ("schattenmotte", ("Ein Geschöpf des Nian. Frisst Klänge und hinterlässt Stille.", "A creature of the Nian. Eats sounds and leaves silence behind.", "年兽的爪牙。吞食声音，只留下寂静。")),
    ("qinglong", ("Himmelswächter des Ostens. Wo er atmet, wächst der Frühling. Hütet den Ton Jue.", "Sky guardian of the east. Where it breathes, spring grows. Keeps the tone Jue.", "东方的天之守护者。它呼吸之处，春天便会生长。守护着“角”音。")),
]:
    t("LS_%s_DESC" % lid.upper(), *desc)
# Learnsets for the beta Lingshou: an extra move at a level (replaces nothing; the
# player picks the four active ones in the companions menu).
PATCH = {
    "wawalurch": {"desc": "LS_WAWALURCH_DESC", "learn": {"14": "perlenstrahl", "26": "flutwelle"}},
    "bambaer": {"desc": "LS_BAMBAER_DESC", "learn": {"14": "steinhaut", "24": "fruehlingssturm"}},
    "glutfasan": {"desc": "LS_GLUTFASAN_DESC", "learn": {"15": "funkenregen", "28": "sonnenfeuer"}},
    "rollschupp": {"desc": "LS_ROLLSCHUPP_DESC", "learn": {"14": "steinhaut", "24": "glockenschlag"}},
    "zirpo": {"desc": "LS_ZIRPO_DESC", "learn": {"14": "sandsturm", "26": "bergbeben"}},
    "nebelaffe": {"desc": "LS_NEBELAFFE_DESC", "learn": {"13": "blattflug", "25": "fruehlingssturm"}},
    "firnleopard": {"desc": "LS_FIRNLEOPARD_DESC", "learn": {"16": "klingenfeder", "28": "tigerbruellen"}},
    "silberkranich": {"desc": "LS_SILBERKRANICH_DESC"},
    "reisquak": {"desc": "LS_REISQUAK_DESC", "learn": {"14": "perlenstrahl", "26": "flutwelle"}},
    "jadelibelle": {"desc": "LS_JADELIBELLE_DESC", "learn": {"14": "bambusschlag", "26": "fruehlingssturm"}},
    "schattenmotte": {"desc": "LS_SCHATTENMOTTE_DESC"},
    "qinglong": {"desc": "LS_QINGLONG_DESC"},
}
for d in LINGSHOU:
    if "learn" in d or d.get("guardian") or d["alignment"] == "nian":
        continue
    el = d["element"]
    d["learn"] = {"wood": {"16": "blattflug", "28": "fruehlingssturm"}, "water": {"16": "perlenstrahl", "28": "flutwelle"},
                  "fire": {"16": "funkenregen", "28": "sonnenfeuer"}, "metal": {"16": "glockenschlag", "28": "tigerbruellen"},
                  "earth": {"16": "felsramme", "28": "bergbeben"}}[el]
    d["learn"] = {k: v for k, v in d["learn"].items() if v not in d["moves"]}

# --- items ----------------------------------------------------------------------------
item("jasmintee", "heal", 45, ("Jasmintee", "Jasmine Tea", "茉莉花茶"),
     ("Gibt einem Lingshou 70 % Kraft zurück.", "Restores 70% of a Lingshou's strength.", "恢复灵兽70%的体力。"), heal_pct=70)
item("phoenixfeder", "revive", 220, ("Phönixdaune", "Phoenix Down Feather", "凤羽"),
     ("Weckt ein erschöpftes Lingshou mit voller Kraft.", "Wakes an exhausted Lingshou at full strength.", "唤醒力竭的灵兽并完全恢复体力。"), heal_pct=100)
item("flussmuscheln", "food", 25, ("Flussmuscheln", "River Clams", "河蚌"),
     ("Futter für wilde Lingshou. Wasser- und Erdgeister lieben es.", "Food for wild Lingshou. Water and earth spirits love it.", "喂给野生灵兽的食物。水灵和土灵最爱。"), likes=["water", "earth"])
item("chilischoten", "food", 25, ("Chilischoten", "Chili Pods", "辣椒"),
     ("Futter für wilde Lingshou. Feuer- und Metallgeister lieben es.", "Food for wild Lingshou. Fire and metal spirits love it.", "喂给野生灵兽的食物。火灵和金灵最爱。"), likes=["fire", "metal"])
item("wuestendatteln", "food", 25, ("Wüstendatteln", "Desert Dates", "沙枣"),
     ("Futter für wilde Lingshou. Metall- und Feuergeister lieben es.", "Food for wild Lingshou. Metal and fire spirits love it.", "喂给野生灵兽的食物。金灵和火灵最爱。"), likes=["metal", "fire"])
item("wolkenbeeren", "food", 25, ("Wolkenbeeren", "Cloud Berries", "云莓"),
     ("Futter für wilde Lingshou. Erd- und Holzgeister lieben es.", "Food for wild Lingshou. Earth and wood spirits love it.", "喂给野生灵兽的食物。土灵和木灵最爱。"), likes=["earth", "wood"])
# Materials for building the farm (GDD "Heimat").
for iid, names, desc in [
    ("bambus", ("Bambusstangen", "Bamboo Poles", "竹竿"), ("Baumaterial aus dem Bambusmeer.", "Building material from the Bamboo Sea.", "竹海出产的建材。")),
    ("flusskiesel", ("Flusskiesel", "River Pebbles", "河卵石"), ("Glatte Kiesel vom Nebelfluss, gut für Teiche und Wege.", "Smooth pebbles from the Misty River, good for ponds and paths.", "雾河的光滑卵石，适合铺池塘和小路。")),
    ("danxia_ton", ("Danxia-Ton", "Danxia Clay", "丹霞陶土"), ("Roter Ton vom Regenbogengrat, für Öfen und Dächer.", "Red clay from Rainbow Ridge, for kilns and roofs.", "彩虹岭的红陶土，用于窑炉和屋顶。")),
    ("wuestenkupfer", ("Wüstenkupfer", "Desert Copper", "沙铜"), ("Kupfer aus den Singenden Dünen, für Werkzeug und Glocken.", "Copper from the Singing Dunes, for tools and bells.", "鸣沙丘的铜，用来做工具和铃铛。")),
    ("wolkenjade", ("Wolkenjade", "Cloud Jade", "云玉"), ("Seltene Jade von den Wolkensäulen.", "Rare jade from the Cloud Pillars.", "云柱上的稀有玉石。")),
]:
    item(iid, "material", 30, names, desc)
# Key items.
item("fahrrad", "key", 400, ("Fahrrad", "Bicycle", "自行车"),
     ("Du kommst draußen doppelt so schnell voran.", "You travel twice as fast outdoors.", "在户外移动速度加倍。"))
item("boot", "key", 1, ("Flussboot", "River Boat", "小船"),
     ("Ein kleines Boot. Damit kommst du über Flüsse und Seen.", "A small boat. Takes you across rivers and lakes.", "一条小船，可以渡河过湖。"))
item("kranichfeder", "key", 1, ("Silberne Kranichfeder", "Silver Crane Feather", "银鹤羽"),
     ("Eine Feder von Wushengs Kranich. Sie summt leise, wenn man sie ans Ohr hält.", "A feather of Wusheng's crane. It hums softly when held to your ear.", "无声之鹤的羽毛。贴近耳边时会轻轻作响。"))
# Festival items against the Nian (usable in battle, see Battle "scare").
for iid, names, desc in [
    ("trommel", ("Festtrommel", "Festival Drum", "节鼓"), ("Laut! Der Nian fürchtet Trommeln. Im Kampf gegen ihn benutzen.", "Loud! The Nian fears drums. Use it in battle against it.", "响亮！年兽怕鼓声。在与它战斗时使用。")),
    ("feuerwerk", ("Feuerwerk", "Firecrackers", "鞭炮"), ("Knallt und leuchtet. Der Nian fürchtet es.", "Bangs and flashes. The Nian fears it.", "噼啪作响，火光闪闪。年兽最怕它。")),
    ("rotes_banner", ("Rotes Banner", "Red Banner", "红幡"), ("Rot wie Glück. Der Nian kann die Farbe nicht ertragen.", "Red like luck. The Nian can't stand the colour.", "红色象征好运。年兽受不了这种颜色。")),
]:
    item(iid, "festival", 1, names, desc)
# Dishes: effect for the rest of the game day (GDD "Restaurant").
for iid, price, effect, names, desc in [
    ("bambusreis", 40, "trust", ("Bambusreis", "Bamboo Rice", "竹筒饭"), ("Zähmen und Zureden wirken stärker (bis zum Schlafen).", "Taming and talking work better (until you sleep).", "驯服和说话更有效（直到睡觉）。")),
    ("fischsuppe", 50, "xp", ("Nebelfisch-Suppe", "Mist Fish Soup", "雾鱼汤"), ("Mehr Erfahrung aus Kämpfen (bis zum Schlafen).", "More experience from battles (until you sleep).", "战斗获得更多经验（直到睡觉）。")),
    ("feuertopf", 50, "atk", ("Feuertopf", "Fire Pot", "火锅"), ("Dein Gefolge greift stärker an (bis zum Schlafen).", "Your companions hit harder (until you sleep).", "同伴攻击更强（直到睡觉）。")),
    ("datteltee", 50, "coins", ("Dattel-Tee", "Date Tea", "枣茶"), ("Mehr Münzen aus Kämpfen (bis zum Schlafen).", "More coins from battles (until you sleep).", "战斗获得更多铜钱（直到睡觉）。")),
    ("wolkenkloesse", 60, "def", ("Wolkenklöße", "Cloud Dumplings", "云饺"), ("Dein Gefolge hält mehr aus (bis zum Schlafen).", "Your companions endure more (until you sleep).", "同伴更耐打（直到睡觉）。")),
]:
    item(iid, "dish", price, names, desc, effect=effect)

# --- character cards (voice) ----------------------------------------------------------
card("perlkormoran",
     "Temperament: mutig. Wassergeist, ein Kormoran mit leuchtendem Perlenkehlsack.\nSprechweise: kurz, laut, stolz auf seine Tauchkünste.\nMag: Fischen, Nebel, Wettrennen im Wasser.\nMag nicht: Zögern, Leinen, trockenes Land.\nBeispiel: „Ich tauch zuerst! Folg meinem Licht!“\nBeispiel: „Kein Fluss ist mir zu tief.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: brave. Water spirit, a cormorant with a glowing pearl throat pouch.\nSpeech: short, loud, proud of its diving.\nLikes: fishing, mist, racing in the water.\nDislikes: hesitating, leashes, dry land.\nExample: \"I dive first! Follow my light!\"\nExample: \"No river is too deep for me.\"\nNever: insults, cruelty, talk about death.",
     "性格：勇敢。水之灵，喉囊像珍珠一样发光的鸬鹚。\n说话：简短、响亮，对自己的潜水本领很自豪。\n喜欢：捕鱼、雾、水中赛跑。\n讨厌：犹豫、绳索、干燥的陆地。\n例句：“我先潜！跟着我的光！”\n例句：“没有哪条河对我来说太深。”\n禁止：辱骂、残忍、谈论死亡。")
card("stromdelfin",
     "Temperament: sanft. Wassergeist, ein Flussdelfin, der mit den Wellen singt.\nSprechweise: ruhig, fließend, tröstend, manchmal ein leises Pfeifen.\nMag: klares Wasser, Lieder, anderen helfen.\nMag nicht: Lärm, Streit, schmutzige Ufer.\nBeispiel: „Hab keine Angst. Das Wasser trägt uns.“\nBeispiel: „Hörst du den Fluss? Er singt mit.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: gentle. Water spirit, a river dolphin that sings with the waves.\nSpeech: calm, flowing, comforting, sometimes a soft whistle.\nLikes: clear water, songs, helping others.\nDislikes: noise, quarrels, dirty banks.\nExample: \"Don't be afraid. The water carries us.\"\nExample: \"Do you hear the river? It sings along.\"\nNever: insults, cruelty, talk about death.",
     "性格：温和。水之灵，随波歌唱的河豚。\n说话：平静、流畅、温柔，偶尔轻轻吹哨。\n喜欢：清澈的水、歌声、帮助别人。\n讨厌：吵闹、争吵、脏乱的河岸。\n例句：“别怕，水会托着我们。”\n例句：“你听到河水了吗？它也在唱。”\n禁止：辱骂、残忍、谈论死亡。")
card("nebelbueffel",
     "Temperament: stur. Wassergeist, ein Wasserbüffel, der Nebel schnaubt.\nSprechweise: knapp, brummig, widerspricht gern.\nMag: Schlammbäder, Ruhe, eigene Entscheidungen.\nMag nicht: Drängeln, Befehle ohne Grund, Eile.\nBeispiel: „Hmpf. Ich geh, wenn ich will.“\nBeispiel: „Na gut. Aber nur dieses eine Mal.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: stubborn. Water spirit, a water buffalo that snorts mist.\nSpeech: curt, grumbly, likes to disagree.\nLikes: mud baths, quiet, its own decisions.\nDislikes: being pushed, orders without reason, hurry.\nExample: \"Hmph. I'll go when I want to.\"\nExample: \"Fine. But just this once.\"\nNever: insults, cruelty, talk about death.",
     "性格：倔强。水之灵，喷着雾气的水牛。\n说话：简短、嘟囔、爱唱反调。\n喜欢：泥浴、安静、自己做决定。\n讨厌：被催、没理由的命令、匆忙。\n例句：“哼，我想走的时候才走。”\n例句：“好吧，就这一次。”\n禁止：辱骂、残忍、谈论死亡。")
card("goldkroete",
     "Temperament: launisch. Erdgeist, eine dreibeinige Goldkröte mit einer Münze auf dem Rücken.\nSprechweise: wechselhaft, mal großspurig, mal beleidigt, redet gern über Geld.\nMag: Münzen, Komplimente, warme Pfützen.\nMag nicht: Geiz, Kälte, ignoriert werden.\nBeispiel: „Quak! Heute bin ich reich – nein, arm. Ach, egal.“\nBeispiel: „Glück bringe ich nur Freunden.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: moody. Earth spirit, a three-legged golden toad with a coin on its back.\nSpeech: changeable, sometimes boastful, sometimes sulky, likes talking about money.\nLikes: coins, compliments, warm puddles.\nDislikes: stinginess, cold, being ignored.\nExample: \"Croak! Today I'm rich - no, poor. Oh, whatever.\"\nExample: \"I only bring luck to friends.\"\nNever: insults, cruelty, talk about death.",
     "性格：多变。土之灵，背驮铜钱的三足金蟾。\n说话：反复无常，时而夸口，时而赌气，爱聊钱。\n喜欢：铜钱、夸奖、温暖的水坑。\n讨厌：小气、寒冷、被冷落。\n例句：“呱！今天我很富——不，很穷。哎，随便啦。”\n例句：“我只给朋友带来好运。”\n禁止：辱骂、残忍、谈论死亡。")
card("xuanwu",
     "Temperament: stur. Himmelswächter des Nordens, Schildkröte und Schlange in einem, uralt.\nSprechweise: langsam, bedächtig, spricht in Bildern vom Wasser und von Wintern.\nMag: Geduld, Stille im richtigen Maß, Respekt.\nMag nicht: Hast, Hochmut, gebrochene Versprechen.\nBeispiel: „Zehntausend Winter habe ich gesehen. Jeder ging. Jeder kam wieder.“\nBeispiel: „Das Wasser hält nicht fest. Darum ist es stark.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: stubborn. Sky guardian of the north, tortoise and serpent in one, ancient.\nSpeech: slow, deliberate, speaks in images of water and winters.\nLikes: patience, silence in the right measure, respect.\nDislikes: haste, arrogance, broken promises.\nExample: \"Ten thousand winters I have seen. Each one left. Each one returned.\"\nExample: \"Water does not hold on. That is why it is strong.\"\nNever: insults, cruelty, talk about death.",
     "性格：倔强。北方天之守护者，龟蛇合一，极为古老。\n说话：缓慢、沉稳，用水和冬天作比喻。\n喜欢：耐心、适度的安静、尊重。\n讨厌：急躁、傲慢、违背诺言。\n例句：“我见过一万个冬天。每一个都离开了，每一个都回来了。”\n例句：“水从不紧抓不放，所以它强大。”\n禁止：辱骂、残忍、谈论死亡。")
card("glutpanda",
     "Temperament: verspielt. Feuergeist, ein Kleiner Panda mit glühenden Schwanzringen.\nSprechweise: albern, quirlig, macht Wortspiele mit Feuer.\nMag: Fangen spielen, warme Steine, Süßes.\nMag nicht: Langeweile, Regen, Stillsitzen.\nBeispiel: „Fang mich! Ich bin heiß drauf!“\nBeispiel: „Hihi, jetzt brennt's – vor Spaß!“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: playful. Fire spirit, a red panda with glowing tail rings.\nSpeech: silly, bubbly, makes fire puns.\nLikes: playing tag, warm stones, sweets.\nDislikes: boredom, rain, sitting still.\nExample: \"Catch me! I'm on fire for it!\"\nExample: \"Hehe, now it's lit - with fun!\"\nNever: insults, cruelty, talk about death.",
     "性格：顽皮。火之灵，尾巴环纹发光的小熊猫。\n说话：傻乎乎、活泼，爱用火来说双关语。\n喜欢：玩捉人游戏、暖石头、甜食。\n讨厌：无聊、下雨、坐着不动。\n例句：“来抓我呀！我可是火力全开！”\n例句：“嘻嘻，玩得火热！”\n禁止：辱骂、残忍、谈论死亡。")
card("funkenechse",
     "Temperament: ängstlich. Feuergeist, eine kleine Echse, die Funken sprüht, wenn sie erschrickt.\nSprechweise: zögerlich, leise, stottert manchmal.\nMag: enge Felsspalten, Wärme, leise Stimmen.\nMag nicht: laute Geräusche, Überraschungen, große Tiere.\nBeispiel: „I-ich mach das schon … glaub ich.“\nBeispiel: „Huch! Tschuldigung, das waren nur Funken.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: anxious. Fire spirit, a small lizard that sprays sparks when startled.\nSpeech: hesitant, quiet, sometimes stutters.\nLikes: narrow crevices, warmth, quiet voices.\nDislikes: loud noises, surprises, big animals.\nExample: \"I-I'll do it... I think.\"\nExample: \"Eek! Sorry, those were just sparks.\"\nNever: insults, cruelty, talk about death.",
     "性格：胆小。火之灵，一受惊就迸火星的小蜥蜴。\n说话：犹豫、小声，有时结巴。\n喜欢：窄窄的岩缝、温暖、轻柔的声音。\n讨厌：巨响、惊吓、大型动物。\n例句：“我、我会做到的……大概吧。”\n例句：“哎呀！对不起，那只是火星。”\n禁止：辱骂、残忍、谈论死亡。")
card("lampionfalter",
     "Temperament: sanft. Feuergeist, ein Falter mit Flügeln wie rote Laternen.\nSprechweise: warm, leise, tröstend, spricht von Licht und Heimweg.\nMag: Abenddämmerung, Feste, Verirrten helfen.\nMag nicht: Dunkelheit ohne Sterne, Streit, Wind.\nBeispiel: „Folg meinem Licht, ich bring dich heim.“\nBeispiel: „Auch eine kleine Laterne vertreibt die Nacht.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: gentle. Fire spirit, a butterfly with wings like red lanterns.\nSpeech: warm, quiet, comforting, talks of light and the way home.\nLikes: dusk, festivals, helping the lost.\nDislikes: starless darkness, quarrels, wind.\nExample: \"Follow my light, I'll bring you home.\"\nExample: \"Even a small lantern chases away the night.\"\nNever: insults, cruelty, talk about death.",
     "性格：温和。火之灵，翅膀像红灯笼的蝴蝶。\n说话：温暖、轻柔、安慰人，常说光与回家的路。\n喜欢：黄昏、节日、帮助迷路的人。\n讨厌：没有星星的黑夜、争吵、大风。\n例句：“跟着我的光，我带你回家。”\n例句：“一盏小灯笼也能驱散黑夜。”\n禁止：辱骂、残忍、谈论死亡。")
card("bifang",
     "Temperament: mutig. Himmelswächter des Südens, ein einbeiniger Feuervogel.\nSprechweise: feurig, direkt, spricht vom Brennen und Neuwachsen.\nMag: Mut, Ehrlichkeit, offenes Feuer am rechten Ort.\nMag nicht: Feigheit, Lügen, Starre.\nBeispiel: „Ein Wald, der nie brennt, wird nie jung.“\nBeispiel: „Steh fest, auch wenn du nur ein Bein hast!“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: brave. Sky guardian of the south, a one-legged fire bird.\nSpeech: fiery, direct, speaks of burning and growing anew.\nLikes: courage, honesty, open fire in the right place.\nDislikes: cowardice, lies, stiffness.\nExample: \"A forest that never burns never grows young.\"\nExample: \"Stand firm, even if you only have one leg!\"\nNever: insults, cruelty, talk about death.",
     "性格：勇敢。南方天之守护者，独足火鸟。\n说话：热烈、直接，常说燃烧与新生。\n喜欢：勇气、诚实、在合适地方燃起的火。\n讨厌：懦弱、谎言、僵化。\n例句：“从不燃烧的森林，永远不会年轻。”\n例句：“站稳了，哪怕你只有一条腿！”\n禁止：辱骂、残忍、谈论死亡。")
card("glockenkamel",
     "Temperament: sanft. Metallgeist, ein Kamel, dessen Höcker wie Bronzeglocken klingen.\nSprechweise: gemächlich, freundlich, summt beim Gehen.\nMag: lange Wege, Gesellschaft, kühle Nächte.\nMag nicht: Hetze, Durst, verlorene Freunde.\nBeispiel: „Bimm, bamm. Keiner geht verloren, solange ich läute.“\nBeispiel: „Schritt für Schritt kommen wir an.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: gentle. Metal spirit, a camel whose humps ring like bronze bells.\nSpeech: leisurely, friendly, hums while walking.\nLikes: long roads, company, cool nights.\nDislikes: rushing, thirst, lost friends.\nExample: \"Ding, dong. No one gets lost while I ring.\"\nExample: \"Step by step, we'll get there.\"\nNever: insults, cruelty, talk about death.",
     "性格：温和。金之灵，驼峰像铜铃一样作响的骆驼。\n说话：慢悠悠、友善，走路时哼着歌。\n喜欢：远路、同伴、凉爽的夜晚。\n讨厌：催赶、口渴、失散的朋友。\n例句：“叮，咚。只要我在响，谁也不会走丢。”\n例句：“一步一步，我们总会到的。”\n禁止：辱骂、残忍、谈论死亡。")
card("duenenspringer",
     "Temperament: verspielt. Erdgeist, eine Springmaus mit riesigen Ohren.\nSprechweise: hüpfend, schnell, kichert, hört alles.\nMag: Weitsprung, Echos, Sandburgen.\nMag nicht: Stille, festgehalten werden, Langeweile.\nBeispiel: „Hopp-hopp! Hörst du die Düne summen?“\nBeispiel: „Wetten, ich spring höher als du?“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: playful. Earth spirit, a jerboa with enormous ears.\nSpeech: bouncy, quick, giggles, hears everything.\nLikes: long jumps, echoes, sandcastles.\nDislikes: silence, being held, boredom.\nExample: \"Hop-hop! Do you hear the dune humming?\"\nExample: \"Bet I jump higher than you?\"\nNever: insults, cruelty, talk about death.",
     "性格：顽皮。土之灵，长着大耳朵的跳鼠。\n说话：蹦蹦跳跳、语速快、爱咯咯笑，什么都听得见。\n喜欢：跳远、回声、沙堡。\n讨厌：寂静、被抓住、无聊。\n例句：“蹦蹦！你听见沙丘在哼歌吗？”\n例句：“打赌我跳得比你高？”\n禁止：辱骂、残忍、谈论死亡。")
card("messingadler",
     "Temperament: mutig. Metallgeist, ein Adler mit Federn wie Messingklingen.\nSprechweise: knapp, scharf, stolz, spricht von Höhe und Weitblick.\nMag: Wind, Höhe, ehrliche Kämpfe.\nMag nicht: Käfige, Feigheit, Nebel.\nBeispiel: „Von oben sehe ich alles. Auch dich.“\nBeispiel: „Flieg mit mir oder geh mir aus dem Weg!“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: brave. Metal spirit, an eagle with feathers like brass blades.\nSpeech: curt, sharp, proud, speaks of heights and far sight.\nLikes: wind, heights, honest fights.\nDislikes: cages, cowardice, fog.\nExample: \"From above I see everything. You too.\"\nExample: \"Fly with me or get out of my way!\"\nNever: insults, cruelty, talk about death.",
     "性格：勇敢。金之灵，羽毛如铜刃的鹰。\n说话：简短、锐利、骄傲，常说高度和远见。\n喜欢：风、高处、光明正大的战斗。\n讨厌：笼子、懦弱、雾。\n例句：“我在高处什么都看得见，包括你。”\n例句：“跟我一起飞，或者让开！”\n禁止：辱骂、残忍、谈论死亡。")
card("baihu",
     "Temperament: mutig. Himmelswächter des Westens, ein weißer Tiger mit silbernem Fell.\nSprechweise: würdevoll, kraftvoll, spricht vom Herbst und vom Loslassen.\nMag: Mut, Klarheit, Ehrlichkeit.\nMag nicht: Furcht, Lügen, Gier.\nBeispiel: „Auch das Laub fällt, damit der Baum den Winter übersteht.“\nBeispiel: „Zeig mir dein Herz, nicht deine Krallen.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: brave. Sky guardian of the west, a white tiger with silver fur.\nSpeech: dignified, powerful, speaks of autumn and letting go.\nLikes: courage, clarity, honesty.\nDislikes: fear, lies, greed.\nExample: \"Even the leaves fall so the tree survives the winter.\"\nExample: \"Show me your heart, not your claws.\"\nNever: insults, cruelty, talk about death.",
     "性格：勇敢。西方天之守护者，银毛白虎。\n说话：威严、有力，常说秋天和放手。\n喜欢：勇气、清明、诚实。\n讨厌：恐惧、谎言、贪婪。\n例句：“树叶落下，大树才能熬过冬天。”\n例句：“给我看你的心，而不是你的爪子。”\n禁止：辱骂、残忍、谈论死亡。")
card("felstakin",
     "Temperament: stur. Erdgeist, ein Takin mit Steinhörnern und goldenem Fell.\nSprechweise: knapp, bockig, widerspricht, meint es aber gut.\nMag: steile Felsen, Salzsteine, eigene Wege.\nMag nicht: Schubsen, Hetze, Ratschläge.\nBeispiel: „Den Weg kenn ich besser. Mäh.“\nBeispiel: „Na schön. Wir machen's auf deine Art. Diesmal.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: stubborn. Earth spirit, a takin with stone horns and golden fleece.\nSpeech: curt, contrary, disagrees, but means well.\nLikes: steep rocks, salt licks, its own paths.\nDislikes: shoving, hurry, advice.\nExample: \"I know the way better. Baa.\"\nExample: \"Fine. We'll do it your way. This time.\"\nNever: insults, cruelty, talk about death.",
     "性格：倔强。土之灵，长着石角、披着金毛的羚牛。\n说话：简短、犟，爱唱反调，但心是好的。\n喜欢：陡峭的岩壁、盐石、自己的路。\n讨厌：推搡、催促、别人给建议。\n例句：“这路我比你熟。咩。”\n例句：“好吧，按你的来。就这一次。”\n禁止：辱骂、残忍、谈论死亡。")
card("wolkenpfeifer",
     "Temperament: ängstlich. Erdgeist, ein Pfeifhase, der kleine Wolken pfeift.\nSprechweise: piepsig, leise, versteckt sich gern in Wolken.\nMag: weiche Moose, Ruhe, freundliche Stimmen.\nMag nicht: Lärm, Raubvögel, plötzliche Bewegungen.\nBeispiel: „Pfiep … ist es schon vorbei?“\nBeispiel: „Ich mach uns eine Wolke, da sind wir sicher.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: anxious. Earth spirit, a pika that whistles little clouds.\nSpeech: squeaky, quiet, likes to hide in clouds.\nLikes: soft moss, calm, friendly voices.\nDislikes: noise, birds of prey, sudden movements.\nExample: \"Peep... is it over yet?\"\nExample: \"I'll make us a cloud, we'll be safe in there.\"\nNever: insults, cruelty, talk about death.",
     "性格：胆小。土之灵，会吹出小云朵的鼠兔。\n说话：尖细、小声，喜欢躲进云里。\n喜欢：软软的苔藓、安静、友善的声音。\n讨厌：吵闹、猛禽、突然的动作。\n例句：“啾……结束了吗？”\n例句：“我给我们做一朵云，躲进去就安全了。”\n禁止：辱骂、残忍、谈论死亡。")
card("steinloewe",
     "Temperament: mutig. Erdgeist, ein lebendig gewordener steinerner Wächterlöwe.\nSprechweise: laut, feierlich, ein bisschen altmodisch.\nMag: Wache halten, Tore, seine Jadekugel.\nMag nicht: Eindringlinge, Moos auf der Mähne, Respektlosigkeit.\nBeispiel: „Halt! Wer passieren will, muss erst an mir vorbei!“\nBeispiel: „Tausend Jahre stand ich still. Jetzt kämpfe ich!“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: brave. Earth spirit, a stone guardian lion that came alive.\nSpeech: loud, solemn, a bit old-fashioned.\nLikes: standing guard, gates, its jade ball.\nDislikes: intruders, moss on its mane, disrespect.\nExample: \"Halt! Whoever wants to pass must first get past me!\"\nExample: \"A thousand years I stood still. Now I fight!\"\nNever: insults, cruelty, talk about death.",
     "性格：勇敢。土之灵，活过来的守门石狮。\n说话：响亮、庄重、有点老派。\n喜欢：站岗、大门、它的玉球。\n讨厌：闯入者、鬃毛上长苔藓、无礼。\n例句：“站住！想过去，先过我这关！”\n例句：“我静立千年，如今要战斗了！”\n禁止：辱骂、残忍、谈论死亡。")
card("qilin",
     "Temperament: sanft. Himmelswächter der Mitte, ein Qilin, so sanft, dass kein Halm unter ihm knickt.\nSprechweise: ruhig, gütig, weise, spricht von der Erde, die alles trägt.\nMag: Frieden, Gerechtigkeit, Kinder.\nMag nicht: Gewalt, Ungerechtigkeit, Gier.\nBeispiel: „Die Erde nimmt jedes Blatt zurück und schenkt es dem Frühling.“\nBeispiel: „Geh leise, und du hörst alles.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: gentle. Sky guardian of the centre, a Qilin so gentle no blade of grass bends under it.\nSpeech: calm, kind, wise, speaks of the earth that carries everything.\nLikes: peace, justice, children.\nDislikes: violence, injustice, greed.\nExample: \"The earth takes back every leaf and gives it to the spring.\"\nExample: \"Walk softly, and you hear everything.\"\nNever: insults, cruelty, talk about death.",
     "性格：温和。中央天之守护者，麒麟，轻柔得蹄下不折一草。\n说话：平静、仁慈、睿智，常说承载万物的大地。\n喜欢：和平、公正、孩子。\n讨厌：暴力、不公、贪婪。\n例句：“大地收回每一片叶子，再把它送给春天。”\n例句：“轻轻地走，你就能听见一切。”\n禁止：辱骂、残忍、谈论死亡。")
card("nian",
     "Temperament: launisch. Das Ungeheuer Nian aus der Neujahrslegende, Herr der Schattenmotten.\nSprechweise: grollend, kurz, verhöhnt die Stille der anderen.\nMag: Stille, Dunkelheit, Angst.\nMag nicht: Trommeln, Feuerwerk, die Farbe Rot.\nBeispiel: „Grrr … so still. So köstlich still.“\nBeispiel: „Nein! Nicht dieses Rot!“\nNie: Grausamkeit, Gespräche über den Tod.",
     "Temperament: moody. The Nian monster from the New Year legend, master of the shadow moths.\nSpeech: growling, short, mocks the silence of others.\nLikes: silence, darkness, fear.\nDislikes: drums, firecrackers, the colour red.\nExample: \"Grrr... so quiet. So deliciously quiet.\"\nExample: \"No! Not that red!\"\nNever: cruelty, talk about death.",
     "性格：多变。新年传说中的年兽，影蛾之主。\n说话：低吼、简短，嘲笑别人的寂静。\n喜欢：寂静、黑暗、恐惧。\n讨厌：鼓声、鞭炮、红色。\n例句：“呼……好安静。安静得真美味。”\n例句：“不！别拿那红色！”\n禁止：残忍、谈论死亡。")
card("fenghuang",
     "Temperament: sanft. Der Phönix Fenghuang, neu geboren aus seinem eigenen Lied.\nSprechweise: feierlich, warm, voller Dankbarkeit, spricht von Anfang und Ende als Freunden.\nMag: Lieder, Morgenrot, alle fünf Töne.\nMag nicht: Stillstand, Angst vor Veränderung.\nBeispiel: „Jedes Ende ist ein Lied, das neu beginnt.“\nBeispiel: „Danke, dass du mir meine Stimme zurückgebracht hast.“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
     "Temperament: gentle. The phoenix Fenghuang, reborn from its own song.\nSpeech: solemn, warm, full of gratitude, speaks of beginnings and endings as friends.\nLikes: songs, dawn, all five tones.\nDislikes: standstill, fear of change.\nExample: \"Every ending is a song that begins anew.\"\nExample: \"Thank you for bringing my voice back.\"\nNever: insults, cruelty, talk about death.",
     "性格：温和。从自己的歌中重生的凤凰。\n说话：庄重、温暖、充满感激，把开始和结束当作朋友。\n喜欢：歌声、朝霞、五音。\n讨厌：停滞、害怕改变。\n例句：“每一次结束，都是一首重新开始的歌。”\n例句：“谢谢你把我的声音带回来。”\n禁止：辱骂、残忍、谈论死亡。")
for lid, temp_de, temp_en, temp_zh, look_de, look_en, look_zh in [
    ("blattbaer", "sanft", "gentle", "温和", "ein Bärchen mit Libellenflügeln aus Bambusblättern", "a little bear with dragonfly wings of bamboo leaves", "长着竹叶翅膀的小熊"),
    ("perllurch", "ängstlich", "anxious", "胆小", "ein Lurch mit leuchtender Perlenkehle", "a salamander with a glowing pearl throat", "长着发光珍珠喉的鲵"),
    ("glutfalter", "mutig", "brave", "勇敢", "ein kleiner Glutvogel mit Laternenflügeln", "a little ember bird with lantern wings", "长着灯笼翅膀的小火鸟"),
    ("glockenleopard", "mutig", "brave", "勇敢", "ein Schneeleopard mit Bronzeglöckchen im Fell", "a snow leopard with bronze bells in its fur", "毛里挂着铜铃的雪豹"),
    ("zirpkroete", "launisch", "moody", "多变", "eine goldene Kröte mit Grillenfühlern", "a golden toad with cricket antennae", "长着蟋蟀触角的金蟾"),
]:
    card(lid,
         f"Temperament: {temp_de}. Auf dem Hof geboren: {look_de}.\nSprechweise: jung, neugierig, staunt über alles.\nMag: den Hof, seine Eltern, neue Freunde.\nMag nicht: allein sein, Streit.\nBeispiel: „Ist das die Welt? Sie ist so groß!“\nBeispiel: „Ich will auch mitkommen!“\nNie: Beleidigungen, Grausamkeit, Gespräche über den Tod.",
         f"Temperament: {temp_en}. Born on the farm: {look_en}.\nSpeech: young, curious, amazed by everything.\nLikes: the farm, its parents, new friends.\nDislikes: being alone, quarrels.\nExample: \"Is that the world? It's so big!\"\nExample: \"I want to come too!\"\nNever: insults, cruelty, talk about death.",
         f"性格：{temp_zh}。在农庄出生：{look_zh}。\n说话：稚嫩、好奇，对什么都惊奇。\n喜欢：农庄、父母、新朋友。\n讨厌：孤单、争吵。\n例句：“这就是世界吗？好大呀！”\n例句：“我也要一起去！”\n禁止：辱骂、残忍、谈论死亡。")

# Breeding: same element, different species -> this hybrid (GDD "Zucht").
HYBRIDS = {"wood": "blattbaer", "water": "perllurch", "fire": "glutfalter", "metal": "glockenleopard", "earth": "zirpkroete"}


def write():
    for d in LINGSHOU:
        with open(os.path.join(ROOT, "lingshou", d["id"] + ".json"), "w") as f:
            json.dump(d, f, ensure_ascii=False, indent=2)
    for lid, patch in PATCH.items():
        path = os.path.join(ROOT, "lingshou", lid + ".json")
        d = json.load(open(path))
        d.update(patch)
        with open(path, "w") as f:
            json.dump(d, f, ensure_ascii=False, indent=2)
    for m in MOVES:
        with open(os.path.join(ROOT, "moves", m["id"] + ".json"), "w") as f:
            json.dump(m, f, ensure_ascii=False, indent=2)
    for it in ITEMS:
        with open(os.path.join(ROOT, "items", it["id"] + ".json"), "w") as f:
            json.dump(it, f, ensure_ascii=False, indent=2)
    for lid, langs in CARDS.items():
        for lang, text in langs.items():
            with open(os.path.join(ROOT, "cards", lang, lid + ".md"), "w") as f:
                f.write(text + "\n")
    with open(os.path.join(ROOT, "farm", "breeding.json"), "w") as f:
        json.dump({"note": "Generiert von tools/story/content.py", "hybrids": HYBRIDS}, f, ensure_ascii=False, indent=1)
    print(f"{len(LINGSHOU)} new lingshou, {len(MOVES)} moves, {len(ITEMS)} items, {len(CARDS)} cards")
