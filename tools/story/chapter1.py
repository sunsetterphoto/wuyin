#!/usr/bin/env python3
"""Chapter 1 of the beta: events (game/data/events/chapter1.json), people
(game/data/npcs.json) and every story text in en/de/zh-Hans
(game/data/i18n/story.csv). Text sits next to the event that uses it; the
game itself only reads the generated JSON and CSV (rule 4).

  python3 tools/story/chapter1.py
"""
import csv, json, os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "data")
TEXT = {}  # key -> (en, de, zh)


def t(key, de, en, zh):
    assert key not in TEXT or TEXT[key] == (en, de, zh), "duplicate key with other text: " + key
    TEXT[key] = (en, de, zh)
    return key


def say(speaker, key, de, en, zh):
    return {"say": speaker, "text": t(key, de, en, zh)}


def quest(key, de, en, zh):
    return {"quest": t(key, de, en, zh)}


def hints(name, de, en, zh):
    for i in range(3):
        t(f"HINT_{name}_{i}", de[i], en[i], zh[i])


def choice(options, branches):
    return {"choice": [t(*o) for o in options], "then": branches}


# --- people ---------------------------------------------------------------------
NPCS = {
    "meister": ("Meister Lu", "Master Lu", "卢师傅", "gong", "gentle", -1),
    "meister_plaza": ("Meister Lu", "Master Lu", "卢师傅", "gong", "gentle", -1),
    "meister_mute": ("Meister Lu", "Master Lu", "卢师傅", "gong", "gentle", -1),
    "yao": ("Yao", "Yao", "尧", "zhi", "brave", 0),
    "wusheng": ("Wusheng", "Wusheng", "无声", "shang", "stubborn", -1),
    "dorf_frau": ("Frau Fang", "Mrs Fang", "方大婶", "yu", "gentle", 1),
    "dorf_kind": ("Kleiner Bo", "Little Bo", "小波", "jue", "playful", 1),
    "dorf_oma": ("Oma Hu", "Granny Hu", "胡奶奶", "gong", "gentle", 0),
    "wirtin": ("Wirtin Su", "Innkeeper Su", "苏老板娘", "yu", "gentle", 0),
    "haendler": ("Händler Gao", "Merchant Gao", "高掌柜", "zhi", "playful", 0),
    "teemeister": ("Teemeister Chen", "Tea Master Chen", "陈茶师", "gong", "gentle", -1),
    "stille_frau": ("Frau Ning", "Mrs Ning", "宁夫人", "yu", "moody", 0),
    "teeufer_kind": ("Ah Tao", "Ah Tao", "阿桃", "jue", "playful", 1),
    "pilger": ("Pilger Wen", "Pilgrim Wen", "文香客", "jue", "gentle", 0),
    "moench": ("Mönch Huan", "Monk Huan", "幻和尚", "shang", "gentle", -1),
    "qinglong_free": ("Azurdrache", "Azure Dragon", "青龙", "jue", "gentle", -1),
    "jinli": ("Jinli", "Jinli", "锦鲤", "yu", "playful", 1),
}
npcs = {}
for nid, (de, en, zh, tone, style, octave) in NPCS.items():
    key = "NPC_" + nid.upper()
    t(key, de, en, zh)
    npcs[nid] = {"name": key, "voice": {"tone": tone, "style": style, "octave": octave}}

E = {}

