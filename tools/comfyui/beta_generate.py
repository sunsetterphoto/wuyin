#!/usr/bin/env python3
"""Generate the raw beta assets listed in tools/comfyui/beta_assets.json via the local ComfyUI.

  python3 tools/comfyui/beta_generate.py                       # all sections
  python3 tools/comfyui/beta_generate.py lingshou chars        # some sections
  python3 tools/comfyui/beta_generate.py chars --only hero,yao # some ids
  python3 tools/comfyui/beta_generate.py chars --only hero --seed 351   # try another seed
  python3 tools/comfyui/beta_generate.py --batch tools/comfyui/full_assets.json lingshou   # other batch file

Raw dir follows the batch name: beta_assets.json -> build/beta_raw, full_assets.json -> build/full_raw.

Raw files land in build/beta_raw/<section>/<id>_s<seed>.(png|flac); existing files are skipped
(--force regenerates). Post-processing: tools/postprocess/beta_postprocess.py and beta_music.py.
Needs the ComfyUI server: python3 ~/.claude/skills/comfyui/scripts/comfy.py start
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
MUSIC_WF = os.path.join(HERE, "ace_step15_music.json")
RAW = os.path.join(ROOT, "build", "beta_raw")
SECTIONS = ["lingshou", "chars", "backgrounds", "ui", "music"]


def raw_dir(batch_path):
    """beta_assets.json -> build/beta_raw, full_assets.json -> build/full_raw."""
    name = os.path.basename(batch_path).split("_assets")[0]
    return os.path.join(ROOT, "build", f"{name}_raw")


def comfy_run(workflow, sets, dst, timeout=1800):
    tmp = os.path.join(RAW, "_tmp")
    cmd = ["python3", COMFY, "run", workflow, "--out", tmp, "--timeout", str(timeout)]
    for k, v in sets.items():
        cmd += ["--set", f"{k}={v}"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    lines = r.stdout.strip().splitlines()
    if r.returncode != 0 or not lines or not os.path.exists(lines[-1]):
        print("FAILED", dst, r.stdout[-600:], r.stderr[-600:])
        return False
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.move(lines[-1], dst)
    print(lines[-2] if len(lines) > 1 else "", "->", os.path.relpath(dst, ROOT), flush=True)
    return True


def image(prompt, seed, w, h, dst):
    return comfy_run(IMG_WF, {"5.text": prompt, "8.seed": seed, "7.width": w, "7.height": h,
                              "10.filename_prefix": "wuyin/" + os.path.basename(RAW)}, dst)


def music(batch, m, seed, dst):
    tags = f'{m["tags"]}, {batch["music_style"]}'
    secs = float(m["seconds"])
    return comfy_run(MUSIC_WF, {"5.tags": tags, "5.lyrics": "[Instrumental]", "5.seed": seed, "8.seed": seed,
                                "5.bpm": m["bpm"], "5.keyscale": m["key"], "5.duration": secs, "7.seconds": secs,
                                "10.filename_prefix": "wuyin/music"}, dst, timeout=3600)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sections", nargs="*", default=SECTIONS)
    ap.add_argument("--only", default="")
    ap.add_argument("--seed", type=int, help="override seed (for trying alternatives)")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--batch", default=os.path.join(HERE, "beta_assets.json"))
    args = ap.parse_args()
    global RAW
    RAW = raw_dir(args.batch)
    batch = json.load(open(args.batch))
    only = set(filter(None, args.only.split(",")))
    for sec in args.sections:
        for item in batch[sec]:
            if only and item["id"] not in only:
                continue
            seed = args.seed if args.seed is not None else item["seed"]
            ext = "flac" if sec == "music" else "png"
            dst = os.path.join(RAW, sec, f'{item["id"]}_s{seed}.{ext}')
            if os.path.exists(dst) and not args.force:
                print("exists", os.path.relpath(dst, ROOT))
                continue
            if sec == "derived":
                continue  # post-process only
            if sec == "music":
                music(batch, item, seed, dst)
                continue
            if sec == "backgrounds":
                prompt, w, h = f'{item["prompt"]}, {batch["styles"]["backgrounds"]}', 1280, 720
            elif sec == "ui":
                prompt, w, h = f'{item["prompt"]}, {batch["styles"]["ui"]}', item["width"], item["height"]
            elif sec == "chars" and item["style"] == "chars":
                prompt, w, h = f'{item["prompt"]}, {batch["styles"]["chars"]}', 768, 1152
            else:
                prompt, w, h = f'{item["prompt"]}, {batch["styles"][item["style"]]}', 768, 768
            if item.get("size", 48) >= 96:
                w = h = 1024
            image(prompt, seed, w, h, dst)


if __name__ == "__main__":
    main()
