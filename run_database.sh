#!/usr/bin/env bash
set -euo pipefail

# Safe terminal runner for the final submission workflow.
# Run from the repository root:
#   bash run_database.sh
# Optional first argument: MySQL user, default is root.

MYSQL_USER="${1:-root}"

if [ ! -f "sql/install.sql" ] || [ ! -f "sql/load.sql" ] || [ ! -f "sql/validation.sql" ]; then
    echo "ERROR: Run this script from the repository root." >&2
    echo "Expected sql/install.sql, sql/load.sql, and sql/validation.sql." >&2
    exit 1
fi

if [ ! -d "data/reference" ] || [ ! -d "data/generated" ]; then
    echo "ERROR: Missing data/reference or data/generated." >&2
    echo "This final branch should include generated CSV data under data/." >&2
    exit 1
fi

if ! find data/reference data/generated -maxdepth 1 -type f -name '*.csv' | grep -q .; then
    echo "ERROR: No CSV files found under data/reference or data/generated." >&2
    exit 1
fi

echo "Enabling local_infile for this MySQL server..."
mysql --default-character-set=utf8mb4 -u "$MYSQL_USER" -e "SET GLOBAL local_infile = 1;"
mysql --default-character-set=utf8mb4 -u "$MYSQL_USER" -e "SHOW GLOBAL VARIABLES LIKE 'local_infile';"

echo "Installing schema..."
mysql --default-character-set=utf8mb4 -u "$MYSQL_USER" < sql/install.sql

echo "Loading included CSV data from data/..."
mysql --default-character-set=utf8mb4 --local-infile=1 -u "$MYSQL_USER" < sql/load.sql

echo "Running validation..."
mysql --default-character-set=utf8mb4 -u "$MYSQL_USER" < sql/validation.sql

echo "Done. If validation problem-detection result sets are empty, the load is valid."
