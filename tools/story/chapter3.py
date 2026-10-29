"""Act 3: Master Lu speaks again, the Nian attacks Willowdale, the Order of
Silence shows itself (Yao joins it); then the Singing Dunes (metal, Shang,
White Tiger Baihu, the Hall of Silence) and the Cloud Pillars (earth, Gong,
Qilin), in any order. Part of tools/story/build.py."""
from common import *

E = {}

person("meister_free", "Meister Lu", "Master Lu", "卢师傅", "gong", "gentle", -1)
person("nian", "Nian", "Nian", "年兽", "gong", "moody", -2)
person("kind_nian", "Kleiner Bo", "Little Bo", "小波", "jue", "playful", 1)
person("oma_nian", "Oma Hu", "Granny Hu", "胡奶奶", "gong", "gentle", 0)
person("order_ying", "Ordensmeisterin Ying", "Grand Mistress Ying", "莹大师", "shang", "gentle", -1)
person("yao_order", "Yao", "Yao", "尧", "zhi", "brave", 0)
person("karawane", "Karawanenführer Batu", "Caravan Leader Batu", "巴图", "gong", "gentle", -1)
person("ordensmeisterin", "Ordensschwester Lu", "Sister Lu", "露师姐", "shang", "gentle", 0)
person("quell_haendlerin", "Händlerin Gul", "Merchant Gul", "古丽", "zhi", "playful", 0)
person("quell_kind", "Ayla", "Ayla", "艾拉", "jue", "playful", 1)
person("yao_free", "Yao", "Yao", "尧", "zhi", "brave", 0)
person("order_kamm", "Bruder Shi", "Brother Shi", "石师兄", "shang", "stubborn", 0)
person("karawanenaelteste", "Älteste Saule", "Elder Saule", "萨乌勒长老", "gong", "gentle", -1)
person("baihu", "Baihu", "Baihu", "白虎", "shang", "brave", -1)
person("baihu_free", "Baihu", "Baihu", "白虎", "shang", "brave", -1)
person("kiefer_aelteste", "Ältester Song", "Elder Song", "宋长老", "gong", "gentle", -1)
person("kiefer_kind", "Shan Shan", "Shan Shan", "珊珊", "jue", "playful", 1)
person("kiefer_frau", "Kräuterfrau Yue", "Herbalist Yue", "月药婆", "yu", "gentle", 0)
person("order_plateau", "Schwester Lan", "Sister Lan", "岚师姐", "shang", "gentle", 0)
person("eremitin", "Eremitin Qing", "Hermit Qing", "青隐士", "gong", "gentle", -1)
person("qilin", "Qilin", "Qilin", "麒麟", "gong", "gentle", -1)
person("qilin_free", "Qilin", "Qilin", "麒麟", "gong", "gentle", -1)

# --- Weidendorf: the Master's voice and the Nian ---------------------------------------------
E["meister_voice"] = [
    {"set": "meister_spoke"},
    {"refresh": True},
    {"music": "village"},
    {"teleport": [15, 7]},
    say("narrator", "EV_MV_1", "Vor der Werkstatt steht Meister Lu. Als er dich sieht, öffnet er den Mund – und diesmal kommt ein Laut heraus.", "Master Lu stands in front of the workshop. When he sees you, he opens his mouth - and this time a sound comes out.", "卢师傅站在作坊门前。看见你的时候，他张开嘴——这一次，发出了声音。"),
    say("meister_free", "EV_MV_2", "{player}! Ich … ich kann wieder sprechen! Drei Töne – ich habe jeden einzelnen gespürt, wie Wind in meinen Windspielen.",
        "{player}! I... I can speak again! Three tones - I felt every single one, like wind in my chimes.",
        "{player}！我……我又能说话了！三个音——每一个我都感觉到了，就像风吹过我的风铃。"),
    say("meister_free", "EV_MV_3", "Hör zu. Während du fort warst, kamen Leute in Grau ins Dorf. Der Orden der Stille. Sie sagen, ohne Wandel gibt es keinen Schmerz. Frau Fang hört ihnen zu … und nicht nur sie.",
        "Listen. While you were away, people in grey came to the village. The Order of Silence. They say without change there is no pain. Mrs Fang listens to them... and not only her.",
        "听着。你不在的时候，有些穿灰衣的人来过村子。寂静教团。他们说，没有变化就没有痛苦。方大婶听进去了……不只是她。"),
    {"time": 22},
    {"music": ""},
    {"fade": "out", "seconds": 0.6},
    {"set": "nian_here"},
    {"refresh": True},
    {"fade": "in", "seconds": 1.0},
    {"sfx": "fail"},
    say("narrator", "EV_MV_4", "Plötzlich ist es Nacht. Die Laternen flackern und gehen aus, eine nach der anderen. Auf dem Festplatz hockt etwas Großes, Zotteliges.",
        "Suddenly it is night. The lanterns flicker and go out, one after another. Something big and shaggy crouches on the festival square.",
        "突然间入夜了。灯笼一盏接一盏地闪烁、熄灭。节日广场上蹲着一个巨大、毛茸茸的东西。"),
    {"music": "nian"},
    say("nian", "EV_MV_5", "Grrr … so still. So köstlich still. Hier schmeckt die Stille am besten.", "Grrr... so quiet. So deliciously quiet. Silence tastes best here.", "呼……好安静。安静得真美味。这里的寂静最好吃了。"),
    say("meister_free", "EV_MV_6", "Der Nian! Er wird in der Stille immer stärker. Mit Kraft allein besiegst du ihn nicht – er fürchtet Lärm und die Farbe Rot! Trommeln, Feuerwerk, rote Banner!",
        "The Nian! It grows ever stronger in the silence. You can't beat it with strength alone - it fears noise and the colour red! Drums, firecrackers, red banners!",
        "是年兽！它在寂静中越来越强。光靠力气打不过它——它怕响声和红色！鼓、鞭炮、红幡！"),
    say("meister_free", "EV_MV_7", "Hier, das Feuerwerk vom Laternenfest – es lag die ganze Zeit in der Werkstatt. Kleiner Bo hat seine Trommel, und Oma Hu näht dir ein Banner aus den Festbändern. Schnell!",
        "Here, the firecrackers from the Lantern Festival - they've been in the workshop all along. Little Bo has his drum, and Granny Hu will sew you a banner from the festival ribbons. Quickly!",
        "给，元宵灯会剩下的鞭炮——一直放在作坊里。小波有他的鼓，胡奶奶会用节日的红丝带给你缝一面幡。快！"),
    {"give_item": "feuerwerk", "n": 1},
    quest("QUEST_NIAN", "Der Nian ist in Weidendorf! Hol Bos Trommel und Oma Hus rotes Banner, dann stell dich ihm auf dem Festplatz.",
          "The Nian is in Willowdale! Get Bo's drum and Granny Hu's red banner, then face it on the festival square.",
          "年兽来柳村了！拿到小波的鼓和胡奶奶的红幡，然后在节日广场上对付它。"),
    {"goal": ["weidendorf", 13, 13]},
    {"save": True},
]
hints("NIAN", ["Miau! (Jinli faucht in Richtung Festplatz.)", "Miau, miau! (Bo spielt unten am Platz, Oma Hu wohnt rechts.)", "Miaaau! (Trommel von Bo unten am Festplatz, Banner von Oma Hu rechts am Dorfrand. Dann zum Nian in der Mitte!)"],
      ["Mew! (Jinli hisses towards the festival square.)", "Mew, mew! (Bo is at the bottom of the square, Granny Hu lives on the right.)", "Meeew! (Drum from Bo at the bottom of the square, banner from Granny Hu at the right edge of the village. Then to the Nian in the middle!)"],
      ["喵！（锦鲤冲着节日广场哈气。）", "喵喵！（小波在广场下面，胡奶奶住在右边。）", "喵——！（广场下面找小波要鼓，村子右边找胡奶奶要幡。然后去中间对付年兽！）"])
