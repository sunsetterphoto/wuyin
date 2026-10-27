#!/bin/zsh
# Run the LLM benchmark scene on a connected phone with a given model.
#   tools/device_llm_bench.sh <model.gguf> [draft.mtp.gguf]
# Needs ANDROID_SERIAL and an installed debug build. Prints WUYIN_LLM lines plus temperatures.
set -e
MODEL=$1
DRAFT=${2:-}
PKG=com.wuyin.game
skin() { adb shell dumpsys thermalservice | grep -A12 "Current temperatures from HAL" | grep "mName=SKIN" | head -1 | sed -E 's/.*mValue=([0-9.]+).*/\1/'; }
adb push "$MODEL" /data/local/tmp/wuyin.gguf >/dev/null
adb shell "run-as $PKG sh -c 'mkdir -p files/models && cp /data/local/tmp/wuyin.gguf files/models/wuyin.gguf && rm -f files/models/wuyin.mtp.gguf'"
adb shell rm /data/local/tmp/wuyin.gguf
if [[ -n "$DRAFT" ]]; then
  adb push "$DRAFT" /data/local/tmp/wuyin.mtp.gguf >/dev/null
  adb shell "run-as $PKG sh -c 'cp /data/local/tmp/wuyin.mtp.gguf files/models/wuyin.mtp.gguf'"
  adb shell rm /data/local/tmp/wuyin.mtp.gguf
fi
adb shell am force-stop $PKG
adb shell "run-as $PKG sh -c 'echo res://scenes/dev/llm_bench.tscn > files/dev_autorun.txt'"
echo "model=$(basename $MODEL) draft=$(basename ${DRAFT:-none}) skin_start=$(skin)"
adb logcat -c
adb shell am start -n $PKG/com.godot.game.GodotAppLauncher >/dev/null
for i in {1..150}; do
  sleep 4
  adb logcat -d | grep -q -E "WUYIN_LLM DONE|SCRIPT ERROR" && break
done
adb logcat -d | grep -E "WUYIN_LLM|SCRIPT ERROR" | sed -E 's/^.*WUYIN_LLM /  /'
echo "skin_end=$(skin)"
adb shell am force-stop $PKG
