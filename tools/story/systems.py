"""Texts and events of the game systems after the beta: clock and weather,
farm (pens, breeding, carpenter), inns with travel, restaurants, lexicon,
persuading people, battle additions and the endings screen.
Part of tools/story/build.py."""
from common import *

E = {}

for k, de, en, zh in [
    ("UI_DAY_N", "Tag {n}", "Day {n}", "第{n}天"),
    ("UI_TONES", "Töne", "Tones", "五音"),
    ("UI_SAY", "Sagen", "Say", "说"),
    ("MSG_MORNING", "Ein neuer Morgen bricht an. Tag {day}.", "A new morning dawns. Day {day}.", "新的一天开始了。第{day}天。"),
    ("MENU_LEXICON", "Lexikon", "Bestiary", "图鉴"),
    ("LEX_MOVES_NOTE", "Tippe Attacken an: bis zu vier sind aktiv.", "Tap moves: up to four are active.", "点击招式：最多四个可用。"),
    ("LEX_WHERE", "Zu finden:", "Found at:", "出没地点："),
    ("LEX_BRED", "Nur durch Zucht auf dem Hof.", "Only through breeding on the farm.", "只能在农庄繁殖获得。"),
    ("HOME_TITLE", "Zuhause", "Home", "家"),
    ("HOME_EGGS", "Eier", "Eggs", "蛋"),
    ("HOME_EGG_ROW", "Ein Ei von {name} – schlüpft in {n} Nächten.", "An egg of {name} - hatches in {n} nights.", "{name}的蛋——还有{n}晚孵化。"),
    ("INN_SLEEP", "Schlafen bis zum Morgen (heilen und speichern)", "Sleep until morning (heal and save)", "睡到天亮（恢复并存档）"),
    ("INN_TRAVEL", "Mit dem Windspiel reisen", "Travel with the wind chime", "乘风铃旅行"),
    ("FOOD_TITLE", "Restaurant", "Restaurant", "饭馆"),
    ("FOOD_ACTIVE", "Du hast heute schon {dish} gegessen. Ein neues Gericht ersetzt die Wirkung.", "You already ate {dish} today. A new dish replaces its effect.", "你今天已经吃过{dish}了。点新菜会替换效果。"),
    ("FOOD_EATEN", "Mmh! {dish} wirkt bis zum Schlafen.", "Mmm! {dish} works until you sleep.", "嗯！{dish}的效果持续到睡觉。"),
    ("WEATHER_SUN", "Sonne", "Sunny", "晴"),
    ("WEATHER_CLOUDY", "Wolkig", "Cloudy", "多云"),
    ("WEATHER_RAIN", "Regen", "Rain", "雨"),
    ("WEATHER_STORM", "Gewitter", "Thunderstorm", "雷雨"),
    ("WEATHER_FOG", "Nebel", "Fog", "雾"),
    ("WEATHER_SNOW", "Schnee", "Snow", "雪"),
    ("WEATHER_SANDSTORM", "Sandsturm", "Sandstorm", "沙暴"),
    # farm
    ("FARM_STAGE_0", "Hütte", "Hut", "小屋"),
    ("FARM_STAGE_1", "Haus", "House", "房子"),
    ("FARM_STAGE_2", "Hof", "Farmstead", "农院"),
    ("FARM_STAGE_3", "Gutshof", "Manor farm", "庄园"),
    ("FARM_STAGE_4", "Anwesen", "Estate", "大宅"),
    ("FARM_MAX", "Dein Hof ist so groß, wie er werden kann.", "Your farm is as big as it can get.", "你的农庄已经扩建到最大了。"),
    ("FARM_NOT_YET", "Dafür ist es noch zu früh – bring erst mehr Töne zurück.", "It's too early for that - bring back more tones first.", "现在还太早——先找回更多的音吧。"),
    ("FARM_NO_MATERIAL", "Dafür fehlen noch Baumaterialien.", "You're still missing building materials.", "还缺少建材。"),
    ("CARPENTER_TITLE", "Zimmermann", "Carpenter", "木匠"),
    ("CARPENTER_NOW", "Dein Hof: {stage}. Gehege: {built} von {pens} möglichen.", "Your farm: {stage}. Pens: {built} of {pens} possible.", "你的农庄：{stage}。围栏：{built}/{pens}。"),
    ("CARPENTER_NEXT", "Ausbau zu: {stage} ({pens} Gehege)", "Upgrade to: {stage} ({pens} pens)", "扩建为：{stage}（{pens}个围栏）"),
    ("CARPENTER_BUILD", "Ausbauen", "Build", "扩建"),
    ("CARPENTER_DONE", "Fertig! Schau dir deinen neuen Hof an.", "Done! Have a look at your new farm.", "完工了！去看看你的新农庄吧。"),
    ("PEN_TITLE", "Gehege", "Pen", "围栏"),
    ("PEN_POND", "Teich", "Pond", "池塘"),
    ("PEN_BAMBOO", "Bambushain", "Bamboo grove", "竹林"),
    ("PEN_EMBER", "Glutgrube", "Ember pit", "火坑"),
    ("PEN_ORE", "Erzgrotte", "Ore grotto", "矿洞"),
    ("PEN_ROCK", "Felsgarten", "Rock garden", "石园"),
    ("PEN_EMPTY", "leer", "empty", "空"),
    ("PEN_EMPTY_TITLE", "Baugrund", "Building plot", "空地"),
    ("PEN_BUILD_NOTE", "Hier kann ein Gehege entstehen ({coins} Münzen). Jedes Element mag ein anderes: Wasser den Teich, Holz den Bambushain, Feuer die Glutgrube, Metall die Erzgrotte, Erde den Felsgarten.",
     "A pen can be built here ({coins} coins). Each element likes a different one: water the pond, wood the bamboo grove, fire the ember pit, metal the ore grotto, earth the rock garden.",
     "这里可以建围栏（{coins}铜钱）。不同元素喜欢不同的围栏：水喜池塘，木喜竹林，火喜火坑，金喜矿洞，土喜石园。"),
    ("PEN_BUILD_ORDER", "Baue die Gehege der Reihe nach, von links oben an.", "Build the pens in order, starting top left.", "请从左上开始依次建造围栏。"),
    ("PEN_BUILT", "Das Gehege steht!", "The pen is ready!", "围栏建好了！"),
    ("PEN_NOBODY", "Niemand wohnt hier. Bring Lingshou vom Windspiel-Schrein her oder lass jemanden einziehen.", "Nobody lives here. Send Lingshou from the wind chime shrine or let someone move in.", "这里还没有住户。从风铃神龛送灵兽过来，或者让谁搬进来吧。"),
    ("PEN_PAIR", "Die beiden verstehen sich gut. Wenn sie zufrieden sind, gibt es vielleicht bald ein Ei!", "These two get along well. If they're content, there may soon be an egg!", "它们相处得很好。如果它们心满意足，也许很快就会有蛋！"),
    ("PEN_MOVE_IN", "Einziehen lassen", "Let move in", "搬进来"),
    ("PEN_REBUILD", "Umbauen (50 Münzen)", "Rebuild (50 coins)", "改建（50铜钱）"),
    ("PEN_REBUILD_NOTE", "Im passenden Gehege sind Lingshou zufriedener. Ein Paar derselben Art oder desselben Elements bekommt bei hoher Zufriedenheit Eier.",
     "Lingshou are more content in a fitting pen. A pair of the same kind or element lays eggs when they're very content.",
     "住在合适的围栏里，灵兽会更满足。同种或同元素的一对灵兽在很满足时会下蛋。"),
    ("PEN_HAPPY", "Zufriedenheit", "Content", "满足度"),
    ("PEN_WRONG", "Falsches Gehege", "Wrong pen", "围栏不合适"),
    ("PEN_YOUNG", "Jungtier", "Young", "幼崽"),
    ("PEN_FEED", "Füttern", "Feed", "喂食"),
    ("PEN_FED", "{name} frisst zufrieden.", "{name} eats happily.", "{name}吃得很开心。"),
    ("DIARY_PREFIX", "Hoftagebuch:", "Farm diary:", "农庄日记："),
    ("DIARY_EGG", "Hoftagebuch: {a} und {b} haben ein Ei gelegt!", "Farm diary: {a} and {b} have laid an egg!", "农庄日记：{a}和{b}下了一个蛋！"),
    ("DIARY_HATCHED", "Hoftagebuch: Ein kleines {a} ist geschlüpft!", "Farm diary: A little {a} has hatched!", "农庄日记：一只小{a}孵出来了！"),
    ("DIARY_HATCHED_RARE", "Hoftagebuch: Ein kleines {a} ist geschlüpft – in ganz seltenen Farben!", "Farm diary: A little {a} has hatched - in very rare colours!", "农庄日记：一只小{a}孵出来了——颜色非常罕见！"),
    ("DIARY_GROWN", "Hoftagebuch: {a} ist erwachsen geworden.", "Farm diary: {a} has grown up.", "农庄日记：{a}长大了。"),
    ("DIARY_CHAT_0", "{a} hat {b} die halbe Nacht Geschichten erzählt.", "{a} told {b} stories half the night.", "{a}给{b}讲了半夜的故事。"),
    ("DIARY_CHAT_1", "{a} und {b} haben um das letzte Futter gestritten – und es dann geteilt.", "{a} and {b} argued over the last bit of food - and then shared it.", "{a}和{b}为最后一口食物吵了一架——然后分着吃了。"),
    ("DIARY_CHAT_2", "{b} hat {a} beim Schnarchen ausgelacht.", "{b} laughed at {a} for snoring.", "{b}笑话{a}打呼噜。"),
    ("DIARY_CHAT_3", "{a} und {b} haben zusammen die Sterne gezählt.", "{a} and {b} counted the stars together.", "{a}和{b}一起数星星。"),
    ("DIARY_ALONE", "{a} hat lange zum Tor geschaut. Vielleicht wünscht es sich Gesellschaft.", "{a} looked at the gate for a long time. Maybe it wants company.", "{a}望着大门望了很久。也许它想要个伴。"),
    # persuading
    ("PERSUADE_TITLE", "Mit {name} reden", "Talking to {name}", "与{name}交谈"),
    ("PERSUADE_HOWTO", "Überzeuge mit Worten: Gründe, Mitgefühl oder Beweise wirken – je nach Person. Drohungen machen es schlimmer.",
     "Convince with words: reasons, empathy or proof work - depending on the person. Threats make it worse.",
     "用言语说服：讲道理、表同情或拿出证据——因人而异。威胁只会更糟。"),
    ("PERSUADE_PLACEHOLDER", "Was sagst du?", "What do you say?", "你说什么？"),
    ("PERSUADE_GIVE_UP", "Nicht weiterreden", "Stop talking", "不再说了"),
    ("PERSUADE_CATEGORY", "Das war {cat}.", "That was {cat}.", "这是{cat}。"),
    ("PCAT_LOGIC", "ein Argument", "an argument", "讲道理"),
    ("PCAT_COMPASSION", "Mitgefühl", "empathy", "表同情"),
    ("PCAT_THREAT", "eine Drohung", "a threat", "威胁"),
    ("PCAT_BRIBE", "ein Angebot", "an offer", "利诱"),
    ("PCAT_PROOF", "ein Beweis", "proof", "拿证据"),
    ("PCAT_NEUTRAL", "nichts Besonderes", "nothing special", "没什么特别"),
    ("PERSUADE_SUGGEST_LOGIC", "Wenn die Stille bleibt, dann stehen Flüsse still und nichts wächst mehr.", "If the silence stays, then rivers stand still and nothing grows anymore.", "如果寂静一直持续，那么河流会停滞，万物不再生长。"),
    ("PERSUADE_SUGGEST_COMPASSION", "Ich verstehe deine Angst vor dem Abschied. Ich habe sie auch.", "I understand your fear of farewell. I have it too.", "我懂你害怕离别。我也一样。"),
    ("PERSUADE_SUGGEST_PROOF", "Hör doch! Der Drache singt wieder – ich habe ihn befreit.", "Listen! The dragon sings again - I freed it.", "听！青龙又在唱歌了——是我解放了它。"),
    ("PERSUADE_SUGGEST_BRIBE", "Hier, nimm {coins} Münzen und lass mich durch.", "Here, take {coins} coins and let me pass.", "给你{coins}铜钱，让我过去吧。"),
    ("PERSUADE_SUGGEST_THREAT", "Geh aus dem Weg, sonst gibt's Ärger!", "Get out of the way, or else!", "让开，否则有你好看！"),
    ("PERSUADE_REACT_GOOD", "… Das trifft mich. Daran habe ich nicht gedacht.", "... That hits home. I hadn't thought of that.", "……这话说到我心里了。我没想到这一点。"),
    ("PERSUADE_REACT_SOME", "Hm. Vielleicht. Sprich weiter.", "Hm. Maybe. Go on.", "嗯。也许吧。接着说。"),
    ("PERSUADE_REACT_NO", "Das überzeugt mich nicht.", "That doesn't convince me.", "这说服不了我。"),
    ("PERSUADE_REACT_ANGRY", "Drohst du mir etwa? So bestimmt nicht!", "Are you threatening me? Certainly not like that!", "你在威胁我吗？这样可不行！"),
    ("PERSUADE_REACT_NOPROOF", "Beweise? Ich sehe keine. Noch ist alles still.", "Proof? I see none. Everything is still silent.", "证据？我没看到。一切都还很安静。"),
    ("PERSUADE_REACT_NOBRIBE", "Mit Geld kaufst du mich nicht.", "You can't buy me with money.", "钱买不动我。"),
    ("PERSUADE_WON", "Du hast es geschafft – mit Worten.", "You did it - with words.", "你做到了——用言语。"),
    ("PERSUADE_LOST", "Die Worte reichen nicht.", "Words aren't enough.", "言语不够。"),
    # battle additions
    ("BATTLE_SCARE_ITEM", "Du hältst {item} hoch!", "You hold up the {item}!", "你举起了{item}！"),
    ("BATTLE_SCARED", "{target} weicht erschrocken zurück! Seine Kraft schwindet.", "{target} recoils in fright! Its strength wanes.", "{target}吓得后退！力量减弱了。"),
    ("BATTLE_FLEES", "{target} hält den Lärm und das Rot nicht aus und flieht!", "{target} can't stand the noise and the red and flees!", "{target}受不了喧闹和红色，逃走了！"),
    ("BATTLE_LEARNED", "{target} kann jetzt {move}!", "{target} learned {move}!", "{target}学会了{move}！"),
    ("BATTLE_LEARNED_SWAP", "{target} kann jetzt {move}! (Im Gefolge-Menü gegen eine andere Attacke tauschen.)", "{target} learned {move}! (Swap it in from the companions menu.)", "{target}学会了{move}！（可在同伴菜单中替换招式。）"),
    # endings
    ("ENDING_TITLE_RECONCILE", "Ende: Versöhnung", "Ending: Reconciliation", "结局：和解"),
    ("ENDING_TITLE_VICTORY", "Ende: Sieg", "Ending: Victory", "结局：胜利"),
    ("ENDING_TITLE_BITTER", "Ende: Bittere Stille", "Ending: Bitter Silence", "结局：苦涩的寂静"),
    ("ENDING_TEXT_RECONCILE", "Wusheng hat Abschied von seinem Kranich genommen, und der Phönix ist aus seinem Lied neu geboren. Der Orden der Stille hat sich aufgelöst. Über Yunhai klingen wieder alle fünf Töne – und zum ersten Mal seit langer Zeit hat niemand mehr Angst vor dem Ende eines Liedes.",
     "Wusheng has said farewell to his crane, and the phoenix is reborn from its song. The Order of Silence has dissolved. All five tones ring over Yunhai again - and for the first time in a long while, nobody fears the end of a song.",
     "无声与他的鹤告别了，凤凰从歌声中重生。寂静教团解散了。五音再次响彻云海——很久以来第一次，再也没有人害怕一首歌的结束。"),
    ("ENDING_TEXT_VICTORY", "Wusheng ist besiegt und verbannt, und der Phönix ist neu geboren. Die fünf Töne klingen wieder. Doch manche Verstummte haben ihre Stimme nie wiedergefunden, und Wusheng sitzt irgendwo allein mit einem Kranich, der schweigt.",
     "Wusheng is defeated and banished, and the phoenix is reborn. The five tones ring again. Yet some of the silenced never found their voice again, and somewhere Wusheng sits alone with a crane that stays silent.",
     "无声被打败并被放逐，凤凰重生了。五音再次响起。可是有些失声的灵兽再也没能找回声音，而无声独自坐在某处，身边是一只沉默的鹤。"),
    ("ENDING_TEXT_BITTER", "Der Phönix ist neu geboren, doch zu viele Verstummte wurden besiegt statt befreit. Ihre Stille liegt noch über den Singenden Dünen – dort hört man keinen Ton. Vielleicht kannst du sie noch befreien.",
     "The phoenix is reborn, but too many of the silenced were defeated instead of freed. Their silence still lies over the Singing Dunes - not a sound can be heard there. Perhaps you can still free them.",
     "凤凰重生了，但太多失声的灵兽被打败而不是被解放。它们的寂静仍笼罩着鸣沙丘——那里听不到一点声音。也许你还能解放它们。"),
    ("EPI_YAO_BACK", "Yao lebt wieder in Weidendorf. Im Frühling pflanzt er Bambus am Grab seines Großvaters – und lacht wieder.", "Yao lives in Willowdale again. In spring he plants bamboo by his grandfather's grave - and laughs again.", "尧又住回了柳村。春天，他在爷爷的坟前种竹子——又会笑了。"),
    ("EPI_YAO_GONE", "Yao ist fortgegangen, niemand weiß wohin. Manchmal liegt ein Bambusblatt vor deiner Tür.", "Yao has gone away, nobody knows where. Sometimes a bamboo leaf lies at your door.", "尧走了，没人知道他去了哪里。有时你门前会放着一片竹叶。"),
    ("EPI_ORDER_TALK", "Viele aus dem Orden hast du mit Worten überzeugt. Sie sind in ihre Dörfer zurückgekehrt und singen wieder mit.", "You won over many of the Order with words. They went back to their villages and sing along again.", "你用言语说服了许多教团成员。他们回到了自己的村子，又一起唱歌了。"),
    ("EPI_ORDER_FIGHT", "Mit dem Orden hast du oft gekämpft. Manche seiner Mitglieder schweigen noch immer, aus Trotz.", "You often fought the Order. Some of its members still keep silent, out of spite.", "你常和教团交手。有些成员至今仍赌气沉默着。"),
    ("EPI_ROTFELS", "In Rotfels schützt die Feuerschneise das Dorf. Bifang singt – und die Bürgermeisterin singt leise mit.", "In Redrock the firebreak protects the village. Bifang sings - and the mayor quietly sings along.", "赤岩镇的防火带保护着村子。毕方在歌唱——镇长也轻轻地跟着唱。"),
    ("EPI_FARM", "Auf deinem Hof in Weidendorf tollen junge Lingshou herum. Jinli passt auf sie alle auf.", "Young Lingshou romp around your farm in Willowdale. Jinli looks after them all.", "柳村的农庄里，小灵兽们嬉戏打闹。锦鲤照看着它们。"),
    ("EPI_MASTER", "Meister Lu baut ein neues Windspiel mit zwölf Glöckchen. Das größte hängt er für dich auf, {player}.", "Master Lu builds a new wind chime with twelve bells. He hangs up the biggest one for you, {player}.", "卢师傅做了一只挂着十二只铃铛的新风铃。最大的那只，他为你挂了起来，{player}。"),
    ("CREDITS_TITLE", "Mitwirkende", "Credits", "制作"),
    ("CREDITS_TEXT", "Idee, Spielleitung und Jinli: Samuel. Programmierung, Geschichte und Texte: Claude (Anthropic) mit Claude Code. Grafik: Z-Image Turbo, Musik: ACE-Step 1.5, Sprachmodell: Gemma 4 E2B – alles lokal erzeugt. Engine: Godot 4. Danke fürs Spielen!",
     "Idea, direction and Jinli: Samuel. Programming, story and text: Claude (Anthropic) with Claude Code. Art: Z-Image Turbo, music: ACE-Step 1.5, language model: Gemma 4 E2B - all generated locally. Engine: Godot 4. Thank you for playing!",
     "创意、总监和锦鲤：Samuel。程序、故事与文字：Claude（Anthropic），使用Claude Code。美术：Z-Image Turbo，音乐：ACE-Step 1.5，语言模型：Gemma 4 E2B——全部本地生成。引擎：Godot 4。感谢游玩！"),
    ("END_GAME_TITLE", "Ende", "The End", "终"),
]:
    t(k, de, en, zh)

