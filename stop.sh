#!/bin/bash
pkill -f "DeskClock.app/Contents/MacOS/DeskClock" 2>/dev/null || true
pkill -f "DeskClock" 2>/dev/null || true
echo stopped
