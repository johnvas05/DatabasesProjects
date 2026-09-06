#!/bin/bash
# Runs once, on the first start of the MariaDB container (empty data volume).
# Loads baseisproject_dump.sql into MariaDB with two adjustments:
#   1. The database is created with collation utf8mb4_0900_ai_ci (the collation the
#      dump's tables use). Stored procedures inherit the *database* collation for
#      their local variables, so a mismatch causes "Illegal mix of collations".
#   2. Any DEFINER=`user`@`host` clauses are stripped, so the dump also loads when
#      it was taken with an account that does not exist on this server.
set -euo pipefail

mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" -e \
  "CREATE DATABASE IF NOT EXISTS baseisproject CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"

sed -E 's#/\*!50017 DEFINER=`[^`]+`@`[^`]+`\*/##g; s#DEFINER=`[^`]+`@`[^`]+` ##g' \
  /dump/baseisproject.sql \
  | mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" baseisproject

echo "baseisproject loaded from dump."