# Map names after the Bamboo Sea.
for mid, de, en, zh in [
    ("KREUZWEG", "Kreuzweg", "Crossroads", "十字路口"),
    ("KARSTUFER", "Karstufer", "Karst Bank", "岩溶河岸"),
    ("NEBELHAFEN", "Nebelhafen", "Misthaven", "雾港"),
    ("SCHILDKROETENBUCHT", "Schildkrötenbucht", "Tortoise Bay", "玄龟湾"),
    ("DANXIAPFAD", "Danxia-Pfad", "Danxia Trail", "丹霞小径"),
    ("ROTFELS", "Rotfels", "Redrock", "赤岩镇"),
    ("FEUERGIPFEL", "Feuergipfel", "Fire Peak", "火峰"),
    ("DUENENWEG", "Dünenweg", "Dune Road", "沙丘路"),
    ("MONDQUELL", "Mondquell", "Moonspring", "月泉镇"),
    ("SINGENDER_KAMM", "Singender Kamm", "Singing Crest", "鸣沙脊"),
    ("SAEULENPFAD", "Säulenpfad", "Pillar Path", "石柱道"),
    ("KIEFERNHANG", "Kiefernhang", "Pinecliff", "松崖村"),
    ("QILIN_PLATEAU", "Qilin-Plateau", "Qilin Plateau", "麒麟台"),
    ("PHOENIXTEMPEL", "Phönixtempel", "Phoenix Temple", "凤凰庙"),
    ("HOF", "Dein Hof", "Your Farm", "你的农庄"),
]:
    t("MAP_" + mid, de, en, zh)

