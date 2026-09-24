# Demo script for the presentation

Everything below starts from the same state, so the numbers in this file are
the numbers on the screen. Reset, then follow the steps in order.

> Keep **`CHEATSHEET.md`** open beside this: it answers "show me X" for any
> requirement, in SQL and in the GUI, including how to make each rule fail
> on purpose.

---

## 0. Before you start (no shell scripts needed)

On the computer of whoever shares the screen:

```bash
docker compose down -v
docker compose up -d
```

This installs the database **already in the demo state**: the seed data of the
report, every reservation priced, no hotel bookings, an empty audit log, and the
90 000 history rows. There is no reset step. Wait until the container reports
`healthy` (about 10 seconds). `down -v` throws away whatever was in the database
before, which is the point.

Connect the IDE (IntelliJ / DataGrip) to `localhost:3307`, user `root`,
password `john2005`, database `baseisproject`, and open `queries/Demo.sql`.

If the data gets into a strange state during a rehearsal, open
`queries/Reset.sql` in the IDE and run the whole file (one second).

Then start the application:

```bash
mvn javafx:run
```

If `mvn` is not on the PATH, the Maven bundled with IntelliJ works:
`"/Applications/IntelliJ IDEA.app/Contents/plugins/maven-plugin/lib/maven3/bin/mvn" javafx:run`

---

## 1. Part A - the database (3.1.x), question by question

The examiner follows the assignment, so `queries/Demo.sql` does too. It has one
block per question, in this order:

| Block | What you show |
|---|---|
| 3.1.1 | the row count of every table against its minimum |
| 3.1.2.1 | the vehicles; a car with 30 seats and a bus with 8 refused (CHECK) |
| 3.1.2.2 | the lodgings, Paris → France, the stays of trip 1 with their dates; a hotel "in France" refused (trigger), a hostel with stars refused (CHECK) |
| 3.1.2.3 | the 90 000 history rows |
| 3.1.2.4 | the DBA accounts and the structure of the log |
| 3.1.3.1 | vehicle 9 assigned to trip 14 (all five checks PASS), then **each check failing on its own**: InUse, Maintenance, too few seats, licence B on a bus, licence B fine on a van, date overlap, lower mileage, two at once, trip/vehicle not found |
| 3.1.3.2 | the search; free rooms shrinking after a booking; nothing found; the order (price, stars, rating); an inactive hotel left out |
| 3.1.3.3 | trip 1 booked (1000 + 300 = 1300), booked again (still 2), 2 rooms for 3 passengers; all-or-nothing when London is full; no confirmed passengers; unknown trip |
| 3.1.3.4 | both reports, EXPLAIN with the index ("Using index") and without it (full scan), and the time of each |
| 3.1.4.1 | changes to a customer, a vehicle and a reservation appear in the log with their details; an account that is not a DBA cannot change anything |
| 3.1.4.2 | 3 nights and 1080.00 computed by the trigger; a stay of 0 nights and one that ends before it starts refused |
| 3.1.4.3 | bus 9 back to Available with 350 km added; no double count; another status leaves the vehicle alone |
| Part B support | the reservation price (500 adult, 300 child), branch financials, the salary guard (refused, +1 %, +2 %, refused above 2 %) |

**How to run it:** put the cursor on a statement and press Ctrl+Enter
(Cmd+Enter on a Mac), one statement at a time. Do not run the whole file at
once: the statements marked `[REFUSED]` fail on purpose, and the error is what
you are showing. Each `-- Say:` line is one sentence you can use to explain the
block. Every block ends with `ROLLBACK`, so the database is back in the demo
state for the next question.

**If you are asked "does it handle every case?"**, run the test file of that
question. It checks every case and prints one PASS/FAIL line for each:

```bash
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/tests/3.1.3.1_assign_vehicle.sql
```

Or all 154 checks at once:

```bash
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/Tests.sql
```

> `154 | 154 | 0 | ALL TESTS PASSED`, in under a second, on the live database,
> and nothing changes: the last row of the output shows it (customers 20,
> reservations 24, room_usage 0, vehicle 9 `Available/90000`). The warning
> about a non-transactional table at the end is expected.
>
> **On Windows PowerShell**, `<` does not work. Use
> `Get-Content queries\Tests.sql -Raw | docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject`
> instead. In `cmd.exe` the `<` form works as it is.

---

## 2. Part B - the application (3.2.x)

### Customers

1. Fill in the form at the bottom: first name, last name, email, phone, and a
   **birth date** (the date picker - the age decides adult or child pricing).
2. **Add Customer** -> the row appears in the table.

### Vehicles

1. **Add Vehicle**: plate, brand, model, type `Van`, seats `8`, branch -> added.
   Notice the seats hint changes with the type (`Bus` -> "> 20", `Van` -> "6-9").
2. Show a rule being enforced: type `Car`, seats `30` -> **Add Vehicle**.
   > Error alert: `chk_vehicle_type_seats` - the database refuses it.
3. Select the vehicle you added -> **Delete Selected**.

### Lodgings

1. The destination list offers **cities only** - `France` is not in it
   (a lodging belongs to a city, 3.1.2.2).
2. Pick type `Hostel` -> the **Stars** list is greyed out.
   Pick `Hotel` -> it becomes selectable (stars are only for hotels and resorts).
3. Add one, then **Delete Selected**.

### Trips - the main screen

**Bonus 1: smart vehicle selection**

1. The **Max Seats** field starts at `40`; the vehicle list holds the 3 buses
   with 50, 52 and 60 seats, smallest first.
