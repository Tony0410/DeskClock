#!/bin/bash
cd "$(dirname "$0")"
pkill -f "DeskClock.app/Contents/MacOS/DeskClock" 2>/dev/null || true
sleep 0.5
nohup "$(pwd)/build/DeskClock.app/Contents/MacOS/DeskClock" >/tmp/deskclock.log 2>&1 &
echo "launched pid $!"
sleep 1
cat /tmp/deskclock.log