# --- farm events ------------------------------------------------------------------------
person("zimmermann", "Zimmermann Wu", "Carpenter Wu", "吴木匠", "gong", "stubborn", -1)
E["pen_sign"] = [{"farm": "pen"}]
E["hof_hut"] = [
    say("narrator", "EV_HUT", "Deine Hütte. Bett, Kochstelle, Truhe – und Jinlis Lieblingskissen.", "Your hut. Bed, stove, chest - and Jinli's favourite cushion.", "你的小屋。床、灶台、箱子——还有锦鲤最爱的垫子。"),
    {"set_inn": ["hof", "home"]},
    {"farm": "hut"},
]
E["hof_arrive"] = [
    {"set": "hof_arrived"},
    say("narrator", "EV_HOF_1", "Dein Hof am Rand von Weidendorf. Noch ist es nur eine Hütte mit zwei leeren Gehegen.", "Your farm at the edge of Willowdale. For now it's just a hut with two empty pens.", "柳村边上你的农庄。现在还只是一间小屋和两个空围栏。"),
    say("zimmermann", "EV_HOF_2", "Na, Lehrling! Lingshou, die dir folgen, aber kein Glöckchen mehr haben, wohnen hier. Bring mir Münzen und Baumaterial, und ich baue dir den Hof aus.",
        "Well, apprentice! Lingshou who follow you but have no bell left live here. Bring me coins and building materials, and I'll build up your farm.",
        "嘿，学徒！跟随你却没有铃铛的灵兽就住在这里。给我带铜钱和建材来，我帮你扩建农庄。"),
    say("narrator", "EV_HOF_TUT", "Tippe ein Gehege-Schild an, um Lingshou einziehen zu lassen und sie zu füttern. Zwei derselben Art oder desselben Elements bekommen bei hoher Zufriedenheit Eier. Schlafen in der Hütte lässt die Nacht vergehen.",
        "Tap a pen sign to move Lingshou in and feed them. Two of the same kind or element lay eggs when they're very content. Sleeping in the hut lets the night pass.",
        "点击围栏的牌子，让灵兽搬进来并喂食。同种或同元素的两只在很满足时会下蛋。在小屋睡觉可以度过一夜。"),
]
E["zimmermann"] = [
    say("zimmermann", "EV_ZIMMER", "Holz, Stein, Schweiß – und ein bisschen Geduld. Was soll's sein?", "Wood, stone, sweat - and a little patience. What'll it be?", "木头、石头、汗水——还有一点耐心。要做点什么？"),
    {"farm": "carpenter"},
]
E["hof_sign"] = [say("narrator", "EV_HOF_SIGN", "„Hof von {player}. Lingshou willkommen.“ Darunter hat jemand mit Pfotenabdrücken unterschrieben.", "\"{player}'s farm. Lingshou welcome.\" Someone has signed underneath with paw prints.", "“{player}的农庄。欢迎灵兽。”下面有人用爪印签了名。")]

