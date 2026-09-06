#!/bin/bash
# =====================================================================
# The complete test suite of the project.
#
#   1. tests/db_tests.sh   - the database itself (spec 3.1.x): tables and
#                            seed data, business rules, stored procedures,
#                            triggers, indexes and the reset script
#   2. tests/app_tests.sh  - the application behind the GUI (spec 3.2.x):
#                            every screen, its buttons and the three bonus
#                            features
#   3. tests/ui_tests.sh   - the screens themselves: every input carries a
#                            label (spec 3.2.2)
#
# Both run against throw-away databases inside the MariaDB container; the
# application database (baseisproject) is never touched.
#
# Usage:  tests/run_all.sh
# =====================================================================
set -u
cd "$(dirname "$0")/.."

STATUS=0

echo "#####################################################################"
echo "# 1/3  Database tests (3.1.x)"
echo "#####################################################################"
if tests/db_tests.sh; then
    DB_RESULT="PASSED"
else
    DB_RESULT="FAILED"
    STATUS=1
fi

echo
echo "#####################################################################"
echo "# 2/3  Application / GUI tests (3.2.x)"
echo "#####################################################################"
if tests/app_tests.sh; then
    APP_RESULT="PASSED"
else
    APP_RESULT="FAILED"
    STATUS=1
fi

echo
echo "#####################################################################"
echo "# 3/3  Screen labels (3.2.2)"
echo "#####################################################################"
# the JavaFX warnings about the class path are noise; keep the exit status of
# the script itself, not of the filter
tests/ui_tests.sh 2>&1 | grep -v '^WARNING\|^Sep \|Unsupported JavaFX configuration'
if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    UI_RESULT="PASSED"
else
    UI_RESULT="FAILED"
    STATUS=1
fi

echo
echo "====================================================================="
echo "  Database tests (3.1.x):         $DB_RESULT"
echo "  Application tests (3.2.x):      $APP_RESULT"
echo "  Screen labels (3.2.2):          $UI_RESULT"
echo "====================================================================="
exit $STATUS