# --- UI / system texts used by the beta --------------------------------------
for k, de, en, zh in [
    ("TITLE_SUBTITLE", "Das Lied des Phönix", "Song of the Phoenix", "凤凰之歌"),
    ("TITLE_CONTINUE", "Weiterspielen", "Continue", "继续游戏"),
    ("TITLE_NEW", "Neues Spiel", "New game", "新游戏"),
    ("TITLE_LLM_ON", "Sprachmodell aktiv", "language model on", "语言模型已启用"),
    ("TITLE_LLM_OFF", "ohne Sprachmodell (Vorlagen)", "no language model (templates)", "未启用语言模型（模板）"),
    ("NEW_TITLE", "Wer bist du?", "Who are you?", "你是谁？"),
    ("NEW_NAME", "Dein Name", "Your name", "你的名字"),
    ("NEW_DEFAULT_NAME", "Lian", "Lian", "莲"),
    ("NEW_HAIR", "Haarfarbe", "Hair colour", "发色"),
    ("NEW_OUTFIT", "Kleidung", "Clothes", "衣服"),
    ("NEW_START", "Los geht's", "Let's go", "出发"),
    ("NEW_OVERWRITE", "Achtung: Der alte Spielstand wird überschrieben.", "Note: this replaces your saved game.", "注意：旧存档将被覆盖。"),
    ("MENU_TITLE", "Menü", "Menu", "菜单"),
    ("MENU_PARTY", "Gefolge", "Companions", "同伴"),
    ("MENU_BAG", "Beutel", "Bag", "背包"),
    ("MENU_OPTIONS", "Optionen", "Options", "设置"),
    ("MENU_SAVE", "Speichern", "Save", "存档"),
    ("MENU_FEEDBACK", "Beta bewerten", "Rate the beta", "评价测试版"),
    ("MENU_TO_TITLE", "Zum Titel", "To title", "返回标题"),
    ("MENU_FARM_NOTE", "Auf deinem Hof in Weidendorf leben {n} weitere Lingshou. Tauschen kannst du am Windspiel-Schrein jeder Unterkunft.",
     "{n} more Lingshou live on your farm in Willowdale. Swap them at the wind chime shrine of any inn.",
     "还有{n}只灵兽住在柳村的农庄里。可以在任何客栈的风铃神龛交换。"),
    ("UI_COINS", "Münzen", "coins", "铜钱"),
    ("UI_BELLS", "Glöckchen", "Bells", "铃铛"),
    ("UI_HP", "Kraft", "HP", "体力"),
    ("UI_BOND", "Bindung", "Bond", "羁绊"),
    ("UI_XP", "EP", "XP", "经验"),
    ("UI_USE", "Benutzen", "Use", "使用"),
    ("UI_OWNED", "im Beutel", "owned", "持有"),
    ("UI_CONTINUE", "Weiter", "Continue", "继续"),
    ("UI_REPORT", "Melden", "Report", "举报"),
    ("UI_REPORTED", "Gemeldet, danke", "Reported, thanks", "已举报，谢谢"),
    ("MSG_SAVED", "Gespeichert.", "Saved.", "已存档。"),
    ("MSG_SAVE_FAILED", "Speichern fehlgeschlagen.", "Saving failed.", "存档失败。"),
    ("MSG_GOT_ITEM", "Du erhältst {n}× {item}.", "You receive {n}× {item}.", "获得{item}×{n}。"),
    ("MSG_GOT_COINS", "Du erhältst {n} Münzen.", "You receive {n} coins.", "获得{n}铜钱。"),
    ("MSG_NEW_BELL", "Am Windspiel hängt jetzt ein Glöckchen mehr. ({n} Glöckchen)", "A new bell hangs on the wind chime. ({n} bells)", "风铃上多了一只铃铛。（共{n}只）"),
    ("MSG_JOINED", "{name} folgt dir jetzt!", "{name} follows you now!", "{name}开始跟随你了！"),
    ("MSG_TO_FARM", "Kein Glöckchen ist frei – {name} wartet auf deinem Hof in Weidendorf.", "No bell is free - {name} waits on your farm in Willowdale.", "没有空余的铃铛——{name}会在柳村的农庄等你。"),
    ("MSG_FREED_JOINS", "{name} hat sich entschieden, dir zu folgen.", "{name} has decided to follow you.", "{name}决定跟随你。"),
    ("MSG_DEFEAT", "Alles wurde schwarz … Du wachst in deiner Unterkunft auf. {coins} Münzen sind weg. Jinli liegt neben dir und schnurrt.",
     "Everything went dark... You wake up at your lodging. {coins} coins are gone. Jinli lies beside you, purring.",
     "眼前一黑……你在住处醒来，丢了{coins}铜钱。锦鲤趴在你身边打着呼噜。"),
    ("SHOP_TITLE", "Laden", "Shop", "商店"),
    ("SHOP_BOUGHT", "{item} gekauft.", "Bought {item}.", "买下了{item}。"),
    ("SHOP_NO_MONEY", "Dafür reichen deine Münzen nicht.", "You don't have enough coins.", "铜钱不够。"),
    ("INN_TITLE", "Unterkunft", "Lodging", "住处"),
    ("INN_REST", "Ausruhen (heilen und speichern)", "Rest (heal and save)", "休息（恢复并存档）"),
    ("INN_RESTED", "Alle sind ausgeruht. Gespeichert.", "Everyone is rested. Saved.", "大家都休息好了。已存档。"),
    ("INN_SHRINE", "Windspiel-Schrein", "Wind chime shrine", "风铃神龛"),
    ("INN_SHRINE_NOTE", "Hier tauschst du Lingshou zwischen Gefolge und Hof. Glöckchen: {bells}", "Swap Lingshou between your companions and the farm. Bells: {bells}", "在这里交换同伴和农庄的灵兽。铃铛：{bells}"),
    ("INN_FARM", "Auf dem Hof", "On the farm", "在农庄"),
    ("INN_TO_FARM", "Zum Hof", "To farm", "送去农庄"),
    ("INN_TO_PARTY", "Mitnehmen", "Take along", "带上"),
    ("OPT_LANGUAGE", "Sprache", "Language", "语言"),
    ("OPT_LANG_SYSTEM", "System", "System", "系统"),
    ("OPT_LANG_DE", "Deutsch", "Deutsch", "Deutsch"),
    ("OPT_LANG_EN", "English", "English", "English"),
    ("OPT_LANG_ZH", "中文", "中文", "中文"),
    ("OPT_LLM", "Sprachmodell", "Language model", "语言模型"),
    ("OPT_LLM_NOTE", "Aus: Rufe, Stimmen und Hinweise kommen aus Vorlagen. Spart Akku.", "Off: calls, voices and hints use templates. Saves battery.", "关闭：呼唤、声音和提示使用模板，更省电。"),
    ("OPT_LLM_MISSING", "Keine Modelldatei gefunden – das Spiel nutzt Vorlagen.", "No model file found - the game uses templates.", "未找到模型文件——游戏使用模板。"),
    ("OPT_CAMERA", "Grafik", "Graphics", "画面"),
    ("OPT_TEXT_SPEED", "Text", "Text", "文字"),
    ("OPT_SLOW", "langsam", "slow", "慢"),
    ("OPT_NORMAL", "normal", "normal", "普通"),
    ("OPT_INSTANT", "sofort", "instant", "立即"),
    ("OPT_MUSIC", "Musik", "Music", "音乐"),
    ("OPT_QUIET", "leise", "quiet", "小声"),
    ("OPT_LOUD", "laut", "loud", "大声"),
    ("OPT_BIG_TEXT", "Große Schrift", "Large text", "大字体"),
    ("OPT_ON", "an", "on", "开"),
    ("OPT_OFF", "aus", "off", "关"),
    ("FB_TITLE", "Beta bewerten", "Rate the beta", "评价测试版"),
    ("FB_INTRO", "Wie gefällt dir die Beta bisher? 1 Stern = gar nicht, 5 = sehr. Leer lassen ist okay. Alles bleibt auf dem Gerät.",
     "How do you like the beta so far? 1 star = not at all, 5 = a lot. Leaving rows empty is fine. Everything stays on the device.",
     "你觉得测试版怎么样？1星=很不喜欢，5星=非常喜欢。可以留空。所有内容只保存在设备上。"),
    ("FB_OVERALL", "Gesamteindruck", "Overall", "总体"),
    ("FB_CALLS", "Ruf (Freitext im Kampf)", "Calls (free text in battle)", "呼唤（战斗自由输入）"),
    ("FB_TAMING", "Zähmen und Befreien", "Taming and freeing", "驯服与解放"),
    ("FB_BATTLES", "Kämpfe", "Battles", "战斗"),
    ("FB_STORY", "Geschichte und Figuren", "Story and characters", "故事与角色"),
    ("FB_GRAPHICS", "Grafik", "Graphics", "画面"),
    ("FB_MUSIC", "Musik und Klang", "Music and sound", "音乐与音效"),
    ("FB_CONTROLS", "Steuerung", "Controls", "操作"),
    ("FB_SPEED", "Tempo und Wartezeiten", "Pace and waiting times", "节奏与等待时间"),
    ("FB_COMMENT", "Was war gut, was hat gestört?", "What was good, what bothered you?", "哪里好？哪里不好？"),
    ("FB_COMMENT_PLACEHOLDER", "Dein Kommentar …", "Your comment...", "你的意见……"),
    ("FB_SEND", "Speichern", "Save", "保存"),
    ("FB_THANKS", "Danke! Deine Bewertung ist gespeichert.", "Thank you! Your rating is saved.", "谢谢！你的评价已保存。"),
    ("END_TITLE", "Ende der Beta", "End of the beta", "测试版结束"),
    ("END_TEXT", "Der erste Ton ist zurück – das Bambusmeer singt wieder. Hier endet die Beta von Wuyin. Danke fürs Spielen! Du kannst weiter herumlaufen, zähmen und kämpfen.",
     "The first tone is back - the Bamboo Sea sings again. This is where the Wuyin beta ends. Thank you for playing! You can keep exploring, taming and battling.",
     "第一个音回来了——竹海再次歌唱。五音测试版到此结束。感谢游玩！你可以继续探索、驯服和战斗。"),
    ("END_STATS", "Spielzeit {time} · {battles} Kämpfe · {tamed} gezähmt · {freed} befreit · {calls} Rufe · {party} Lingshou",
     "Play time {time} · {battles} battles · {tamed} tamed · {freed} freed · {calls} calls · {party} Lingshou",
     "游戏时间{time} · 战斗{battles}次 · 驯服{tamed} · 解放{freed} · 呼唤{calls}次 · 灵兽{party}只"),
    ("END_RATE", "Jetzt bewerten", "Rate now", "现在评价"),
    ("END_CONTINUE", "Weiterspielen", "Keep playing", "继续游玩"),
    ("MAP_WEIDENDORF", "Weidendorf", "Willowdale", "柳村"),
    ("MAP_FLUSSUFER", "Flussufer", "Riverbank", "河岸"),
    ("MAP_BAMBUSPFAD", "Bambuspfad", "Bamboo Path", "竹径"),
    ("MAP_TEEUFER", "Teeufer", "Teabank", "茶岸镇"),
    ("MAP_REISTERRASSEN", "Reisterrassen", "Rice Terraces", "稻田梯"),
    ("MAP_DRACHENSCHREIN", "Drachenschrein", "Dragon Shrine", "龙祠"),
    ("TEMPERAMENT_BRAVE", "mutig", "brave", "勇敢"),
    ("TEMPERAMENT_ANXIOUS", "ängstlich", "anxious", "胆小"),
    ("TEMPERAMENT_STUBBORN", "stur", "stubborn", "倔强"),
    ("TEMPERAMENT_PLAYFUL", "verspielt", "playful", "顽皮"),
    ("TEMPERAMENT_GENTLE", "sanft", "gentle", "温和"),
    ("TEMPERAMENT_MOODY", "launisch", "moody", "多变"),
    ("TONE_SOOTHING", "beruhigend", "soothing", "安抚"),
    ("TONE_ENCOURAGING", "ermutigend", "encouraging", "鼓励"),
    ("TONE_PLAYFUL", "verspielt", "playful", "玩闹"),
    ("TONE_RESPECTFUL", "respektvoll", "respectful", "尊重"),
    ("TONE_PRAISING", "lobend", "praising", "称赞"),
    ("TONE_RUDE", "grob", "rude", "粗鲁"),
    ("TONE_NEUTRAL", "neutral", "neutral", "平淡"),
    ("BATTLE_TAB_ATTACK", "Attacken", "Moves", "招式"),
    ("BATTLE_TAB_CALL", "Ruf", "Call", "呼唤"),
    ("BATTLE_TAB_TAME", "Zähmen", "Befriend", "驯服"),
    ("BATTLE_TAB_FREE", "Befreien", "Free", "解放"),
    ("BATTLE_TAB_BAG", "Beutel", "Bag", "背包"),
    ("BATTLE_TAB_SWITCH", "Wechseln", "Switch", "替换"),
    ("BATTLE_TAB_FLEE", "Ausweichen", "Run", "逃跑"),
    ("BATTLE_FLEE_CONFIRM", "Ausweichen und gehen", "Step back and leave", "退开离去"),
    ("BATTLE_FLED", "Du weichst aus und gehst weiter.", "You step back and move on.", "你退开，继续前行。"),
    ("BATTLE_BAG_EMPTY", "Nichts Passendes im Beutel.", "Nothing useful in the bag.", "背包里没有合适的东西。"),
    ("BATTLE_CALM", "Beruhigen", "Calm", "安抚"),
    ("BATTLE_TALK", "Zureden", "Talk", "说话"),
    ("BATTLE_TALK_PLACEHOLDER", "Sag etwas Freundliches …", "Say something kind...", "说点友善的话……"),
    ("BATTLE_TALK_PROMPT", "Was sagst du zu {name}?", "What do you say to {name}?", "你对{name}说什么？"),
    ("BATTLE_TALK_HEARD", "Du sagst: „{text}“", "You say: \"{text}\"", "你说：“{text}”"),
    ("BATTLE_TALK_TONE", "Das klang {tone}.", "That sounded {tone}.", "听起来很{tone}。"),
    ("BATTLE_TRUST", "Vertrauen", "Trust", "信任"),
    ("BATTLE_HEART", "Herzklang", "Heartsong", "心音"),
    ("BATTLE_CALMS", "Du summst leise für {target}.", "You hum softly for {target}.", "你轻轻地为{target}哼歌。"),
    ("BATTLE_FEEDS", "Du bietest {target} {item} an.", "You offer {target} some {item}.", "你把{item}递给{target}。"),
    ("BATTLE_TALKS", "{target} hört dir zu.", "{target} listens to you.", "{target}在听你说话。"),
    ("BATTLE_TRUST_UP", "{target} kommt ein Stück näher.", "{target} comes a little closer.", "{target}靠近了一点。"),
    ("BATTLE_TRUST_DOWN", "{target} weicht zurück.", "{target} backs away.", "{target}后退了。"),
    ("BATTLE_TRUST_SAME", "{target} schaut dich nur an.", "{target} just looks at you.", "{target}只是看着你。"),
    ("BATTLE_HEART_UP", "In {target} regt sich ein leiser Klang.", "A faint sound stirs inside {target}.", "{target}心中响起微弱的声音。"),
    ("BATTLE_TAMED", "{target} vertraut dir!", "{target} trusts you!", "{target}信任你了！"),
    ("BATTLE_FREED", "Die Stille fällt von {target} ab!", "The silence falls away from {target}!", "寂静从{target}身上褪去！"),
    ("BATTLE_ITEM", "{item} für {target}.", "{item} for {target}.", "给{target}使用了{item}。"),
    ("BATTLE_REVIVE", "{target} steht wieder auf!", "{target} gets back up!", "{target}重新站了起来！"),
    ("BATTLE_WATCHES", "{user} beobachtet dich neugierig.", "{user} watches you curiously.", "{user}好奇地看着你。"),
    ("BATTLE_COINS", "Du findest {n} Münzen.", "You find {n} coins.", "你找到了{n}铜钱。"),
    ("BATTLE_NOT_POSSIBLE", "Das geht gerade nicht.", "That doesn't work right now.", "现在做不到。"),
    ("BATTLE_INTRO_WILD", "Ein wildes {name} taucht auf!", "A wild {name} appears!", "野生的{name}出现了！"),
    ("BATTLE_INTRO_SILENCED", "Ein verstummtes {name} versperrt den Weg. Fülle seinen Herzklang!", "A silenced {name} blocks the way. Fill its heartsong!", "失声的{name}挡住了去路。唤醒它的心音！"),
    ("BATTLE_INTRO_GUARDIAN", "Der {name} erhebt sich – stumm und grau.", "The {name} rises - mute and grey.", "{name}缓缓升起——无声而灰暗。"),
    ("BATTLE_INTRO_MOTH", "Eine {name} flattert heran und frisst die letzten Klänge!", "A {name} flutters close, eating the last sounds!", "{name}扑了过来，吞食着最后的声音！"),
    ("BATTLE_INTRO_FOE", "{foe} fordert dich heraus!", "{foe} challenges you!", "{foe}向你发起挑战！"),
    ("BEFRIEND_INTRO", "{name} ist scheu ({temperament}). Beruhige es, füttere es oder sprich mit ihm – greif es nicht an.",
     "{name} is shy ({temperament}). Calm it, feed it or talk to it - don't attack.",
     "{name}很怕生（{temperament}）。安抚它、喂它或者和它说话——不要攻击。"),
    ("BEFRIEND_FLED", "{name} erschrickt und huscht davon …", "{name} startles and darts away...", "{name}吓了一跳，溜走了……"),
    ("VOICE_FREED_GENERIC", "Ich … ich kann wieder sprechen. Danke.", "I... I can speak again. Thank you.", "我……我又能说话了。谢谢你。"),
    ("HINT_NONE", "Miau? (Jinli streicht dir um die Beine. Gerade ist alles gut.)", "Mew? (Jinli rubs against your legs. All is well right now.)", "喵？（锦鲤蹭了蹭你的腿。现在一切都好。）"),
]:
    t(k, de, en, zh)

