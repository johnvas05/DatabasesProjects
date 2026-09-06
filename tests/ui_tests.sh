#!/bin/bash
# =====================================================================
# Label check for the GUI (spec 3.2.2).
#
# Builds every screen and reports any input control without a label.
# Needs JavaFX, so it uses the class path Maven resolved for the project.
# The screens are only built, never shown, and the database is only read.
#
# Usage:  tests/ui_tests.sh
# Env:    DB_URL / DB_USER / DB_PASSWORD (defaults: the demo database)
# =====================================================================
set -u
cd "$(dirname "$0")/.."

BUILD=tests/build-ui
CPFILE=$(mktemp)

# ---------------------------------------------------------------- Maven
MVN=$(command -v mvn)
if [[ -z "$MVN" ]]; then
    for candidate in "/Applications/IntelliJ IDEA.app/Contents/plugins/maven-plugin/lib/maven3/bin/mvn" \
                     "$HOME/.m2/wrapper/mvn"; do
        [[ -x "$candidate" ]] && MVN="$candidate" && break
    done
fi
[[ -n "$MVN" ]] || { echo "Maven not found; JavaFX cannot be put on the class path."; exit 1; }

echo "Resolving the class path ..."
"$MVN" -o -q dependency:build-classpath -Dmdep.outputFile="$CPFILE" >/dev/null 2>&1 \
    || "$MVN" -q dependency:build-classpath -Dmdep.outputFile="$CPFILE" >/dev/null 2>&1 \
    || { echo "could not resolve the class path"; rm -f "$CPFILE"; exit 1; }
CP="target/classes:$(cat "$CPFILE")"
rm -f "$CPFILE"

echo "Compiling the screens and the check ..."
"$MVN" -o -q compile >/dev/null 2>&1 || "$MVN" -q compile >/dev/null 2>&1 \
    || { echo "the application does not compile"; exit 1; }

rm -rf "$BUILD"; mkdir -p "$BUILD"
javac -nowarn -d "$BUILD" -cp "$CP" tests/app/UiLabelTests.java || { echo "Compilation failed."; exit 1; }

echo
java -cp "$BUILD:$CP" UiLabelTests
STATUS=$?

rm -rf "$BUILD"
exit $STATUS
