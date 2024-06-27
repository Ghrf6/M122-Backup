#!/bin/bash
set -euo pipefail

log_file="./backup.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$log_file"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log "Error: $1 is not installed. Please install it first."
        exit 1
    fi
}

create_backup() {
    local to_backup_dir="$1"
    local dir_name=$(basename "$to_backup_dir")
    local local_destination="${local_backup_base}/${dir_name}/${timestamp}"
    local cloud_destination="${cloud_backup_base}/${dir_name}/${timestamp}"
    local data_size=$(du -sh "$to_backup_dir" | cut -f1)

    # Write backup information to backup.txt
    echo -e "\n\n\n$timestamp $data_size\n\nTo restore local data, run:\n\t./restore_backup.sh $local_destination <target_directory> local\n\nTo restore data from the cloud, run:\n\t./restore_backup.sh $cloud_destination <target_directory> cloud" >> "$to_backup_dir/backup.txt"

    # Local Backup
    if sudo mkdir -p "$local_destination" && sudo cp -r "$to_backup_dir"/* "$local_destination"; then
        log "Local backup created for: $to_backup_dir at $local_destination"
    else
        log "Error: Failed to create local backup for: $to_backup_dir"
    fi

    # Cloud Backup
    #if rclone copy "$local_destination" "$cloud_destination"; then
    #    log "Cloud backup created for: $to_backup_dir at $cloud_destination"
    #else
    #    log "Error: Failed to create cloud backup for: $to_backup_dir"
    #fi
}

main() {
    log "Backup script started."

    readarray -t backup_dirs < <(find "/mnt/c/Projects" -name "backup.txt" -exec dirname {} \;)
    timestamp=$(date +"%H_%M-%Y.%m.%d")
    local_backup_base="/home/backup"
    cloud_backup_base="onedrive:/backup"

    check_command "rclone"

    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        log "No files found for backup."
        exit 0
    fi

    for to_backup_dir in "${backup_dirs[@]}"; do
        create_backup "$to_backup_dir"
    done

    log "Backup script completed."
}

main "$@"
