#!/bin/bash
set -euo pipefail

# Author: Ghrf6
# This script automates the process of creating backups both locally and to cloud storage.
# It encrypts the backup files for security and logs the backup details.

# Standard backup paths
default_local_backup_base="/mnt/c/Backup"
default_cloud_backup_base="onedrive:/Backup"
root_folder="/mnt/c/Test"

local_backup_base="$default_local_backup_base"
cloud_backup_base="$default_cloud_backup_base"
message=${1:-}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        exit 1
    fi
    return 0
}

# Function to encrypt a directory
encrypt_directory() {
    local source_dir="$1"
    local dest_file="$2"

    if [[ -z "${TEST_PASSWORD:-}" ]]; then
        read -s -p "Enter password for encryption: " password
        echo
        read -s -p "Confirm password: " password_confirm
        echo
    else
        password=$TEST_PASSWORD
    fi

    if [ "$password" != "$password_confirm" ]; then
        echo "Passwords do not match."
        exit 1
    fi
    echo "Store your password in a safe place. You will need it to restore your data."

    (cd "$source_dir" && sudo tar -czvf - .) | sudo openssl aes-128-cbc -a -salt -pbkdf2 -pass pass:"$password" -out "$dest_file"
}

# Wrapper function for encrypting data
encrypt_data() {
    local source_dir="$1"
    local dest_file="$2"
    encrypt_directory "$source_dir" "$dest_file"
}

# Function to get the current timestamp
get_timestamp() {
    echo "$(date +"%H_%M-%Y.%m.%d")"
}

# Function to create a backup message
create_backup_message() {
    local timestamp="$1"
    local message="$2"
    local to_backup_dir="$3"
    local local_destination="$4"
    local cloud_destination="$5"

    if [[ -z "$message" ]]; then
        message="No message was written"
    fi

    echo -e "\n\n$timestamp $message\n\nTo restore local data, run:\n\t./restore_backup.sh $local_destination/$timestamp.enc <target directory> local\n\nTo restore data from the cloud, run:\n\t./restore_backup.sh $cloud_destination/$timestamp.enc <target directory> cloud" >> "$to_backup_dir/backup.txt"
}

# Function to create a local backup
create_local_backup() {
    local to_backup_dir="$1"
    local local_destination="$2"

    sudo mkdir -p "$local_destination"
    sudo cp -r "$to_backup_dir"/* "$local_destination"
    encrypt_data "$local_destination" "${local_destination}.enc"
    sudo rm -rf "$local_destination"/*
    sudo mv "${local_destination}.enc" "$local_destination/"
    sudo cp "$to_backup_dir/backup.txt" "$local_destination/backup.txt"
    echo "Local backup created for: $to_backup_dir at $local_destination"
}

# Function to create a cloud backup using rclone
create_cloud_backup() {
    local local_destination="$1"
    local cloud_destination="$2"
    if rclone copy "$local_destination" "$cloud_destination"; then
        echo "Cloud backup created for: $local_destination at $cloud_destination"
    else
        echo "Error: Failed to create cloud backup for: $local_destination"
    fi
}

# Main function to create a backup
create_backup() {
    local to_backup_dir="$1"
    local dir_name=$(basename "$to_backup_dir")
    local timestamp=$(get_timestamp)
    local local_destination="${local_backup_base}/${dir_name}/${timestamp}"
    local cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"

    create_backup_message "$timestamp" "$message" "$to_backup_dir" "$local_destination" "$cloud_destination"
    create_local_backup "$to_backup_dir" "$local_destination"
    create_cloud_backup "$local_destination" "$cloud_destination"
}

# Function to display help message
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

# Function to parse input parameters
test_input_parameters() {
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
}

# Main function to run the backup script
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
        create_backup "$to_backup_dir"
    done
}

# Entry point of the script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_input_parameters "$@"
    main "$@"
fi
