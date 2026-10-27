#!/bin/zsh
# Full local check: unit tests, headless boot, all export presets.
#   tools/check.sh            tests + boot
#   tools/check.sh --export   additionally export every preset to build/
set -e
cd "${0:A:h}/.."
GODOT=${GODOT:-godot}

$GODOT --headless --path game --import >/dev/null 2>&1
echo "== tests"
$GODOT --headless --path game -s res://tests/run_tests.gd 2>&1 | grep -E "TESTS|FAIL|ERROR"
echo "== boot"
$GODOT --headless --path game -- --quit-after-boot 2>&1 | grep -E "WUYIN_BOOT_OK" || { echo "boot marker missing"; exit 1; }

if [[ "$1" == "--export" ]]; then
  mkdir -p build/{android,linux,windows}
  for preset in "Android" "Android Emulator" "Linux" "Linux x86_64" "Windows"; do
    echo "== export $preset"
    $GODOT --headless --path game --export-debug "$preset" 2>&1 | grep -E "ERROR" && exit 1 || true
  done
  ls -la build/*/
fi
