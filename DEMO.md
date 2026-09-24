# Run-through for the exam

The exam follows the assignment: every question of Part A one by one, then the
functionality of Part B. For each functionality below you **show it in the
GUI**, then **run its SQL test** to prove every case works, including the ones
the database refuses.

Every step has been rehearsed against the database; the messages and numbers
here are the ones on the screen. Keep [`CHEATSHEET.md`](CHEATSHEET.md) open for
questions outside this script.

---

## Before the exam

On the computer of whoever shares the screen:

```bash
docker compose down -v
docker compose up -d
```

This gives a fresh database **already in the demo state**. Wait ~10 seconds,
then check it once:

```bash
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/Tests.sql
```

> The last tables must say `154 | 154 | 0 | ALL TESTS PASSED`.

Open three things side by side:

1. **The GUI** - `mvn javafx:run` (or run `Launcher` in IntelliJ).
2. **A terminal in the project folder** - for the SQL tests.
3. **IntelliJ** - to show the code when you are asked, and `queries/Demo.sql`.

### How to run an SQL test

Every test is one file in `queries/tests/`, and every one is run the same way:

```bash
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/tests/3.1.3.1_assign_vehicle.sql
```

On **Windows PowerShell** (where `<` does not work):

```powershell
Get-Content queries\tests\3.1.3.1_assign_vehicle.sql -Raw | docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject
```

What you get: first the output of the procedures themselves, then **one line
per case with PASS or FAIL**, then a summary like `18 | 18 | 0 | ALL TESTS PASSED`.
Scroll to the list of cases and read two or three of them out.

What to say about it:

> "Each test checks every outcome of the procedure or trigger - the case that
> works and every case it must refuse. It loads the report's seed data inside a
> transaction, so it doesn't matter what we just did in the GUI, and it rolls
> everything back, so it changes nothing."

**The tests do not depend on the GUI.** You can show something in the GUI and
run its test right after, in any order, as many times as you like.

---

## Part A

### 3.1.1 - The data  *(1 min)*

**GUI** - click **Customers** (20 rows), **Trips** (14), **Staff** (26).

**Say:** every table holds at least twice the minimum of the assignment,
because we are two.

**Test** - `3.1.1_seed_data.sql` → **15 / 15**

---

### 3.1.2.1 - Vehicles  *(1 min)*

**GUI** - **Vehicles**:

1. Add a vehicle: plate `DEMO-1`, brand `Ford`, model `Transit`, type `Van`,
   seats `8`, branch `Athens` → **Add Vehicle** → it appears in the table.
2. The form clears itself. Fill it again with plate `DEMO-2`, brand `Toyota`,
   model `Yaris`, type **`Car`**, seats **`30`** → **Add Vehicle**.
   > Error: `CONSTRAINT chk_vehicle_type_seats failed` - the database refuses a
   > car with 30 seats.
3. Select `DEMO-1` → **Delete Selected**.

**Say:** the seats must match the type (bus > 20, mini-bus 10-20, van 6-9,
car up to 5). The rule is a CHECK constraint in the database, so no screen can
get around it.

**Test** - `rules_section2_check_constraints.sql` → **18 / 18**
(every vehicle type accepted, each wrong combination refused, on INSERT and UPDATE)

---

### 3.1.2.2 - Lodging and stays  *(1 min)*

**GUI** - **Lodgings**:

1. Open the **Destination** list: only cities. `France` is not there - Paris
   belongs to France, and a lodging belongs to a city.
2. Pick type `Hostel`: the **Stars** list greys out. Pick `Hotel`: it turns on.

Then **Universal Manager** → table `travel_to`: each stay of a trip has its own
dates and its place in the order of the trip (`to_sequence`).

**Test** - `3.1.2.2_lodging_in_a_city.sql` → **4 / 4**
(a lodging in a city accepted, in a country refused - on INSERT and on UPDATE)

---

### 3.1.2.3 and 3.1.2.4 - History, DBAs and the log  *(1 min)*

**GUI** - **Universal Manager** → table `dba_users`: the registered DBA accounts.
**Admin & Logs → System Logs**: the audit log (it already holds the actions of
this demo).

**SQL** - in IntelliJ, `queries/Demo.sql`, block **3.1.2.3**: the 90 000 trips of
the history. (Not in the GUI: the table view would load 90 000 rows.)

**Test** - `3.1.2_new_tables.sql` → **12 / 12**
(the new tables, their rows, the new columns, all 26 triggers and 8 procedures)

---

### 3.1.3.1 - Assigning a vehicle to a trip  *(3 min - the most important one)*

**GUI** - **Trips**. Fill the form the same way three times, changing only the
driver and the vehicle:

- **Departure date** `2 October 2026`, **Return date** `5 October 2026`
  (keep the times)
- **Branch** `Athens (Panepistimiou 56)`, **Guide** any, **Max seats** `40`

