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

@test "encrypt_directory should fail if passwords do not match" {
    export TEST_PASSWORD="testpass"
    export TEST_PASSWORD_CONFIRM="wrongpass"

    local test_source_dir=$(mktemp -d)
    local test_dest_file=$(mktemp)

    run bash -c "source ./backup.sh; encrypt_directory '$test_source_dir' '$test_dest_file'"

    [ "$status" -eq 1 ]
    [ "$output" = "Passwords do not match." ]

    rm -rf "$test_source_dir"
    rm -f "$test_dest_file"
}

@test "create_backup_message should write the correct message to backup.txt" {
    sudo touch "/tmp/backup.txt"

    run bash -c "source ./backup.sh; create_backup_message '12_34-2023.07.01' 'Backup completed successfully' '/tmp' '/local/destination' '/cloud/destination'"

    run cat "/tmp/backup.txt"
    [[ "$output" == *"12_34-2023.07.01"* ]]
    [[ "$output" == *"/local/destination"* ]]
    [[ "$output" == *"/cloud/destination"* ]]
}

@test "create_backup_message should write default message if no message is provided" {
    sudo touch "/tmp/backup.txt"

    run bash -c "source ./backup.sh; create_backup_message '12_34-2023.07.01' '' '/tmp' '/local/destination' '/cloud/destination'"

    run cat "/tmp/backup.txt"
    [[ "$output" == *"12_34-2023.07.01"* ]]
    [[ "$output" == *"No message was written"* ]]
    [[ "$output" == *"/local/destination"* ]]
    [[ "$output" == *"/cloud/destination"* ]]
}

@test "main: should output 'No files found for backup.' when no files are present" {
    sudo mkdir /tmp/empty
    export root_folder="/tmp/empty"

    run main

    [ "$status" -eq 0 ]
    [[ "$output" == *"No files found for backup."* ]]
    rm -rf /tmp/empty
}