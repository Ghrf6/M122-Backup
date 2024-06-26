#!/bin/bash

backup_dirs=$(find "/mnt/c/Projects" -name "backup.txt" -exec dirname {} \;)
timestamp=$(date +"%H_%M-%Y.%m.%d")

# Lokales Backup-Verzeichnis
local_backup_base="/home/backup"

# Cloud-Backup-Verzeichnis (OneDrive Remote)
cloud_backup_base="onedrive:/backup"

if [ -z "$backup_dirs" ]; then
    echo "Keine Dateien zum Backup gefunden."
else
    for to_backup_dir in $backup_dirs; do
        dir_name=$(basename "$to_backup_dir")
        
        local_destination="${local_backup_base}/${dir_name}/${timestamp}"
        cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"
        data_size=$(du -sh "$to_backup_dir" | cut -f1)

        echo -e "\n\n\n$timestamp $data_size\n\nUm die lokalen Daten zu restoren, führe:\n\t./restore_backup.sh -p $to_backup_dir/backup.txt -d <zielverzeichnis> -s local\n\nUm die Daten aus der Cloud zu restoren, führe:\n\t./restore_backup.sh -p $to_backup_dir/backup.txt -d <zielverzeichnis> -s cloud" >> "$to_backup_dir/backup.txt"
        
        # Lokales Backup
        sudo mkdir -p "$local_destination"
        sudo cp -r "$to_backup_dir"/* "$local_destination"
        echo "Lokales Backup erstellt für: $to_backup_dir"
        
        # Cloud-Backup 
        # rclone copy "$local_destination" "$cloud_destination"
        # echo "Cloud-Backup erstellt für: $to_backup_dir"
    done
fi