# Suggested sentences for talking to Lingshou ({name} = the Lingshou).
for tone, rows in {
    "SOOTHING": [("Keine Angst, {name}. Ich tu dir nichts.", "Don't be afraid, {name}. I won't hurt you.", "别怕，{name}。我不会伤害你。"),
                 ("Ganz ruhig. Alles ist gut.", "Easy now. Everything is okay.", "放松，没事的。")],
    "ENCOURAGING": [("Komm, {name}, zusammen schaffen wir das!", "Come on, {name}, together we can do it!", "来吧{name}，我们一起加油！"),
                    ("Du bist mutig, zeig es mir!", "You're brave, show me!", "你很勇敢，让我看看！")],
    "PLAYFUL": [("Wollen wir ein Wettrennen machen?", "Want to have a race?", "我们来比赛跑步吧？"),
                ("Fang mich doch, {name}!", "Catch me if you can, {name}!", "来抓我呀，{name}！")],
    "RESPECTFUL": [("Ich warte hier. Nimm dir Zeit.", "I'll wait here. Take your time.", "我在这里等你，慢慢来。"),
                   ("Darf ich näherkommen, {name}?", "May I come closer, {name}?", "我可以靠近一点吗，{name}？")],
    "PRAISING": [("Du bist wunderschön, {name}.", "You are beautiful, {name}.", "你真漂亮，{name}。"),
                 ("Was für ein starkes Lingshou!", "What a strong Lingshou!", "多么强大的灵兽！")],
}.items():
    for i, (de, en, zh) in enumerate(rows):
        t(f"TALK_{tone}_{i}", de, en, zh)

# Rumours (templates; the model may retell them from facts).
t("RUMOR_0", "Man sagt, der Azurdrache über den Reisterrassen habe aufgehört zu singen. Seitdem wächst kein neuer Bambus mehr.",
  "They say the Azure Dragon above the rice terraces stopped singing. Since then, no new bamboo grows.",
  "听说稻田梯上的青龙不再歌唱了。从那以后，竹子再也没长新芽。")
t("RUMOR_1", "Auf den Reisterrassen flattern Schattenmotten. Sie fressen jeden Klang – sogar das Quaken der Reisfrösche.",
  "Shadow moths flutter over the rice terraces. They eat every sound - even the croaking of the paddy frogs.",
  "稻田梯上飞着影蛾，它们吞食一切声音——连稻田蛙的呱呱声也不放过。")
t("RUMOR_2", "Ein Schneeleopard sitzt verstummt am Pass zum Schrein. Wer ihn befreien will, braucht freundliche Worte, nicht nur Kraft.",
  "A snow leopard sits silenced at the pass to the shrine. Whoever wants to free it needs kind words, not only strength.",
  "一只失声的雪豹守在通往龙祠的山口。想解放它，需要温柔的话语，而不只是力量。")
# Voices for freed / spoken Lingshou in events (templates).
t("VOICE_QINGLONG_FREED", "Mein Lied … es ist wieder in mir. Ich danke dir, kleiner Mensch mit dem Windspiel.",
  "My song... it is in me again. I thank you, little one with the wind chime.",
  "我的歌……又回到了我心中。谢谢你，带着风铃的小家伙。")

# --- Prologue: Weidendorf -------------------------------------------------------
E["intro"] = [
    {"music": "village"},
    say("narrator", "EV_INTRO_1", "Weidendorf im Bambusmeer, am Abend des Laternenfests. Einmal alle fünfhundert Jahre singt das ganze Land das Lied des Phönix.",
        "Willowdale in the Bamboo Sea, on the evening of the Lantern Festival. Once every five hundred years, the whole land sings the Song of the Phoenix.",
        "竹海中的柳村，元宵灯会之夜。每隔五百年，整片大地都会唱起凤凰之歌。"),
    say("narrator", "EV_INTRO_2", "Du bist {player}, Lehrling des alten Windspielmachers. Und das ist Jinli, deine kleine dreifarbige Katze.",
        "You are {player}, apprentice of the old wind chime maker. And this is Jinli, your little tortoiseshell cat.",
        "你是{player}，老风铃匠的学徒。这是锦鲤，你的三花小猫。"),
    {"set": "jinli_follows"},
    {"sfx": "meow"},
    say("jinli", "EV_INTRO_3", "Miau! (Jinli springt von der Fensterbank und läuft dir voraus.)", "Mew! (Jinli hops off the windowsill and runs ahead of you.)", "喵！（锦鲤从窗台跳下，跑在你前面。）"),
    say("meister", "EV_INTRO_4", "{player}! Da bist du ja. Komm zur Werkstatt, ich habe etwas für dich – bevor das Fest beginnt.",
        "{player}! There you are. Come to the workshop, I have something for you - before the festival begins.",
        "{player}！你来啦。到作坊来，节日开始前我有东西要给你。"),
    say("narrator", "EV_INTRO_TUT", "Laufen: linke Bildschirmhälfte gedrückt halten und ziehen. Sprechen: A. Menü: ☰ oben rechts.",
        "Walk: hold and drag on the left half of the screen. Talk: A. Menu: ☰ at the top right.",
        "移动：按住屏幕左半边拖动。对话：A。菜单：右上角的☰。"),
    {"set": "intro_done"},
    quest("QUEST_MEISTER", "Geh zur Werkstatt von Meister Lu.", "Go to Master Lu's workshop.", "去卢师傅的作坊。"),
    {"goal": ["weidendorf", 15, 5]},
    {"set_inn": ["weidendorf", "home"]},
    {"save": True},
]
hints("MEISTER", ["Miau! (Jinli schaut zur roten Werkstatt.)", "Miau, miau! (Jinli trippelt zur roten Werkstatt oben in der Mitte des Dorfs.)",
                  "Miaaau! (Die rote Werkstatt mit dem Windspiel, oben in der Dorfmitte. Meister Lu wartet vor der Tür.)"],
      ["Mew! (Jinli looks at the red workshop.)", "Mew, mew! (Jinli trots towards the red workshop at the top middle of the village.)",
       "Meeew! (The red workshop with the wind chime, top middle of the village. Master Lu waits at the door.)"],
      ["喵！（锦鲤望向红色的作坊。）", "喵喵！（锦鲤朝村子上方中间的红色作坊小跑过去。）", "喵——！（村子上方中间那座挂着风铃的红色作坊，卢师傅在门口等你。）"])

E["meister_gift"] = [
    say("meister", "EV_GIFT_1", "Heute Nacht hängen wir das Windspiel des Phönixtempels am Festplatz auf. Ich bin zu alt, es zu tragen. Nimm du es.",
        "Tonight we hang the wind chime of the Phoenix Temple on the festival square. I'm too old to carry it. You take it.",
        "今晚我们要把凤凰庙的风铃挂到节日广场上。我老了，拿不动了。你来拿吧。"),
    {"sfx": "bell"},
    say("narrator", "EV_GIFT_2", "Du erhältst das Windspiel. Zwei kleine Glöckchen hängen daran.", "You receive the wind chime. Two small bells hang from it.", "你得到了风铃，上面挂着两只小铃铛。"),
    say("meister", "EV_GIFT_3", "Jedes Glöckchen erlaubt einem Lingshou, dir zu folgen. Nicht weil du es fängst – weil es dir vertraut. Vergiss das nie.",
        "Each bell allows one Lingshou to follow you. Not because you catch it - because it trusts you. Never forget that.",
        "每只铃铛都能让一只灵兽跟随你。不是因为你抓住了它，而是因为它信任你。永远别忘了。"),
    say("meister", "EV_GIFT_4", "Geh schon vor zum Festplatz. Ich komme nach.", "Go ahead to the festival square. I'll follow.", "你先去节日广场吧，我随后就来。"),
    {"set": "has_fengling"},
    quest("QUEST_FESTIVAL", "Bring das Windspiel zum Festplatz.", "Bring the wind chime to the festival square.", "把风铃带到节日广场。"),
    {"goal": ["weidendorf", 16, 9]},
]
hints("FESTIVAL", ["Miau! (Jinli schaut zu den vielen Laternen.)", "Miau! (Jinli läuft zum großen Platz mit dem Brunnen.)", "Miaaau! (Zum Festplatz mit dem Brunnen in der Mitte des Dorfs, direkt unter der Werkstatt.)"],
      ["Mew! (Jinli looks at all the lanterns.)", "Mew! (Jinli runs towards the big square with the well.)", "Meeew! (To the festival square with the well, in the middle of the village, just below the workshop.)"],
      ["喵！（锦鲤看着满街的灯笼。）", "喵！（锦鲤跑向有水井的大广场。）", "喵——！（去村子中间、作坊下面那个有水井的节日广场。）"])