E["kind_nian"] = [
    {"if_item": "trommel", "then": [say("kind_nian", "EV_BO_N2", "Hau drauf! Bumm-bumm!", "Hit it! Boom-boom!", "使劲敲！咚咚！")],
     "else": [say("kind_nian", "EV_BO_N1", "Meine Trommel klingt wieder! Seit der Drache singt! Hier, nimm sie – hau dem Nian was auf die Ohren!", "My drum sounds again! Ever since the dragon sings! Here, take it - give the Nian an earful!", "我的鼓又能响了！自从青龙唱歌以后！给你——敲得年兽耳朵嗡嗡响！"),
              {"give_item": "trommel", "n": 1}]},
]
E["oma_nian"] = [
    {"if_item": "rotes_banner", "then": [say("oma_nian", "EV_HU_N2", "Rot wie Glück, Kind. Halt es hoch!", "Red like luck, child. Hold it high!", "红色代表好运，孩子。举高点！")],
     "else": [say("oma_nian", "EV_HU_N1", "Schon fertig! Aus allen roten Bändern vom Festbaum. Meine Großmutter hat den Nian so vertrieben – und ihre Großmutter auch.", "Already done! From all the red ribbons on the festival tree. My grandmother drove the Nian off this way - and her grandmother too.", "已经缝好了！用节日树上所有的红丝带缝的。我奶奶就是这样赶走年兽的——她奶奶也是。"),
              {"give_item": "rotes_banner", "n": 1}]},
]
E["nian_battle"] = [
    {"if_items": ["trommel", 1], "then": [], "else": [
        say("jinli", "EV_NB_WARN", "Miau! (Jinli zerrt an deinem Ärmel. Ohne Trommel und Banner ist das gefährlich!)", "Mew! (Jinli tugs at your sleeve. Without drum and banner this is dangerous!)", "喵！（锦鲤拽着你的袖子。没有鼓和幡太危险了！）")]},
    say("nian", "EV_NB_1", "Noch mehr Klang? Ich fresse ihn!", "More sound? I'll eat it!", "还有声音？我要吃掉它！"),
    say("narrator", "EV_NB_TUT", "Im Beutel findest du Trommel, Feuerwerk und Banner. Halte sie dem Nian entgegen – dreimal, und er flieht!", "In your bag you find the drum, firecrackers and banner. Hold them up at the Nian - three times, and it flees!", "背包里有鼓、鞭炮和红幡。对着年兽举起它们——三次，它就会逃跑！"),
    {"battle": {"enemies": [{"id": "nian", "level": 21, "scale": 1}, {"id": "schattenmotte", "level": 18, "scale": -2}], "active": 2,
                "music": "nian", "bg": "village_night", "no_join": True},
     "win": [{"run": "nian_driven_scene"}],
     "lose": [say("meister_free", "EV_NB_LOSE", "Steh auf! Der Nian ist noch da. Trommel, Feuerwerk, Banner – du schaffst das!", "Get up! The Nian is still here. Drum, firecrackers, banner - you can do it!", "起来！年兽还在。鼓、鞭炮、红幡——你能行的！")]},
]
E["nian_driven_scene"] = [
    {"set": "nian_driven"},
    {"clear": "nian_here"},
    {"refresh": True},
    {"music": "village"},
    say("narrator", "EV_ND_1", "Der Nian heult auf und flieht in die Nacht. Hinter dir beginnt jemand zu trommeln. Dann noch jemand. Bald trommelt das ganze Dorf, und die Laternen gehen wieder an.",
        "The Nian howls and flees into the night. Behind you someone starts drumming. Then someone else. Soon the whole village is drumming, and the lanterns light up again.",
        "年兽嚎叫着逃进了夜色。你身后有人开始打鼓，又一个人跟着打。很快全村都敲起了鼓，灯笼又亮了起来。"),
    say("meister_free", "EV_ND_2", "Hörst du das, {player}? Das ist Weidendorf. Laut und lebendig.", "Do you hear that, {player}? That's Willowdale. Loud and alive.", "听到了吗，{player}？这就是柳村。热闹又鲜活。"),
    {"set": "order_visit"},
    {"refresh": True},
    say("narrator", "EV_ND_3", "Doch am Rand des Platzes stehen Gestalten in Grau. Eine Frau mit ruhigem Blick tritt vor. Neben ihr – Yao, in einer grauen Kutte.",
        "But at the edge of the square stand figures in grey. A woman with a calm gaze steps forward. Next to her - Yao, in a grey robe.",
        "可广场边上站着几个灰衣人。一个目光平静的女人走上前来。她身边——是穿着灰袍的尧。"),
    say("order_ying", "EV_ND_4", "Ich bin Ying, Meisterin des Ordens der Stille. Siehst du, was der Wandel bringt? Mit den Tönen kehrt auch der Nian zurück. Jedes Jahr wird er wiederkommen.",
        "I am Ying, Mistress of the Order of Silence. Do you see what change brings? With the tones the Nian returns too. Every year it will come back.",
        "我是莹，寂静教团的大师。你看到变化带来了什么吗？五音回来了，年兽也会回来。它每年都会再来。"),
    say("yao_order", "EV_ND_5", "Sie hat recht, {player}. Jedes Lied endet. Jeder Mensch geht. Ich will das nicht mehr. Im Orden muss niemand mehr Abschied nehmen.",
        "She's right, {player}. Every song ends. Every person leaves. I don't want that anymore. In the Order nobody has to say goodbye.",
        "她说得对，{player}。每首歌都会结束，每个人都会离开。我不想再这样了。在教团里，没有人需要告别。"),
    choice([("CH_YAO_ND_A", "Yao, komm nach Hause. Wir finden einen anderen Weg.", "Yao, come home. We'll find another way.", "尧，回家吧。我们会找到别的办法。"),
            ("CH_YAO_ND_B", "Der Nian wurde in der Stille stark, Yao – nicht im Lärm.", "The Nian grew strong in the silence, Yao - not in the noise.", "年兽是在寂静中变强的，尧——不是在喧闹中。")],
           [[say("yao_order", "EV_ND_6A", "… Nach Hause. Da wartet niemand mehr auf mich.", "... Home. Nobody waits for me there anymore.", "……家。那里已经没有人等我了。")],
            [say("yao_order", "EV_ND_6B", "… Das sagst du so. Komm nach Mondquell, in die Halle der Stille. Dann reden wir.", "... Easy for you to say. Come to Moonspring, to the Hall of Silence. Then we'll talk.", "……你说得轻巧。来月泉镇的寂静堂吧。到时候再说。")]]),
    say("order_ying", "EV_ND_7", "Die Wege nach Westen und zu den Säulen stehen dir offen. Wer die Stille sucht, findet uns in den Dünen. Und der Großkanzler erwartet dich ganz oben.",
        "The roads west and to the pillars are open to you. Whoever seeks silence finds us in the dunes. And the Grand Chancellor awaits you at the very top.",
        "往西和去云柱的路都为你敞开了。寻求寂静的人会在沙丘找到我们。大司仪在最高处等你。"),
    {"fade": "out", "seconds": 0.5},
    {"set": "order_left"},
    {"refresh": True},
    {"time": 7},
    {"fade": "in", "seconds": 0.8},
    say("meister_free", "EV_ND_8", "Yao … Er war immer ein guter Junge. Bring ihn zurück, wenn du kannst. Und die letzten zwei Töne: Shang in den Dünen, Gong bei den Säulen.",
        "Yao... He was always a good boy. Bring him back if you can. And the last two tones: Shang in the dunes, Gong at the pillars.",
        "尧……他一直是个好孩子。如果可以，把他带回来。还有最后两个音：沙丘的“商”，云柱的“宫”。"),
    {"give_item": "phoenixfeder", "n": 1},
    quest("QUEST_LAST_TWO", "Zwei Töne fehlen: Shang in den Singenden Dünen (Kreuzweg, Westen) und Gong bei den Wolkensäulen (Kreuzweg, Treppe). Yao ist in der Halle der Stille in Mondquell.",
          "Two tones are missing: Shang in the Singing Dunes (Crossroads, west) and Gong at the Cloud Pillars (Crossroads, stairs). Yao is in the Hall of Silence in Moonspring.",
          "还差两个音：鸣沙丘的“商”（十字路口往西）和云柱的“宫”（十字路口的石阶）。尧在月泉镇的寂静堂。"),
    {"goal": ["kreuzweg", 17, 12]},
    {"save": True},
]
hints("LAST_TWO", ["Miau! (Jinli schaut nach Westen, dann nach oben.)", "Miau, miau! (Am Kreuzweg sind jetzt beide Wege frei.)", "Miaaau! (Kreuzweg: links zu den Dünen und nach Mondquell, die Treppe in der Mitte hinauf zu den Wolkensäulen.)"],
      ["Mew! (Jinli looks west, then up.)", "Mew, mew! (At the Crossroads both roads are open now.)", "Meeew! (Crossroads: left to the dunes and Moonspring, up the stairs in the middle to the Cloud Pillars.)"],
      ["喵！（锦鲤望望西边，又望望上方。）", "喵喵！（十字路口的两条路现在都通了。）", "喵——！（十字路口：往左去沙丘和月泉镇，从中间石阶上去是云柱。）"])