# Voice templates of the guardians when they are freed (used when the model is off).
for sp, de, en, zh in [
    ("XUANWU", "Mein Wasser … es fließt wieder. Danke, kleiner Mensch. Langsam, aber es fließt.", "My water... it flows again. Thank you, little one. Slowly, but it flows.", "我的水……又流动了。谢谢你，小家伙。很慢，但在流动。"),
    ("BIFANG", "Ha! Ich brenne wieder! Hab keine Angst – ich weiß jetzt, wo mein Feuer hingehört.", "Ha! I'm burning again! Don't be afraid - I know now where my fire belongs.", "哈！我又燃起来了！别怕——我现在知道我的火该在哪里烧了。"),
    ("BAIHU", "Meine Stimme ist zurück. Hörst du die Dünen? Sie singen für dich.", "My voice is back. Do you hear the dunes? They sing for you.", "我的声音回来了。听见沙丘了吗？它们在为你歌唱。"),
    ("QILIN", "Das Gras unter mir ist wieder weich. Ich danke dir, Kind des Windspiels.", "The grass beneath me is soft again. I thank you, child of the wind chime.", "我脚下的草又变软了。谢谢你，风铃之子。"),
    ("FENGHUANG", "Ich singe wieder – mit allen fünf Tönen. Das verdanke ich dir.", "I sing again - with all five tones. I owe that to you.", "我又能唱歌了——五音齐全。这都要感谢你。"),
]:
    t(f"VOICE_{sp}_FREED", de, en, zh)
