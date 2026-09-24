#!/bin/bash
# =====================================================================
# Split queries/Tests.sql into one runnable file per question.
#
# queries/Tests.sql runs every check at once. For the presentation it helps
# to run only the question you are asked about ("show me 3.1.3.1"), so this
# script cuts it into queries/tests/<question>.sql. Every file is complete
# on its own: it installs the test harness, runs the checks of that one
# section inside a transaction, rolls back and prints its own report.
#
# Tests.sql stays the single source: edit it, then run this script again.
#
# It also fills in the seed rows of the test fixture (procedure t_fixture in
# Tests.sql, between "BEGIN FIXTURE ROWS" and "END FIXTURE ROWS") from
# baseisproject_dump.sql, so the checks always start from the rows of the
# demo state, whatever was done in the GUI before.
#
# Usage:  tests/split_sql_tests.sh           write queries/tests/ (and the
#                                            fixture rows of Tests.sql)
#         tests/split_sql_tests.sh --check   only report whether everything
#                                            is up to date (exit 1 if not)
# =====================================================================
set -eu
cd "$(dirname "$0")/.."

SRC=queries/Tests.sql
DUMP=baseisproject_dump.sql
OUT=queries/tests
MODE=${1:-write}

# the tables the fixture empties and fills again with the rows of the dump
# (log_actions is emptied by t_fixture itself; trip_history never changes)
FIXTURE_TABLES=(admin branch customer destination driver event guide language_ref languages
                lodging manages phones reservation room_usage travel_to trip vehicle worker)

