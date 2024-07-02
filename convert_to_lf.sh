#!/bin/bash

# Verzeichnis, das konvertiert werden soll
directory="./bats-mock"

# Überprüfen, ob ein Verzeichnis als Argument übergeben wurde
if [ "$#" -eq 1 ]; then
    directory="$1"
fi

# Alle Dateien im Verzeichnis und seinen Unterverzeichnissen durchlaufen
find "$directory" -type f | while read -r file; do
    # Konvertierung zu LF-Zeilenenden
    sed -i 's/\r$//' "$file"
done

echo "Konvertierung abgeschlossen."