E["meister_home"] = [
    {"if": "nian_here", "then": [say("meister_free", "EV_MH_1", "Trommel, Feuerwerk, Banner! Der Nian wartet auf dem Platz.", "Drum, firecrackers, banner! The Nian waits on the square.", "鼓、鞭炮、红幡！年兽在广场上等着。")],
     "else": [{"if": "phoenix_reborn", "then": [say("meister_free", "EV_MH_3", "Zwölf Glöckchen, {player}. Ich hätte nie gedacht, dass ich das noch erlebe.", "Twelve bells, {player}. I never thought I'd live to see it.", "十二只铃铛，{player}。我从没想过这辈子还能看到。")],
               "else": [say("meister_free", "EV_MH_2", "Ruh dich zu Hause aus, wenn du müde bist. Und vergiss deinen Hof nicht – die Lingshou dort vermissen dich.", "Rest at home when you're tired. And don't forget your farm - the Lingshou there miss you.", "累了就回家歇歇。别忘了你的农庄——那里的灵兽想你了。")]}]},
]
E["order_ying_idle"] = [say("order_ying", "EV_YING_IDLE", "…", "...", "……")]

# --- Singende Dünen ---------------------------------------------------------------------
E["duenenweg_arrive"] = [
    {"set": "duenenweg_arrived"},
    say("narrator", "EV_DW_1", "Goldene Dünen bis zum Horizont. Man sagt, sie singen, wenn der Wind über sie streicht. Heute schweigen sie.", "Golden dunes to the horizon. They say they sing when the wind brushes over them. Today they are silent.", "金色的沙丘一直延伸到天边。听说风吹过时它们会歌唱。今天它们沉默着。"),
    rquest("dunes", "QUEST_DUNES_1", "Folge dem Dünenweg nach Westen bis Mondquell.", "Follow the Dune Road west to Moonspring.", "沿沙丘路往西走到月泉镇。"),
    {"goal": ["mondquell", 16, 18], "region": "dunes"},
]
hints("DUNES_1", ["Miau! (Jinli stapft durch den Sand nach Westen.)", "Miau, miau! (Immer dem Weg nach links folgen.)", "Miaaau! (Der Weg in der Mitte führt ganz links nach Mondquell.)"],
      ["Mew! (Jinli trudges west through the sand.)", "Mew, mew! (Keep following the road to the left.)", "Meeew! (The road in the middle leads to Moonspring at the far left.)"],
      ["喵！（锦鲤踩着沙子往西走。）", "喵喵！（一直沿着路往左走。）", "喵——！（中间的路一直往左就是月泉镇。）"])
E["chest_duenen"] = [say("narrator", "EV_CHEST_DUENEN", "Halb im Sand vergraben: eine Kiste mit Kupferbeschlägen.", "Half buried in the sand: a chest with copper fittings.", "半埋在沙里：一个包铜的箱子。"),
                     {"give_item": "wuestenkupfer", "n": 3}, {"give_item": "phoenixfeder", "n": 1}, {"set": "chest_duenen"}, {"refresh": True}]
