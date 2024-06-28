#!/bin/bash
set -euo pipefail

message=${1:-}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        exit 1
    fi
}

encrypt_data() {
    local data_size="$1"
    local dest_dir="$2"
    local key_file="$3"
    local tomb_name="${dest_dir}.tomb"
    
    sudo tomb dig -s "$data_size" "$tomb_name"
    sudo tomb forge -k "$key_file"
    sudo tomb lock "$tomb_name" -k "$key_file"
}

create_backup() {
    local local_backup_base="/home/Backup"
    local cloud_backup_base="onedrive:/Backup"
    local key_dir="/home/Cert"
    
    local to_backup_dir="$1"
    local dir_name=$(basename "$to_backup_dir")
    local timestamp=$(date +"%H_%M-%Y.%m.%d")
    local local_destination="${local_backup_base}/${dir_name}/${timestamp}"
    local cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"
    local key_file="${key_dir}/${dir_name}_${timestamp}.tomb.key"
    local data_size=$(du -sm "$to_backup_dir" | cut -f1)
    
    if [[ "$data_size" -lt 10 ]]; then
        data_size=100
    fi

    echo "$data_size"
    if [[ -z "$message" ]]; then
        message="No message was written"
    fi

    echo -e "\n\n$timestamp $data_size MB $message\n\nTo restore local data, run:\n\t./restore_backup.sh $local_destination.tomb <target directory> local $key_file\n\nTo restore data from the cloud, run:\n\t./restore_backup.sh $cloud_destination.tomb <target directory> cloud $key_file" >> "$to_backup_dir/backup.txt"

    sudo mkdir -p "$local_destination"
    
    if sudo cp -r "$to_backup_dir"/* "$local_destination"; then
        encrypt_data "$data_size" "$local_destination" "$key_file"
        sudo rm -rf "$local_destination"/*
        sudo mv "${local_destination}.tomb" "$local_destination/"
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
    local root_folder="/mnt/c/Test"

    echo "Backup script started."
    readarray -t backup_dirs < <(find "$root_folder" -name "backup.txt" -exec dirname {} \;)
    timestamp=$(date +"%H_%M-%Y.%m.%d")

    check_command "rclone"
    check_command "tomb"

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

    echo "Backup script completed."
}

main "$@"
