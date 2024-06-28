#!/bin/bash
set -euo pipefail

local_backup_base="/mnt/c/Backup"
cloud_backup_base="onedrive:/Backup"
root_folder="/mnt/c/Test"

message=${1:-}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        exit 1
    fi
}

encrypt_data() {
    local dest_dir="$1"
    encrypted_file="${dest_dir}.enc"

    tar --create --file - --gzip -- "$dest_dir" | \
    openssl aes-256-cbc -salt -out "$encrypted_file"
}

create_backup() {
    local to_backup_dir="$1"
    local dir_name=$(basename "$to_backup_dir")
    local timestamp=$(date +"%H_%M-%Y.%m.%d")
    local local_destination="${local_backup_base}/${dir_name}/${timestamp}"
    local cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"
    local data_size=$(du -sm "$to_backup_dir" | cut -f1)
    
    if [[ -z "$message" ]]; then
        message="No message was written"
    fi

    echo -e "\n\n$timestamp $data_size MB $message\n\nTo restore local data, run:\n\t./restore_backup.sh $local_destination/$timestamp.enc <target directory> local\n\nTo restore data from the cloud, run:\n\t./restore_backup.sh $cloud_destination/$timestamp.enc <target directory> cloud" >> "$to_backup_dir/backup.txt"

    sudo mkdir -p "$local_destination"
    
    if sudo cp -r "$to_backup_dir"/* "$local_destination"; then
        encrypt_data "$local_destination"
        sudo rm -rf "$local_destination"/*
        sudo mv "${local_destination}.enc" "$local_destination/"
        sudo cp "$to_backup_dir/backup.txt" "$local_destination/backup.txt"
        echo "Local backup created for: $to_backup_dir at $local_destination"
    else
        echo "Error: Failed to create local backup for: $to_backup_dir"
        return
    fi

    if rclone copy "$local_destination" "$cloud_destination"; then
        echo "Cloud backup created for: $to_backup_dir at $cloud_destination"
    else
        echo "Error: Failed to create cloud backup for: $to_backup_dir"
    fi
}

main() {
    readarray -t backup_dirs < <(find "$root_folder" -name "backup.txt" -exec dirname {} \;)
    timestamp=$(date +"%H_%M-%Y.%m.%d")

    check_command "rclone"

    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        echo "No files found for backup."
        exit 0
    fi

    for to_backup_dir in "${backup_dirs[@]}"; do
        if [[ -d "$to_backup_dir" ]]; then
            create_backup "$to_backup_dir"
        else
            echo "Error: Directory $to_backup_dir does not exist."
        fi
    done
}

main "$@"
