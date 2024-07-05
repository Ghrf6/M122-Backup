#!/bin/bash
set -euo pipefail

# Author: Ghrf6
# This script restores data from an encrypted backup file to a specified directory.
# It supports restoring from either local storage or cloud storage.

RCLONE_CONFIG="Path/to/file"  # Update this to the correct path with rclone config file

# Function to display help message and usage instructions
help() {
    echo "Usage: $0 <path to backup> <target directory> <storage option>"
    echo "path to backup: Path to the encrypted backup file."
    echo "target directory: Directory where the backup should be restored."
    echo "storage option: Either 'cloud' or 'local'."
    exit 1
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        exit 1
    fi
    return 0
}

# Function to validate input parameters
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

# Function to get the name of the encrypted backup file
get_encrypted_backup_file_name() {
    local path_to_encrypted_backup=$1
    echo "$(basename "$path_to_encrypted_backup")"
}

# Function to prompt for password
prompt_for_password() {
    if [[ -z "${TEST_PASSWORD:-}" ]]; then
        read -s -p "Enter password for decryption: " password
    else
        password=$TEST_PASSWORD
    fi
    echo "$password"
}

# Check if the required command is installed
check_command() {
    local command=$1
    if ! command -v "$command" &> /dev/null; then
        echo "Error: $command is not installed."
        exit 1
    fi
}

# Function to restore data from the cloud
restore_from_cloud() {
    local path_to_encrypted_backup=$1
    local target_directory=$2
    local secrets_file=$3
    local password=$4

    check_command "rclone"

    echo "Starting cloud restore: $path_to_encrypted_backup to $target_directory"

    if sudo rclone --config "$RCLONE_CONFIG" copy "$path_to_encrypted_backup" "$target_directory"; then
        sudo openssl aes-128-cbc -d -a -pbkdf2 -pass pass:"$password" -in "$secrets_file" | sudo tar -xzvf - -C "$target_directory"
        echo "Data restored from the cloud from: $path_to_encrypted_backup to: $target_directory"
    else
        echo "Error: Failed to copy data from the cloud."
        exit 1
    fi
}

# Function to restore data from a local backup
restore_from_local() {
    local path_to_encrypted_backup=$1
    local target_directory=$2
    local secrets_file=$3
    local password=$4

    echo "Starting local restore: $path_to_encrypted_backup to $target_directory"

    if sudo cp "$path_to_encrypted_backup" "$target_directory"; then
        sudo openssl aes-128-cbc -d -a -pbkdf2 -pass pass:"$password" -in "$secrets_file" | sudo tar -xzvf - -C "$target_directory"
        echo "Local data restored from: $path_to_encrypted_backup to: $target_directory"
    else
        echo "Error: Failed to copy local data."
        exit 1
    fi
}

# Function to remove a file
remove_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        sudo rm "$file"
    fi
}

# Main function to restore data
restore_data() {
    local path_to_encrypted_backup=$1
    local target_directory=$2
    local storage_option=$3

    local encrypted_backup_file_name=$(get_encrypted_backup_file_name "$path_to_encrypted_backup")
    local secrets_file="$target_directory/$encrypted_backup_file_name"
    local password=$(prompt_for_password)

    echo "Restoring backup: $path_to_encrypted_backup to $target_directory using $storage_option storage"

    if [[ "$storage_option" == "cloud" ]]; then
        restore_from_cloud "$path_to_encrypted_backup" "$target_directory" "$secrets_file" "$password"
    else
        restore_from_local "$path_to_encrypted_backup" "$target_directory" "$secrets_file" "$password"
    fi

    remove_file "$secrets_file"
}

# Main entry point of the script
main() {
    if [[ $# -ne 3 ]]; then
        help
    fi

    validate_inputs "$@"
    restore_data "$@"
}

# Ensure the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
