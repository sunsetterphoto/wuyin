#!/bin/zsh
# Install and start Wuyin on an Android device/emulator, wait for the boot marker, save a screenshot.
#   tools/android_run.sh [serial] [apk]
# Defaults: serial emulator-5556 (AVD wuyin_test), apk build/android/wuyin-emulator.apk (GLES3).
# Real devices: pass their serial and build/android/wuyin-debug.apk (Vulkan).
# Start the test emulator first if needed:
#   $ANDROID_HOME/emulator/emulator -avd wuyin_test -gpu host -no-snapshot -no-boot-anim -port 5556 &
set -e
cd "${0:A:h}/.."
SERIAL=${1:-emulator-5556}
APK=${2:-build/android/wuyin-emulator.apk}
PKG=com.wuyin.game
A=(adb -s $SERIAL)

$A install -r $APK | tail -1
$A logcat -c
$A shell am force-stop $PKG
$A shell am start -n $PKG/com.godot.game.GodotAppLauncher >/dev/null
for i in {1..30}; do
  line=$($A logcat -d | grep -m1 "WUYIN_BOOT_OK" || true)
  [[ -n "$line" ]] && break
  sleep 2
done
[[ -z "$line" ]] && { echo "boot marker missing"; $A logcat -d | grep -E "godot" | tail -20; exit 1; }
echo "$line"
mkdir -p build/screens
sleep 2
if [[ $SERIAL == emulator-* ]]; then
  $A emu screenrecord screenshot "$PWD/build/screens/android.png" >/dev/null   # host-side, catches GPU surfaces
else
  $A exec-out screencap -p > build/screens/android.png
fi
echo "screenshot: build/screens/android.png"