E["work_door"] = [
    {"if": "voice_taken", "then": [say("narrator", "EV_WORK_MUTE", "In der Werkstatt ist es still. Kein einziges Windspiel klingt.", "The workshop is silent. Not a single wind chime rings.", "作坊里一片寂静，没有一只风铃在响。")],
     "else": [say("narrator", "EV_WORK", "Die Werkstatt riecht nach Bambus und Lack. Überall hängen halbfertige Windspiele.", "The workshop smells of bamboo and lacquer. Half-finished wind chimes hang everywhere.", "作坊里弥漫着竹子和漆的味道，到处挂着做了一半的风铃。")]},
]
E["home_door"] = [
    say("narrator", "EV_HOME", "Dein Zuhause. Ein Bett, eine Kochstelle und Jinlis Lieblingskissen.", "Your home. A bed, a stove and Jinli's favourite cushion.", "你的家。一张床、一个灶台，还有锦鲤最爱的垫子。"),
    {"set_inn": ["weidendorf", "home"]},
    {"inn": True},
]
E["meister_plaza"] = [say("meister_plaza", "EV_MEISTER_PLAZA", "Gleich beginnt das Lied. Häng das Windspiel an den Festbaum am Brunnen, {player}.", "The song is about to begin. Hang the wind chime on the festival tree by the well, {player}.", "歌马上就要开始了。{player}，把风铃挂到井边的节日树上。")]
E["festival_chime"] = [
    {"if": "silence_fell", "then": [say("narrator", "EV_CHIME_SILENT", "Das Windspiel hängt am Festbaum. Es bewegt sich im Wind – aber es klingt nicht.", "The wind chime hangs on the festival tree. It moves in the wind - but makes no sound.", "风铃挂在节日树上，随风摆动——却没有一点声音。")],
     "else": [say("narrator", "EV_CHIME", "Der Festbaum am Brunnen, voller roter Bänder.", "The festival tree by the well, full of red ribbons.", "井边的节日树，挂满了红丝带。")]},
]
E["yao_festival"] = [
    say("yao", "EV_YAO_FEST_1", "He, {player}. Du darfst das Windspiel tragen? Na toll.", "Hey, {player}. They let you carry the wind chime? Great.", "嘿，{player}。他们让你拿风铃？真行。"),
    say("yao", "EV_YAO_FEST_2", "Weißt du, was ich am Lied des Phönix hasse? Danach ist alles anders. Altes geht, Neues kommt. Als ob das so einfach wäre.",
        "You know what I hate about the Song of the Phoenix? Afterwards everything is different. The old goes, the new comes. As if it were that easy.",
        "你知道我讨厌凤凰之歌哪一点吗？唱完以后一切都变了。旧的离开，新的到来。说得好像很容易似的。"),
]
E["dorf_frau"] = [
    {"if": "voice_taken", "then": [say("dorf_frau", "EV_FRAU_3", "Meister Lu sitzt nur noch vor seiner Werkstatt und starrt auf seine Hände. Bring ihm sein Lied zurück, {player}.", "Master Lu just sits in front of his workshop, staring at his hands. Bring back his song, {player}.", "卢师傅只是坐在作坊前，盯着自己的手。{player}，把他的歌找回来吧。")],
     "else": [{"if": "silence_fell", "then": [say("dorf_frau", "EV_FRAU_2", "Ich höre nicht einmal mehr mein eigenes Herz … Was ist nur passiert?", "I can't even hear my own heart anymore... What happened?", "我连自己的心跳都听不见了……到底发生了什么？")],
               "else": [say("dorf_frau", "EV_FRAU_1", "Riechst du die Mondkuchen? Wenn das Lied vorbei ist, gibt es für jeden einen!", "Can you smell the mooncakes? When the song is over, there's one for everyone!", "闻到月饼的香味了吗？歌唱完了每人一个！")]}]},
]
E["dorf_kind"] = [
    {"if": "silence_fell", "then": [say("dorf_kind", "EV_KIND_2", "Meine Trommel macht keinen Ton mehr! Hast du sie kaputt gemacht?", "My drum doesn't make a sound anymore! Did you break it?", "我的鼓不响了！是你弄坏的吗？")],
     "else": [say("dorf_kind", "EV_KIND_1", "Bumm-bumm! Ich trommel beim Lied mit! Der Nian hat Angst vor Trommeln, weißt du?", "Boom-boom! I'll drum along to the song! The Nian is scared of drums, you know?", "咚咚！我要跟着歌打鼓！年兽最怕鼓声了，你知道吗？")]},
]
E["dorf_oma"] = [
    {"if": "prologue_done", "then": [say("dorf_oma", "EV_OMA_2", "Der Bambuspfad führt nach Norden und dann nach Osten bis Teeufer. Nimm Reisbällchen mit, Kind.", "The bamboo path leads north and then east to Teabank. Take some rice balls, child.", "竹径先往北再往东，一直通到茶岸镇。孩子，带些饭团吧。")],
     "else": [say("dorf_oma", "EV_OMA_1", "Fünfhundert Jahre … Ich bin nicht so alt, wie ich aussehe, aber ich habe das Lied noch nie gehört.", "Five hundred years... I'm not as old as I look, but I've never heard the song.", "五百年啊……我没看上去那么老，可这首歌我也从没听过。")]},
]
E["sign_north"] = [say("narrator", "EV_SIGN_NORTH", "Wegweiser: Norden – Bambuspfad, Teeufer.", "Signpost: North - Bamboo Path, Teabank.", "路牌：北——竹径、茶岸镇。")]
E["blocked_north"] = [say("jinli", "EV_BLOCK_NORTH", "Miau. (Jinli setzt sich auf den Weg. Heute Nacht ist das Fest – nicht die Reise.)", "Mew. (Jinli sits down on the road. Tonight is the festival - not the journey.)", "喵。（锦鲤坐在路中间。今晚是节日，不是出远门的时候。）")]
E["blocked_river"] = [say("jinli", "EV_BLOCK_RIVER", "Miau? (Jinli schaut zurück zum Festplatz. Erst das Fest!)", "Mew? (Jinli looks back at the festival square. Festival first!)", "喵？（锦鲤回头看着节日广场。先过节吧！）")]

E["silence_falls"] = [
    {"music": "village"},
    say("narrator", "EV_SILENCE_1", "Du hängst das Windspiel an den Festbaum. Das ganze Dorf stimmt das Lied des Phönix an …", "You hang the wind chime on the festival tree. The whole village begins the Song of the Phoenix...", "你把风铃挂上节日树。全村人一起唱起了凤凰之歌……"),
    {"wait": 1.5},
    {"music": ""},
    {"silence": True},
    {"set": "silence_fell"},
    say("narrator", "EV_SILENCE_2", "Mitten im Lied bricht alles ab. Die Musik. Der Fluss. Das Zirpen im Gras. Es ist vollkommen still.", "In the middle of the song, everything stops. The music. The river. The chirping in the grass. Complete silence.", "歌唱到一半，一切戛然而止。音乐、河水、草丛里的虫鸣……万籁俱寂。"),
    say("dorf_frau", "EV_SILENCE_3", "Was … was ist das? Ich höre nichts mehr!", "What... what is this? I can't hear anything!", "这……这是怎么了？我什么都听不见了！"),
    say("meister_plaza", "EV_SILENCE_4", "Das Lied … jemand hat es gestohlen. Die Töne sind fort.", "The song... someone has stolen it. The tones are gone.", "这首歌……被人偷走了。五音都不见了。"),
    {"sfx": "bell"},
    say("jinli", "EV_SILENCE_5", "MIAU! (Jinlis Koi-Glöckchen klingt – als einziges im ganzen Dorf. Sie starrt nach Osten, zum Fluss.)", "MEW! (Jinli's koi bell rings - the only sound in the whole village. She stares east, towards the river.)", "喵！（锦鲤的锦鲤铃响了——全村唯一的声音。她盯着东边的河。）"),
    say("meister_plaza", "EV_SILENCE_6", "Jinli hört etwas, das wir nicht hören. Folge ihr, {player}. Am Fluss sind die Lingshou bestimmt verängstigt. Vielleicht folgen sie dir.",
        "Jinli hears something we cannot. Follow her, {player}. The Lingshou at the river must be frightened. Maybe they will follow you.",
        "锦鲤听到了我们听不到的东西。{player}，跟着她。河边的灵兽一定吓坏了，也许它们会跟随你。"),
    say("narrator", "EV_SILENCE_TUT", "Tipp: Wenn du nicht weiterweißt, sprich Jinli an. Sie zeigt dir den Weg.", "Tip: When you don't know where to go, talk to Jinli. She shows you the way.", "提示：不知道去哪儿时，和锦鲤说话，她会给你指路。"),
    {"music": "silence"},
    quest("QUEST_RIVER", "Folge Jinli zum Flussufer im Osten.", "Follow Jinli to the riverbank in the east.", "跟着锦鲤去东边的河岸。"),
    {"goal": ["flussufer", 15, 9]},
    {"save": True},
]
hints("RIVER", ["Miau! (Jinli schaut nach Osten.)", "Miau, miau! (Jinli läuft zum Weg am rechten Dorfrand.)", "Miaaau! (Am rechten Rand des Dorfs, unterhalb des Hauses von Oma Hu, geht es zum Flussufer.)"],
      ["Mew! (Jinli looks east.)", "Mew, mew! (Jinli runs to the road at the right edge of the village.)", "Meeew! (At the right edge of the village, below Granny Hu's house, the road leads to the riverbank.)"],
      ["喵！（锦鲤望向东方。）", "喵喵！（锦鲤跑到村子右边的路口。）", "喵——！（村子右边、胡奶奶家下面，有条路通往河岸。）"])

