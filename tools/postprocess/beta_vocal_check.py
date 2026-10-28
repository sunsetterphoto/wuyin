#!/usr/bin/env python3
"""Vocal check for the generated music (we cannot listen): Whisper (local-audio skill, auto language)
transcribes each OGG. Whisper hallucinates on instrumental music ("Thank you.", one word repeated),
so a track only counts as "vocals suspected" when a segment has at least 4 distinct words that are
not just repeats (distinct/total >= 0.4), is not a known hallucination phrase, and is time-aligned
(0.5-20 s long). Hallucinations on music come as whole 30 s windows or zero-length segments, real
sung lines as short aligned segments (checked against an ACE-Step song with vocals: all lines found).

  python3 tools/postprocess/beta_vocal_check.py [id ...]
"""
import glob
import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AUDIO = os.path.expanduser("~/.claude/skills/local-audio/scripts/audio.sh")
HALLUCINATIONS = {"thank you.", "thank you", "thanks for watching!", "you", "music", "[music]", "(music)",
                  "subtitles by the amara.org community"}


def check(path):
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "a" + os.path.splitext(path)[1])
        shutil.copy(path, src)
        subprocess.run([AUDIO, "stt", src, "", "json"], capture_output=True, text=True)
        d = json.load(open(os.path.join(tmp, "a.json")))
    suspicious = []
    for s in d.get("segments", []):
        text = s["text"].strip()
        words = text.lower().split()
        if not words or text.lower() in HALLUCINATIONS:
            continue
        distinct = len(set(words))
        aligned = 0.5 <= s["end"] - s["start"] <= 20
        if aligned and distinct >= 4 and distinct / len(words) >= 0.4:
            suspicious.append(f'{s["start"]:.0f}-{s["end"]:.0f}s: {text[:80]}')
    return suspicious, d.get("text", "")[:100].strip()


def main():
    ids = sys.argv[1:]
    files = sorted(glob.glob(os.path.join(ROOT, "game", "assets", "audio", "music", "*.ogg")))
    for f in files:
        name = os.path.basename(f)[:-4]
        if ids and name not in ids:
            continue
        sus, raw = check(f)
        print(f"{name:13s} {'VOCALS SUSPECTED' if sus else 'ok (no lyrics found)'}   whisper: {raw!r}")
        for line in sus:
            print("   ", line)


if __name__ == "__main__":
    main()