| # | Driver | Vehicle | What appears |
|---|---|---|---|
| 1 | `AT114 \| Akis Petretzikis (licence B, LOCAL)` | `Man Lion (IFF-6001)` | **Trip … created without vehicle** - *driver licence B (C/D needed)* |
| 2 | `AT113 \| Lakis Lazopoulos (licence D, ABROAD)` | `Mercedes Tourismo (IAA-1001)` | **Trip … created without vehicle** - *overlaps 1 other trip(s)* |
| 3 | `AT113 \| Lakis Lazopoulos (licence D, ABROAD)` | `Man Lion (IFF-6001)` | **Trip … created** - the five checks, all **PASS**, then *Success* |

**Say:** the button calls `sp_assign_vehicle_to_trip`, which runs five checks:
the vehicle is available, it has seats for the confirmed passengers, a vehicle
of more than 9 seats needs a C or D licence, it is not on another trip on those
dates (bus 1 is on trip 11, 1-10 October), and the odometer does not go
backwards. Only if all five pass is the vehicle assigned and set to InUse.

Point at the **Vehicles** screen: bus `IFF-6001` is now **InUse**.

**Test** - `3.1.3.1_assign_vehicle.sql` → **18 / 18**
(each of the five checks failing on its own, the cases where they pass, two
failing at once, the successful assignment and what it writes)

---

### 3.1.3.2 - Searching for accommodation  *(1 min)*

There is no button of its own: auto-booking (next) calls it for every stay.

**Test** - `3.1.3.2_search_accommodation.sql` → **8 / 8**
(found; free rooms reduced by other bookings; not enough rooms; an inactive
lodging; a destination with none; cheapest first, then stars)

The output also shows the hotel list the procedure returns. For a slower
walk-through, `queries/Demo.sql` block **3.1.3.2**, one statement at a time.

---

### 3.1.3.3 - Booking a whole trip  *(2 min - also bonus 3)*

**GUI** - **Trips**:

1. Select the **trip you created in step 3** of 3.1.3.1. The three new trips
   depart on 2 October, so they sit just above trip 11; the one from step 3 has
   the **highest ID** of the three. → **Auto-Book Accommodations** → OK.
   > **Booking Failed** - *no confirmed or paid reservations for this trip,
   > nothing to book.*
2. Select **trip 1** → **Auto-Book Accommodations** → OK.
   > *Automatically booked 2 accommodation(s) for this trip.*
3. **Show Trip Details**:
   > Le Grand Paris (5-star Hotel), 2026-06-01 → 2026-06-05, 1 room, **$1000.00**
   > London Stay (Hostel), 2026-06-05 → 2026-06-10, 1 room, **$300.00**
4. Press **Auto-Book** again → still 2 bookings, not 4.

**Say:** for every stay of the trip, in order, it books the best lodging that
3.1.3.2 finds, for the dates of that stay - one room per two confirmed
passengers. If one stay cannot be booked, every booking of the trip is
cancelled: all or nothing.

**Test** - `3.1.3.3_book_whole_trip.sql` → **13 / 13**
(including the all-or-nothing case: London full, so the Paris booking is
cancelled too)

---

### 3.1.3.4 - Queries on the history, and the indexes  *(2 min)*

Not in the GUI. In IntelliJ, `queries/Demo.sql`, block **3.1.3.4**, one
statement at a time:

1. `SHOW INDEX FROM trip_history` - the two covering indexes.
2. `CALL sp_history_revenue(...)` - the revenue of 2021.
3. `EXPLAIN` **with** the index → `key idx_hist_dep_rev`, Extra **`Using index`**.
4. `EXPLAIN` **without** it (`IGNORE INDEX`) → type **`ALL`**, the whole table.
5. `SHOW PROFILES` → about **8 ms without, 2 ms with** the index.

**Say:** the column in the WHERE comes first and the column in the SELECT
second, so the answer comes from the index alone, without reading the table.

**Test** - `3.1.3.4_history_and_indexes.sql` → **6 / 6**

---

### 3.1.4.1 - The audit log  *(1 min)*

**GUI** - **Admin & Logs → System Logs → Refresh Logs**: every change of this
demo - the trips you created, the vehicle set to InUse, the hotel bookings -
with the account and the time, newest first.

**Say:** 21 triggers - insert, update and delete on seven tables. The account
must be a registered DBA (a foreign key to `dba_users`), so nobody can change
the data without leaving a trace.

**Test** - `3.1.4.1_audit_log.sql` → **15 / 15**
(each of the seven tables logs all three actions; an account that is not a DBA
cannot change anything)

---

### 3.1.4.2 - Nights and cost of a stay  *(1 min)*

**GUI** - **Universal Manager** → table `room_usage`: the two bookings of trip 1.
`ru_nights` (4 and 5) and `ru_total_cost` (1000.00 and 300.00) were never
typed in - the trigger computed them when the booking was made.

