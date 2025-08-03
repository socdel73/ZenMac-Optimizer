#!/bin/bash

# ZenMac Optimizer Script - Text Window Edition

# Demanar contrasenya una sola vegada
if [[ $EUID -ne 0 && -z "$ZENMAC_ROOT" ]]; then
  pass=$(/usr/bin/osascript -e 'Tell application "System Events" to display dialog "Introdueix la contrasenya per executar ZenMac:" default answer "" with hidden answer buttons {"OK"} default button 1' | awk -F "text returned:" '{print $2}')
  if ! echo "$pass" | sudo -S true 2>/dev/null; then
    /usr/bin/osascript -e 'Tell application "System Events" to display alert "Contrasenya incorrecta. Sortint." as critical'
    exit 1
  fi
  export ZENMAC_ROOT=1
  echo "$pass" | sudo -S bash "$0" "$@"
  exit $?
fi
export ZENMAC_ROOT=1

echo "🔧 Iniciant optimització de macOS..."

backup_dir="$HOME/Desktop/backup_plist_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

echo "[1/8] Tancant processos hsgamma..."
if pgrep -f hsgamma_FGRP5 > /dev/null; then
    pkill -f hsgamma_FGRP5
fi

echo "[2/8] Backup i eliminant LaunchDaemons orfes..."
for plist in /Library/LaunchDaemons/com.nginx.start.plist ~/Library/LaunchAgents/com.tailscale.ipcheck.plist; do
    if [ -f "$plist" ]; then sudo mv "$plist" "$backup_dir/"; fi
done

echo "[3/8] Eliminant extensions Objective-See..."
if ls /Library/SystemExtensions/*Objective-See* 1> /dev/null 2>&1; then
    sudo mv /Library/SystemExtensions/*Objective-See* "$backup_dir/"
fi

echo "[4/8] Netejant caches de sistema..."
sudo rm -rf /System/Library/Caches/* /Library/Caches/* ~/Library/Caches/* 2>/dev/null

echo "[5/8] Netejant logs antics..."
sudo rm -rf /private/var/log/* ~/Library/Logs/* 2>/dev/null

echo "[6/8] Netejant DerivedData i DeviceSupport d'Xcode..."
if [ -d ~/Library/Developer/Xcode ]; then
    rm -rf ~/Library/Developer/Xcode/DerivedData/* ~/Library/Developer/Xcode/iOS\ DeviceSupport/*
fi

echo "[7/8] Alliberant RAM inactiva..."
sudo purge

echo "[8/8] Desactivant Screen i Web Sharing..."
sudo launchctl bootout system/com.apple.screensharing 2>/dev/null
sudo launchctl bootout system/org.apache.httpd 2>/dev/null

echo "✅ Optimització finalitzada!"
echo "📂 Backup guardat a: $backup_dir"