# --- Prologue: Flussufer --------------------------------------------------------
E["river_arrive"] = [
    {"set": "river_arrived"},
    {"refresh": True},
    say("narrator", "EV_RIVER_1", "Am Fluss steht das Wasser still wie Glas. Zwischen Schilf und Bambus kauern scheue Lingshou.", "At the river, the water stands still as glass. Shy Lingshou crouch between reeds and bamboo.", "河水静止如镜。芦苇和竹林之间蜷缩着怕生的灵兽。"),
    say("yao", "EV_RIVER_2", "Du auch hier? … Die Stille. Hörst du das? Gar nichts. Ist das nicht … friedlich?", "You're here too? ... The silence. Do you hear that? Nothing at all. Isn't it... peaceful?", "你也来了？……这寂静，你听，什么都没有。不觉得……很安宁吗？"),
    say("yao", "EV_RIVER_3", "Die kleinen Lingshou hier zittern vor Angst. Mal sehen, wem sie eher vertrauen – dir oder mir.", "The little Lingshou here are trembling. Let's see who they trust more - you or me.", "这里的小灵兽都在发抖。看看它们更信任谁——你还是我。"),
    say("narrator", "EV_RIVER_TUT", "Geh zu einem scheuen Lingshou. Beruhige es, füttere es oder sprich mit ihm, bis es dir vertraut. Jedes Lingshou mag etwas anderes: Ängstliche brauchen Ruhe, Mutige Ermutigung, Verspielte Spaß.",
        "Walk up to a shy Lingshou. Calm it, feed it or talk to it until it trusts you. Each Lingshou likes something else: anxious ones need calm, brave ones courage, playful ones fun.",
        "走近一只怕生的灵兽，安抚它、喂它或和它说话，直到它信任你。每只灵兽喜欢的不一样：胆小的需要安静，勇敢的需要鼓励，顽皮的需要乐趣。"),
    quest("QUEST_TAME", "Gewinne das Vertrauen eines scheuen Lingshou.", "Win the trust of a shy Lingshou.", "赢得一只怕生灵兽的信任。"),
    {"goal": ["flussufer", 6, 12]},
]
hints("TAME", ["Miau. (Jinli schaut zum zitternden Wawalurch am Wasser.)", "Miau! (Jinli zeigt mit der Pfote: Geh zu einem Lingshou und sprich es mit A an.)", "Miaaau! (Geh zu einem Lingshou. Ängstliche wie Wawalurch mögen leise, beruhigende Worte.)"],
      ["Mew. (Jinli looks at the trembling Wailamander by the water.)", "Mew! (Jinli points with her paw: walk up to a Lingshou.)", "Meeew! (Walk up to a Lingshou. Anxious ones like Wailamander love quiet, soothing words.)"],
      ["喵。（锦鲤望着水边发抖的娃娃鲵。）", "喵！（锦鲤用爪子比划：走到灵兽身边。）", "喵——！（走到灵兽身边。像娃娃鲵这样胆小的，喜欢轻声安慰的话。）"])

for sp, de, en, zh in [
    ("wawalurch", "Ein Wawalurch kauert am Wasser und weint leise. Es sieht dich mit großen Augen an.", "A Wailamander crouches by the water, crying softly. It looks at you with big eyes.", "一只娃娃鲵蹲在水边轻声哭泣，睁着大眼睛看着你。"),
    ("bambaer", "Ein Bambär sitzt zwischen den Bambusstangen. Um ihn herum sprießen winzige Triebe.", "A Bambear sits among the bamboo stalks. Tiny shoots sprout around it.", "一只竹熊宝坐在竹子中间，身边冒出小小的嫩芽。"),
    ("zirpo", "Ein Zirpo hockt auf einem warmen Stein und zirpt – lautlos. Es wirkt ziemlich beleidigt.", "A Chirpo sits on a warm stone and chirps - without a sound. It looks rather offended.", "一只唧唧蹲在暖石上鸣叫——却没有声音。它看起来很不高兴。"),
    ("nebelaffe", "Ein Nebelaffe schaukelt an einem Ast und versteckt sich halb in seinem eigenen Nebel.", "A Mistape swings on a branch, half hidden in its own mist.", "一只雾猴在树枝上荡来荡去，半个身子藏在自己的雾里。"),
]:
    E[f"prolog_{sp}"] = [
        say("narrator", f"EV_SHY_{sp.upper()}", de, en, zh),
        {"befriend": sp, "level": 4,
         "tamed": [{"set": f"gone_shy_{sp}"}, {"refresh": True}, {"run": "prolog_after_tame"}],
         "fled": [say("narrator", "EV_SHY_FLED", "Es ist erschrocken weggelaufen – aber nicht weit. Versuch es noch einmal, vielleicht freundlicher.", "It ran away in fright - but not far. Try again, maybe more kindly.", "它吓跑了——但没跑远。再试一次吧，也许要更温柔些。")]},
    ]

E["prolog_after_tame"] = [
    {"if_party_min": 2, "then": [{"run": "prolog_two_tamed"}], "else": [{"run": "prolog_first_tamed"}]},
]
E["prolog_first_tamed"] = [
    {"sfx": "meow"},
    say("jinli", "EV_FIRST_1", "Miau! (Jinli reibt sich an deinem neuen Gefährten.)", "Mew! (Jinli rubs against your new companion.)", "喵！（锦鲤蹭了蹭你的新伙伴。）"),
    {"move": "yao", "to": [10, 9], "speed": 3.0},
    say("yao", "EV_FIRST_2", "Nicht schlecht. Ich hab auch eins – meinen Glutfasan hab ich schon länger. Lass uns sehen, wer seins besser kennt!",
        "Not bad. I've got one too - my Cinderfowl has been with me for a while. Let's see who knows theirs better!",
        "不错嘛。我也有——我的炭雉跟了我好久了。看看谁更了解自己的伙伴！"),
    say("narrator", "EV_FIRST_TUT", "Im Kampf wählst du eine Attacke – oder du rufst deinem Lingshou zu, was es tun soll: Tippe einen Ruf an oder schreib ihn selbst. Ein Ruf kostet Atem.",
        "In battle, pick a move - or call out to your Lingshou what to do: tap a suggested call or type your own. A call costs breath.",
        "战斗中可以选择招式——也可以对灵兽喊出指令：点选建议的呼唤，或自己输入。呼唤会消耗气息。"),
    {"battle": {"enemies": [{"id": "glutfasan", "level": 3}], "active": 1, "foe": "yao", "allow_lose": True, "coins": 20},
     "win": [say("yao", "EV_FIRST_WIN", "Tch. Glück gehabt. … Okay, du hast es verdient.", "Tch. Lucky. ... Okay, you earned it.", "切，运气好罢了。……好吧，算你厉害。")],
     "lose": [say("yao", "EV_FIRST_LOSE", "Ha! Aber dein Lingshou hat gut gekämpft. Du musst ihm nur mehr zutrauen.", "Ha! But your Lingshou fought well. You just need to trust it more.", "哈！不过你的灵兽打得不错。你只是需要更信任它。")]},
    {"heal": True},
    {"set": "yao_battle1"},
    say("narrator", "EV_FIRST_3", "Am Windspiel ist noch ein Glöckchen frei.", "One bell on the wind chime is still free.", "风铃上还有一只铃铛空着。"),
    quest("QUEST_SECOND", "Gewinne ein zweites Lingshou für dich.", "Win a second Lingshou over.", "再赢得一只灵兽的信任。"),
]
hints("SECOND", ["Miau. (Jinli schaut zu den anderen scheuen Lingshou.)", "Miau! (Noch ein Lingshou hier am Fluss wartet auf dich.)", "Miaaau! (Verspielte wie der Nebelaffe mögen Spiele, Mutige mögen Ermutigung. Sprich sie an!)"],
      ["Mew. (Jinli looks at the other shy Lingshou.)", "Mew! (Another Lingshou here at the river is waiting for you.)", "Meeew! (Playful ones like Mistape love games, brave ones love encouragement. Talk to them!)"],
      ["喵。（锦鲤看着其他怕生的灵兽。）", "喵！（河边还有一只灵兽在等你。）", "喵——！（顽皮的雾猴喜欢游戏，勇敢的喜欢鼓励。去和它们说说话！）"])
