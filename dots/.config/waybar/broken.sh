#!/usr/bin/bash
# 
print "hi";
print "Change detected in $path. Reloading Waybar..."
pkill -x waybar
CONFIG_FILE="$(pwd)/config.jsonc"
STYLE_FILE="$(pwd)/style.css"
waybar -c $CONFIG_FILE -s $STYLE_FILE &
print "Waybar reloaded."