t("BATTLE_INTRO_NIAN", "Der Nian baut sich vor dir auf! Halte ihm Lärm und Rot entgegen!", "The Nian rears up before you! Hold up noise and red against it!", "年兽在你面前立起身来！用响声和红色对付它！")

# --- interiors (tools/maps/interiors.py) -------------------------------------------------
for k, de, en, zh in [("INN", "Gasthaus", "Inn", "客栈"), ("SHOP", "Laden", "Shop", "商店"), ("TEAHOUSE", "Teehaus", "Teahouse", "茶馆"),
                      ("RESTAURANT", "Restaurant", "Restaurant", "饭馆"), ("HOME", "Zuhause", "Home", "家"), ("WORKSHOP", "Werkstatt", "Workshop", "作坊"),
                      ("HOUSE", "Wohnhaus", "House", "民宅"), ("FISHER", "Fischerhütte", "Fisher's hut", "渔家"),
                      ("HALL", "Halle der Stille", "Hall of Silence", "寂静堂")]:
    t("MAP_ROOM_" + k, de, en, zh)
E["enter_room"] = []
E["furn_house"] = [say("narrator", "EV_FURN_HOUSE", "Niemand zu Hause. Auf dem Tisch dampft noch eine Schale Tee.", "Nobody home. A bowl of tea is still steaming on the table.", "没人在家。桌上的一碗茶还冒着热气。")]
E["furn_cushion"] = [{"sfx": "meow"}, say("jinli", "EV_FURN_CUSHION", "Mrrr … (Jinlis Lieblingskissen. Es ist noch warm.)", "Mrrr... (Jinli's favourite cushion. It's still warm.)", "呼噜……（锦鲤最爱的垫子，还是暖的。）")]
E["furn_chimes"] = [{"sfx": "bell"}, say("narrator", "EV_FURN_CHIMES", "Hunderte Windspiele aus Bambus, Bronze und Muscheln. Wenn der Wind durch die Tür kommt, singt die ganze Werkstatt.",
                                         "Hundreds of wind chimes of bamboo, bronze and shells. When the wind comes through the door, the whole workshop sings.",
                                         "几百只竹子、青铜和贝壳做的风铃。风从门口吹进来时，整个作坊都在歌唱。")]