E["prolog_two_tamed"] = [
    {"set": "prologue_tamed"},
    say("yao", "EV_TWO_1", "Zwei Glöckchen, zwei Lingshou. Die anderen kommen mit mir.", "Two bells, two Lingshou. The others come with me.", "两只铃铛，两只灵兽。剩下的跟我走。"),
    say("yao", "EV_TWO_2", "Du … sag mal. Wenn diese Stille bleibt – dann geht doch auch nichts mehr verloren, oder?", "Hey... tell me. If this silence stays - then nothing gets lost anymore either, right?", "喂……你说，如果这寂静一直持续下去，那也就不会再失去什么了，对吧？"),
    {"refresh": True},
    {"sfx": "bell"},
    say("jinli", "EV_TWO_3", "MIAU! (Jinli faucht in Richtung Dorf. Ihr Fell sträubt sich.)", "MEW! (Jinli hisses towards the village. Her fur bristles.)", "喵！（锦鲤朝村子方向哈气，毛都竖起来了。）"),
    quest("QUEST_BACK", "Etwas stimmt nicht im Dorf. Kehr nach Weidendorf zurück.", "Something is wrong in the village. Return to Willowdale.", "村里出事了。回柳村去。"),
    {"goal": ["weidendorf", 28, 14]},
    {"save": True},
]
hints("BACK", ["Miau! (Jinli zieht dich nach Westen.)", "Miau, miau! (Zurück nach Weidendorf, der Weg links am Fluss.)", "Miaaau! (Der Weg ganz links führt zurück ins Dorf. Schnell!)"],
      ["Mew! (Jinli pulls you west.)", "Mew, mew! (Back to Willowdale, the road on the left by the river.)", "Meeew! (The road on the far left leads back to the village. Hurry!)"],
      ["喵！（锦鲤拉着你往西走。）", "喵喵！（回柳村，沿着河岸左边的路。）", "喵——！（最左边的路通回村子，快！）"])
E["yao_river"] = [
    {"if": "yao_battle1", "then": [say("yao", "EV_YAO_RIVER_2", "Na los, das zweite Glöckchen wartet.", "Go on, the second bell is waiting.", "去吧，第二只铃铛在等着呢。")],
     "else": [say("yao", "EV_YAO_RIVER_1", "Worauf wartest du? Die Lingshou laufen nicht von selbst zu dir.", "What are you waiting for? The Lingshou won't come to you by themselves.", "还等什么？灵兽可不会自己跑过来。")]},
]

# --- Prologue end: Wusheng --------------------------------------------------------
E["wusheng_scene"] = [
    {"music": ""},
    {"set": "wusheng_here"},
    {"refresh": True},
    {"teleport": [21, 10]},
    say("narrator", "EV_WU_1", "Auf dem Festplatz steht eine hohe Gestalt in grauen Gewändern. Wo sie geht, verlöschen die Laternen.", "A tall figure in grey robes stands on the festival square. Wherever it walks, the lanterns go out.", "节日广场上站着一个身穿灰袍的高大身影。他走到哪里，哪里的灯笼就熄灭。"),
    say("wusheng", "EV_WU_2", "Ein Windspiel mit zwei Glöckchen. Wie rührend. Du bist also der Lehrling.", "A wind chime with two bells. How touching. So you are the apprentice.", "挂着两只铃铛的风铃。真感人。原来你就是那个学徒。"),
    say("meister_plaza", "EV_WU_3", "Wusheng … Hüter des Tempels. Du warst es. Gib die Töne zurück!", "Wusheng... keeper of the temple. It was you. Give back the tones!", "无声……庙的守护者。是你干的。把五音还回来！"),
    say("wusheng", "EV_WU_4", "Zurück? Damit der Phönix verbrennt und alles mit sich nimmt, was wir lieben? Nein, alter Freund. Ab heute endet nichts mehr. Keine Stürme. Keine Abschiede.",
        "Give them back? So the Phoenix burns and takes everything we love with it? No, old friend. From today on, nothing ends. No storms. No farewells.",
        "还回去？让凤凰燃尽，带走我们所爱的一切？不，老朋友。从今天起，再也没有终结。没有风暴，没有离别。"),
    say("meister_plaza", "EV_WU_5", "Ohne Abschied gibt es auch kein Wiedersehen, Wusheng! Ohne Ende keinen Frühling!", "Without farewell there is no reunion, Wusheng! Without an end, no spring!", "没有离别就没有重逢，无声！没有终结，就没有春天！"),
    say("wusheng", "EV_WU_6", "Du redest zu viel.", "You talk too much.", "你话太多了。"),
    {"sfx": "fail"},
    {"fade": "out", "seconds": 0.15},
    {"fade": "in", "seconds": 0.6},
    say("narrator", "EV_WU_7", "Wusheng hebt die Hand. Meister Lu öffnet den Mund – doch kein Laut kommt heraus.", "Wusheng raises his hand. Master Lu opens his mouth - but no sound comes out.", "无声抬起手。卢师傅张开嘴——却发不出一点声音。"),
    say("wusheng", "EV_WU_8", "Geh nicht nach Osten, Kind des Windspiels. Es gibt dort nichts, das du retten musst.", "Do not go east, child of the wind chime. There is nothing there you need to save.", "风铃之子，不要往东去。那里没有你需要拯救的东西。"),
    {"move": "wusheng", "to": [28, 2], "speed": 2.2},
    {"clear": "wusheng_here"},
    {"set": "voice_taken"},
    {"refresh": True},
    {"sfx": "bell"},
    say("jinli", "EV_WU_9", "Miau … (Jinli drückt sich an das Windspiel. Ein drittes Glöckchen erscheint daran, hell wie ein Funke.)", "Mew... (Jinli presses against the wind chime. A third bell appears on it, bright as a spark.)", "喵……（锦鲤贴着风铃。风铃上出现了第三只铃铛，亮得像一粒火星。）"),
    {"bells": 3},
    say("meister_mute", "EV_WU_10", "(Meister Lu schreibt mit zitternder Hand auf seine Schiefertafel:) „Fünf Töne. Der erste, Jue, gehört dem Azurdrachen im Osten, über den Reisterrassen. Geh über den Bambuspfad nach Teeufer. Bring das Lied zurück.“",
        "(Master Lu writes on his slate with a trembling hand:) \"Five tones. The first, Jue, belongs to the Azure Dragon in the east, above the rice terraces. Take the Bamboo Path to Teabank. Bring the song back.\"",
        "（卢师傅用颤抖的手在石板上写道：）“五音。第一个音‘角’属于东方稻田梯之上的青龙。走竹径去茶岸镇。把歌找回来。”"),
    {"give_item": "kraeutertee", "n": 2},
    {"coins": 100},
    {"set": "prologue_done"},
    {"music": "silence"},
    quest("QUEST_TEEUFER", "Folge dem Bambuspfad im Norden bis nach Teeufer.", "Follow the Bamboo Path in the north to Teabank.", "沿着北边的竹径去茶岸镇。"),
    {"goal": ["teeufer", 10, 9]},
    say("narrator", "EV_WU_TUT", "Prolog geschafft! Im Menü (☰) siehst du dein Gefolge und den Beutel. Zu Hause kannst du dich ausruhen und speichern.", "Prologue complete! The menu (☰) shows your companions and bag. At home you can rest and save.", "序章完成！菜单（☰）里可以查看同伴和背包。回家可以休息和存档。"),
    {"save": True},
]
hints("TEEUFER", ["Miau! (Jinli schaut nach Norden.)", "Miau, miau! (Der Weg oben rechts im Dorf führt in den Bambuspfad.)", "Miaaau! (Oben rechts aus dem Dorf hinaus, durch den Bambuspfad und dann nach Osten bis Teeufer.)"],
      ["Mew! (Jinli looks north.)", "Mew, mew! (The road at the top right of the village leads into the Bamboo Path.)", "Meeew! (Out of the village at the top right, through the Bamboo Path, then east to Teabank.)"],
      ["喵！（锦鲤望向北方。）", "喵喵！（村子右上方的路通往竹径。）", "喵——！（从村子右上方出去，穿过竹径，再往东到茶岸镇。）"])
E["meister_mute"] = [say("meister_mute", "EV_MUTE", "(Meister Lu lächelt traurig und tippt auf seine Tafel: „Osten. Azurdrache. Ich glaube an dich.“)", "(Master Lu smiles sadly and taps his slate: \"East. Azure Dragon. I believe in you.\")", "（卢师傅悲伤地笑了笑，敲了敲石板：“东方。青龙。我相信你。”）")]
E["wusheng_idle"] = [say("wusheng", "EV_WU_IDLE", "…", "...", "……")]

# --- Bambuspfad -----------------------------------------------------------------
E["sign_bamboo"] = [say("narrator", "EV_SIGN_BAMBOO", "Bambuspfad. Osten: Teeufer. Süden: Weidendorf. Achtung: Im hohen Gras leben wilde Lingshou.", "Bamboo Path. East: Teabank. South: Willowdale. Careful: wild Lingshou live in the tall grass.", "竹径。东：茶岸镇。南：柳村。注意：高草丛中有野生灵兽。")]
E["chest_bamboo"] = [
    say("narrator", "EV_CHEST", "Zwischen den Bambuswurzeln steht eine kleine Kiste.", "A little chest stands between the bamboo roots.", "竹根之间放着一个小箱子。"),
    {"give_item": "glockenbluete", "n": 1}, {"give_item": "silbertau", "n": 2},
    {"set": "chest_bamboo"}, {"refresh": True},
]
E["yao_bamboo"] = [
    {"set": "yao_bamboo_waiting"}, {"refresh": True},
    say("yao", "EV_YAO_B_1", "Du gehst also wirklich. Weil ein alter Mann es auf eine Tafel geschrieben hat.", "So you're really going. Because an old man wrote it on a slate.", "你真的要去啊。就因为一个老头在石板上写了几个字。"),
    say("yao", "EV_YAO_B_2", "Mein Großvater ist letzten Winter gegangen. Einfach so. Wenn nichts mehr endet, muss auch niemand mehr gehen. Verstehst du das nicht?",
        "My grandfather left last winter. Just like that. If nothing ends anymore, nobody has to leave anymore. Don't you understand?",
        "我爷爷去年冬天走了，就那么走了。如果一切都不会结束，就没有人需要离开。你不明白吗？"),
    choice([("CH_YAO_A", "Ich verstehe dich. Aber ohne Ende gibt es auch keinen Frühling.", "I understand you. But without an end there is no spring either.", "我懂你。但没有终结，也就没有春天。"),
            ("CH_YAO_B", "Wusheng nimmt allen ihre Stimme. Das ist kein Frieden.", "Wusheng takes everyone's voice. That isn't peace.", "无声夺走了所有人的声音，这不是安宁。")],
           [[{"set": "yao_understood"}, say("yao", "EV_YAO_B_3", "… Frühling. Großvater mochte den Frühling.", "... Spring. Grandfather liked spring.", "……春天。爷爷喜欢春天。")],
            [say("yao", "EV_YAO_B_4", "Und was ist dann Frieden? Zeig's mir!", "Then what is peace? Show me!", "那什么才是安宁？你证明给我看！")]]),
    {"battle": {"enemies": [{"id": "glutfasan", "level": 7}, {"id": "rollschupp", "level": 6}], "active": 1, "foe": "yao", "allow_lose": True, "coins": 60, "bg": "bamboo"},
     "win": [say("yao", "EV_YAO_B_WIN", "… Geh schon. Aber wenn du den Drachen weckst, und er dir nichts als Abschied bringt – dann denk an mich.", "... Go on then. But if you wake the dragon and it brings you nothing but farewells - think of me.", "……去吧。但如果你唤醒了青龙，它只带给你离别——那就想想我。")],
     "lose": [say("yao", "EV_YAO_B_LOSE", "Siehst du? Du bist nicht stark genug. Bleib in der Stille, da ist es sicher.", "See? You're not strong enough. Stay in the silence, it's safe there.", "看吧，你还不够强。待在寂静里吧，那里很安全。")]},
    {"set": "yao_battle2"}, {"clear": "yao_bamboo_waiting"}, {"refresh": True},
    {"heal": True},
    say("narrator", "EV_YAO_B_5", "Yao geht in den Bambus davon, ohne sich umzudrehen.", "Yao walks off into the bamboo without looking back.", "尧头也不回地走进了竹林。"),
]
E["yao_bamboo_idle"] = [say("yao", "EV_YAO_B_IDLE", "…", "...", "……")]

