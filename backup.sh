#!/bin/bash

backup_dirs=$(find "/mnt/c/Projects" -name "backup.txt" -exec dirname {} \;)
timestamp=$(date +"%H_%M-%Y.%m.%d")

if [ -z "$backup_dirs" ]; then
    echo "Keine Dateien zum Backup gefunden."
else
    for to_backup_dir in $backup_dirs; do
        dir_name=$(basename "$to_backup_dir")
        destination="/home/backup/${dir_name}/${timestamp}"
        sudo mkdir -p "$destination"
        sudo cp -r "$to_backup_dir"/* "$destination"
        echo "Backup erstellt für: $to_backup_dir"
        echo "Letztes Backup: $timestamp" >> "$to_backup_dir/backup.txt"
    done
fi