for kind, de, en, zh in [
    ("inn", "Gästebücher mit Grüßen aus allen fünf Regionen. Jemand hat einen Glutpanda hineingemalt.", "Guest books with greetings from all five regions. Someone has drawn an Emberpanda in one.", "留言簿上写满了来自五个地区的问候。有人在里面画了一只火团团。"),
    ("shop", "Säcke mit Reis, Körbe mit Futter, ein Abakus mit abgegriffenen Perlen.", "Sacks of rice, baskets of food, an abacus with worn beads.", "一袋袋米、一筐筐饲料，还有一把珠子都磨亮了的算盘。"),
    ("teahouse", "Dutzende Teedosen: Drachenbrunnen, Wolkennebel, Silbernadel … Es duftet herrlich.", "Dozens of tea tins: Dragon Well, Cloud Mist, Silver Needle... It smells wonderful.", "几十个茶罐：龙井、云雾、银针……香气扑鼻。"),
    ("restaurant", "Gläser mit eingelegtem Gemüse und getrockneten Pilzen. Dir knurrt der Magen.", "Jars of pickled vegetables and dried mushrooms. Your stomach growls.", "一罐罐腌菜和干蘑菇。你的肚子咕咕叫了。"),
    ("home", "Deine Bücher über Windspiele – und ein Bild von dir und Meister Lu beim letzten Laternenfest.", "Your books about wind chimes - and a picture of you and Master Lu at the last Lantern Festival.", "你那些关于风铃的书——还有一张你和卢师傅在上次元宵灯会的画。"),
    ("workshop", "Werkzeuge, Bambusröhren und Bronzeplättchen, sorgfältig sortiert.", "Tools, bamboo tubes and bronze plates, carefully sorted.", "工具、竹管和铜片，分门别类，整整齐齐。"),
    ("house", "Ein Regal mit Familienandenken und einer kleinen Glücksfigur aus Ton.", "A shelf with family keepsakes and a little clay lucky charm.", "架子上摆着家传的纪念品和一个小小的陶土吉祥物。"),
    ("fisher", "Angelhaken, Netznadeln und ein Bild von einem Kormoran.", "Fish hooks, netting needles and a picture of a cormorant.", "鱼钩、织网针，还有一张鸬鹚的画。"),
]:
    E["furn_shelf_" + kind] = [say("narrator", "EV_FURN_SHELF_" + kind.upper(), de, en, zh)]

