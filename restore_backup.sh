#!/bin/bash
set -euo pipefail

help() {
    echo "Help: $0 <path to backup> <target directory> <storage option>"
    exit 1
}

validate_inputs() {
    # Check if the correct number of arguments are provided
    if [[ "$#" -ne 3 ]]; then
        echo "Error: Incorrect number of arguments."
        help
    fi

    # Validate the path for the backup
    if [[ -z "$path_to_backup" ]]; then
        echo "Error: Please provide a correct path."
        help
    fi

    # Validate the local directory
    if [[ ! -d "$local_path" ]]; then
        echo "Error: The local directory '$local_path' does not exist."
        help
    fi

    # Validate the storage option
    if [[ "$storage_option" != "cloud" && "$storage_option" != "local" ]]; then
        echo "Error: The storage option must be either 'cloud' or 'local'."
        help
    fi
}

restore_data() {

    # Perform the restore operation
    if [[ "$storage_option" == "cloud" ]]; then
        if ! command -v rclone &> /dev/null; then
            echo "Error: rclone is not installed. Please install it first."
            exit 1
        fi
        if rclone copy "$path_to_backup" "$local_path"; then
            echo "Data restored from the cloud from: $path_to_backup to: $local_path"
        else
            echo "Error: Failed to copy data from the cloud."
            exit 1
        fi
    else
        if sudo cp -r "$path_to_backup" "$local_path"; then
            echo "Local data restored from: $path_to_backup to: $local_path"
        else
            echo "Error: Failed to copy local data."
            exit 1
        fi
    fi
}

main() {
    path_to_backup=$1
    local_path=$2
    storage_option=$3

    echo "Restore script started."

    validate_inputs "$@"
    restore_data

    echo "Restore script completed."
}

main "$@"