E["karawane"] = [
    say("karawane", "EV_BATU", "Früher sangen die Dünen uns den Weg. Jetzt verirren sich sogar die Kamele. Datteln? Kupfer? Für den Weg, Freund.", "The dunes used to sing us the way. Now even the camels get lost. Dates? Copper? For the road, friend.", "以前沙丘会唱着给我们指路。现在连骆驼都会迷路。枣子？铜？路上用得着，朋友。"),
    {"shop": ["wuestendatteln", "wuestenkupfer", "jasmintee", "kraeutertee", "phoenixfeder"]},
]
E["mondquell_arrive"] = [
    {"set": "mondquell_arrived"},
    say("narrator", "EV_MQ_1", "Mondquell: ein Dorf um eine Quelle in Form einer Mondsichel. Die meisten Häuser sind still. Vor einer großen grauen Halle stehen Menschen in Kutten.",
        "Moonspring: a village around a spring shaped like a crescent moon. Most houses are quiet. People in robes stand in front of a large grey hall.",
        "月泉镇：一座围着新月形泉水的村子。大多数房子都静悄悄的。一座灰色大殿前站着穿袍子的人。"),
    rquest("dunes", "QUEST_DUNES_2", "Yao ist in der Halle der Stille (unten in der Mitte). Der Singende Kamm liegt oben hinter dem Dorf.", "Yao is in the Hall of Silence (bottom middle). The Singing Crest lies above, behind the village.", "尧在寂静堂（下方中间）。鸣沙脊在村子后面的上方。"),
    {"goal": ["mondquell", 21, 18], "region": "dunes"},
    {"set_inn": ["mondquell", "inn"]},
]
hints("DUNES_2", ["Miau! (Jinli schaut zur grauen Halle.)", "Miau, miau! (Die Halle der Stille ist das große graue Haus unten.)", "Miaaau! (Halle der Stille unten in der Mitte – dort ist Yao. Der Weg zum Kamm ist oben.)"],
      ["Mew! (Jinli looks at the grey hall.)", "Mew, mew! (The Hall of Silence is the big grey house below.)", "Meeew! (Hall of Silence, bottom middle - Yao is there. The way to the crest is at the top.)"],
      ["喵！（锦鲤望着灰色的大殿。）", "喵喵！（寂静堂就是下面那座灰色的大房子。）", "喵——！（下方中间的寂静堂——尧在那里。去沙脊的路在上方。）"])
E["halle_tuer"] = [
    {"if": "yao_hall_done", "then": [say("ordensmeisterin", "EV_HALL_DONE", "Die Halle ist leer geworden. Viele sind nach Hause gegangen.", "The hall has become empty. Many have gone home.", "大殿空了。很多人都回家了。")],
     "else": [
         say("ordensmeisterin", "EV_HALL_1", "Willkommen in der Halle der Stille. Hier muss niemand Abschied nehmen. Yao erwartet dich.", "Welcome to the Hall of Silence. Here nobody has to say goodbye. Yao awaits you.", "欢迎来到寂静堂。在这里，没有人需要告别。尧在等你。"),
         say("narrator", "EV_HALL_2", "In der Halle hängen hunderte Bronzeglocken. Keine klingt. In der Mitte steht Yao, die Arme verschränkt.", "Hundreds of bronze bells hang in the hall. None of them rings. Yao stands in the middle, arms crossed.", "大殿里挂着几百只铜钟，没有一只在响。尧抱着胳膊站在中间。"),
         say("yao_order", "EV_HALL_3", "Du bist also gekommen. Weißt du, warum ich hier bin? Weil hier alles bleibt. Nichts geht verloren. Niemand stirbt einfach so wie Großvater.",
             "So you came. Do you know why I'm here? Because here everything stays. Nothing gets lost. Nobody just dies like Grandfather did.",
             "你还是来了。你知道我为什么在这里吗？因为在这里，一切都不会变。什么都不会失去。没有人会像爷爷那样，说走就走。"),
         {"choice": [{"text": t("CH_HALL_A", "Dein Großvater mochte den Frühling, Yao. Er würde wollen, dass er wiederkommt.", "Your grandfather liked spring, Yao. He'd want it to come back.", "你爷爷喜欢春天，尧。他会希望春天回来的。"), "when": "yao_understood"},
                 t("CH_HALL_B", "Ich habe auch Angst vor Abschieden. Aber ich will nicht, dass alles stehen bleibt.", "I'm afraid of goodbyes too. But I don't want everything to stand still.", "我也害怕告别。但我不想让一切都停下来。"),
                 t("CH_HALL_C", "Du läufst nur weg, Yao. Feigling.", "You're just running away, Yao. Coward.", "你只是在逃避，尧。胆小鬼。")],
          "then": [[{"set": "yao_doubt"}, say("yao_order", "EV_HALL_4A", "… Der Frühling. Er hat jedes Jahr die ersten Bambussprossen für mich gesucht.", "... Spring. Every year he looked for the first bamboo shoots for me.", "……春天。每年他都会给我找第一批竹笋。")],
                         [{"set": "yao_doubt"}, say("yao_order", "EV_HALL_4B", "… Du auch? Ich dachte, du hättest vor gar nichts Angst.", "... You too? I thought you weren't afraid of anything.", "……你也会？我还以为你什么都不怕。")],
                         [say("yao_order", "EV_HALL_4C", "Feigling? Dann zeig mir, wie mutig du bist!", "Coward? Then show me how brave you are!", "胆小鬼？那你就让我看看你有多勇敢！")]]},
         {"battle": {"enemies": [{"id": "glutfasan", "level": 25, "scale": 0}, {"id": "messingadler", "level": 24, "role": "silenced", "scale": -1}, {"id": "rollschupp", "level": 24, "scale": -1}],
                     "active": 2, "foe": "yao_order", "coins": 200, "bg": "order_hall", "music": "order"},
          "win": [{"set": "yao_hall_done"}, {"refresh": True},
                  {"if": "yao_doubt",
                   "then": [say("yao_order", "EV_HALL_5A", "… Ich weiß nicht mehr, was richtig ist. Geh zu deinen Tönen. Wenn du oben im Tempel bist … dann komme ich auch.", "... I don't know what's right anymore. Go to your tones. When you're up in the temple... I'll come too.", "……我不知道什么才是对的了。去找你的音吧。等你到了上面的庙里……我也会去。")],
                   "else": [say("yao_order", "EV_HALL_5B", "Du hast gewonnen. Und? Großvater bleibt trotzdem fort. Ich gehe zum Großkanzler.", "You won. So what? Grandfather is still gone. I'm going to the Grand Chancellor.", "你赢了。那又怎样？爷爷还是回不来了。我去找大司仪。")]},
                  {"count": "order_fought"}],
          "lose": [say("yao_order", "EV_HALL_LOSE", "Siehst du? Die Stille ist stärker.", "See? The silence is stronger.", "看吧？寂静更强大。")]},
     ]},
]
E["hall_greet"] = [
    {"if": "yao_hall_done", "then": [say("ordensmeisterin", "EV_HALL_GREET_2", "Die Halle ist leer geworden. Viele sind nach Hause gegangen – zu ihren lauten Familien.", "The hall has become empty. Many have gone home - to their noisy families.", "大殿空了。很多人都回家了——回到他们吵吵闹闹的家人身边。")],
     "else": [say("ordensmeisterin", "EV_HALL_GREET_1", "Tritt ein, wenn du die Stille suchst. Yao wartet drinnen auf dich.", "Step inside if you seek the silence. Yao is waiting for you inside.", "若你寻求寂静，请进吧。尧在里面等你。")]},
]
E["quell_haendlerin"] = [
    {"if": "tone_shang", "then": [say("quell_haendlerin", "EV_GUL_2", "Hörst du die Dünen? Sie summen wieder! Die Kunden kommen zurück.", "Do you hear the dunes? They're humming again! The customers are coming back.", "听见沙丘了吗？它们又在哼歌了！客人们都回来了。")],
     "else": [say("quell_haendlerin", "EV_GUL_1", "Die halbe Stadt ist in die Halle gezogen. Sie sagen, dort ist es friedlich. Ich finde es nur … leer.", "Half the town has moved into the hall. They say it's peaceful there. I just find it... empty.", "半个镇子的人都搬进了大殿。他们说那里很安宁。我只觉得……空荡荡的。")]},
]
E["quell_kind"] = [say("quell_kind", "EV_AYLA", "Weißt du, warum der Mond in unserer Quelle wohnt? Weil er sich sonst nachts so allein fühlt!", "Do you know why the moon lives in our spring? Because otherwise he feels so lonely at night!", "你知道月亮为什么住在我们的泉水里吗？因为不然它晚上会很孤单！")]
E["yao_after"] = [say("yao_free", "EV_YAO_AFTER", "Ich fange wieder an zu trommeln, {player}. Ganz leise erst.", "I'm starting to drum again, {player}. Very quietly at first.", "我又开始打鼓了，{player}。先轻轻地。")]
town(E, "mondquell",
     {"wirt": ("Wirt Arslan", "Innkeeper Arslan", "阿尔斯兰"), "haendler": ("Händler Wei", "Merchant Wei", "魏掌柜"),
      "teemeister": ("Teemeisterin Nur", "Tea Mistress Nur", "努尔茶娘"), "koch": ("Koch Dawut", "Cook Dawut", "达吾提厨子")},
     {"inn": ("Ein kühles Bett nach der Hitze. Schlaf gut, Wanderer.", "A cool bed after the heat. Sleep well, traveller.", "炎热之后的一张凉床。睡个好觉，旅人。"),
      "shop": ("Datteln, Kupfer, Tee – alles, was die Wüste hergibt.", "Dates, copper, tea - everything the desert gives.", "枣子、铜、茶——沙漠出产的都在这里。"),
      "tea": ("Dattel-Tee und Geschichten. Beides wird hier nie alle.", "Date tea and stories. Neither ever runs out here.", "枣茶和故事，在这里永远不会少。"),
      "food": ("Dattel-Tee! Wer ihn trinkt, findet Münzen im Sand.", "Date tea! Whoever drinks it finds coins in the sand.", "枣茶！喝了它的人能在沙里捡到铜钱。")},
     ["reisbaellchen", "jasmintee", "kraeutertee", "glockenbluete", "phoenixfeder", "wuestendatteln", "silbertau", "wuestenkupfer"],
     [("Auf dem Singenden Kamm liegt Baihu, der Weiße Tiger, und rührt sich nicht. Sein Fell ist grau wie Staub.", "Baihu, the White Tiger, lies on the Singing Crest and doesn't move. His fur is grey as dust.", "白虎躺在鸣沙脊上一动不动，毛色灰得像尘土。"),
      ("Glockenkamele finden immer den Weg. Wer eines zähmt, verirrt sich nie im Sand.", "Bellcamels always find the way. Whoever tames one never gets lost in the sand.", "铃驼总能找到路。驯服一只，就永远不会在沙漠里迷路。"),
      ("Die Ordensmeisterin sagt, oben im Phönixtempel wartet der Großkanzler. Mit einem Kranich, der nicht singt.", "The Grand Mistress says the Grand Chancellor waits up in the Phoenix Temple. With a crane that doesn't sing.", "教团大师说，大司仪在凤凰庙上面等着。身边有一只不唱歌的鹤。")],
     ["datteltee"])
