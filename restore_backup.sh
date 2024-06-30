#!/bin/bash
set -euo pipefail

help() {
    echo "Usage: $0 <path to backup> <target directory> <storage option>"
    exit 1
}

validate_inputs() {
    # Validate the path for the backup
    if [[ ! -f "$path_to_encrypted_backup" ]]; then
        echo "Error: Please provide a correct path to the backup file: $path_to_encrypted_backup"
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
    local encrypted_backup_file_name=$(basename "$path_to_encrypted_backup")
    local secrets_file="$target_directory/$encrypted_backup_file_name"

    # Perform the restore operation
    read -s -p "Enter password for decryption: " password
    echo

    if [[ "$storage_option" == "cloud" ]]; then
        if ! command -v rclone &> /dev/null; then
            echo "Error: rclone is not installed. Please install it first."
            exit 1
        fi

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
    if [[ "$#" -ne 3 ]]; then
        help
    fi

    path_to_encrypted_backup=$1
    target_directory=$2
    storage_option=$3

    validate_inputs
    restore_data
}

main "$@"
