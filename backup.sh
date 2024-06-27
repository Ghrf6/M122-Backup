#!/bin/bash
set -euo pipefail

readarray -t backup_dirs < <(find "/mnt/c/Projects" -name "backup.txt" -exec dirname {} \;)

timestamp=$(date +"%H_%M-%Y.%m.%d")

local_backup_base="/home/backup"
cloud_backup_base="onedrive:/backup"

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "Error: rclone is not installed. Please install it first."
    exit 1
fi

# Check if directories were found
if [ ${#backup_dirs[@]} -eq 0 ]; then
    echo "No files found for backup."
    exit 0
fi

for to_backup_dir in "${backup_dirs[@]}"; do
    dir_name=$(basename "$to_backup_dir")
    local_destination="${local_backup_base}/${dir_name}/${timestamp}"
    cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"

    data_size=$(du -sh "$to_backup_dir" | cut -f1)

    # Write backup information to backup.txt
    echo -e "\n\n\n$timestamp $data_size\n\nTo restore local data, run:\n\t./restore_backup.sh $local_destination <target_directory> local\n\nTo restore data from the cloud, run:\n\t./restore_backup.sh $cloud_destination <target_directory> cloud" >> "$to_backup_dir/backup.txt"

    # Local Backup
    sudo mkdir -p "$local_destination"
    sudo cp -r "$to_backup_dir"/* "$local_destination"
    echo "Local backup created for: $to_backup_dir"

    # Cloud Backup
    # rclone copy "$local_destination" "$cloud_destination"
    # echo "Cloud backup created for: $to_backup_dir"
done
