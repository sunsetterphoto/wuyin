"""Act 4: the rebirth. The Phoenix Temple above the Cloud Pillars, Yao's
choice, the conversation with Wusheng (answers unlocked by the lessons of the
journey), his crane, the Nian's last stand, the three endings and what comes
after the credits. Part of tools/story/build.py."""
from common import *

E = {}

person("kranich", "Silberkranich", "Silver Crane", "银鹤", "shang", "gentle", 0)
person("yao_ally", "Yao", "Yao", "尧", "zhi", "brave", 0)
person("meister_temple", "Meister Lu", "Master Lu", "卢师傅", "gong", "gentle", -1)
person("wusheng_after", "Wusheng", "Wusheng", "无声", "shang", "gentle", -1)
person("fenghuang", "Fenghuang", "Fenghuang", "凤凰", "zhi", "gentle", 0)

E["temple_arrive"] = [
    {"set": "temple_arrived"},
    say("narrator", "EV_TA_1", "Der Phönixtempel schwebt über dem Wolkenmeer. Fünf Säulen tragen fünf ausgeblichene Banner. In einem Nest aus Gold glimmt ein Haufen Asche.",
        "The Phoenix Temple floats above the sea of clouds. Five pillars carry five faded banners. In a nest of gold, a heap of ashes glows faintly.",
        "凤凰庙悬浮在云海之上。五根柱子上挂着五面褪色的幡。金色的巢里，一堆灰烬微微发光。"),
    say("narrator", "EV_TA_2", "Davor steht Wusheng. Neben ihm, auf einem Bein, ein alter Silberkranich, der dich still ansieht.", "In front of it stands Wusheng. Beside him, on one leg, an old silver crane watching you silently.", "无声站在巢前。他身旁，一只年老的银鹤单脚而立，静静地看着你。"),
    quest("QUEST_FINALE", "Stell dich Wusheng im Phönixtempel.", "Face Wusheng in the Phoenix Temple.", "在凤凰庙面对无声。"),
    {"goal": ["phoenixtempel", 14, 12]},
    {"set_inn": ["kiefernhang", "inn"]},
]
hints("FINALE", ["Miau. (Jinli schaut zu Wusheng. Ihr Schwanz zuckt.)", "Miau! (Geh zu Wusheng vor dem Nest.)", "Miaaau! (Wusheng steht vor dem goldenen Nest. Du hast alles gelernt, was du brauchst.)"],
      ["Mew. (Jinli looks at Wusheng. Her tail twitches.)", "Mew! (Go to Wusheng in front of the nest.)", "Meeew! (Wusheng stands in front of the golden nest. You have learned everything you need.)"],
      ["喵。（锦鲤盯着无声，尾巴一抽一抽的。）", "喵！（去巢前找无声。）", "喵——！（无声站在金色的巢前。你需要的，都已经学会了。）"])
E["wusheng_temple"] = [{"run": "finale"}]
E["kranich_temple"] = [
    say("narrator", "EV_KT", "Der Kranich sieht dich an. Er öffnet den Schnabel, als wolle er etwas sagen – und schließt ihn wieder.", "The crane looks at you. It opens its beak as if to say something - and closes it again.", "鹤看着你。它张开喙，好像要说什么——又合上了。"),
]
E["phoenix_ashes"] = [say("narrator", "EV_ASHES", "Die Asche ist warm. Ganz tief darin glimmt ein Funke, der auf sein Lied wartet.", "The ashes are warm. Deep inside, a spark glows, waiting for its song.", "灰烬是温的。在最深处，一粒火星在闪烁，等待着它的歌。")]
E["yao_temple"] = [say("yao_order", "EV_YT", "…", "...", "……")]
E["yao_ally"] = [say("yao_ally", "EV_YA", "Ich bin bei dir, {player}.", "I'm with you, {player}.", "我和你在一起，{player}。")]

