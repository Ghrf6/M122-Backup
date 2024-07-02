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