#!/bin/bash
# =====================================================================
# Application / GUI tests for the travel agency project (spec 3.2.x).
#
# Compiles the classes behind the JavaFX screens (the DAOs, the models and
# UniversalTableManager - none of them need JavaFX) together with
# tests/app/AppTests.java, and runs them against a throw-away database
# (baseisproject_apptest) inside the MariaDB container. The application
# database (baseisproject) is never touched.
#
# Usage:  tests/app_tests.sh [dump-file]      (default: baseisproject_dump.sql)
# Env:    CONTAINER (default baseis-mariadb), DB_PASSWORD (default john2005),
#         DB_PORT   (default 3307)
#         TARGET_DB - run against an existing database instead of a throw-away
#                     copy, e.g. TARGET_DB=baseisproject tests/app_tests.sh to
#                     check the database the GUI actually uses. The suite resets
#                     that database (queries/Reset.sql) before every section and
#                     once more at the end, so it is left in the demo state.
# =====================================================================
set -u
cd "$(dirname "$0")/.."

CONTAINER=${CONTAINER:-baseis-mariadb}
DB_PASSWORD=${DB_PASSWORD:-john2005}
DB_PORT=${DB_PORT:-3307}
DUMP=${1:-baseisproject_dump.sql}
TARGET_DB=${TARGET_DB:-}
TDB=${TARGET_DB:-baseisproject_apptest}
BUILD=tests/build

[[ -n "$TARGET_DB" || -f "$DUMP" ]] || { echo "dump file not found: $DUMP"; exit 1; }
docker exec "$CONTAINER" true 2>/dev/null \
    || { echo "container $CONTAINER is not running (docker compose up -d)"; exit 1; }

# ---------------------------------------------------------------- the JDBC driver
JAR=$(find "$HOME/.m2/repository/com/mysql" -name 'mysql-connector-j-*.jar' ! -name '*sources*' 2>/dev/null | head -1)
if [[ -z "$JAR" ]]; then
    echo "MySQL JDBC driver not found in ~/.m2."
    echo "Build the project once so Maven downloads it (mvn -q compile), then run this again."
    exit 1
fi

# ---------------------------------------------------------------- compile
echo "Compiling the application classes and the tests ..."
rm -rf "$BUILD"; mkdir -p "$BUILD"
# only the classes that do not import JavaFX: the DAOs, the models and the
# universal table manager - exactly the code behind the buttons of the GUI
SOURCES=$(grep -L "javafx" src/main/java/com/travelagency/*.java)
if ! javac -nowarn -d "$BUILD" -cp "$JAR" $SOURCES tests/app/AppTests.java 2>&1; then
    echo "Compilation failed."
    exit 1
fi

# ---------------------------------------------------------------- test database
if [[ -n "$TARGET_DB" ]]; then
    echo "Running against the existing database $TDB (it is reset before every section)."
else
    echo "Loading $DUMP into $TDB ..."
    docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" -e \
        "DROP DATABASE IF EXISTS $TDB; CREATE DATABASE $TDB CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;" \
        || { echo "cannot create $TDB"; exit 1; }
    sed -E 's#/\*!50017 DEFINER=`[^`]+`@`[^`]+`\*/##g; s#DEFINER=`[^`]+`@`[^`]+` ##g' "$DUMP" \
        | docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" "$TDB" \
        || { echo "cannot load $DUMP"; exit 1; }
fi

# ---------------------------------------------------------------- run
echo
DB_URL="jdbc:mysql://localhost:$DB_PORT/$TDB?serverTimezone=UTC&allowMultiQueries=true" \
DB_USER=root \
DB_PASSWORD="$DB_PASSWORD" \
    java -cp "$BUILD:$JAR" AppTests queries/Reset.sql
STATUS=$?

# ---------------------------------------------------------------- clean up
if [[ -z "$TARGET_DB" ]]; then
    docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS $TDB;"
fi
rm -rf "$BUILD"
exit $STATUS
