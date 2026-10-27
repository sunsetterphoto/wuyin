#!/usr/bin/env python3
"""Generate raw concept images for a batch file via the local ComfyUI (comfyui skill).
Usage: python3 tools/comfyui/generate.py tools/comfyui/assets_phase1_test.json build/assets_raw
Needs the ComfyUI server (python3 ~/.claude/skills/comfyui/scripts/comfy.py start).
"""
import json, os, subprocess, sys

COMFY = os.path.expanduser("~/.claude/skills/comfyui/scripts/comfy.py")
WORKFLOW = os.path.join(os.path.dirname(os.path.abspath(__file__)), "z_image_asset.json")


def run(prompt, seed, size, prefix, out):
    cmd = ["python3", COMFY, "run", WORKFLOW, "--set", f"5.text={prompt}", "--set", f"8.seed={seed}",
           "--set", f"7.width={size}", "--set", f"7.height={size}", "--set", f"10.filename_prefix=wuyin/{prefix}",
           "--out", out]
    r = subprocess.run(cmd, capture_output=True, text=True)
    print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else r.stderr[-400:])


def main():
    batch = json.load(open(sys.argv[1]))
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)
    for s in batch["sprites"]:
        run(f'{s["prompt"]}, {batch["sprite_style"]}', s["seed"], 768, "sprite_" + s["id"], out)
    for t in batch["tiles"]:
        run(f'{t["prompt"]}, {batch["tile_style"]}', t["seed"], 512, "tile_" + t["id"], out)


if __name__ == "__main__":
    main()
