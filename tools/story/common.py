"""Shared helpers for the story and content generators (tools/story/build.py).

Every text is registered with t() next to the data that uses it, in German,
English and Simplified Chinese; build.py writes all of them to
game/data/i18n/story.csv. Events are plain step lists (see EventRunner).
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "data")
TEXT = {}  # key -> (en, de, zh)
NPCS = {}  # id -> {"name": key, "voice": {...}}


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


def person(nid, de, en, zh, tone, style, octave):
    key = "NPC_" + nid.upper()
    t(key, de, en, zh)
    NPCS[nid] = {"name": key, "voice": {"tone": tone, "style": style, "octave": octave}}


def town(E, prefix, names, greet, shop, rumors, dishes, tone="yu"):
    """Standard town services: inn (rest, travel, shrine), shop, teahouse with rumours, restaurant.
    names: {"wirt": (de, en, zh), "haendler": ..., "teemeister": ..., "koch": ...}
    greet: {"inn": (de, en, zh), "shop": ..., "tea": ..., "food": ...}
    rumors: list of (de, en, zh) templates for the teahouse."""
    styles = {"wirt": ("yu", "gentle", 0), "haendler": ("zhi", "playful", 0), "teemeister": ("gong", "gentle", -1), "koch": ("jue", "playful", 0)}
    for role, (de, en, zh) in names.items():
        person(f"{prefix}_{role}", de, en, zh, *styles[role])
    up = prefix.upper()
    E[f"{prefix}_inn"] = [say(f"{prefix}_wirt", f"EV_{up}_INN", *greet["inn"]), {"set_inn": [prefix, "inn"]}, {"inn": True}]
    E[f"{prefix}_shop"] = [say(f"{prefix}_haendler", f"EV_{up}_SHOP", *greet["shop"]), {"shop": shop}]
    keys = []
    for i, r in enumerate(rumors):
        keys.append(t(f"RUMOR_{up}_{i}", *r))
    E[f"{prefix}_tea"] = [say(f"{prefix}_teemeister", f"EV_{up}_TEA", *greet["tea"]), {"rumor": True, "speaker": f"{prefix}_teemeister", "templates": keys}]
    E[f"{prefix}_food"] = [say(f"{prefix}_koch", f"EV_{up}_FOOD", *greet["food"]), {"restaurant": dishes}]


def order_guard(E, eid, who, intro, accept, need, proof_flags, enemies, done_flag, won_line, fought_line, bg, react=None):
    """A member of the Order of Silence blocking the way: talk them round or fight
    (the fight's silenced Lingshou can be freed). Counts for the endings."""
    spec = {"who": who, "intro": intro, "accept": accept, "need": need, "tries": 3, "proof_flags": proof_flags}
    if react:
        spec.update(react)
    E[eid] = [
        {"persuade": spec,
         "success": [say(who, f"EV_{eid.upper()}_WON", *won_line), {"set": done_flag}, {"count": "order_convinced"}, {"refresh": True}],
         "fail": [say(who, f"EV_{eid.upper()}_FIGHT", *fought_line),
                  {"battle": {"enemies": enemies, "active": 1, "foe": who, "coins": 80, "bg": bg},
                   "win": [{"set": done_flag}, {"count": "order_fought"}, {"refresh": True}]}]},
    ]


def rquest(region, key, de, en, zh):
    """A task of one region: shown and hinted while the player is in that region."""
    return {"quest": t(key, de, en, zh), "region": region}