# --- Teeufer -----------------------------------------------------------------------
E["teeufer_arrive"] = [
    {"set": "teeufer_arrived"},
    say("narrator", "EV_TOWN_1", "Teeufer: Teeterrassen am Fluss, sonst voller Lieder der Pflückerinnen. Heute hört man nur das Klappern der Körbe nicht.", "Teabank: tea terraces by the river, usually full of the pickers' songs. Today not even the baskets rattle.", "茶岸镇：河边的茶园梯田，平时满是采茶女的歌声。今天连竹篓的碰撞声都听不见。"),
    say("jinli", "EV_TOWN_2", "Miau. (Jinli schaut den Berg hinauf, nach Norden.)", "Mew. (Jinli looks up the mountain, to the north.)", "喵。（锦鲤抬头望向北边的山。）"),
    say("narrator", "EV_TOWN_TUT", "In der Unterkunft (links oben) ruhst du dich aus und speicherst. Im Laden (Mitte oben) gibt es Futter und Heilmittel. Im Teehaus (rechts) hört man Gerüchte.",
        "At the lodging (top left) you rest and save. The shop (top middle) sells food and remedies. At the teahouse (right) you hear rumours.",
        "在客栈（左上）可以休息存档，商店（中上）卖食物和药品，茶馆（右边）能听到传闻。"),
    quest("QUEST_TERRACES", "Steig über die Reisterrassen im Norden zum Drachenschrein.", "Climb the rice terraces in the north to the Dragon Shrine.", "沿北边的稻田梯登上龙祠。"),
    {"goal": ["drachenschrein", 13, 8]},
    {"set_inn": ["teeufer", "inn"]},
]
hints("TERRACES", ["Miau! (Jinli schaut nach Norden zu den Terrassen.)", "Miau, miau! (Rechts oben in Teeufer geht es zu den Reisterrassen.)", "Miaaau! (Rechts oben aus der Stadt, die Terrassen hinauf. Ganz oben, hinter dem Pass, ist der Schrein.)"],
      ["Mew! (Jinli looks north to the terraces.)", "Mew, mew! (At the top right of Teabank, the road leads to the rice terraces.)", "Meeew! (Out of town at the top right, up the terraces. At the very top, beyond the pass, is the shrine.)"],
      ["喵！（锦鲤望向北边的梯田。）", "喵喵！（茶岸镇右上方的路通往稻田梯。）", "喵——！（从镇子右上方出去，爬上梯田。最上面，过了山口就是龙祠。）"])
E["inn_door"] = [
    say("wirtin", "EV_INN", "Willkommen im Gasthaus zum Stillen Tee – na ja, so heißt es erst seit gestern. Ruh dich aus, Reisende Seele.", "Welcome to the Inn of the Quiet Tea - well, it's only been called that since yesterday. Rest, traveller.", "欢迎光临静茶客栈——嗯，这名字是昨天才改的。旅人，歇歇脚吧。"),
    {"set_inn": ["teeufer", "inn"]},
    {"inn": True},
]
E["shop_door"] = [
    say("haendler", "EV_SHOP", "Kundschaft! Reisbällchen, Kräutertee, Futter für scheue Lingshou – alles frisch, auch wenn die Waage nicht mehr piept.", "A customer! Rice balls, herbal tea, food for shy Lingshou - all fresh, even if the scales don't beep anymore.", "来客人啦！饭团、草药茶、给怕生灵兽的食物——都是新鲜的，虽然秤不响了。"),
    {"shop": ["reisbaellchen", "kraeutertee", "glockenbluete", "bambussprossen", "suessreis", "silbertau"]},
]
E["teahouse"] = [
    say("teemeister", "EV_TEA_1", "Setz dich. Tee schmeckt auch in der Stille. Und Neuigkeiten gibt es immer.", "Sit down. Tea tastes good even in silence. And there's always news.", "坐吧。安静时茶也一样香。消息嘛，总是有的。"),
    {"rumor": True, "speaker": "teemeister"},
]
E["stille_frau"] = [
    {"if": "tone_jue", "then": [say("stille_frau", "EV_NING_2", "Der Wind ist zurück. Und mit ihm das Pfeifen in den Fensterläden … Ich gebe zu, ich hatte die Ruhe gemocht. Aber die Lieder der Pflückerinnen haben mir gefehlt.",
                                    "The wind is back. And with it the whistling in the shutters... I admit I liked the quiet. But I missed the pickers' songs.",
                                    "风回来了，百叶窗又开始呼呼作响……我承认，我曾喜欢那份安静。可我也想念采茶女的歌。")],
     "else": [say("stille_frau", "EV_NING_1", "Weißt du, die Stille ist gar nicht so schlecht. Kein Sturm, kein Hochwasser. Mein Mann ist im Frühjahr mit dem Hochwasser gegangen. Wenn sich nichts mehr ändert … vielleicht ist das gut so.",
                       "You know, the silence isn't so bad. No storms, no floods. My husband was taken by the spring flood. If nothing changes anymore... maybe that's good.",
                       "你知道吗，寂静也没那么糟。没有风暴，没有洪水。我丈夫就是在春汛里走的。如果一切都不再改变……也许这样也好。")]},
]
E["teeufer_kind"] = [say("teeufer_kind", "EV_TAO", "Ich hab ein Reisquak gesehen! Die quaken jetzt lautlos. Das sieht sooo lustig aus!", "I saw a Paddyhop! They croak without a sound now. It looks sooo funny!", "我看到稻蛙仔了！它们现在呱呱叫却没声音，好好笑！")]
E["pilger"] = [
    {"if": "tone_jue", "then": [say("pilger", "EV_WEN_2", "Hörst du den Bambus rauschen? Der Drache singt wieder. Danke dir, Kind.", "Do you hear the bamboo rustle? The dragon sings again. Thank you, child.", "听到竹林沙沙响了吗？青龙又在歌唱了。谢谢你，孩子。")],
     "else": [say("pilger", "EV_WEN_1", "Ich wollte zum Schrein des Azurdrachen pilgern. Doch am Pass sitzt ein verstummter Schneeleopard. Mit Gewalt allein kommt man da nicht vorbei.",
                  "I wanted to make a pilgrimage to the Azure Dragon's shrine. But a silenced snow leopard sits at the pass. Force alone won't get you past.",
                  "我本想去青龙祠朝拜，可山口坐着一只失声的雪豹。光靠蛮力是过不去的。")]},
]

# --- Reisterrassen ------------------------------------------------------------------
E["terraces_arrive"] = [
    {"set": "terraces_arrived"},
    say("narrator", "EV_TER_1", "Die Reisterrassen spiegeln den Himmel. Über dem Wasser tanzen dunkle Motten – Schattenmotten, Geschöpfe des Nian, die Klänge fressen.", "The rice terraces mirror the sky. Dark moths dance over the water - shadow moths, creatures of the Nian that eat sounds.", "稻田映着天空。水面上飞舞着黑色的蛾子——影蛾，年兽的爪牙，以声音为食。"),
]
E["moth_a"] = [{"battle": {"enemies": [{"id": "schattenmotte", "level": 8}], "active": 1, "bg": "terraces"},
                "win": [{"set": "gone_moth_a"}, {"refresh": True}]}]
E["moth_b"] = [{"battle": {"enemies": [{"id": "schattenmotte", "level": 9}], "active": 1, "bg": "terraces"},
                "win": [{"set": "gone_moth_b"}, {"refresh": True}]}]
