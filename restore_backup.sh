#!/bin/bash

path_to_backup=$1
local_path=$2
storage_option=$3

help() {
    echo "Help: $0 <path to backup> <local directory> <storage option>"
    exit 1
}

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Error: Incorrect number of arguments."
    help
fi

# Validate the path to backup
if [ -z "$path_to_backup" ]; then
    echo "Error: Please provide a correct path."
    help
fi

# Validate the local directory
if [ ! -d "$local_path" ]; then
    echo "Error: The local directory '$local_path' does not exist."
    help
fi

# Validate the storage option
if [ "$storage_option" != "cloud" ] && [ "$storage_option" != "local" ]; then
    echo "Error: The storage option must be either 'cloud' or 'local'."
    help
fi

# Extract the name of the original folder
original_folder_name=$(basename "$path_to_backup")

# Perform the restore operation
if [ "$storage_option" = "cloud" ]; then
    if ! command -v rclone &> /dev/null; then
        echo "Error: rclone is not installed. Please install it first."
        exit 1
    fi
    rclone copy "$path_to_backup" "$local_path/$original_folder_name"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy data from the cloud."
        exit 1
    fi
    echo "Daten aus der Cloud wiederhergestellt von: $path_to_backup nach: $local_path/$original_folder_name"
else
    sudo cp -r "$path_to_backup" "$local_path/$original_folder_name"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy local data."
        exit 1
    fi
    echo "Lokale Daten wiederhergestellt von: $path_to_backup nach: $local_path/$original_folder_name"
fi
