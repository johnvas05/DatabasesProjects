# How to Run the Travel Agency GUI

## Quick Start

### 1. Start the database (Docker, MariaDB 11)

```bash
docker compose up -d
```

This starts a MariaDB 11 container named `baseis-mariadb` on **localhost:3307**
(root / `john2005`) and, on first start, loads `baseisproject_dump.sql` into the
`baseisproject` database via `docker/init-db.sh` (it strips the `DEFINER` clauses
and sets the collation MariaDB needs for the stored procedures).

To reset the data, remove the volume and start again:

```bash
docker compose down -v && docker compose up -d
```

`DatabaseConnection.java` already points at this container:

```java
private static final String URL = "jdbc:mysql://localhost:3307/baseisproject?serverTimezone=UTC";
private static final String USER = "root";
private static final String PASSWORD = "john2005";
```

If you use your own MySQL/MariaDB instead, set the environment variables `DB_URL`,
`DB_USER` and `DB_PASSWORD` (or edit those constants) and load `baseisproject_dump.sql`.

### 2. Launch the Application

**Run this file:** `src/main/java/com/travelagency/Launcher.java`

**In Eclipse:**
- Right-click `Launcher.java` → Run As → Java Application

**From Command Line:**
```bash
java -cp ".;src/main/java;lib/*" com.travelagency.Launcher
```

That's it! The GUI window will open.

---

## Main Features

- **Home** - Dashboard
- **Customers** - Manage customers
- **Vehicles** - Manage vehicles
- **Lodging** - Manage hotels
- **Trips** - ⭐ Main feature (includes all bonus features)
- **Reservations** - Manage bookings
- **Staff** - Manage employees

### Input restriction (3.2.2)

Every form picks from the database where possible: branches, drivers (with the licence
that decides which vehicles the trip may use) and guides, destinations (cities only
for lodging), customers, trips, free seats of the selected trip, vehicles with enough
seats, enum values (status, type, licence, route), dates via date pickers, numbers via
numeric-only fields. The **Universal Manager** builds its insert/update dialog from the
schema: foreign keys become drop-downs of the referenced rows (e.g. the list of
destinations when adding a `travel_to` row), ENUM columns become lists, DATE/DATETIME
columns get date pickers, boolean flags become check boxes.

### Bonus Features (3.2.3) - All in "Trips" section:
1. **Smart Vehicle Selection** - Dropdown filters by capacity (real-time)
2. **Trip Details** - Click "Show Trip Details" button
3. **Auto-Book Hotels** - Click "Auto-Book Accommodations 🏨" button

---

## Prerequisites

- Java JDK 21+
- Docker (for the bundled MariaDB container) or a MySQL/MariaDB server
- Database `baseisproject` created and populated (automatic with `docker compose up -d`)

---

## Resetting the demo data

```bash
tests/reset_db.sh
```

Puts every table back to the seed data of the report, empties the hotel bookings
(`room_usage`) and the audit log (`log_actions`), prices every reservation again
and restarts the ids at 1. `trip_history` (90 000 rows) is kept, because
regenerating it takes minutes. Run it before a presentation and between two
rehearsals. The script it runs is `queries/Reset.sql`, which also works on its own:

```bash
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 baseisproject < queries/Reset.sql
```

`DEMO.md` is a step-by-step walkthrough of the whole project for the presentation.

---

## Tests

With the container running:

```bash
tests/run_all.sh
```

**`tests/db_tests.sh` - 146 checks on the database (3.1.x).** Loads the dump into
a throw-away `baseisproject_test` database and checks every stored procedure and
trigger of Part A (vehicle assignment checks, accommodation search and
auto-booking, cost/nights trigger, log triggers on all seven tables, trip
completion trigger, history indexes, reservation pricing, salary guard), the
business rules of the description (one category per worker, driver route/licence
vs. trip, vehicle type vs. seats, stars only for hotels/resorts, lodging only in
city destinations) and the reset script.

**`tests/app_tests.sh` - 182 checks on the application (3.2.x).** Compiles the
classes behind the JavaFX screens (the DAOs, the models and
`UniversalTableManager`) together with `tests/app/AppTests.java` and runs them
against a throw-away `baseisproject_apptest` database: every screen and every
button, the input restrictions of 3.2.2, the three bonus features and the errors
the alerts show. Each section starts by re-applying `queries/Reset.sql`, so the
tests are independent of each other.

**`tests/ui_tests.sh` - the screens themselves (3.2.2).** Builds every screen,
walks its scene graph and fails if any input (text field, drop-down, date
picker, check box) has no label next to it. The window is never shown and the
database is only read. It starts by checking itself: a bare field must be
reported, a labelled one must not.

Neither of the first two suites touches the application database
`baseisproject`; the label check only reads it. To run the application tests
against the database the GUI uses (after a reset), set `TARGET_DB`:

```bash
TARGET_DB=baseisproject tests/app_tests.sh
```

That database is reset before every section and once at the end, so it is left
in the demo state.

---

## SQL sources (`queries/`)

| File | Content |
|------|---------|
| `Query.sql`, `Insertions.sql` | base tables seed data (3.1.1) and seed data for the new tables |
| `cars.sql`, `Accommodation.sql`, `history.sql`, `AdminLog.sql` | new tables: vehicle, lodging/room_usage, trip_history (+ indexes 3.1.3.4), dba_users/log_actions (3.1.2) |
| `VechicleProcedure.sql` | `sp_assign_vehicle_to_trip` (3.1.3.1) |
| `AccommodationProcedure.sql` | `sp_search_accommodation` (3.1.3.2) and the nights/cost trigger (3.1.4.2) |
| `AutoBookProcedure.sql` | `sp_book_trip_accommodation` (3.1.3.3) |
| `Triggers.sql` | log triggers on trip, reservation, customer, destination, vehicle, lodging, room_usage (3.1.4.1) and the trip-completion trigger (3.1.4.3) |
| `CalculateReservationCost.sql`, `PROCEDURE.sql`, `TRIGGER.sql` | reservation pricing, branch financials, salary guard (used by the GUI) |
| `Upgrade_2026-09.sql` | one-off upgrade of the January dump: real stay dates and `to_sequence`, `ru_nights`, covering indexes, lodging seed with postal codes, reservation prices, minimum participants, driver route/licence consistency, events for every trip, DBA usernames, CHECK constraints (vehicle type by seats, stars only for hotels/resorts), city/country destinations |

| `Reset.sql` | puts the database back into the demo state: the seed data of `Insertions.sql` (with reproducible birth dates), reservation prices, empty `room_usage` and `log_actions`, ids restarting at 1, `trip_history` kept |

`baseisproject_dump.sql` is the complete database (schema, data, routines, triggers) after all of the above.