2. Type `60` -> only the 60-seat bus is left.
3. Type `5` -> 9 vehicles.
4. Type `999` -> "No available vehicles with 999+ seats".

> Vehicles in maintenance never appear: the list is `Available` only.

**Adding a trip (3.1.3.1 from the GUI)**

1. Max Seats back to `40`, pick the dates, a **Branch**, a **Driver with
   licence D**, a **Guide** and the 50-seat bus.
2. **Add Trip**.
   > `Trip N created` with the five checks of the procedure, all PASS.
3. Try it again with a driver whose licence is **B**.
   > `Trip N created without vehicle` - "driver licence B (C/D needed)".
   > The trip is created, the vehicle is not attached: the procedure refused it.

**Bonus 2: trip details**

1. Select trip **1** in the table -> **Show Trip Details**.
   > Driver (Takis Volanis, licence D, 10 years), guide (Zoi Laskari, French),
   > the accommodations, and the passenger list with the seats.

**Bonus 3: auto-booking hotels**

1. Still on trip **1** -> **Auto-Book Accommodations 🏨** -> confirm.
   > "Automatically booked 2 accommodation(s) for this trip."
2. **Show Trip Details** again.
   > Le Grand Paris, 2026-06-01 to 2026-06-05, 1 room, $1000.00
   > London Stay, 2026-06-05 to 2026-06-10, 1 room, $300.00
3. Press the button a second time -> still 2 bookings, not 4 (it replaces them).

### Reservations

1. Pick customer **C1 Lname1** (an adult), trip **Trip ID: 1**, a free seat
   (seats 1-3 are taken, so the list starts at 4), status `PENDING`
   -> **Book Reservation**.
   > Cost **500.00** - the adult price of the trip.
2. Now pick **C16 Lname16** (a child), the same trip, the next free seat.
   > Cost **300.00** - the child price. The price is not typed in anywhere;
   > `sp_calculate_reservation_cost` computes it from the birth date.

### Staff

1. Category `DRIVER` -> the licence, route and experience fields appear.
   Fill in an ID (e.g. `AT901`), name, salary, branch -> **Add Worker**.
   The worker row and the driver row are written in one transaction.
2. Category `GUIDE` -> CV and language. Category `ADMIN` -> type and diploma.
   > Every worker belongs to exactly one category (section 2.3).
3. Select a worker -> **Update Salary** -> raise it a lot.
   > `Trigger Denied: branch is not profitable` - the trigger checks the branch
   > through `sp_branch_financials` before allowing any raise.

   To also show the **accepted** path, make a branch profitable first (in the
   SQL client), then come back:

   ```sql
   UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1;  -- lowering is always allowed
   ```

   Now select worker **AT101** and set the salary to `101` (a 1% raise)
   -> accepted. Set it to `110` (a 10% raise) -> `exceeds 2% limit`.

### Admin & Logs

1. **System Logs** -> **Refresh Logs**.
   > Every action of this demo, newest first, with the DBA account and the time.
   > The log started empty because of the reset, so this is only your demo.
2. **Branch Financials** -> pick a branch -> **Calculate Financials**.
   > Revenue, expenses and profit ratio, straight from `sp_branch_financials` -
   > the same procedure the salary trigger uses.

### Universal Manager (3.2.2)

1. Pick any table, e.g. `travel_to`.
2. **Insert** -> the dialog is built from the schema:
   - `to_tr_id` and `to_dst_id` are **drop-downs of the existing rows**
     (foreign keys), not free text
   - `to_arrival` / `to_departure` get **date pickers**
   - ENUM columns become lists, flags become check boxes
   - the generated key is not asked for
3. Show that the rules still hold: pick `vehicle`, insert a `Car` with 30 seats
   -> the same `chk_vehicle_type_seats` error as in the Vehicles screen.

---

## 3. If something goes wrong

| Problem | Fix |
|---|---|
| The demo data is in a strange state | run `queries/Reset.sql` in the IDE (one second) |
| A `Demo.sql` block was left half way | run `ROLLBACK;`, or `queries/Reset.sql` |
| "Connection Failed" in the status bar | `docker compose up -d`, wait for healthy |
| A change is refused with `foreign key constraint fails` on `dba_users` | The account is not a registered DBA; reconnect (the app registers it) or `INSERT IGNORE INTO dba_users (dba_username, dba_start_date) VALUES ('root', CURDATE());` |
| Everything is broken | `docker compose down -v && docker compose up -d` - a clean install in the demo state (about 10 seconds) |

## 4. Questions you may be asked

**"Where is the input restricted?" (3.2.2)** - Every form takes its values from
the database: branches, drivers, guides, destinations (cities only for
lodging), customers, trips, the free seats of the chosen trip, vehicles with
enough seats. Dates use date pickers, numbers use numeric-only fields, ENUM
columns become lists. The Universal Manager builds all of this from the schema
at runtime.

**"How do you know it works?"** - `queries/Tests.sql`: 154 checks on the
database in plain SQL, every procedure and trigger shown both accepting and
refusing, run on the live database in under a second without changing a row.
The same checks are split into one file per question in `queries/tests/`, so
any single question can be proved on its own. Behind that, the project has a
full developer suite (`tests/run_all.sh`: 165 database checks, 182 on the
application code behind every screen and button, and a check that every input
on all 8 screens carries a label).

**"What happens if two checks fail at once?"** -
`CALL sp_assign_vehicle_to_trip(1, 4, 1)` -> the alert names both reasons:
`vehicle is Maintenance; mileage 1 < recorded 200000`.