**Test** - `3.1.4.2_stay_nights_and_cost.sql` → **5 / 5**
(computed for 1 and for 3 rooms; a stay of 0 nights and one that ends before it
starts refused)

---

### 3.1.4.3 - Completing a trip frees its vehicle  *(1 min)*

**GUI** - **Universal Manager** → table `trip` → select the trip you created in
step 3 of 3.1.3.1 (the row with `tr_vehicle_id` = 9 and the highest `tr_id`) →
**Update Row** → set `tr_status` to `COMPLETED` and `tr_km` to `350` → **Update**.

Then **Vehicles**: bus `IFF-6001` is **Available** again and its mileage went
from 90 000 to **90 350**.

**Say:** the trigger fires only on the change *into* COMPLETED: another status
leaves the vehicle alone, and the kilometres are never added twice.

**Test** - `3.1.4.3_trip_completion.sql` → **5 / 5**

---

## Part B

### 3.2.1 - Any table, any row  *(1 min)*

**GUI** - **Universal Manager**: pick a table, **Insert / Update / Delete Row**.
Insert into `travel_to` to show the dialog: `to_tr_id` and `to_dst_id` are
**drop-downs of the existing rows**, the dates have **date pickers**, the
generated key is not asked for. Cancel.

### 3.2.2 - Restricted input  *(1 min)*

Point it out on the forms you have already used: branch, driver, guide,
vehicle, status, type are lists from the database; dates are pickers; seats,
mileage and prices accept only digits; the Lodgings destination list has
cities only; Reservations offers only the **free** seats of the chosen trip.

### 3.2.3 - Bonus features  *(1 min)*

1. **Smart vehicle selection** - Trips → **Max seats**: `40` → three buses
   (50, 52, 60 seats); `60` → one; `999` → *No available vehicles with 999+
   seats*. Only vehicles that are Available and big enough. (Three buses
   because 3.1.4.3 made bus 9 Available again; while it is on a trip, it is
   left out - which is the point.)
2. **Trip details** - trip 1 → **Show Trip Details**: driver *Takis Volanis*
   (licence D, 10 years), guide *Zoi Laskari* (French), the hotels, the
   passengers.
3. **Auto-booking** - shown in 3.1.3.3.

### Reservations - the price by age  *(1 min)*

**GUI** - **Reservations**: customer `C1 Lname1`, trip `ID 1 …`, the first free
seat (**4** - seats 1-3 are taken), **Book Reservation** → cost **500**.
Again with `C16 Lname16` → **300**.

**Say:** nobody types the price: `sp_calculate_reservation_cost` takes the adult
or the child price of the trip from the customer's age.

**Test** - `gui_reservation_price.sql` → **3 / 3**

### Staff - the salary guard  *(2 min)*

**GUI** - **Staff**:

1. Choose category `DRIVER`: the licence, route and experience fields appear
   (`GUIDE` → CV and language, `ADMIN` → type and diploma).
2. Select `AT101` → **Update Salary** → `1515` (+1 %).
   > **Trigger Denied** - *branch is not profitable*

**Say:** a raise needs a profitable branch and at most 2 %. With our data every
branch pays more in salaries than it takes in.

To also show a raise **accepted**, run this in IntelliJ (lowering is always
allowed), then reopen **Staff**:

```sql
UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1;
```

`AT101` → `101` → *Salary updated successfully*. → `110` → **Trigger Denied** -
*exceeds 2% limit*.

**Test** - `gui_salary_guard.sql` → **12 / 12**
(lowering, no change, +1 %, exactly +2 %, above 2 % refused, any raise refused
in a branch without profit)

### Admin - branch financials  *(30 s)*

**GUI** - **Admin & Logs → Branch Financials** → `Athens` → **Calculate**:
revenue, expenses and profit ratio from `sp_branch_financials` - the procedure
the salary trigger uses.

**Test** - `gui_branch_financials.sql` → **5 / 5**

---

## If there is time, or if you are asked "does everything work?"

```bash
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/Tests.sql
```

> All 154 checks, under a second: `154 | 154 | 0 | ALL TESTS PASSED`.

## After the exam, or to rehearse again

Run `queries/Reset.sql` in IntelliJ (or `docker compose down -v && docker compose up -d`).
Do **not** reset in the middle of the demo: 3.1.3.3 and 3.1.4.3 use the trip you
created in 3.1.3.1.

## If something goes wrong

| Problem | Fix |
|---|---|
| "Connection Failed" in the GUI status bar | `docker compose up -d`, wait for healthy, restart the GUI |
| A GUI table does not show a change | open the screen again from the menu on the left |
| The data is in a strange state | run `queries/Reset.sql` in IntelliJ (one second), restart the GUI |
| A change is refused with `foreign key constraint fails` on `dba_users` | restart the GUI - it registers the account again on connect |
| Everything is broken | `docker compose down -v && docker compose up -d` - a clean install in the demo state (about 10 seconds) |