E["kamm_arrive"] = [
    {"set": "kamm_arrived"},
    say("narrator", "EV_KA_1", "Der Singende Kamm. Auf dem höchsten Grat liegt ein weißer Tiger, so groß wie ein Pferd. Der Sand um ihn ist glatt, kein Windhauch.",
        "The Singing Crest. On the highest ridge lies a white tiger as big as a horse. The sand around him is smooth, not a breath of wind.",
        "鸣沙脊。最高的沙脊上躺着一只马那么大的白虎。它周围的沙子平平整整，一丝风都没有。"),
    rquest("dunes", "QUEST_DUNES_3", "Befreie Baihu auf dem Kamm und hol den Ton Shang zurück.", "Free Baihu on the crest and bring back the tone Shang.", "解放沙脊上的白虎，找回“商”音。"),
    {"goal": ["singender_kamm", 13, 8], "region": "dunes"},
]
hints("DUNES_3", ["Miau! (Jinli schaut den Grat hinauf.)", "Miau, miau! (Ganz oben liegt Baihu.)", "Miaaau! (Oben auf dem Kamm: Baihu. Die Älteste unten heilt dein Gefolge.)"],
      ["Mew! (Jinli looks up the ridge.)", "Mew, mew! (Baihu lies at the very top.)", "Meeew! (Up on the crest: Baihu. The elder below heals your companions.)"],
      ["喵！（锦鲤望着沙脊。）", "喵喵！（白虎在最上面。）", "喵——！（沙脊上就是白虎。下面的长老能给同伴疗伤。）"])
order_guard(E, "order_kamm", "order_kamm",
            t("PER_KAMM_INTRO", "Halt. Der Tiger schläft, und die Dünen schweigen. Seit sie nicht mehr singen, verirrt sich niemand mehr in einem Sandsturm. Es gibt keine Sandstürme mehr.",
              "Halt. The tiger sleeps and the dunes are silent. Since they stopped singing, nobody gets lost in a sandstorm. There are no sandstorms anymore.",
              "站住。老虎在睡觉，沙丘沉默着。自从它们不再歌唱，就没人在沙暴中迷路了。根本没有沙暴了。"),
            {"logic": 2, "proof": 2, "compassion": 1, "threat": -1}, 2, ["tone_jue", "tone_yu", "tone_zhi"],
            [{"id": "duenenspringer", "level": 25, "role": "silenced"}], "order_kamm_done",
            ("Die Karawanen verirren sich trotzdem … weil die Dünen ihnen keinen Weg mehr singen. Du hast recht. Geh.", "The caravans get lost anyway... because the dunes no longer sing them the way. You're right. Go.", "商队还是会迷路……因为沙丘不再为他们唱出道路。你说得对。去吧。"),
            ("Nein. Mein Springer und ich bleiben hier.", "No. My Duneskip and I stay here.", "不。我和我的沙跳鼠留在这里。"), "dunes")
