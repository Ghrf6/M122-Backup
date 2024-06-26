#!/bin/bash

# Verzeichnisse finden, die "backup.txt" enthalten
backup_dirs=$(find "/mnt/c/Projects" -name "backup.txt" -exec dirname {} \;)

# Zeitstempel für das Backup
timestamp=$(date +"%H_%M-%Y.%m.%d")

# Lokales Backup-Verzeichnis
local_backup_base="/home/backup"

# Cloud-Backup-Verzeichnis (OneDrive Remote)
cloud_backup_base="onedrive:/backup"

# Überprüfen, ob Verzeichnisse zum Backup vorhanden sind
if [ -z "$backup_dirs" ]; then
    echo "Keine Dateien zum Backup gefunden."
else
    for to_backup_dir in $backup_dirs; do
        dir_name=$(basename "$to_backup_dir")
        
        # Lokales Backup-Ziel
        local_destination="${local_backup_base}/${dir_name}/${timestamp}"
        
        # Cloud-Backup-Ziel
        cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"
        
        # Lokales Backup erstellen
        sudo mkdir -p "$local_destination"
        sudo cp -r "$to_backup_dir"/* "$local_destination"
        echo "Lokales Backup erstellt für: $to_backup_dir"
        
        # Letztes Backup-Zeitstempel aktualisieren
        echo "Letztes Backup: $timestamp" >> "$to_backup_dir/backup.txt"
        
        # Cloud-Backup erstellen
        rclone copy "$local_destination" "$cloud_destination"
        echo "Cloud-Backup erstellt für: $to_backup_dir"
    done
fi
