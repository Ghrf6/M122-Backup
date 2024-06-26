#!/bin/bash

# Verzeichnisse mit "backup.txt" suchen und in ein Array speichern
readarray -t backup_dirs < <(find "/mnt/c/Projects" -name "backup.txt" -exec dirname {} \;)

# Timestamp für das Backup
timestamp=$(date +"%H_%M-%Y.%m.%d")

# Lokales Backup-Verzeichnis
local_backup_base="/home/backup"

# Cloud-Backup-Verzeichnis (OneDrive Remote)
cloud_backup_base="onedrive:/backup"

# Überprüfen, ob rclone installiert ist
if ! command -v rclone &> /dev/null; then
    echo "Error: rclone is not installed. Please install it first."
    exit 1
fi

# Prüfen, ob Verzeichnisse gefunden wurden
if [ ${#backup_dirs[@]} -eq 0 ]; then
    echo "Keine Dateien zum Backup gefunden."
    exit 0
fi

# Schleife durch gefundene Verzeichnisse
for to_backup_dir in "${backup_dirs[@]}"; do
    dir_name=$(basename "$to_backup_dir")

    # Zielverzeichnisse für lokale und Cloud-Backups
    local_destination="${local_backup_base}/${dir_name}/${timestamp}"
    cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"
    data_size=$(du -sh "$to_backup_dir" | cut -f1)

    # Backup-Informationen in backup.txt schreiben
    echo -e "\n\n\n$timestamp $data_size\n\nUm die lokalen Daten zu restoren, führe:\n\t./restore_backup.sh $local_destination <zielverzeichnis> local\n\nUm die Daten aus der Cloud zu restoren, führe:\n\t./restore_backup.sh $cloud_destination <zielverzeichnis> cloud" >> "$to_backup_dir/backup.txt"

    # Lokales Backup erstellen
    sudo mkdir -p "$local_destination"
    sudo cp -r "$to_backup_dir"/* "$local_destination"
    echo "Lokales Backup erstellt für: $to_backup_dir"

    # Cloud-Backup erstellen (auskommentiert)
    # rclone copy "$local_destination" "$cloud_destination"
    # echo "Cloud-Backup erstellt für: $to_backup_dir"
done
