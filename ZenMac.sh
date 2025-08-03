#!/bin/bash

# ===== Configuració d'idioma =====
CONFIG_FILE="$(dirname "$0")/config.txt"
DEFAULT_LANG="ca"

# Si hi ha fitxer de config, llegeix l'idioma, si no, crea'l amb per defecte
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    LANG="${LANG:-$DEFAULT_LANG}"
else
    LANG="$DEFAULT_LANG"
    echo "LANG=$DEFAULT_LANG" > "$CONFIG_FILE"
fi

# Si es crida amb --config, obre diàleg de selecció d'idioma
if [[ "$1" == "--config" ]]; then
    config_lang=$(/usr/bin/osascript -e 'choose from list {"ca","en","es"} with prompt "Selecciona idioma:" default items {"'"$LANG"'"}' 2>/dev/null)
    if [[ "$config_lang" != "false" && -n "$config_lang" ]]; then
        echo "LANG=$config_lang" > "$CONFIG_FILE"
        /usr/bin/osascript -e 'display dialog "Idioma guardat. Reinicia ZenMac per aplicar-ho." buttons {"OK"}'
    fi
    exit 0
fi

# Carrega les traduccions segons l'idioma
source "$(dirname "$0")/lang/$LANG.txt"

# ===== Sol·licitud de contrasenya =====
if [[ $EUID -ne 0 && -z "$ZENMAC_ROOT" ]]; then
  pass=$(/usr/bin/osascript -e "Tell application \"System Events\" to display dialog \"$PASSWORD_PROMPT\" default answer \"\" with hidden answer buttons {\"OK\"} default button 1" | awk -F "text returned:" '{print $2}')
  if ! echo "$pass" | sudo -S true 2>/dev/null; then
    /usr/bin/osascript -e "Tell application \"System Events\" to display alert \"$PASSWORD_WRONG\" as critical"
    exit 1
  fi
  export ZENMAC_ROOT=1
  echo "$pass" | sudo -S bash "$0" "$@"
  exit $?
fi
export ZENMAC_ROOT=1

# ===== Inici optimització =====
echo "$START"

# Backup amb permisos d'usuari
user_home=$(eval echo ~$SUDO_USER)
backup_dir="$user_home/Desktop/backup_plist_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
chown -R "$SUDO_USER":staff "$backup_dir"

# ===== Passos =====
echo "$STEP1"
if pgrep -f hsgamma_FGRP5 > /dev/null; then pkill -f hsgamma_FGRP5; fi

echo "$STEP2"
for plist in /Library/LaunchDaemons/com.nginx.start.plist ~/Library/LaunchAgents/com.tailscale.ipcheck.plist; do
    if [ -f "$plist" ]; then sudo mv "$plist" "$backup_dir/"; fi
done

echo "$STEP3"
if ls /Library/SystemExtensions/*Objective-See* 1> /dev/null 2>&1; then sudo mv /Library/SystemExtensions/*Objective-See* "$backup_dir/"; fi

echo "$STEP4"
sudo rm -rf /System/Library/Caches/* /Library/Caches/* ~/Library/Caches/* 2>/dev/null

echo "$STEP5"
sudo rm -rf /private/var/log/* ~/Library/Logs/* 2>/dev/null

echo "$STEP6"
if [ -d ~/Library/Developer/Xcode ]; then rm -rf ~/Library/Developer/Xcode/DerivedData/* ~/Library/Developer/Xcode/iOS\ DeviceSupport/*; fi

echo "$STEP7"
sudo purge

echo "$STEP8"
sudo launchctl bootout system/com.apple.screensharing 2>/dev/null
sudo launchctl bootout system/org.apache.httpd 2>/dev/null

# ===== Final =====
echo "$DONE"
echo "$BACKUP $backup_dir"