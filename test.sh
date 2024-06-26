#!/bin/bash

# Cloud-Backup-Verzeichnis (OneDrive Remote)
cloud_backup_base="onedrive:/backup"

# Lokales Verzeichnis, in dem das Backup gespeichert werden soll
local_restore_base="/home/restore"

# Backup-Info-Verzeichnis
backup_info_dir="/home/backup/backup_info"

# Pfad der zu sichernden Dateien (als Argument übergeben)
restore_path=$1

# Lokales oder Cloud-Ziel (als Option übergeben)
while getopts "l:c:" opt; do
  case $opt in
    l) 
      local_restore_path=$OPTARG
      ;;
    c)
      cloud_restore_path=$OPTARG
      ;;
    \?)
      echo "Ungültige Option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Sicherstellen, dass entweder ein lokales oder ein Cloud-Ziel angegeben ist
if [ -z "$local_restore_path" ] && [ -z "$cloud_restore_path" ]; then
    echo "Bitte geben Sie ein Zielverzeichnis mit -l für lokal oder -c für Cloud an."
    exit 1
fi

# Funktion zur Suche des Backup-Verzeichnisses anhand des Pfads
find_backup_by_path() {
    backup_entry=$(grep "$restore_path" "${backup_info_dir}/backup.txt")
    if [ -z "$backup_entry" ]; then
        echo "Kein Backup für den angegebenen Pfad gefunden."
        exit 1
    else
        echo "$backup_entry"
    fi
}

# Backup-Eintrag suchen
backup_entry=$(find_backup_by_path)
local_backup_path=$(echo "$backup_entry" | awk -F', ' '{print $4}' | awk -F': ' '{print $2}')
cloud_backup_path=$(echo "$backup_entry" | awk -F', ' '{print $5}' | awk -F': ' '{print $2}')

# Sicherstellen, dass das Zielverzeichnis existiert
if [ -n "$local_restore_path" ]; then
    mkdir -p "$local_restore_path"
    # Backup aus dem lokalen Verzeichnis herunterladen
    cp -r "$local_backup_path"/* "$local_restore_path"
    if [ $? -eq 0 ]; then
        echo "Lokales Backup erfolgreich wiederhergestellt: $local_restore_path"
    else
        echo "Fehler beim Wiederherstellen des lokalen Backups."
        exit 1
    fi
elif [ -n "$cloud_restore_path" ]; then
    mkdir -p "$cloud_restore_path"
    # Backup aus der Cloud herunterladen
    rclone copy "$cloud_backup_path" "$cloud_restore_path"
    if [ $? -eq 0 ]; then
        echo "Cloud-Backup erfolgreich wiederhergestellt: $cloud_restore_path"
    else
        echo "Fehler beim Wiederherstellen des Cloud-Backups."
        exit 1
    fi
fi
