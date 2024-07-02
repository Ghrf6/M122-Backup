#!/usr/bin/env bats

@test "help: should say how to structure the command" {
    run bash -c "source ./restore_backup.sh; help"
    [ "$status" -eq 1 ]
}

@test "check_command: should fail for non-existent command" {
    run bash -c "source ./restore_backup.sh; check_command non_existent_command"
    [ "$status" -eq 1 ]
    [ "$output" = "Error: non_existent_command is not installed. Please install it first." ]
}

@test "check_command: should work for existing command" {
    run bash -c "source ./restore_backup.sh; check_command ls"
    [ "$status" -eq 0 ]
}

@test "validate_inputs: too few inputs should fail" {
    run bash -c "source ./restore_backup.sh; validate_inputs"
    [ "$status" -eq 1 ]
}

@test "validate_inputs: too much inputs should fail" {
    run bash -c "source ./restore_backup.sh; validate_inputs 1 2 3 4"
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
    mkdir -p valid_directory
    run bash -c "source ./restore_backup.sh; validate_inputs test valid_directory local"
    [ "$status" -eq 0 ]
    rm -rf valid_directory
}

@test "main: too few inputs should fail" {
    run bash -c "source ./restore_backup.sh; main"
    [ "$status" -eq 1 ]
}

@test "main: too much inputs should fail" {
    run bash -c "source ./restore_backup.sh; main 1 2 3 4"
    [ "$status" -eq 1 ]
}