E["karawanenaelteste"] = [
    say("karawanenaelteste", "EV_SAULE", "Setz dich in den Schatten, Kind. Trink. Dann geh zum Tiger.", "Sit in the shade, child. Drink. Then go to the tiger.", "到阴凉处坐会儿，孩子。喝点水。然后去找老虎吧。"),
    {"heal": True}, {"set_inn": ["singender_kamm", "from_town"]}, {"save": True},
    say("narrator", "EV_SAULE_2", "Dein Gefolge ist geheilt. Gespeichert.", "Your companions are healed. Saved.", "同伴已恢复。已存档。"),
]
E["boss_baihu"] = [
    {"if_not": "baihu_seen", "then": [
        {"set": "baihu_seen"},
        say("narrator", "EV_BH_1", "Baihu hebt den Kopf. Seine Streifen, einst silbern, sind stumpf. Er brüllt – lautlos.", "Baihu raises his head. His stripes, once silver, are dull. He roars - without a sound.", "白虎抬起了头。它曾经银光闪闪的条纹黯淡无光。它咆哮着——却没有声音。"),
        say("baihu", "EV_BH_2", "… Herbst … nie … mehr …", "... autumn... never... again...", "……秋天……再也……不……"),
        say("narrator", "EV_BH_TUT", "Zwei gegen zwei! Mutige wollen Ermutigung und Lob hören.", "Two against two! Brave ones want to hear encouragement and praise.", "二对二！勇敢的灵兽喜欢听鼓励和称赞。"),
    ]},
    {"if_party_min": 2, "then": [
        {"battle": {"enemies": [{"id": "baihu", "level": 30, "role": "silenced", "scale": 1}, {"id": "messingadler", "level": 26, "role": "silenced", "scale": -2}],
                    "active": 2, "music": "boss", "bg": "dunes"},
         "win": [{"run": "tone_shang_returns"}],
         "lose": [say("karawanenaelteste", "EV_BH_LOSE", "Der Tiger ist stark. Ruh dich aus und versuch es noch einmal.", "The tiger is strong. Rest and try again.", "老虎很强。休息一下再试吧。")]}],
     "else": [say("karawanenaelteste", "EV_BH_ALONE", "Allein? Du brauchst mindestens zwei Gefährten.", "Alone? You need at least two companions.", "一个人？你至少需要两个同伴。")]},
]
E["tone_shang_returns"] = [
    {"music": "tone_returns"},
    {"if": "freed_baihu",
     "then": [say("narrator", "EV_SH_1", "Baihus Herzklang klirrt wie Metall – und da ist er: ein klarer, silberner Ton. Shang.", "Baihu's heartsong rings like metal - and there it is: a clear, silver tone. Shang.", "白虎的心音像金属一样铿锵作响——它来了：一个清亮的银色之音。商。")],
     "else": [say("narrator", "EV_SH_1B", "Der Tiger legt sich nieder. Ein Ton klingt auf, dünn wie ein Faden: Shang.", "The tiger lies down. A tone rings out, thin as a thread: Shang.", "老虎卧了下去。一个音响起，细得像一根丝线：商。")]},
    {"tone": "tone_shang"},
    {"refresh": True},
    say("narrator", "EV_SH_2", "Wind streicht über die Dünen, und sie beginnen zu singen – ein tiefes, summendes Lied, das man in der Brust spürt.", "Wind brushes over the dunes, and they begin to sing - a deep, humming song you feel in your chest.", "风拂过沙丘，它们开始歌唱——一首低沉的、嗡嗡作响的歌，能在胸口感觉到。"),
    {"voice": "baihu", "event": "freed"},
    say("baihu", "EV_SH_3", "Auch das Laub fällt, damit der Baum den Winter übersteht. Wer nichts loslässt, kann nichts Neues halten. Sag das Wusheng, kleiner Mensch.",
        "Even the leaves fall so the tree survives the winter. Whoever lets nothing go can hold nothing new. Tell Wusheng that, little one.",
        "树叶落下，大树才能熬过冬天。什么都不放手的人，也抓不住新的东西。把这话告诉无声吧，小家伙。"),
    {"set": "lesson_leaves"},
    {"give_item": "wuestenkupfer", "n": 3},
    {"clear_region": "dunes"},
    {"run": "after_tone"},
]
E["baihu_free"] = [
    {"if": "bitter_dunes", "then": [{"run": "bitter_dunes_free"}],
     "else": [say("baihu_free", "EV_BH_FREE", "Zeig mir dein Herz, nicht deine Krallen. Das hast du getan.", "Show me your heart, not your claws. You did that.", "给我看你的心，而不是你的爪子。你做到了。")]},
]

# --- Wolkensäulen -----------------------------------------------------------------------
E["saeulenpfad_arrive"] = [
    {"set": "saeulenpfad_arrived"},
    say("narrator", "EV_SP_1", "Steinsäulen ragen aus einem Meer aus Wolken. Ein schmaler Pfad windet sich von Säule zu Säule nach oben. Kiefern krallen sich an die Felsen.",
        "Stone pillars rise out of a sea of clouds. A narrow path winds upwards from pillar to pillar. Pines cling to the rocks.",
        "石柱从云海中拔地而起。一条窄窄的小路在石柱间蜿蜒向上。松树紧紧扒着岩石。"),
    rquest("pillars", "QUEST_PILLARS_1", "Steig den Säulenpfad hinauf bis Kiefernhang.", "Climb the Pillar Path up to Pinecliff.", "沿石柱道往上爬到松崖村。"),
    {"goal": ["kiefernhang", 17, 12], "region": "pillars"},
]
hints("PILLARS_1", ["Miau! (Jinli springt von Stein zu Stein nach oben.)", "Miau, miau! (Der Weg in der Mitte führt nach oben.)", "Miaaau! (Immer den Weg in der Mitte hinauf – oben liegt Kiefernhang.)"],
      ["Mew! (Jinli hops upwards from stone to stone.)", "Mew, mew! (The path in the middle leads up.)", "Meeew! (Keep going up the path in the middle - Pinecliff is at the top.)"],
      ["喵！（锦鲤从一块石头跳到另一块，往上爬。）", "喵喵！（中间的路通往上面。）", "喵——！（一直沿中间的路往上——上面就是松崖村。）"])
E["chest_saeulen"] = [say("narrator", "EV_CHEST_SAEULEN", "Auf einer Säule, zwischen Kiefernwurzeln: eine Kiste aus grüner Jade.", "On a pillar, between pine roots: a chest of green jade.", "石柱上，松根之间：一个绿玉箱子。"),
                      {"give_item": "wolkenjade", "n": 3}, {"give_item": "phoenixfeder", "n": 1}, {"set": "chest_saeulen"}, {"refresh": True}]
