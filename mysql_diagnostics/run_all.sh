#!/bin/bash
# Run all diagnostic SQL files in order
DB="mysql"  # Change or pass via arg
SQL_DIR="./mysql_diagnostics"

for sql in "$SQL_DIR"/??.*.sql; do
    echo "Running $(basename "$sql")..."
    mysql -u root -p --database="$DB" < "$sql" >> diagnostics_full.txt 2>&1
done

echo "All diagnostics completed. Output: diagnostics_full.txt"
