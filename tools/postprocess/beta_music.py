#!/usr/bin/env python3
"""Raw ACE-Step tracks (build/beta_raw/music/<id>_s<seed>.flac) -> game/assets/audio/music/<id>.ogg

Steps: trim leading/trailing silence (-50 dB), two-pass EBU R128 loudnorm to TARGET LUFS
(true peak -1.5 dBTP), 44.1 kHz stereo, 10 ms fade at both ends against clicks, Ogg Vorbis
(libsndfile, quality 0.4, about 100-130 kbps). Prints duration, integrated loudness and peak.

Needs ffmpeg and a Python with soundfile + numpy (the brew ffmpeg here has no libvorbis):
  ~/.unsloth/studio/unsloth_studio/bin/python tools/postprocess/beta_music.py [--only id,id]
  ... beta_music.py --batch tools/comfyui/full_assets.json   # full batch, raw files from build/full_raw/music
"""
import argparse
import json
import os
import re
import subprocess
import tempfile

import numpy as np
import soundfile as sf

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RAW = os.path.join(ROOT, "build", "beta_raw", "music")
OUT = os.path.join(ROOT, "game", "assets", "audio", "music")
TARGET = {"default": -16.0, "silence": -18.0}
TRIM = ("silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05,"
        "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05,areverse")


def ff(args):
    return subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-y"] + args, capture_output=True, text=True).stderr


def measure(path):
    err = ff(["-i", path, "-af", "ebur128=peak=true", "-f", "null", "-"])
    i = re.findall(r"I:\s+(-?[\d.]+) LUFS", err)[-1]
    tp = re.findall(r"Peak:\s+(-?[\d.inf]+) dBFS", err)[-1]
    return float(i), tp


def process(item, src):
    target = TARGET.get(item["id"], TARGET["default"])
    with tempfile.TemporaryDirectory() as tmp:
        trimmed = os.path.join(tmp, "t.wav")
        ff(["-i", src, "-af", TRIM, "-ar", "44100", "-ac", "2", "-c:a", "pcm_f32le", trimmed])
        err = ff(["-i", trimmed, "-af", f"loudnorm=I={target}:TP=-1.5:LRA=11:print_format=json", "-f", "null", "-"])
        m = json.loads(err[err.rindex("{"):err.rindex("}") + 1])
        norm = os.path.join(tmp, "n.wav")
        ln = (f"loudnorm=I={target}:TP=-1.5:LRA=11:measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
              f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true")
        ff(["-i", trimmed, "-af", ln, "-ar", "44100", "-ac", "2", "-c:a", "pcm_f32le", norm])
        data, sr = sf.read(norm, dtype="float32")
        n = int(0.01 * sr)
        ramp = np.linspace(0, 1, n, dtype=np.float32)[:, None]
        data[:n] *= ramp
        data[-n:] *= ramp[::-1]
        peak = float(np.abs(data).max())
        if peak > 0.84:  # keep about -1.5 dBFS headroom (Vorbis adds a little overshoot)
            data *= 0.84 / peak
        os.makedirs(OUT, exist_ok=True)
        dst = os.path.join(OUT, item["id"] + ".ogg")
        data = np.ascontiguousarray(data)
        # libsndfile's Vorbis encoder crashes on one huge write; feed it in blocks.
        with sf.SoundFile(dst, "w", sr, 2, format="OGG", subtype="VORBIS", compression_level=0.6) as f:
            for i in range(0, len(data), 4096):
                f.write(data[i:i + 4096])
    i, tp = measure(dst)
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration,bit_rate", "-of", "csv=p=0", dst],
                           capture_output=True, text=True).stdout.strip()
    dur, br = probe.split(",")
    print(f'{item["id"]:13s} {float(dur):6.1f}s  {int(br) // 1000:4d} kbps  {i:6.1f} LUFS  peak {tp} dBFS  -> {os.path.relpath(dst, ROOT)}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--batch", default=os.path.join(ROOT, "tools", "comfyui", "beta_assets.json"))
    args = ap.parse_args()
    global RAW
    RAW = os.path.join(ROOT, "build", os.path.basename(args.batch).split("_assets")[0] + "_raw", "music")
    batch = json.load(open(args.batch))
    only = set(filter(None, args.only.split(",")))
    for item in batch["music"]:
        if only and item["id"] not in only:
            continue
        src = os.path.join(RAW, f'{item["id"]}_s{item["seed"]}.flac')
        if not os.path.exists(src):
            print("missing", src)
            continue
        process(item, src)


if __name__ == "__main__":
    main()