# --- the finale --------------------------------------------------------------------------
E["finale"] = [
    {"if": "wusheng_resolved", "then": [{"run": "finale_nian"}], "else": [{"run": "finale_talk"}]},
]
E["finale_talk"] = [
    {"music": "order"},
    {"if_not": "finale_started", "then": [
        {"set": "finale_started"},
        say("wusheng", "EV_FIN_1", "Du bist also gekommen, Kind des Windspiels. Mit allen fünf Tönen. Ich habe gehört, wie sie einer nach dem anderen zurückkehrten.",
            "So you have come, child of the wind chime. With all five tones. I heard them return, one after another.",
            "你还是来了，风铃之子。带着全部五音。我听着它们一个接一个地回来。"),
        say("wusheng", "EV_FIN_2", "Wenn das Lied erklingt, verbrennt der Phönix, und mit ihm geht das Alte. Diesmal ginge auch er.", "When the song sounds, the phoenix burns, and the old goes with it. This time he would go too.", "歌声一响，凤凰就会燃尽，旧的一切随之而去。这一次，他也会走。"),
        say("narrator", "EV_FIN_3", "Wusheng legt die Hand auf den Rücken des Kranichs. Der Vogel lehnt den Kopf an seine Schulter.", "Wusheng lays his hand on the crane's back. The bird leans its head against his shoulder.", "无声把手放在鹤的背上。鹤把头靠在他的肩上。"),
    ]},
    # Yao decides.
    {"if": "yao_returned", "then": [], "else": [
        {"if": "yao_doubt",
         "then": [say("yao_order", "EV_FIN_YAO_1", "Großkanzler … Ich habe genug von der Stille. Großvater hätte gewollt, dass ich weitersinge.", "Grand Chancellor... I've had enough of the silence. Grandfather would have wanted me to keep singing.", "大司仪……我受够了寂静。爷爷会希望我继续唱下去的。"),
                  say("narrator", "EV_FIN_YAO_2", "Yao zieht die graue Kutte aus und stellt sich neben dich.", "Yao takes off the grey robe and stands beside you.", "尧脱下灰袍，站到了你身边。"),
                  {"set": "yao_returned"}, {"refresh": True}],
         "else": [{"if_not": "yao_left", "then": [
             say("yao_order", "EV_FIN_YAO_3", "Ich lasse nicht zu, dass du alles verbrennst, {player}!", "I won't let you burn everything, {player}!", "我不会让你把一切都烧掉的，{player}！"),
             {"battle": {"enemies": [{"id": "glutfasan", "level": 33, "scale": 0}, {"id": "rollschupp", "level": 32, "scale": -1}, {"id": "messingadler", "level": 32, "role": "silenced", "scale": -1}],
                         "active": 2, "foe": "yao_order", "coins": 300, "music": "order", "bg": "phoenix_temple"},
              "win": [say("yao_order", "EV_FIN_YAO_4", "… Mach doch, was du willst. Ich geh.", "... Do what you want. I'm leaving.", "……随你便吧。我走了。"),
                      {"set": "yao_left"}, {"refresh": True}]}]}]},
    ]},
    # The conversation: wise answers come from what the journey taught.
    {"clear": "wise_1"}, {"clear": "wise_2"}, {"clear": "wise_3"},
    say("wusheng", "EV_FIN_Q1", "Sag mir, Kind: Warum sollte ich zulassen, dass alles verbrennt, was ich liebe?", "Tell me, child: why should I let everything I love burn?", "告诉我，孩子：我为什么要让我所爱的一切都烧掉？"),
    {"choice": [{"text": t("CH_FI_1A", "Auch der Bambus wirft alte Halme ab, damit neue wachsen. Das hat mir der Azurdrache gesagt.", "Even bamboo sheds old stalks so new ones can grow. The Azure Dragon told me that.", "竹子也要褪去旧竿，新竹才能生长。这是青龙告诉我的。"), "when": "lesson_bamboo"},
                {"text": t("CH_FI_1B", "Die Feuerkiefer öffnet ihre Zapfen nur im Feuer. Ohne Brand gibt es keinen neuen Wald.", "The fire pine opens its cones only in fire. Without burning there's no new forest.", "火松的松果只在火中张开。没有燃烧，就没有新的森林。"), "when": "lesson_forest"},
                t("CH_FI_1C", "Weil es nun mal so sein muss!", "Because that's just how it has to be!", "因为本来就该这样！")],
     "then": [[{"set": "wise_1"}, say("wusheng", "EV_FIN_1A", "… Der Drache. Er war immer der Geduldigste von allen.", "... The dragon. He was always the most patient of them all.", "……青龙。它一向是最有耐心的。")],
              [{"set": "wise_1"}, say("wusheng", "EV_FIN_1B", "… Ich habe diese Zapfen gesehen. Ich dachte, sie seien einfach verbrannt.", "... I have seen those cones. I thought they had simply burned.", "……我见过那些松果。我以为它们只是被烧焦了。")],
              [say("wusheng", "EV_FIN_1C", "Muss es? Das sagen alle, die nichts zu verlieren haben.", "Must it? That's what everyone says who has nothing to lose.", "该这样？没有东西可失去的人都这么说。")]]},
    say("wusheng", "EV_FIN_Q2", "Und die, die gehen? Er ist alt. Wenn der Phönix verbrennt, geht er mit. Ich will ihn nicht verlieren.", "And those who leave? He is old. When the phoenix burns, he goes with it. I don't want to lose him.", "那些离去的呢？他老了。凤凰燃尽时，他也会随之而去。我不想失去他。"),
    {"choice": [{"text": t("CH_FI_2A", "Der Fischer in Nebelhafen lässt seinen Kormoran jeden Herbst ziehen. Und jeden Frühling kommt er zurück.", "The fisher in Misthaven lets his cormorant go every autumn. And every spring it comes back.", "雾港的渔夫每年秋天都放他的鸬鹚走。每年春天它都会回来。"), "when": "lesson_fisher"},
                {"text": t("CH_FI_2B", "Xuanwu hat zehntausend Winter gesehen. Jeder ging, jeder kam wieder.", "Xuanwu has seen ten thousand winters. Each one left, each one came back.", "玄武见过一万个冬天。每一个都离开了，每一个都回来了。"), "when": "lesson_water"},
                {"text": t("CH_FI_2C", "Meister Lu hat es dir gesagt: Ohne Abschied gibt es kein Wiedersehen.", "Master Lu told you: without farewell there is no reunion.", "卢师傅早就告诉过你：没有离别，就没有重逢。"), "when": "lesson_master"},
                t("CH_FI_2D", "Das ist mir egal.", "I don't care.", "我不在乎。")],
     "then": [[{"set": "wise_2"}, say("wusheng", "EV_FIN_2A", "… Jeden Frühling.", "... Every spring.", "……每个春天。")],
              [{"set": "wise_2"}, say("wusheng", "EV_FIN_2B", "… Die alte Schildkröte. Sie hat ihm so gern zugehört.", "... The old tortoise. She loved listening to him.", "……那只老玄龟。她那么喜欢听他唱歌。")],
              [{"set": "wise_2"}, say("wusheng", "EV_FIN_2C", "… Lu. Alter Freund. Du hattest damals schon recht.", "... Lu. Old friend. You were right even back then.", "……卢。老朋友。你那时候就说对了。")],
              [say("wusheng", "EV_FIN_2D", "Dann verstehst du nichts.", "Then you understand nothing.", "那你什么都不懂。")]]},
    say("wusheng", "EV_FIN_Q3", "Was weißt du schon vom Loslassen, Kind?", "What do you know of letting go, child?", "你又懂什么叫放手，孩子？"),
    {"choice": [{"text": t("CH_FI_3A", "Baihu hat gesagt: Auch das Laub fällt, damit der Baum den Winter übersteht.", "Baihu said: even the leaves fall so the tree survives the winter.", "白虎说过：树叶落下，大树才能熬过冬天。"), "when": "lesson_leaves"},
                {"text": t("CH_FI_3B", "Der Qilin sagt: Die Erde nimmt jedes Blatt zurück und schenkt es dem Frühling. Nichts geht verloren.", "The Qilin says: the earth takes back every leaf and gives it to the spring. Nothing is lost.", "麒麟说：大地收回每一片叶子，再把它送给春天。什么都不会失去。"), "when": "lesson_earth"},
                {"text": t("CH_FI_3C", "Bifang hat gesagt: Ein Wald, der nie brennt, wird nie jung.", "Bifang said: a forest that never burns never grows young.", "毕方说过：从不燃烧的森林，永远不会年轻。"), "when": "lesson_fire"},
                t("CH_FI_3D", "Gib einfach auf, alter Mann!", "Just give up, old man!", "放弃吧，老头！")],
     "then": [[{"set": "wise_3"}, say("wusheng", "EV_FIN_3A", "… Der Tiger hat nie viele Worte gemacht. Aber wenn, dann stimmten sie.", "... The tiger never used many words. But when he did, they were true.", "……白虎从不多言。可他说的话，句句是真。")],
              [{"set": "wise_3"}, say("wusheng", "EV_FIN_3B", "… Nichts geht verloren.", "... Nothing is lost.", "……什么都不会失去。")],
              [{"set": "wise_3"}, say("wusheng", "EV_FIN_3C", "… Nie jung.", "... Never young.", "……永远不会年轻。")],
              [say("wusheng", "EV_FIN_3D", "Aufgeben? Ich habe nie etwas anderes getan, als festzuhalten.", "Give up? I have never done anything but hold on.", "放弃？我这辈子除了紧抓不放，什么都没做过。")]]},
    {"if_count": [["wise_1", "wise_2", "wise_3"], 2],
     "then": [
         say("wusheng", "EV_FIN_W1", "… Vielleicht hast du recht. Vielleicht habe ich all die Jahre nur Angst gehabt.", "... Perhaps you are right. Perhaps all these years I was only afraid.", "……也许你说得对。也许这些年来，我只是在害怕。"),
         say("wusheng", "EV_FIN_W2", "Aber er … er singt nicht mehr. Nicht einmal für mich. Wenn er gehen will, warum sagt er es mir nicht?", "But he... he doesn't sing anymore. Not even for me. If he wants to go, why won't he tell me?", "可是他……他不再唱歌了。连为我都不唱了。如果他想走，为什么不告诉我？"),
         {"if_item": "kranichfeder",
          "then": [
              {"choice": [t("CH_FI_FEATHER", "Zeig dem Kranich die Feder aus der Schildkrötenbucht und sprich mit ihm.", "Show the crane the feather from Tortoise Bay and talk to it.", "把玄龟湾的羽毛给鹤看，和它说说话。"),
                          t("CH_FI_NOFEATHER", "Genug geredet.", "Enough talk.", "说够了。")],
               "then": [[
                   say("narrator", "EV_FIN_F1", "Du hältst die silberne Feder hoch. Der Kranich erkennt sie – er hat sie am See verloren, damals, als er für Xuanwu sang.", "You hold up the silver feather. The crane recognises it - it lost it at the lake, back when it sang for Xuanwu.", "你举起银色的羽毛。鹤认出了它——那是它当年在湖边为玄武唱歌时掉落的。"),
                   say("narrator", "EV_FIN_F2", "Sprich mit dem Kranich. Er schweigt nicht, weil ihm die Stimme fehlt – sondern aus Treue. Finde die richtigen Worte.", "Talk to the crane. It isn't silent because it lacks a voice - but out of loyalty. Find the right words.", "和鹤说说话。它沉默不是因为失去了声音——而是出于忠诚。找到合适的话吧。"),
                   {"crane": True,
                    "sings": [{"set": "crane_sings"}, {"set": "wusheng_convinced"}, {"run": "crane_song"}],
                    "silent": [say("narrator", "EV_FIN_F3", "Der Kranich senkt den Kopf. Er bleibt stumm.", "The crane lowers its head. It stays silent.", "鹤低下了头，依旧沉默。"),
                               say("wusheng", "EV_FIN_F4", "Siehst du? Er will nicht. Dann soll alles so bleiben, wie es ist!", "You see? He doesn't want to. Then everything shall stay as it is!", "你看到了吧？他不愿意。那就让一切保持原样！"),
                               {"run": "wusheng_battle"}]}],
                        [{"run": "wusheng_battle"}]]}],
          "else": [say("wusheng", "EV_FIN_W3", "Nein … ich kann es nicht. Nicht ohne ein Zeichen von ihm.", "No... I can't. Not without a sign from him.", "不……我做不到。没有他的一点表示，我做不到。"),
                   {"run": "wusheng_battle"}]}],
     "else": [say("wusheng", "EV_FIN_N1", "Worte. Nur Worte. Du verstehst nichts vom Verlieren.", "Words. Only words. You understand nothing of losing.", "空话。全是空话。你根本不懂失去。"),
              {"run": "wusheng_battle"}]},
]
E["crane_song"] = [
    {"music": "tone_returns"},
    say("narrator", "EV_CS_1", "Der Kranich hebt den Kopf, breitet die Flügel aus – und singt. Ein heller, zitternder Ton, alt und wunderschön.", "The crane raises its head, spreads its wings - and sings. A bright, trembling tone, old and beautiful.", "鹤抬起头，展开双翅——唱了起来。一个明亮、颤抖的音，古老而美丽。"),
    say("wusheng", "EV_CS_2", "… Du hast es die ganze Zeit gewusst. Du wolltest gehen, und hast nur für mich geschwiegen.", "... You knew all along. You wanted to go, and you only kept silent for me.", "……你一直都知道。你想走，只是为了我才保持沉默。"),
    say("wusheng", "EV_CS_3", "Ich lasse dich gehen, alter Freund. Danke für jedes Lied.", "I let you go, old friend. Thank you for every song.", "我放你走，老朋友。谢谢你唱过的每一首歌。"),
    {"set": "wusheng_resolved"},
    {"count": "order_convinced"},
    {"run": "finale_nian"},
]
E["wusheng_battle"] = [
    say("wusheng", "EV_WB_1", "Dann zwinge mich, Kind des Windspiels!", "Then force me, child of the wind chime!", "那就来逼我吧，风铃之子！"),
    {"battle": {"enemies": [{"id": "steinloewe", "level": 34, "role": "silenced", "scale": 1}, {"id": "nebelbueffel", "level": 33, "role": "silenced", "scale": 0},
                            {"id": "firnleopard", "level": 33, "role": "silenced", "scale": 0}],
                "active": 2, "foe": "wusheng", "music": "finale", "bg": "phoenix_temple", "coins": 500},
     "win": [say("wusheng", "EV_WB_2", "… Es ist vorbei.", "... It is over.", "……结束了。"),
             {"set": "wusheng_defeated"}, {"set": "wusheng_resolved"}, {"count": "order_fought"},
             {"run": "finale_nian"}]},
]
E["finale_nian"] = [
    {"heal": True},
    say("narrator", "EV_FN_1", "Da bebt die Asche im Nest. Aus den Schatten zwischen den Säulen kriecht etwas Riesiges, Zotteliges. Der Nian – größer als in Weidendorf.",
        "Then the ashes in the nest tremble. Out of the shadows between the pillars crawls something huge and shaggy. The Nian - bigger than in Willowdale.",
        "巢里的灰烬颤动起来。从柱子间的阴影里，爬出一个巨大的、毛茸茸的东西。年兽——比在柳村时更大了。"),
    say("nian", "EV_FN_2", "So viel Stille hier oben … ein ganzes Jahr lang habe ich gefressen. Das Lied bekommt ihr nicht!", "So much silence up here... I have been feeding for a whole year. You won't get the song!", "这上面这么安静……我吃了整整一年。你们别想得到那首歌！"),
    {"if": "yao_returned", "then": [say("yao_ally", "EV_FN_YAO", "Trommeln, {player}! Ich hab meine dabei!", "Drums, {player}! I brought mine!", "打鼓，{player}！我带着我的鼓呢！")]},
    say("narrator", "EV_FN_TUT", "Der letzte Kampf! Halte dem Nian Trommel, Feuerwerk und Banner entgegen, um ihn zu schwächen und zu vertreiben.", "The last battle! Hold up the drum, firecrackers and banner against the Nian to weaken it and drive it off.", "最后一战！对年兽举起鼓、鞭炮和红幡，削弱它、赶走它。"),
    {"battle": {"enemies": [{"id": "nian", "level": 36, "scale": 2}, {"id": "schattenmotte", "level": 30, "scale": -3}, {"id": "schattenmotte", "level": 30, "scale": -3}],
                "active": 2, "music": "finale", "bg": "phoenix_temple", "no_join": True},
     "win": [{"run": "rebirth"}],
     "lose": [say("jinli", "EV_FN_LOSE", "Miau … (Jinli leckt dir die Hand. Noch einmal. Ihr schafft das.)", "Mew... (Jinli licks your hand. Once more. You can do this.)", "喵……（锦鲤舔了舔你的手。再来一次。你们能行的。）")]},
]
E["rebirth"] = [
    {"set": "finale_done"},
    {"music": "tone_returns"},
    say("narrator", "EV_RB_1", "Der Nian flieht heulend in die Wolken. Stille – aber eine andere Stille. Eine, die wartet.", "The Nian flees howling into the clouds. Silence - but a different silence. One that waits.", "年兽嚎叫着逃进了云里。寂静——但这是另一种寂静。一种在等待的寂静。"),
    {"sfx": "bell"},
    say("jinli", "EV_RB_2", "Miau! (Jinlis Koi-Glöckchen klingt. Und dann, eins nach dem anderen, erklingen die fünf Töne: Jue, Yu, Zhi, Shang, Gong.)", "Mew! (Jinli's koi bell rings. And then, one after another, the five tones sound: Jue, Yu, Zhi, Shang, Gong.)", "喵！（锦鲤的锦鲤铃响了。接着，五音一个接一个地响起：角、羽、徵、商、宫。）"),
    {"ending": True},
]
for kind, lines in [
    ("reconcile", [
        ("EV_END_R1", "Wusheng hält den Kranich ein letztes Mal im Arm. Dann fliegt der alte Vogel singend in das Nest – und die Asche fängt Feuer.", "Wusheng holds the crane in his arms one last time. Then the old bird flies singing into the nest - and the ashes catch fire.", "无声最后一次把鹤抱在怀里。然后，老鹤唱着歌飞进了巢中——灰烬燃了起来。"),
        ("EV_END_R2", "Aus den Flammen steigt der Phönix, in allen fünf Farben. Sein Lied trägt über das ganze Wolkenmeer. Wusheng weint – und lächelt.", "Out of the flames rises the phoenix, in all five colours. Its song carries over the whole sea of clouds. Wusheng weeps - and smiles.", "凤凰从火焰中升起，五彩斑斓。它的歌声传遍整个云海。无声流着泪——笑了。"),
    ]),
    ("victory", [
        ("EV_END_V1", "Wusheng steht reglos, als die Asche Feuer fängt. Der Kranich fliegt nicht ins Feuer. Er folgt Wusheng, der wortlos die Wolkentreppe hinabsteigt.", "Wusheng stands motionless as the ashes catch fire. The crane does not fly into the fire. It follows Wusheng, who descends the cloud stairs without a word.", "灰烬燃起时，无声一动不动。鹤没有飞进火里。它跟着一言不发的无声，走下了云梯。"),
        ("EV_END_V2", "Aus den Flammen steigt der Phönix, in allen fünf Farben. Sein Lied trägt über das Wolkenmeer – nur hinter Wusheng bleibt es leise.", "Out of the flames rises the phoenix, in all five colours. Its song carries over the sea of clouds - only behind Wusheng does it stay quiet.", "凤凰从火焰中升起，五彩斑斓。它的歌声传遍云海——只有无声身后依旧安静。"),
    ]),
    ("bitter", [
        ("EV_END_B1", "Die Asche fängt Feuer, und der Phönix steigt auf. Doch sein Lied klingt dünn, als fehle ihm eine Stimme.", "The ashes catch fire, and the phoenix rises. But its song sounds thin, as if a voice were missing.", "灰烬燃起，凤凰升空。可它的歌声单薄，好像缺了一个声音。"),
        ("EV_END_B2", "Zu viele Verstummte wurden besiegt statt befreit. Im Westen, über den Singenden Dünen, bleibt es still.", "Too many of the silenced were defeated instead of freed. In the west, over the Singing Dunes, it stays silent.", "太多失声的灵兽被打败而不是被解放。西边的鸣沙丘上，依旧一片寂静。"),
    ]),
]:
    steps = [say("narrator", k, de, en, zh) for k, de, en, zh in lines]
    if kind == "bitter":
        steps.append({"set": "bitter_dunes"})
    E["ending_" + kind] = steps + [{"run": "phoenix_joins"}]
