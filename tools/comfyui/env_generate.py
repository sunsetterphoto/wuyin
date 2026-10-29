#!/usr/bin/env python3
"""Generate the raw environment assets listed in tools/comfyui/env_assets.json via the local ComfyUI.

  python3 tools/comfyui/env_generate.py                          # tiles, props, portraits
  python3 tools/comfyui/env_generate.py tiles --only grass,sand  # some ids
  python3 tools/comfyui/env_generate.py props --only barrel --seed 2145   # try another seed

Raw files: build/env_raw/<section>/<id>_s<seed>.png (existing files are skipped, --force regenerates).
Image sizes: tiles 1024x1024, portraits 1024x1024, props follow the aspect of the final sprite
(about 0.6 megapixels, sides multiples of 64). Post-processing: tools/postprocess/env_postprocess.py.
Needs the ComfyUI server (shared queue): python3 ~/.claude/skills/comfyui/scripts/comfy.py status
"""
import argparse
import json
import os
import shutil
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
COMFY = os.path.expanduser("~/.claude/skills/comfyui/scripts/comfy.py")
IMG_WF = os.path.join(HERE, "z_image_asset.json")
BATCH = os.path.join(HERE, "env_assets.json")
RAW = os.path.join(ROOT, "build", "env_raw")
SECTIONS = ["tiles", "props", "portraits"]


def comfy_run(sets, dst, timeout=1800):
    tmp = os.path.join(RAW, "_tmp")
    cmd = ["python3", COMFY, "run", IMG_WF, "--out", tmp, "--timeout", str(timeout)]
    for k, v in sets.items():
        cmd += ["--set", f"{k}={v}"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    lines = r.stdout.strip().splitlines()
    if r.returncode != 0 or not lines or not os.path.exists(lines[-1]):
        print("FAILED", dst, r.stdout[-600:], r.stderr[-600:], flush=True)
        return False
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.move(lines[-1], dst)
    print(lines[-2] if len(lines) > 1 else "", "->", os.path.relpath(dst, ROOT), flush=True)
    return True


def prop_size(w, h, area=768 * 768):
    """Generation size with the sprite's aspect ratio (clamped to 1:2 .. 2:1), sides multiple of 64."""
    ar = max(0.5, min(2.0, w / h))
    gw = (area * ar) ** 0.5
    gh = gw / ar
    return int(round(gw / 64) * 64), int(round(gh / 64) * 64)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sections", nargs="*", default=SECTIONS)
    ap.add_argument("--only", default="")
    ap.add_argument("--seed", type=int, help="override seed (for trying alternatives)")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()
    batch = json.load(open(BATCH))
    only = set(filter(None, args.only.split(",")))
    for sec in args.sections:
        for item in batch[sec]:
            if only and item["id"] not in only:
                continue
            seed = args.seed if args.seed is not None else item["seed"]
            dst = os.path.join(RAW, sec, f'{item["id"]}_s{seed}.png')
            if os.path.exists(dst) and not args.force:
                print("exists", os.path.relpath(dst, ROOT), flush=True)
                continue
            if sec == "portraits":
                style, w, h = batch["styles"]["portrait"], 1024, 1024
            elif sec == "tiles":
                style, w, h = batch["styles"][item["style"]], 1024, 1024
            else:
                style = batch["styles"][item["style"]]
                w, h = prop_size(item["w"], item["h"])
            comfy_run({"5.text": f'{item["prompt"]}, {style}', "8.seed": seed, "7.width": w, "7.height": h,
                       "10.filename_prefix": "wuyin_env/" + sec}, dst)


if __name__ == "__main__":
    main()
