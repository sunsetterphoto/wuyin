#!/bin/zsh
# Fetches the beta feedback from the phone: ratings, AI-text reports, playtest log, save.
#   tools/pull_feedback.sh [serial]   -> build/feedback/<timestamp>/
set -e
cd "${0:A:h}/.."
SERIAL=${1:-${ANDROID_SERIAL:-RFCX10BSPDA}}
PKG=com.wuyin.game
OUT=build/feedback/$(date +%Y%m%d-%H%M)
mkdir -p $OUT
for f in feedback.jsonl reports.jsonl playtest.jsonl save_0.json settings.cfg; do
  adb -s $SERIAL exec-out run-as $PKG cat files/$f > $OUT/$f 2>/dev/null || true
  [[ -s $OUT/$f ]] || rm -f $OUT/$f
done
ls -la $OUT
[[ -f $OUT/feedback.jsonl ]] && python3 -c "
import json,sys
for line in open('$OUT/feedback.jsonl'):
    d=json.loads(line); print(d['time'], d['context'], d['ratings'], '|', d['text'])
" || echo "noch kein Feedback gespeichert"
