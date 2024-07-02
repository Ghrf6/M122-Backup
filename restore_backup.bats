#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

@test "help should say how to structure the command" {
    run bash -c "source ./restore_backup.sh; help"
    [ "$status" -eq 1 ]
    assert_output --partial "Usage: $0 <path to backup> <target directory> <storage option>"
}

@test "check_command should fail for non-existent command" {
    run check_command non_existent_command
    [ "$status" -eq 1 ]
    [ "$output" = "Error: non_existent_command is not installed. Please install it first." ]
}

@test "check_command should work for existing command" {
    run check_command ls
    [ "$status" -eq 0 ]
}

@test "validate_inputs too few inputs should fail" {
    run bash -c "source ./restore_backup.sh; validate_inputs"
    [ "$status" -eq 1 ]
    assert_output --partial "Usage: $0 <path to backup> <target directory> <storage option>"
}

@test "validate_inputs with invalid target directory should fail" {
    run bash -c "source ./restore_backup.sh; validate_inputs test /invalid/path local"
    [ "$status" -eq 1 ]
    assert_output --partial "Error: The target directory '/invalid/path' does not exist."
}

@test "validate_inputs with invalid storage option should fail" {
    run bash -c "source ./restore_backup.sh; validate_inputs test /tmp invalid"
    [ "$status" -eq 1 ]
    assert_output --partial "Error: The storage option must be either 'cloud' or 'local'."
}

@test "validate_inputs with valid inputs should succeed" {
    mkdir -p valid_directory
    run bash -c "source ./restore_backup.sh; validate_inputs test valid_directory local"
    [ "$status" -eq 0 ]
    rm -rf valid_directory
}

@test "main function is called when valid arguments are provided" {
    mkdir -p valid_directory
    run ./restore_backup.sh path/to/backup valid_directory cloud
    [ "$status" -eq 1 ] # Assuming help is called instead of executing restore_data
    assert_output --partial "Enter password for decryption:"
    rm -rf valid_directory
}
