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

get_encrypted_backup_file_name() {
    local path_to_encrypted_backup=$1
    echo "$(basename "$path_to_encrypted_backup")"
}

prompt_for_password() {
    if [[ -z "${TEST_PASSWORD:-}" ]]; then
        read -s -p "Enter password for decryption: " password
    else
        password=$TEST_PASSWORD
    fi
    echo "$password"
}

check_command() {
    local command=$1
    if ! command -v "$command" &> /dev/null; then
        echo "Error: $command is not installed."
        exit 1
    fi
}

restore_from_cloud() {
    local path_to_encrypted_backup=$1
    local target_directory=$2
    local secrets_file=$3
    local password=$4

    check_command "rclone"

    if sudo rclone copy "$path_to_encrypted_backup" "$target_directory"; then
        sudo openssl aes-128-cbc -d -a -pbkdf2 -pass pass:"$password" -in "$secrets_file" | sudo tar -xzvf - -C "$target_directory"
        echo "Data restored from the cloud from: $path_to_encrypted_backup to: $target_directory"
    else
        echo "Error: Failed to copy data from the cloud."
        exit 1
    fi
}

restore_from_local() {
    local path_to_encrypted_backup=$1
    local target_directory=$2
    local secrets_file=$3
    local password=$4

    if sudo cp "$path_to_encrypted_backup" "$target_directory"; then
        sudo openssl aes-128-cbc -d -a -pbkdf2 -pass pass:"$password" -in "$secrets_file" | sudo tar -xzvf - -C "$target_directory"
        echo "Local data restored from: $path_to_encrypted_backup to: $target_directory"
    else
        echo "Error: Failed to copy local data."
        exit 1
    fi
}

remove_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        sudo rm "$file"
    fi
}

restore_data() {
    local path_to_encrypted_backup=$1
    local target_directory=$2
    local storage_option=$3

    local encrypted_backup_file_name=$(get_encrypted_backup_file_name "$path_to_encrypted_backup")
    local secrets_file="$target_directory/$encrypted_backup_file_name"
    local password=$(prompt_for_password)

    if [[ "$storage_option" == "cloud" ]]; then
        restore_from_cloud "$path_to_encrypted_backup" "$target_directory" "$secrets_file" "$password"
    else
        restore_from_local "$path_to_encrypted_backup" "$target_directory" "$secrets_file" "$password"
    fi

    remove_file "$secrets_file"
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