E["silent_leopard"] = [
    say("narrator", "EV_LEO_1", "Im engen Pass sitzt ein Firnleopard. Seine Augen sind grau, wie mit Asche bestreut. Er knurrt – lautlos.", "In the narrow pass sits a Frostpard. Its eyes are grey, as if dusted with ash. It growls - without a sound.", "狭窄的山口坐着一只霜豹，眼睛灰蒙蒙的，像落了灰。它在低吼——却没有声音。"),
    {"if_not": "leo_tutorial", "then": [
        say("narrator", "EV_LEO_TUT", "Verstummte Lingshou zähmst du nicht – du befreist sie. Fülle ihren Herzklang: Zureden und Beruhigen helfen am meisten, auch Treffer lockern die Stille. Erschöpfst du es stattdessen, bleibt es verstummt.",
            "Silenced Lingshou aren't tamed - they are freed. Fill their heartsong: talking and calming help most, hits loosen the silence too. If you exhaust it instead, it stays silenced.",
            "失声的灵兽不是被驯服的，而是被解放的。唤醒它的心音：说话和安抚最有用，攻击也能松动寂静。但如果把它打倒，它就会一直失声。"),
        {"set": "leo_tutorial"}]},
    {"battle": {"enemies": [{"id": "firnleopard", "level": 8, "role": "silenced"}], "active": 1, "bg": "terraces"},
     "win": [{"set": "gone_silent_leopard"}, {"refresh": True},
             say("narrator", "EV_LEO_WIN", "Der Firnleopard bricht zusammen und schleppt sich davon. Seine Augen bleiben grau.", "The Frostpard collapses and drags itself away. Its eyes stay grey.", "霜豹倒下了，拖着身子离开，眼睛依旧灰暗。")],
     "freed": [{"set": "gone_silent_leopard"}, {"refresh": True}]},
]

# --- Drachenschrein -------------------------------------------------------------------
E["shrine_arrive"] = [
    {"set": "shrine_arrived"},
    say("narrator", "EV_SHR_1", "Der Drachenschrein. Rote Säulen, grau vor Staub. Oben, um den Altar gewunden, schläft ein riesiger Drache – azurblau einst, jetzt aschfahl.", "The Dragon Shrine. Red pillars, grey with dust. Above, coiled around the altar, a huge dragon sleeps - azure once, now ashen.", "龙祠。朱红的柱子蒙着灰。上方，一条巨龙盘绕着祭坛沉睡——曾经青碧如天，如今灰白如烬。"),
    say("moench", "EV_SHR_2", "Du kommst, um ihn zu wecken? Dann sei behutsam. Er ist nicht böse – er hat nur sein Lied verloren. Komm zu mir, wenn deine Gefährten Ruhe brauchen.",
        "You've come to wake him? Then be gentle. He isn't evil - he has only lost his song. Come to me when your companions need rest.",
        "你是来唤醒他的？那就温柔些。他并不邪恶——只是失去了自己的歌。同伴需要休息时就来找我。"),
    {"set_inn": ["drachenschrein", "from_terraces"]},
]
E["moench"] = [
    say("moench", "EV_MONK", "Setzt euch. Atmet. … So. Jetzt seid ihr bereit.", "Sit. Breathe. ... There. Now you are ready.", "坐下，呼吸……好了。现在你们准备好了。"),
    {"heal": True}, {"save": True},
    say("narrator", "EV_MONK_2", "Dein Gefolge ist geheilt. Gespeichert.", "Your companions are healed. Saved.", "同伴已恢复。已存档。"),
]
E["boss_qinglong"] = [
    {"if": "boss_seen", "else": [
        {"set": "boss_seen"},
        say("narrator", "EV_BOSS_1", "Der Drache öffnet die Augen. Grau, leer. Eine Schattenmotte löst sich aus seinen Schuppen.", "The dragon opens its eyes. Grey, empty. A shadow moth peels away from its scales.", "巨龙睁开眼睛，灰暗而空洞。一只影蛾从它的鳞片间飞了出来。"),
        say("qinglong", "EV_BOSS_2", "… Frühling … fort … nichts … wächst …", "... spring... gone... nothing... grows...", "……春天……走了……什么……都不长……"),
        say("narrator", "EV_BOSS_TUT", "Zwei gegen zwei! Fülle den Herzklang des Azurdrachen, um ihn zu befreien. Die Motte frisst Klänge – halte sie in Schach.", "Two against two! Fill the Azure Dragon's heartsong to free it. The moth eats sounds - keep it in check.", "二对二！唤醒青龙的心音来解放它。影蛾会吞食声音——要压制住它。"),
    ]},
    {"if_party_min": 2, "then": [
        {"battle": {"enemies": [{"id": "qinglong", "level": 11, "role": "silenced"}, {"id": "schattenmotte", "level": 9}],
                    "active": 2, "music": "boss", "bg": "shrine", "no_join": True},
         "win": [{"run": "tone_returns"}],
         "lose": [say("moench", "EV_BOSS_LOSE", "Ruh dich aus und versuch es noch einmal. Er wartet.", "Rest and try again. He is waiting.", "休息一下再试吧。他会等你的。")]}],
     "else": [say("moench", "EV_BOSS_ALONE", "Allein kommst du nicht an ihn heran. Du brauchst mindestens zwei Gefährten.", "You can't reach him alone. You need at least two companions.", "一个人是靠近不了他的。你至少需要两个同伴。")]},
]
E["tone_returns"] = [
    {"music": "tone_returns"},
    {"set": "tone_jue"},
    {"silence": False},
    {"refresh": True},
    {"if": "freed_qinglong",
     "then": [say("narrator", "EV_TONE_1", "Der Herzklang des Drachen schwillt an – und plötzlich ist er da: ein einzelner, warmer Ton. Jue.", "The dragon's heartsong swells - and suddenly it is there: a single, warm tone. Jue.", "青龙的心音越来越响——忽然间，它出现了：一个温暖的音。角。")],
     "else": [{"set": "qinglong_defeated"},
              say("narrator", "EV_TONE_1B", "Der Drache sinkt erschöpft nieder. Die Stille bricht – aber leiser, als sie hätte brechen können. Ein einzelner Ton: Jue.", "The dragon sinks down, exhausted. The silence breaks - but more quietly than it could have. A single tone: Jue.", "巨龙精疲力竭地伏下。寂静被打破了——却比本可以的更轻。一个音：角。")]},
    say("narrator", "EV_TONE_2", "Der Wind fährt durch den Bambus. Das Rauschen kehrt zurück, das Wasser in den Terrassen gluckst. Die Farben kommen zurück in die Welt.", "Wind sweeps through the bamboo. The rustling returns, water gurgles in the terraces. Colour flows back into the world.", "风穿过竹林。沙沙声回来了，梯田里的水汩汩作响。色彩重新回到了世界。"),
    {"voice": "qinglong", "event": "freed"},
    say("qinglong", "EV_TONE_3", "Wusheng nahm mein Lied, weil er Angst vor dem Abschied hat. Doch auch der Bambus muss alte Halme abwerfen, damit neue wachsen. Vier weitere Töne fehlen noch, kleiner Mensch.",
        "Wusheng took my song because he fears farewell. But even bamboo must shed old stalks so new ones can grow. Four more tones are still missing, little one.",
        "无声夺走我的歌，是因为他害怕离别。可竹子也要褪去旧竿，新竹才能生长。还有四个音没有找回，小家伙。"),
    {"sfx": "bell"},
    {"bells": 4},
    say("jinli", "EV_TONE_4", "Miau! (Jinlis Glöckchen klingt hell – und von weit her antwortet ein anderes.)", "Mew! (Jinli's bell rings brightly - and from far away, another one answers.)", "喵！（锦鲤的铃铛清脆地响起——远处传来另一声回应。）"),
    quest("QUEST_FREE", "Der erste Ton ist zurück. Fortsetzung folgt – erkunde weiter, zähme und befreie.", "The first tone is back. To be continued - keep exploring, taming and freeing.", "第一个音回来了。未完待续——继续探索、驯服和解放吧。"),
    {"save": True},
    {"end_beta": True},
]
hints("FREE", ["Miau! (Jinli schnurrt zufrieden.)", "Miau. (Jinli rollt sich in der Sonne zusammen. Vielleicht warten noch Lingshou im hohen Gras?)", "Miaaau. (Mehr Töne gibt es in einer späteren Version. Bis dahin: Zähmen, kämpfen, die Beta bewerten!)"],
      ["Mew! (Jinli purrs happily.)", "Mew. (Jinli curls up in the sun. Maybe more Lingshou wait in the tall grass?)", "Meeew. (More tones come in a later version. Until then: tame, battle, rate the beta!)"],
      ["喵！（锦鲤满足地打着呼噜。）", "喵。（锦鲤在阳光下蜷成一团。也许高草丛里还有灵兽在等你？）", "喵——。（更多的音会在以后的版本中出现。现在先驯服、战斗、给测试版打分吧！）"])
E["qinglong_free"] = [
    say("qinglong_free", "EV_QL_FREE", "Hörst du? Der Bambus singt wieder. Geh, kleiner Mensch. Der nächste Ton ruht im Norden, im Nebelfluss … doch das ist eine Reise für ein anderes Mal.",
        "Do you hear it? The bamboo sings again. Go, little one. The next tone rests in the north, in the Misty River... but that is a journey for another time.",
        "听见了吗？竹子又在歌唱了。去吧，小家伙。下一个音在北方的雾河……不过那是以后的旅程了。"),
]

# Jinli: hint on request (the event runner asks the model with the quest's templates).
E["jinli_talk"] = [{"hint": True}]

# --- write ------------------------------------------------------------------------
with open(os.path.join(ROOT, "events", "chapter1.json"), "w") as f:
    json.dump({"note": "Generiert von tools/story/chapter1.py – dort bearbeiten.", "events": E}, f, ensure_ascii=False, indent=1)
with open(os.path.join(ROOT, "npcs.json"), "w") as f:
    json.dump(npcs, f, ensure_ascii=False, indent=1)
with open(os.path.join(ROOT, "i18n", "story.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["keys", "en", "de", "zh_Hans"])
    for k in sorted(TEXT):
        en, de, zh = TEXT[k]
        w.writerow([k, en, de, zh])
print(f"{len(E)} events, {len(TEXT)} texts, {len(npcs)} people")
