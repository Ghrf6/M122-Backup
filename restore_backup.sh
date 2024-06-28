#!/bin/bash
set -euo pipefail

help() {
    echo "Help: $0 <path to backup> <target directory> <storage option>"
    exit 1
}

validate_inputs() {
    # Validate the path for the backup
    if [[ ! -f "$path_to_backup" ]]; then
        echo "Error: Please provide a correct path to the backup file: $path_to_backup"
        help
    fi

    # Validate the target directory
    if [[ ! -d "$target_directory" ]]; then
        echo "Error: The target directory '$target_directory' does not exist."
        help
    fi

    # Validate the storage option
    if [[ "$storage_option" != "cloud" && "$storage_option" != "local" ]]; then
        echo "Error: The storage option must be either 'cloud' or 'local'."
        help
    fi
}

restore_data() {
    local backup_file="$path_to_backup"

    # Perform the restore operation
    if [[ "$storage_option" == "cloud" ]]; then
        if ! command -v rclone &> /dev/null; then
            echo "Error: rclone is not installed. Please install it first."
            exit 1
        fi
        if rclone copy "$backup_file" "$target_directory"; then
            sudo openssl aes-256-cbc -d -pbkdf2 -in "$backup_file" | \
            sudo tar -v --extract --gzip --directory "$target_directory"
            echo "Data restored from the cloud from: $path_to_backup to: $target_directory"
        else
            echo "Error: Failed to copy data from the cloud."
            exit 1
        fi
    else
        if sudo cp "$backup_file" "$target_directory"; then
            sudo openssl aes-256-cbc -d -pbkdf2 -in "$backup_file" | \
            sudo tar -v --extract --gzip --directory "$target_directory"
            echo "Local data restored from: $path_to_backup to: $target_directory"
        else
            echo "Error: Failed to copy local data."
            exit 1
        fi
    fi
}

main() {
    if [[ "$#" -ne 3 ]]; then
        help
    fi

    path_to_backup=$1
    target_directory=$2
    storage_option=$3

    echo "Restore script started."

    validate_inputs "$@"
    restore_data

    echo "Restore script completed."
}

main "$@"
