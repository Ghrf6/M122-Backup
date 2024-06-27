#!/bin/bash
set -euo pipefail

log_file="./backup.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$log_file"
}

help() {
    log "Help: $0 <path to backup> <local directory> <storage option>"
    exit 1
}

validate_inputs() {
    # Check if the correct number of arguments are provided
    if [[ "$#" -ne 3 ]]; then
        log "Error: Incorrect number of arguments."
        help
    fi

    # Validate the path for the backup
    if [[ -z "$path_to_backup" ]]; then
        log "Error: Please provide a correct path."
        help
    fi

    # Validate the local directory
    if [[ ! -d "$local_path" ]]; then
        log "Error: The local directory '$local_path' does not exist."
        help
    fi

    # Validate the storage option
    if [[ "$storage_option" != "cloud" && "$storage_option" != "local" ]]; then
        log "Error: The storage option must be either 'cloud' or 'local'."
        help
    fi
}

restore_data() {
    # Extract the name of the original folder
    local original_folder_name=$(basename "$path_to_backup")

    # Perform the restore operation
    if [[ "$storage_option" == "cloud" ]]; then
        if ! command -v rclone &> /dev/null; then
            log "Error: rclone is not installed. Please install it first."
            exit 1
        fi
        if rclone copy "$path_to_backup" "$local_path/$original_folder_name"; then
            log "Data restored from the cloud from: $path_to_backup to: $local_path/$original_folder_name"
        else
            log "Error: Failed to copy data from the cloud."
            exit 1
        fi
    else
        if sudo cp -r "$path_to_backup" "$local_path/$original_folder_name"; then
            log "Local data restored from: $path_to_backup to: $local_path/$original_folder_name"
        else
            log "Error: Failed to copy local data."
            exit 1
        fi
    fi
}

main() {
    path_to_backup=$1
    local_path=$2
    storage_option=$3

    log "Restore script started."

    validate_inputs "$@"
    restore_data

    log "Restore script completed."
}

main "$@"