[[ -f "$DUMP" ]] || { echo "not found: $DUMP"; exit 1; }
[[ -f "$SRC" ]] || { echo "not found: $SRC"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- the fixture rows
for t in "${FIXTURE_TABLES[@]}"; do
    echo "    DELETE FROM \`$t\`;"
    awk -v t="$t" '$0 ~ "^INSERT INTO `" t "` VALUES" { p = 1 } p { print "    " $0 } p && /;$/ { exit }' "$DUMP"
done > "$WORK/fixture.sql"

# Tests.sql with the fixture rows put in place
awk -v fx="$WORK/fixture.sql" '
    /-- BEGIN FIXTURE ROWS/ { print; while ((getline line < fx) > 0) print line; skip = 1; next }
    /-- END FIXTURE ROWS/   { skip = 0 }
    !skip                   { print }' "$SRC" > "$WORK/Tests.sql"

if [[ "$MODE" == "--check" ]]; then
    if ! cmp -s "$WORK/Tests.sql" "$SRC"; then
        echo "queries/Tests.sql: the fixture rows are OUT OF DATE with $DUMP - run tests/split_sql_tests.sh"
        exit 1
    fi
elif ! cmp -s "$WORK/Tests.sql" "$SRC"; then
    cp "$WORK/Tests.sql" "$SRC"
    echo "Updated the fixture rows of $SRC from $DUMP"
fi

# section number -> file name (the question it answers comes first)
NAMES=(
    ""                                   # there is no section 0
    "3.1.1_seed_data"
    "3.1.2_new_tables"
    "rules_section2_data"
    "rules_section2_check_constraints"
    "3.1.2.2_lodging_in_a_city"
    "3.1.4.2_stay_nights_and_cost"
    "gui_reservation_price"
    "3.1.3.2_search_accommodation"
    "3.1.3.3_book_whole_trip"
    "3.1.3.1_assign_vehicle"
    "3.1.4.3_trip_completion"
    "3.1.4.1_audit_log"
    "gui_branch_financials"
    "gui_salary_guard"
    "3.1.3.4_history_and_indexes"
)
SECTIONS=$(( ${#NAMES[@]} - 1 ))

line_of() { grep -n -- "$1" "$SRC" | head -1 | cut -d: -f1; }

# the parts of Tests.sql that every file needs
harness_start=$(( $(line_of '^--  THE TEST HARNESS') - 1 ))
harness_end=$(awk -v s="$harness_start" 'NR > s && /^DELIMITER ;/ { print NR; exit }' "$SRC")
undo_start=$(( $(line_of '^--  Undo everything') - 1 ))
report_start=$(( $(line_of '^--  THE REPORT') - 1 ))

section_start() { echo $(( $(line_of "^--  SECTION $1 - ") - 1 )); }

TARGET=$OUT
if [[ "$MODE" == "--check" ]]; then
    TARGET="$WORK/out"
fi
mkdir -p "$TARGET"
rm -f "$TARGET"/*.sql

INDEX="$TARGET/README.md"
{
    echo "# One file per question"
    echo
    echo "Generated from \`queries/Tests.sql\` by \`tests/split_sql_tests.sh\` - edit"
    echo "Tests.sql, then run the script again. Every file runs on its own, checks"
    echo "one part of the project inside a transaction that is rolled back, prints"
    echo "its own PASS/FAIL report and changes nothing."
    echo
    echo "Each file starts from the seed data of the report, loaded inside its"
    echo "transaction, so it passes whatever was done in the GUI before - you can"
    echo "show a feature in the GUI and run its test right after."
    echo
    echo '```bash'
    echo 'docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/tests/3.1.3.1_assign_vehicle.sql'
    echo '```'
    echo
    echo "Or open a file in a SQL client and execute all of it."
    echo
    echo "| File | What it checks |"
    echo "|---|---|"
} > "$INDEX"

for (( n = 1; n <= SECTIONS; n++ )); do
    name=${NAMES[$n]}
    file="$TARGET/$name.sql"
    start=$(section_start "$n")
    if (( n < SECTIONS )); then
        end=$(( $(section_start $(( n + 1 ))) - 1 ))
    else
        end=$(( undo_start - 1 ))
    fi
    title=$(sed -n "$(( start + 1 ))p" "$SRC" | sed -E 's/^--  SECTION [0-9]+ - //')

    {
        echo "-- #####################################################################"
        echo "--  $name.sql"
        echo "--  $title"
        echo "-- #####################################################################"
        echo "--  GENERATED from queries/Tests.sql (section $n) by"
        echo "--  tests/split_sql_tests.sh - edit Tests.sql and run the script again,"
        echo "--  do not edit this file by hand."
        echo "--"
        echo "--  It runs on its own: it installs the small test harness, loads the"
        echo "--  seed data of the report inside a transaction (so it passes whatever"
        echo "--  was done in the GUI before), runs the checks of this one question,"
        echo "--  rolls everything back and prints a PASS/FAIL report. It changes"
        echo "--  nothing."
        echo "--  (The client warns about a non-transactional table at the end: that"
        echo "--  is the MEMORY table that carries the report through the rollback.)"
        echo "--"
        echo "--  Run it with"
        echo "--    docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/tests/$name.sql"
        echo "--  or open it in a SQL client and execute the whole file."
        echo "-- #####################################################################"
        echo
        sed -n "${harness_start},${harness_end}p" "$SRC"
        echo
        echo
        echo "-- #####################################################################"
        echo "--  Everything from here is undone by the ROLLBACK below"
        echo "-- #####################################################################"
        echo "START TRANSACTION;"
        echo
        echo "-- start from the seed data of the report, whatever the GUI did before"
        echo "CALL t_fixture();"
        echo
        sed -n "${start},${end}p" "$SRC"
        echo "-- #####################################################################"
        echo "--  Undo everything the checks did"
        echo "-- #####################################################################"
        echo "ROLLBACK;"
        echo
        echo
        sed -n "${report_start},\$p" "$SRC"
    } > "$file"

    echo "| [\`$name.sql\`]($name.sql) | $title |" >> "$INDEX"
done

if [[ "$MODE" == "--check" ]]; then
    if diff -r -q "$TARGET" "$OUT" > /dev/null 2>&1; then
        echo "queries/tests is up to date with queries/Tests.sql"
        exit 0
    fi
    echo "queries/tests is OUT OF DATE - run tests/split_sql_tests.sh"
    diff -r -q "$TARGET" "$OUT" || true
    exit 1
fi

echo "Wrote $SECTIONS files to $OUT/ (index: $OUT/README.md)"