E["kiefernhang_arrive"] = [
    {"set": "kiefernhang_arrived"},
    say("narrator", "EV_KH_1", "Kiefernhang, ein Dorf auf einer Säule hoch über den Wolken. Über dem Dorf schwebt eine Treppe aus Wolken – sie endet im Nichts.", "Pinecliff, a village on a pillar high above the clouds. Above the village floats a staircase of clouds - it ends in nothing.", "松崖村，一座建在高耸入云的石柱上的村子。村子上方飘着一道云梯——却通向虚无。"),
    rquest("pillars", "QUEST_PILLARS_2", "Der Qilin wartet auf dem Plateau rechts von Kiefernhang.", "The Qilin waits on the plateau to the right of Pinecliff.", "麒麟在松崖村右边的高台上。"),
    {"goal": ["qilin_plateau", 14, 9], "region": "pillars"},
    {"set_inn": ["kiefernhang", "inn"]},
]
hints("PILLARS_2", ["Miau! (Jinli schaut nach rechts.)", "Miau, miau! (Der Weg rechts aus dem Dorf führt zum Plateau.)", "Miaaau! (Kiefernhang, rechts in der Mitte: der Weg zum Qilin-Plateau.)"],
      ["Mew! (Jinli looks to the right.)", "Mew, mew! (The road out of the village to the right leads to the plateau.)", "Meeew! (Pinecliff, middle right: the way to the Qilin Plateau.)"],
      ["喵！（锦鲤望向右边。）", "喵喵！（村子右边的路通往高台。）", "喵——！（松崖村右边中间：去麒麟台的路。）"])
E["kiefer_aelteste"] = [
    {"if": "five_tones", "then": [say("kiefer_aelteste", "EV_SONG_3", "Die Wolkentreppe trägt dich jetzt. Geh, Kind des Windspiels. Oben wartet ein alter Mann, der Angst hat.", "The cloud stairs will carry you now. Go, child of the wind chime. Up there waits an old man who is afraid.", "云梯现在能载你上去了。去吧，风铃之子。上面有个害怕的老人在等你。")],
     "else": [say("kiefer_aelteste", "EV_SONG_1", "Die Wolkentreppe führt zum Phönixtempel. Sie trägt nur, wenn alle fünf Töne klingen.", "The cloud stairs lead to the Phoenix Temple. They only carry you when all five tones ring.", "云梯通往凤凰庙。只有五音齐鸣时，它才能载人上去。"),
              say("kiefer_aelteste", "EV_SONG_2", "Vor einem Jahr stieg Wusheng sie hinauf, mit einem Silberkranich auf der Schulter. Der Kranich war alt. Er sang nicht mehr – aber er sah ihn an, als wolle er etwas sagen.",
                  "A year ago Wusheng climbed them, a silver crane on his shoulder. The crane was old. It no longer sang - but it looked at him as if it wanted to say something.",
                  "一年前，无声肩上带着一只银鹤走了上去。那只鹤老了，不再唱歌——但它望着他，好像想说什么。"),
              {"set": "heard_crane_story"}]},
]
E["temple_closed"] = [say("jinli", "EV_TEMPLE_CLOSED", "Miau. (Jinli tritt auf die erste Wolkenstufe – und ihre Pfote sinkt durch. Es fehlen noch Töne.)", "Mew. (Jinli steps onto the first cloud step - and her paw sinks through. Tones are still missing.)", "喵。（锦鲤踩上第一级云阶——爪子却陷了进去。还缺音呢。）")]
E["kiefer_kind"] = [say("kiefer_kind", "EV_SHAN", "Wenn man von hier spuckt, dauert es ewig, bis es unten ankommt. Hab ich gehört. Ich mach das natürlich nie.", "If you spit from here it takes forever to reach the bottom. So I've heard. I'd never do that, of course.", "从这儿吐口水，要好久才能落到底。我听说的。我当然从来不这么干。")]
E["kiefer_frau"] = [
    say("kiefer_frau", "EV_YUE", "Wolkenbeeren! Die Erdgeister lieben sie. Nimm ein paar mit, die Säulen sind lang.", "Cloud berries! Earth spirits love them. Take a few, the pillars are long.", "云莓！土灵最爱吃了。带上几颗吧，石柱道很长。"),
    {"if_not": "got_berries", "then": [{"give_item": "wolkenbeeren", "n": 3}, {"set": "got_berries"}]},
]
town(E, "kiefernhang",
     {"wirt": ("Wirtin Lan", "Innkeeper Lan", "兰老板娘"), "haendler": ("Händler Gu", "Merchant Gu", "古掌柜"),
      "teemeister": ("Teemeister Yun", "Tea Master Yun", "云茶师"), "koch": ("Köchin Xue", "Cook Xue", "雪厨娘")},
     {"inn": ("Hier oben schläft man über den Wolken. Gute Nacht.", "Up here you sleep above the clouds. Good night.", "在这里，人睡在云上。晚安。"),
      "shop": ("Jade, Beeren, Tee. Und Phönixdaunen – für alle Fälle.", "Jade, berries, tea. And phoenix down - just in case.", "玉石、云莓、茶叶。还有凤羽——以防万一。"),
      "tea": ("Tee aus Wolkenwasser. Er schmeckt nach Höhe.", "Tea from cloud water. It tastes of heights.", "用云水泡的茶。尝起来有高处的味道。"),
      "food": ("Wolkenklöße! Leicht wie Nebel, fest wie Fels.", "Cloud dumplings! Light as mist, firm as rock.", "云饺！轻如薄雾，结实如石。")},
     ["reisbaellchen", "jasmintee", "kraeutertee", "glockenbluete", "phoenixfeder", "wolkenbeeren", "wolkenjade"],
     [("Der Qilin auf dem Plateau ist so sanft, dass unter seinen Hufen kein Halm knickt. Jetzt steht er grau und still.", "The Qilin on the plateau is so gentle that not a blade of grass bends under its hooves. Now it stands grey and still.", "高台上的麒麟温柔得蹄下不折一草。如今它灰扑扑地静立着。"),
      ("Steinlöwen bewachen die Säulen. Wer Respekt zeigt, dem öffnen sie den Weg.", "Stonelions guard the pillars. They open the way to whoever shows respect.", "石狮守护着石柱。谁表现出尊重，它们就为谁让路。"),
      ("Oben im Tempel liegt die Asche des Phönix. Wusheng wacht daneben, Tag und Nacht.", "Up in the temple lie the phoenix's ashes. Wusheng keeps watch beside them, day and night.", "庙里放着凤凰的灰烬。无声日夜守在旁边。")],
     ["wolkenkloesse"])