E["phoenix_joins"] = [
    {"phoenix_rise": [14.5, 4]},
    {"set": "phoenix_reborn"},
    {"refresh": True},
    {"voice": "fenghuang", "event": "freed"},
    say("fenghuang", "EV_PJ_1", "Jedes Ende ist ein Lied, das neu beginnt. Ich danke dir, {player}. Lass mich das zwölfte Glöckchen an deinem Windspiel sein.",
        "Every ending is a song that begins anew. I thank you, {player}. Let me be the twelfth bell on your wind chime.",
        "每一次结束，都是一首重新开始的歌。谢谢你，{player}。让我成为你风铃上的第十二只铃铛吧。"),
    {"bells": 12},
    {"give_lingshou": "fenghuang", "level": 40, "bond": 80},
    {"count": "freed"},
    say("meister_temple", "EV_PJ_2", "{player}! Ich bin die Treppe hinaufgestiegen, so schnell meine alten Beine konnten. Hör nur – das ganze Land singt.", "{player}! I climbed the stairs as fast as my old legs could. Just listen - the whole land is singing.", "{player}！我拼了这把老骨头，尽快爬上了云梯。听啊——整片大地都在歌唱。"),
    {"music": "ending"},
    {"credits": True},
    {"if": "bitter_dunes",
     "then": [quest("QUEST_POST_BITTER", "Die Singenden Dünen schweigen noch. Befreie Baihu am Singenden Kamm ein zweites Mal – diesmal mit dem Herzen.", "The Singing Dunes are still silent. Free Baihu at the Singing Crest a second time - this time with your heart.", "鸣沙丘依旧沉默。再去鸣沙脊解放白虎一次——这次用你的心。"),
              {"goal": ["singender_kamm", 13, 8]}],
     "else": [quest("QUEST_POST", "Das Lied des Phönix klingt wieder. Erkunde Yunhai, zähme und züchte Lingshou, bau deinen Hof aus.", "The Song of the Phoenix rings again. Explore Yunhai, tame and breed Lingshou, build up your farm.", "凤凰之歌再次响起。去探索云海、驯服和繁育灵兽、扩建你的农庄吧。")]},
    {"save": True},
]
hints("POST_BITTER", ["Miau. (Jinli schaut nach Westen, zu den stillen Dünen.)", "Miau, miau! (Zum Singenden Kamm hinter Mondquell.)", "Miaaau! (Baihu liegt wieder grau auf dem Kamm. Sprich ihm Mut zu, statt ihn zu besiegen.)"],
      ["Mew. (Jinli looks west, towards the silent dunes.)", "Mew, mew! (To the Singing Crest behind Moonspring.)", "Meeew! (Baihu lies grey on the crest again. Give him courage instead of defeating him.)"],
      ["喵。（锦鲤望向西边沉默的沙丘。）", "喵喵！（去月泉镇后面的鸣沙脊。）", "喵——！（白虎又灰扑扑地躺在沙脊上了。给它打气，而不是打败它。）"])