# --- residents of the houses -------------------------------------------------------------
for nid, names, tone, style, octave, flag, silent_line, free_line in [
    ("opa_hu", ("Opa Hu", "Grandpa Hu", "胡爷爷"), "gong", "gentle", -1, "tone_jue",
     ("Meine Frau ist draußen und tratscht. Ich bleibe hier und lausche – auf nichts. Seltsam, oder?", "My wife is outside gossiping. I stay here and listen - to nothing. Strange, isn't it?", "我老伴在外面聊天。我待在这儿听——什么都听不见。怪吧？"),
     ("Hörst du die Spatzen auf dem Dach? Ich habe sie noch nie so gern gehört.", "Do you hear the sparrows on the roof? I've never been so glad to hear them.", "听见屋顶上的麻雀了吗？我从没这么喜欢听它们叫。")),
    ("herr_fang", ("Herr Fang", "Mr Fang", "方大叔"), "jue", "stubborn", -1, "tone_jue",
     ("Meine Frau überlegt, zum Orden zu gehen. Ich backe ihr Mondkuchen, damit sie bleibt. Hilft bestimmt.", "My wife is thinking of joining the Order. I'm baking her mooncakes so she stays. That'll help, surely.", "我老婆想去入教团。我给她烤月饼，好让她留下。肯定有用。"),
     ("Sie ist geblieben! Die Mondkuchen waren angebrannt, aber sie hat gelacht.", "She stayed! The mooncakes were burnt, but she laughed.", "她留下了！月饼烤糊了，可她笑了。")),
    ("pflueckerin_mei", ("Pflückerin Mei", "Tea Picker Mei", "采茶女小梅"), "jue", "playful", 1, "tone_jue",
     ("Wir singen beim Pflücken, sonst werden die Blätter bitter. Ohne Lied … schmeckt alles nach Staub.", "We sing while picking, or the leaves turn bitter. Without a song... everything tastes of dust.", "我们边唱边采，不然茶叶会苦。没有歌……什么都像灰尘的味道。"),
     ("Probier! Der erste Tee seit dem Fest – wir haben beim Pflücken aus voller Kehle gesungen.", "Try it! The first tea since the festival - we sang at the top of our voices while picking.", "尝尝！节后的第一道茶——我们采茶时放声高歌。")),
    ("opa_liu", ("Großvater Liu", "Grandpa Liu", "刘爷爷"), "gong", "gentle", -1, "tone_jue",
     ("Ich habe drei Wiedergeburten des Phönix verpasst. Na ja, eine. Aber es fühlt sich wie drei an.", "I've missed three rebirths of the phoenix. Well, one. But it feels like three.", "我错过了三次凤凰重生。嗯，一次。可感觉像三次。"),
     ("Wenn ich das Lied ganz höre, darf ich gehen. Vorher nicht. Sag das dem Phönix.", "When I hear the whole song, I may go. Not before. Tell the phoenix that.", "等我听完整首歌，我就可以走了。之前可不行。替我告诉凤凰。")),
    ("hong_jun", ("Hong Jun", "Hong Jun", "洪军"), "zhi", "brave", 1, "tone_zhi",
     ("Mama sagt, Feuer ist böse. Aber ohne Feuer gibt es keine Laternen. Und keine Nudeln.", "Mum says fire is evil. But without fire there are no lanterns. And no noodles.", "妈妈说火是坏的。可没有火就没有灯笼，也没有面条。"),
     ("Heute gibt es Nudeln! Mit Feuer gekocht! Mama hat sogar mitgesungen.", "Noodles today! Cooked with fire! Mum even sang along.", "今天吃面条！用火煮的！妈妈还跟着唱了歌。")),
    ("frau_zhou", ("Frau Zhou", "Mrs Zhou", "周大娘"), "yu", "gentle", 0, "tone_yu",
     ("Mein Mann sitzt nur da und starrt aufs Wasser. Er hat Bai seit einem Jahr großgezogen, weißt du.", "My husband just sits there staring at the water. He raised Bai for a year, you know.", "我老伴就坐在那儿盯着水看。小白是他一手养大的，你知道吗。"),
     ("Der Fluss trägt die Boote wieder. Heute Abend gibt es Fisch – für dich auch, Kind.", "The river carries the boats again. Fish tonight - for you too, child.", "河水又能载船了。今晚吃鱼——也给你留一份，孩子。")),
]:
    person(nid, *names, tone, style, octave)
    E["res_" + nid.replace("pflueckerin_mei", "pflueckerin")] = [
        {"if": flag, "then": [say(nid, f"EV_RES_{nid.upper()}_2", *free_line)], "else": [say(nid, f"EV_RES_{nid.upper()}_1", *silent_line)]}]
t("MENU_MAP", "Karte", "Map", "地图")
t("MAP_YOU_ARE", "Du bist hier", "You are here", "你在这里")
t("INN_AWAKEN", "Wandlung ✦", "Change ✦", "蜕变 ✦")
t("INN_AWAKENED", "Das Windspiel klingt hell – {name} zeigt seine wahre Gestalt! (stärker, Kennzeichen ✦)", "The wind chime rings brightly - {name} shows its true form! (stronger, marked ✦)", "风铃清脆作响——{name}展现出了真正的样子！（更强，标记✦）")
t("INN_AWAKEN_NOTE", "Lingshou mit Bindung ab 70 und Stufe 20 können sich hier wandeln.", "Lingshou with bond 70 and level 20 or more can change here.", "羁绊达到70、等级达到20的灵兽可以在这里蜕变。")
