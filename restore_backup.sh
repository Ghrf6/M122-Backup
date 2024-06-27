#!/bin/bash
set -euo pipefail

help() {
    echo "Help: $0 <path to backup> <target directory> <storage option> <path to key>"
    exit 1
}

validate_inputs() {
    # Check if the correct number of arguments are provided
    if [[ "$#" -ne 4 ]]; then
        echo "Error: Incorrect number of arguments."
        help
    fi

    # Validate the path for the backup
    if [[ ! -d "$path_to_backup" ]]; then
        echo "Error: Please provide a correct path to the backup file."
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

    # Validate the key path
    if [[ ! -f "$key_path" ]]; then
        echo "Error: The key file '$key_path' does not exist."
        help
    fi
}

restore_data() {
    local base_path=$(basename "$path_to_backup")
    local backup_tomb_file="$path_to_backup/$base_path.tomb"
    echo "$backup_tomb_file"

    # Perform the restore operation
    if [[ "$storage_option" == "cloud" ]]; then
        if ! command -v rclone &> /dev/null; then
            echo "Error: rclone is not installed. Please install it first."
            exit 1
        fi
        if rclone copy "$backup_tomb_file" "$target_directory"; then
            sudo tomb open "$backup_tomb_file" -k "$key_path"
            echo "Data restored from the cloud from: $path_to_backup to: $target_directory"
        else
            echo "Error: Failed to copy data from the cloud."
            exit 1
        fi
    else
        if sudo cp -r "$backup_tomb_file" "$target_directory"; then
            sudo tomb open "$backup_tomb_file" -k "$key_path"
            echo "Local data restored from: $path_to_backup to: $target_directory"
        else
            echo "Error: Failed to copy local data."
            exit 1
        fi
    fi
}

main() {
    path_to_backup=$1
    target_directory=$2
    storage_option=$3
    key_path=$4

    echo "Restore script started."

    validate_inputs "$@"
    restore_data

    echo "Restore script completed."
}

main "$@"