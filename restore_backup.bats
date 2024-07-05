#!/usr/bin/env bats

source ./restore_backup.sh

setup(){
    mkdir -p valid_directory
    touch /tmp/testfile
}

teardown(){
    rm -rf valid_directory
    rm -f /tmp/testfile
}

@test "help: should say how to structure the command" {
    run ./restore_backup.sh help
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: ./restore_backup.sh <path to backup> <target directory> <storage option>"* ]]
}

@test "check_command: should fail for non-existent command" {
    run ./restore_backup.sh check_command non_existent_command
    [ "$status" -eq 1 ]
}

@test "check_command: should work for existing command" {
    run bash -c "source ./restore_backup.sh; check_command ls"
    [ "$status" -eq 0 ]
}

@test "validate_inputs: too few inputs should fail" {
    run ./restore_backup.sh validate_inputs
    [ "$status" -eq 1 ]
}

@test "validate_inputs: too much inputs should fail" {
    run ./restore_backup.sh validate_inputs 1 2 3 4
    [ "$status" -eq 1 ]
}

@test "validate_inputs: with invalid target directory should fail" {
    run bash -c "source ./restore_backup.sh; validate_inputs test /invalid/path local"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: The target directory '/invalid/path' does not exist."* ]]
}

@test "validate_inputs: with invalid storage option should fail" {
    run bash -c "source ./restore_backup.sh; validate_inputs test /tmp invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: The storage option must be either 'cloud' or 'local'."* ]]
}

@test "validate_inputs: with valid inputs should succeed" {
    run bash -c "source ./restore_backup.sh; validate_inputs test valid_directory local"
    [ "$status" -eq 0 ]
}

@test "main: too few inputs should fail" {
    run ./restore_backup.sh main
    [ "$status" -eq 1 ]
}

@test "main: too much inputs should fail" {
    run ./restore_backup.sh main 1 2 3 4
    [ "$status" -eq 1 ]
}

@test "get_encrypted_backup_file_name should return the base name of the encrypted backup file path" {
    run bash -c "source ./restore_backup.sh; get_encrypted_backup_file_name /path/to/encrypted/backup/file.enc"
    [ "$status" -eq 0 ]
    [ "$output" = "file.enc" ]
}

@test "remove_file should remove the file if it exists" {

    run bash -c 'source ./restore_backup.sh; remove_file "/tmp/testfile"'
    [ "$status" -eq 0 ]
    [ ! -f /tmp/testfile ]
}

@test "remove_file should do nothing if the file does not exist" {
    run bash -c 'source ./restore_backup.sh; remove_file "/tmp/nonexistentfile"'
    [ "$status" -eq 0 ]
}
