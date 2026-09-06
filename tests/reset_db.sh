#!/bin/bash
# =====================================================================
# Put the application database back into the demo state (queries/Reset.sql).
#
# Run it before a presentation, or between two runs of the demo: every table
# goes back to the seed data of the report, room_usage and log_actions are
# emptied and the ids start at 1 again. trip_history (90 000 rows) is kept.
#
# Usage:  tests/reset_db.sh [database]      (default: baseisproject)
# Env:    CONTAINER (default baseis-mariadb), DB_PASSWORD (default john2005)
# =====================================================================
set -u
cd "$(dirname "$0")/.."

CONTAINER=${CONTAINER:-baseis-mariadb}
DB_PASSWORD=${DB_PASSWORD:-john2005}
DB=${1:-baseisproject}
SCRIPT=queries/Reset.sql

[[ -f "$SCRIPT" ]] || { echo "reset script not found: $SCRIPT"; exit 1; }
docker exec "$CONTAINER" true 2>/dev/null \
    || { echo "container $CONTAINER is not running (docker compose up -d)"; exit 1; }

echo "Resetting $DB from $SCRIPT ..."
# the script starts with "USE baseisproject;" - point it at the requested database
out=$(sed "s/^USE baseisproject;/USE $DB;/" "$SCRIPT" \
        | docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" -t "$DB" 2>&1 \
        | grep -v '^mysql: \[Warning\]')

if grep -qi 'ERROR' <<<"$out"; then
    echo "$out"
    echo
    echo "Reset FAILED."
    exit 1
fi

echo "$out"
echo
echo "Database $DB is back in the demo state."
