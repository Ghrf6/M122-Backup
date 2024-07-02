#!/bin/bash
set -euo pipefail

help() {
    echo "Usage: $0 <path to backup> <target directory> <storage option>"
    echo "path to backup: Path to the encrypted backup file."
    echo "target directory: Directory where the backup should be restored."
    echo "storage option: Either 'cloud' or 'local'."
    exit 1
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        exit 1
    fi
    return 0
}

validate_inputs() {
    local path_to_encrypted_backup=$1
    local target_directory=$2
    local storage_option=$3

    if [[ $# -ne 3 ]]; then
        help
    fi
    
    # Validate the target directory
    if [[ ! -d "$target_directory" ]]; then
        echo "Error: The target directory '$target_directory' does not exist."
        exit 1
    fi

    # Validate the storage option
    if [[ "$storage_option" != "cloud" && "$storage_option" != "local" ]]; then
        echo "Error: The storage option must be either 'cloud' or 'local'."
        exit 1
    fi
}

restore_data() {
    local path_to_encrypted_backup=$1
    local target_directory=$2
    local storage_option=$3

    local encrypted_backup_file_name=$(basename "$path_to_encrypted_backup")
    local secrets_file="$target_directory/$encrypted_backup_file_name"

    # Perform the restore operation
    read -s -p "Enter password for decryption: " password
    echo

    if [[ "$storage_option" == "cloud" ]]; then
        check_command "rclone"

        if sudo rclone copy "$path_to_encrypted_backup" "$target_directory"; then
            sudo openssl aes-128-cbc -d -a -pbkdf2 -pass pass:"$password" -in "$secrets_file" | sudo tar -xzvf - -C "$target_directory"
            echo "Data restored from the cloud from: $path_to_encrypted_backup to: $target_directory"
        else
            echo "Error: Failed to copy data from the cloud."
            exit 1
        fi
    else
        if sudo cp "$path_to_encrypted_backup" "$target_directory"; then
            sudo openssl aes-128-cbc -d -a -pbkdf2 -pass pass:"$password" -in "$secrets_file" | sudo tar -xzvf - -C "$target_directory"
            echo "Local data restored from: $path_to_encrypted_backup to: $target_directory"
        else
            echo "Error: Failed to copy local data."
            exit 1
        fi
    fi

    # Remove the encrypted file after restoration
    if [[ -f "$secrets_file" ]]; then
        sudo rm "$secrets_file"
    fi
}

main() {
    if [[ $# -ne 3 ]]; then
        help
    fi

    validate_inputs "$@"
    restore_data "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
