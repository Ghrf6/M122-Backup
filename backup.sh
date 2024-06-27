#!/bin/bash
set -euo pipefail

message=${1:-}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        exit 1
    fi
}

create_backup() {
    local to_backup_dir="$1"
    local dir_name=$(basename "$to_backup_dir")
    local local_destination="${local_backup_base}/${dir_name}/${timestamp}"
    local cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"
    local data_size=$(du -sh "$to_backup_dir" | cut -f1)

    if [[ -z "$message" ]]; then
        message="No message was written"
    fi

    # Write backup information to backup.txt
    echo -e "\n\n$timestamp $data_size $message\n\nTo restore local data, run:\n\t./restore_backup.sh $local_destination <target directory> local\n\nTo restore data from the cloud, run:\n\t./restore_backup.sh $cloud_destination <target directory> cloud" >> "$to_backup_dir/backup.txt"

    # Local Backup
    if sudo mkdir -p "$local_destination" && sudo cp -r "$to_backup_dir"/* "$local_destination"; then
        echo "Local backup created for: $to_backup_dir at $local_destination"
    else
        echo "Error: Failed to create local backup for: $to_backup_dir"
    fi

    # Cloud Backup
    #if rclone copy "$local_destination" "$cloud_destination"; then
    #    echo "Cloud backup created for: $to_backup_dir at $cloud_destination"
    #else
    #    echo "Error: Failed to create cloud backup for: $to_backup_dir"
    #fi
}

main() {
    # change to the folder path you want the backup to be stored locally
    local_backup_base="/home/backup"
    # change to the folder path you want the backup to be stored in the cloud
    cloud_backup_base="onedrive:/backup"
    # root folder for your backups
    root_folder="/mnt/c/Projects"

    echo "Backup script started."
    readarray -t backup_dirs < <(find "$root_folder" -name "backup.txt" -exec dirname {} \;)
    timestamp=$(date +"%H_%M-%Y.%m.%d")

    check_command "rclone"

    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        echo "No files found for backup."
        exit 0
    fi

    for to_backup_dir in "${backup_dirs[@]}"; do
        create_backup "$to_backup_dir"
    done

    echo "Backup script completed."
}

main "$@"