E["plateau_arrive"] = [
    {"set": "plateau_arrived"},
    say("narrator", "EV_PL_1", "Das Qilin-Plateau. Zwischen den Säulen steht ein Wesen wie ein Hirsch mit Schuppen und einem einzelnen Horn. Grau, reglos – wie aus Stein.",
        "The Qilin Plateau. Between the pillars stands a creature like a deer with scales and a single horn. Grey, motionless - as if made of stone.",
        "麒麟台。石柱间站着一头像鹿一样、身披鳞片、头生独角的生灵。灰扑扑的，一动不动——像石头雕成的。"),
    rquest("pillars", "QUEST_PILLARS_3", "Befreie den Qilin und hol den Ton Gong zurück.", "Free the Qilin and bring back the tone Gong.", "解放麒麟，找回“宫”音。"),
    {"goal": ["qilin_plateau", 14, 9], "region": "pillars"},
]
hints("PILLARS_3", ["Miau! (Jinli schaut zum Qilin.)", "Miau, miau! (Den Weg hinauf zum Qilin.)", "Miaaau! (Oben auf dem Plateau: der Qilin. Sanfte mögen Ruhe und Respekt.)"],
      ["Mew! (Jinli looks at the Qilin.)", "Mew, mew! (Up the path to the Qilin.)", "Meeew! (Up on the plateau: the Qilin. Gentle ones like calm and respect.)"],
      ["喵！（锦鲤望着麒麟。）", "喵喵！（沿路上去找麒麟。）", "喵——！（高台上就是麒麟。温和的灵兽喜欢平静和尊重。）"])
order_guard(E, "order_plateau", "order_plateau",
            t("PER_PLATEAU_INTRO", "Bitte geh nicht weiter. Meine Mutter ist letzten Herbst gestorben. Wenn alles stillsteht, muss nie wieder jemand so etwas erleben.",
              "Please don't go any further. My mother died last autumn. If everything stands still, nobody will ever have to go through that again.",
              "请别再往前走了。我母亲去年秋天去世了。如果一切都停下来，就再也没有人要经历这种事了。"),
            {"compassion": 2, "logic": 1, "proof": 1, "threat": -2}, 2, ["lesson_water", "lesson_fisher", "lesson_master"],
            [{"id": "felstakin", "level": 25, "role": "silenced"}], "order_plateau_done",
            ("… Sie hat immer gesagt, ich soll weitersingen, wenn sie nicht mehr da ist. Ich hatte es vergessen. Danke.", "... She always said I should keep singing when she's gone. I had forgotten. Thank you.", "……她总说，等她不在了，我要继续唱下去。我都忘了。谢谢你。"),
            ("Ich kann nicht. Bitte verzeih mir.", "I can't. Please forgive me.", "我做不到。请原谅我。"), "pillars")
E["eremitin"] = [
    say("eremitin", "EV_QING", "Atme die Wolken ein. Langsam. So.", "Breathe in the clouds. Slowly. Like that.", "吸一口云气。慢慢地。就这样。"),
    {"heal": True}, {"set_inn": ["qilin_plateau", "from_town"]}, {"save": True},
    say("narrator", "EV_QING_2", "Dein Gefolge ist geheilt. Gespeichert.", "Your companions are healed. Saved.", "同伴已恢复。已存档。"),
]
E["boss_qilin"] = [
    {"if_not": "qilin_seen", "then": [
        {"set": "qilin_seen"},
        say("narrator", "EV_QL_1", "Der Qilin hebt den Kopf. Wo seine Hufe den Boden berühren, ist das Gras grau und starr.", "The Qilin raises its head. Where its hooves touch the ground, the grass is grey and stiff.", "麒麟抬起了头。它的蹄子踩过的地方，草又灰又硬。"),
        say("qilin", "EV_QL_2", "… nichts … kehrt … zurück …", "... nothing... returns...", "……什么……都不……回来……"),
        say("narrator", "EV_QL_TUT", "Zwei gegen zwei! Sanfte hören auf Ruhe und Respekt.", "Two against two! Gentle ones listen to calm and respect.", "二对二！温和的灵兽听得进平静和尊重。"),
    ]},
    {"if_party_min": 2, "then": [
        {"battle": {"enemies": [{"id": "qilin", "level": 30, "role": "silenced", "scale": 1}, {"id": "steinloewe", "level": 26, "role": "silenced", "scale": -2}],
                    "active": 2, "music": "boss", "bg": "pillars"},
         "win": [{"run": "tone_gong_returns"}],
         "lose": [say("eremitin", "EV_QL_LOSE", "Die Erde ist geduldig. Sei du es auch. Versuch es noch einmal.", "The earth is patient. Be patient too. Try again.", "大地很有耐心。你也要有耐心。再试一次吧。")]}],
     "else": [say("eremitin", "EV_QL_ALONE", "Allein? Du brauchst mindestens zwei Gefährten.", "Alone? You need at least two companions.", "一个人？你至少需要两个同伴。")]},
]
E["tone_gong_returns"] = [
    {"music": "tone_returns"},
    {"if": "freed_qilin",
     "then": [say("narrator", "EV_GO_1", "Der Herzklang des Qilin wird tief und warm wie die Erde selbst – und da ist er: Gong, der Grundton.", "The Qilin's heartsong grows deep and warm as the earth itself - and there it is: Gong, the root tone.", "麒麟的心音变得深沉而温暖，就像大地本身——它来了：宫，五音之本。")],
     "else": [say("narrator", "EV_GO_1B", "Der Qilin kniet nieder. Ein Ton steigt aus dem Boden, leise und schwer: Gong.", "The Qilin kneels down. A tone rises from the ground, quiet and heavy: Gong.", "麒麟跪了下来。一个音从地底升起，低沉而厚重：宫。")]},
    {"tone": "tone_gong"},
    {"refresh": True},
    say("narrator", "EV_GO_2", "Die Wolken unter den Säulen beginnen zu wogen. Die Kiefern rauschen. Unter den Hufen des Qilin sprießt grünes Gras.", "The clouds below the pillars begin to surge. The pines rustle. Green grass sprouts under the Qilin's hooves.", "石柱下的云海开始翻涌，松涛阵阵。麒麟蹄下冒出了青草。"),
    {"voice": "qilin", "event": "freed"},
    say("qilin", "EV_GO_3", "Die Erde nimmt jedes Blatt zurück und schenkt es dem Frühling. Nichts geht verloren, kleiner Mensch. Es verwandelt sich nur.",
        "The earth takes back every leaf and gives it to the spring. Nothing is lost, little one. It only changes.",
        "大地收回每一片叶子，再把它送给春天。什么都不会失去，小家伙。它只是变了样子。"),
    {"set": "lesson_earth"},
    {"give_item": "wolkenjade", "n": 3},
    {"clear_region": "pillars"},
    {"run": "after_tone"},
]
E["qilin_free"] = [say("qilin_free", "EV_QL_FREE", "Geh leise, und du hörst alles.", "Walk softly, and you hear everything.", "轻轻地走，你就能听见一切。")]
