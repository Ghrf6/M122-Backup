#!/bin/bash

# Cloud-Backup-Verzeichnis (OneDrive Remote)
cloud_backup_base="onedrive:/backup"

# Lokales Verzeichnis, in dem das Backup gespeichert werden soll
local_restore_base="/home/restore"

# UUID des gewünschten Backups (als Argument übergeben)
backup_uuid=$1

if [ -z "$backup_uuid" ]; then
    echo "Bitte geben Sie eine UUID an."
    exit 1
fi

# Funktion zur Suche des Backup-Verzeichnisses anhand der UUID
find_backup_by_uuid() {
    backup_info_dir="${local_backup_base}/backup_info"
    backup_entry=$(grep "$backup_uuid" "${backup_info_dir}/backup.txt")
    if [ -z "$backup_entry" ]; then
        echo "Kein Backup mit der angegebenen UUID gefunden."
        exit 1
    else
        echo "$backup_entry"
    fi
}

# Backup-Eintrag suchen
backup_entry=$(find_backup_by_uuid)
backup_dir=$(echo "$backup_entry" | awk -F', ' '{print $3}' | awk -F': ' '{print $2}')
timestamp=$(echo "$backup_entry" | awk -F', ' '{print $1}' | awk -F': ' '{print $2}')
dir_name=$(basename "$backup_dir")

# Cloud-Backup-Ziel
cloud_backup_path="${cloud_backup_base}/${dir_name}/${timestamp}"

# Lokales Zielverzeichnis für das Restore
local_restore_path="${local_restore_base}/${dir_name}/${timestamp}"

# Sicherstellen, dass das Zielverzeichnis existiert
mkdir -p "$local_restore_path"

# Backup aus der Cloud herunterladen
rclone copy "$cloud_backup_path" "$local_restore_path"
if [ $? -eq 0 ]; then
    echo "Backup erfolgreich wiederhergestellt: $local_restore_path"
else
    echo "Fehler beim Wiederherstellen des Backups."
    exit 1
fi