hints("POST", ["Miau! (Jinli schnurrt zufrieden.)", "Miau. (Jinli rollt sich in der Sonne zusammen. Auf dem Hof warten die Lingshou.)", "Miaaau. (Hast du schon alle Lingshou im Lexikon? Manche schlüpfen nur auf dem Hof.)"],
      ["Mew! (Jinli purrs happily.)", "Mew. (Jinli curls up in the sun. The Lingshou wait on the farm.)", "Meeew. (Do you have every Lingshou in the bestiary yet? Some only hatch on the farm.)"],
      ["喵！（锦鲤满足地打着呼噜。）", "喵。（锦鲤在阳光下蜷成一团。农庄里的灵兽在等你。）", "喵——。（图鉴里的灵兽都集齐了吗？有些只能在农庄孵化。）"])
E["bitter_dunes_free"] = [
    say("narrator", "EV_BDF_1", "Baihu liegt wieder grau im Sand. Die Stille der Besiegten hat sich über ihn gelegt.", "Baihu lies grey in the sand again. The silence of the defeated has settled over him.", "白虎又灰扑扑地躺在沙里。被打败者的寂静笼罩着它。"),
    {"battle": {"enemies": [{"id": "baihu", "level": 40, "role": "silenced", "scale": 0}], "active": 1, "music": "boss", "bg": "dunes", "no_join": True},
     "freed": [{"set": "bitter_dunes", "value": False}, {"refresh": True},
               say("narrator", "EV_BDF_2", "Die Dünen beginnen zu singen. Jetzt klingt das Lied des Phönix vollständig.", "The dunes begin to sing. Now the Song of the Phoenix is complete.", "沙丘开始歌唱。现在，凤凰之歌终于完整了。"),
               quest("QUEST_POST", "Das Lied des Phönix klingt wieder. Erkunde Yunhai, zähme und züchte Lingshou, bau deinen Hof aus.", "The Song of the Phoenix rings again. Explore Yunhai, tame and breed Lingshou, build up your farm.", "凤凰之歌再次响起。去探索云海、驯服和繁育灵兽、扩建你的农庄吧。")],
     "win": [say("narrator", "EV_BDF_3", "Baihu sinkt nieder, die Dünen bleiben stumm. Mit Gewalt geht es nicht.", "Baihu sinks down, the dunes stay mute. Force won't do it.", "白虎倒下了，沙丘依旧无声。用武力是不行的。")]},
]
E["meister_temple"] = [say("meister_temple", "EV_MT", "Ich baue dir ein neues Windspiel, {player}. Mit zwölf Glöckchen.", "I'll build you a new wind chime, {player}. With twelve bells.", "我给你做一只新风铃，{player}。挂十二只铃铛。")]
E["wusheng_after"] = [say("wusheng_after", "EV_WA", "Ich höre ihn noch, wenn der Wind durch die Säulen geht. Danke, Kind des Windspiels.", "I still hear him when the wind passes through the pillars. Thank you, child of the wind chime.", "风吹过石柱的时候，我还能听见他。谢谢你，风铃之子。")]
