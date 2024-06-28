#!/bin/bash
# Encryption/Decryption for a specific directory

# Directory to be encrypted/decrypted
DIR="/mnt/c/users/ghrf4/desktop/m122-backup/test"
ENCRYPTED_FILE="test.enc"

encrypt() {
  tar --create --file - --gzip -- "$DIR" | \
  openssl aes-256-cbc -salt -out "$ENCRYPTED_FILE"
}

decrypt() {
  openssl aes-256-cbc -d -salt -in "$ENCRYPTED_FILE" | \
  tar -v --extract --gzip --directory /mnt/c/users/ghrf4/desktop/m122-backup/
}

# Call the function based on user input
case "$1" in
  encrypt)
    encrypt
    ;;
  decrypt)
    decrypt
    ;;
  *)
    echo "Usage: $0 {encrypt|decrypt}"
    exit 1
    ;;
esac
