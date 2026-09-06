# Demo script for the presentation

Everything below starts from the same state, so the numbers in this file are
the numbers on the screen. Reset, then follow the steps in order.

---

## 0. Before you start

```bash
docker compose up -d
```

```bash
tests/reset_db.sh
```

The reset puts every table back to the seed data of the report, empties the
hotel bookings and the audit log, and starts the ids at 1 again. The 90 000
rows of `trip_history` are kept (they take minutes to regenerate).

Run it again at any point - between two rehearsals, or if a demo goes sideways.

Optionally show that everything still works:

```bash
tests/run_all.sh
```

> 146 database checks + 182 application checks + the label check on all
> 8 screens, all green.

Then start the application:

```bash
mvn javafx:run
```

If `mvn` is not on the PATH, the Maven bundled with IntelliJ works:
`"/Applications/IntelliJ IDEA.app/Contents/plugins/maven-plugin/lib/maven3/bin/mvn" javafx:run`

---

## 1. Part A - the database (3.1.x)

### The whole database, checked in one script

If you only get to show one thing, show this:

```bash
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/Tests.sql
```

> 100 checks - schema, seed data, the business rules of section 2, every stored
> procedure, every trigger, the indexes - and a table at the end:
> `100 | 100 | 0 | ALL TESTS PASSED`.
>
> It runs in under a second **on the live database and changes nothing**: the
> whole script is one transaction that is rolled back before the report is
> printed. The last row of the output proves it (customers 20, reservations 24,
> room_usage 0, vehicle 9 `Available/90000`). You can run it again straight
> away. The warning about a non-transactional table is expected - it is the
> MEMORY table that carries the report through the rollback.

Then walk through the interesting checks by hand.

Open a SQL client on the container:

```bash
docker exec -it baseis-mariadb mariadb -uroot -pjohn2005 baseisproject
```

### 3.1.3.1 Assigning a vehicle - five checks in one procedure

```sql
CALL sp_assign_vehicle_to_trip(14, 9, 90500);
```
> Five rows, all **PASS**, then `Success: vehicle 9 assigned to trip 14`.
> Vehicle 9 becomes `InUse` and its mileage becomes 90 500.

Now show each check refusing on its own:

```sql
CALL sp_assign_vehicle_to_trip(1, 4, 200100);   -- vehicle is in Maintenance
CALL sp_assign_vehicle_to_trip(8, 1, 150100);   -- driver has licence B, the bus needs C/D
CALL sp_assign_vehicle_to_trip(2, 1, 150100);   -- the bus is already on trip 1 those days
```
> Each one prints the full PASS/FAIL table first, then rejects with the reason.

### 3.1.3.2 Searching for accommodation

```sql
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 2, @id);
```
> The hotels of Paris with enough free rooms, cheapest first, with their
> amenities. `@id` holds the best match.

### 3.1.3.3 Booking a whole trip at once

```sql
CALL sp_book_trip_accommodation(1);
```
> One lodging per destination: Le Grand Paris (4 nights, 1000.00) and
> London Stay (5 nights, 300.00), total 1300.00.

### 3.1.4 Triggers

```sql
-- 3.1.4.2 nights and cost are computed on insert
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-01', '2026-10-04', 3);
SELECT ru_nights, ru_total_cost FROM room_usage WHERE ru_trip_id = 11;   -- 3 nights, 1080.00

-- 3.1.4.3 completing a trip frees the vehicle and adds its kilometres
UPDATE trip SET tr_status = 'COMPLETED', tr_km = 350 WHERE tr_id = 14;
SELECT v_status, v_mileage FROM vehicle WHERE v_id = 9;                  -- Available, 90850

-- 3.1.4.1 every change is logged, on all seven tables
SELECT log_table_name, log_action_type, log_dba_username, log_details
FROM log_actions ORDER BY log_id DESC LIMIT 5;
```

### 3.1.3.4 The 90 000-row history and its indexes

```sql
CALL sp_history_revenue('2021-01-01', '2021-12-31');
EXPLAIN SELECT SUM(th_revenue) FROM trip_history
WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';   -- key: idx_hist_dep_rev
```

After Part A, run `tests/reset_db.sh` again before the GUI demo.

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
| The demo data is in a strange state | `tests/reset_db.sh` |
| "Connection Failed" in the status bar | `docker compose up -d`, wait for healthy |
| A change is refused with `foreign key constraint fails` on `dba_users` | The account is not a registered DBA; reconnect (the app registers it) or `INSERT IGNORE INTO dba_users (dba_username, dba_start_date) VALUES ('root', CURDATE());` |
| Everything is broken | `docker compose down -v && docker compose up -d` reloads the whole dump (about a minute) |

## 4. Questions you may be asked

**"Where is the input restricted?" (3.2.2)** - Every form takes its values from
the database: branches, drivers, guides, destinations (cities only for
lodging), customers, trips, the free seats of the chosen trip, vehicles with
enough seats. Dates use date pickers, numbers use numeric-only fields, ENUM
columns become lists. The Universal Manager builds all of this from the schema
at runtime.

**"How do you know it works?"** - Two answers. `queries/Tests.sql` is 100
checks on the database in plain SQL, runs on the live database in under a
second and changes nothing. `tests/run_all.sh` is the full suite: 146 checks on
the database, 182 on the application (every screen and every button, including
the three bonus features) and a check that every input on all 8 screens carries
a label. The shell suites run on throw-away copies of the database.

**"What happens if two checks fail at once?"** -
`CALL sp_assign_vehicle_to_trip(1, 4, 1)` -> the alert names both reasons:
`vehicle is Maintenance; mileage 1 < recorded 200000`.
