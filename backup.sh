#!/bin/bash
set -euo pipefail

# Standard Backup Pfade
default_local_backup_base="/mnt/c/work/Backup"
default_cloud_backup_base="onedrive:/Backup"
root_folder="/mnt/c/work/Test"

message=${1:-}

# Funktionen
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        exit 1
    fi
}

encrypt_data() {
    local source_dir="$1"
    local dest_file="$2"

    read -s -p "Enter password for encryption: " password
    echo
    read -s -p "Confirm password: " password_confirm
    echo

    if [ "$password" != "$password_confirm" ]; then
        echo "Passwords do not match."
        exit 1
    fi

    (cd "$source_dir" && sudo tar -czvf - .) | sudo openssl aes-128-cbc -a -salt -pbkdf2 -pass pass:"$password" -out "$dest_file"
    
    if [ $? -eq 0 ]; then
        echo "Data encrypted successfully."
    else
        echo "Error: Data encryption failed."
        exit 1
    fi
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
    
    sudo cp -r "$to_backup_dir"/* "$local_destination"
    encrypt_data "$local_destination" "${local_destination}.enc"
    sudo rm -rf "$local_destination"/*
    sudo mv "${local_destination}.enc" "$local_destination/"
    sudo cp "$to_backup_dir/backup.txt" "$local_destination/backup.txt"
    echo "Local backup created for: $to_backup_dir at $local_destination"

    if rclone copy "$local_destination" "$cloud_destination"; then
        echo "Cloud backup created for: $to_backup_dir at $cloud_destination"
    else
        echo "Error: Failed to create cloud backup for: $to_backup_dir"
    fi
}

show_help() {
    echo "Usage: backup.sh [options] [message]"
    echo
    echo "Options:"
    echo "  -l                Specify the local backup base directory (default: $default_local_backup_base)"
    echo "  -c                Specify the cloud backup base directory (default: $default_cloud_backup_base)"
    echo "  -h, --help        Show this help message and exit"
    echo
    echo "Arguments:"
    echo "  message           Optional message to include in the backup log"
    echo
    exit 0
}

# Standard Pfade
local_backup_base="$default_local_backup_base"
cloud_backup_base="$default_cloud_backup_base"

# Argumente verarbeiten
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -l)
            local_backup_base="$2"
            shift 2
            ;;
        -c)
            cloud_backup_base="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            message="$1"
            shift
            ;;
    esac
done

main() {
    readarray -t backup_dirs < <(find "$root_folder" -name "backup.txt" -exec dirname {} \;)
    timestamp=$(date +"%H_%M-%Y.%m.%d")

    check_command "rclone"
    check_command "openssl"

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
