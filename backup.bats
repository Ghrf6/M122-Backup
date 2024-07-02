#!/usr/bin/env bats

source ./backup.sh

@test "check_command should fail for non-existent command" {
    run check_command non_existent_command
    [ "$status" -eq 1 ]
    [ "$output" = "Error: non_existent_command is not installed. Please install it first." ]
}

@test "check_command should work for existing command" {
    run check_command ls
    [ "$status" -eq 0 ]
}

@test "show_help should display usage information" {
    run show_help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: backup.sh [options] [message]"* ]]
}

@test "test_input_parameters sets local_backup_base correctly" {
    local_backup_base="$default_local_backup_base"
    cloud_backup_base="$default_cloud_backup_base"
    message=""

    test_input_parameters -l /new/local/path -c /new/cloud/path "Test message"

    [ "$local_backup_base" = "/new/local/path" ]
    [ "$cloud_backup_base" = "/new/cloud/path" ]
    [ "$message" = "Test message" ]
}

@test "test_input_parameters shows help" {
    run test_input_parameters --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: backup.sh [options] [message]"* ]]
}

@test "test_input_parameters sets message correctly" {
    local_backup_base="$default_local_backup_base"
    cloud_backup_base="$default_cloud_backup_base"
    message=""

    test_input_parameters "Test message"

    [ "$message" = "Test message" ]
}

@test "get_timestamp should return the correct timestamp format" {
    run get_timestamp
    [ "$status" -eq 0 ]

    [[ "$output" =~ ^[0-9]{2}_[0-9]{2}-[0-9]{4}\.[0-9]{2}\.[0-9]{2}$ ]]
}

@test "create_backup_message should write the correct message to backup.txt" {
    local timestamp="12_34-2023.07.01"
    local message="Backup completed successfully"
    local to_backup_dir="/tmp"
    local local_destination="/local/destination"
    local cloud_destination="/cloud/destination"

    mkdir -p "$to_backup_dir"
    > "$to_backup_dir/backup.txt"

    run bash -c "source ./backup.sh; create_backup_message '$timestamp' '$message' '$to_backup_dir' '$local_destination' '$cloud_destination'"

    [ "$status" -eq 0 ]

    expected_output="

12_34-2023.07.01 Backup completed successfully

To restore local data, run:
    ./backup.sh /local/destination/12_34-2023.07.01.enc <target directory> local

To restore data from the cloud, run:
    ./backup.sh /cloud/destination/12_34-2023.07.01.enc <target directory> cloud"

    run cat "$to_backup_dir/backup.txt"
    [ "$output" = "$expected_output" ]
}

@test "create_backup_message should write default message if no message is provided" {
    local timestamp="12_34-2023.07.01"
    local message=""
    local to_backup_dir="/tmp"
    local local_destination="/local/destination"
    local cloud_destination="/cloud/destination"

    mkdir -p "$to_backup_dir"
    > "$to_backup_dir/backup.txt"

    run bash -c "source ./backup.sh; create_backup_message '$timestamp' '$message' '$to_backup_dir' '$local_destination' '$cloud_destination'"

    [ "$status" -eq 0 ]

    expected_output="

12_34-2023.07.01 No message was written

To restore local data, run:
    ./backup.sh /local/destination/12_34-2023.07.01.enc <target directory> local

To restore data from the cloud, run:
    ./backup.sh /cloud/destination/12_34-2023.07.01.enc <target directory> cloud"

    run cat "$to_backup_dir/backup.txt"
    [ "$output" = "$expected_output" ]
}
