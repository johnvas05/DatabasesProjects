# Cheat sheet - showing the project in the exam

One page per question you might be asked. Each entry gives the **SQL** proof,
the **GUI** proof, and what should appear on screen. Everything assumes the
database is in the demo state (`tests/reset_db.sh`).

**The three commands you need**

```bash
tests/reset_db.sh                                                                   # back to the demo state
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/Tests.sql   # 154 checks
mvn javafx:run                                                                       # the GUI
```

---

## Where everything lives

| Requirement | SQL file | GUI screen | Tests.sql section |
|---|---|---|---|
| 3.1.1 seed data | `Insertions.sql` | every table | 1 |
| 3.1.2.1 vehicle | `cars.sql` | Vehicles | 2 |
| 3.1.2.2 lodging, room_usage | `Accommodation.sql` | Lodgings | 2, 5 |
| 3.1.2.3 trip_history (90 000) | `history.sql` | Universal Manager | 2, 15 |
| 3.1.2.4 dba_users, log_actions | `AdminLog.sql` | Admin & Logs | 2, 12 |
| 3.1.3.1 assign a vehicle | `VechicleProcedure.sql` | Trips → Add Trip | 10 |
| 3.1.3.2 search accommodation | `AccommodationProcedure.sql` | (used by auto-booking) | 8 |
| 3.1.3.3 book a whole trip | `AutoBookProcedure.sql` | Trips → Auto-Book | 9 |
| 3.1.3.4 history + indexes | `history.sql` | – | 15 |
| 3.1.4.1 audit log triggers | `Triggers.sql` | Admin → System Logs | 12 |
| 3.1.4.2 nights and cost | `AccommodationProcedure.sql` | Trip Details | 6 |
| 3.1.4.3 trip completion | `Triggers.sql` | Universal Manager → trip | 11 |
| reservation pricing | `CalculateReservationCost.sql` | Reservations | 7 |
| branch financials | `PROCEDURE.sql` | Admin → Branch Financials | 13 |
| salary guard | `TRIGGER.sql` | Staff → Update Salary | 14 |
| 3.2.1 CRUD on any table | – | Universal Manager | – |
| 3.2.2 restricted input | – | every form | – |
| 3.2.3 bonus features | – | Trips | 8, 9 |

---

## 3.1.3.1 - Assigning a vehicle (five checks)

**GUI** — Trips → fill the form → **Add Trip**.

| To show | Pick in the form | What appears |
|---|---|---|
| ✅ it works | Driver with **licence D**, the 50-seat bus | `Trip N created` + five checks, all **PASS** |
| ❌ wrong licence | Driver with **licence B**, the 50-seat bus | `Trip N created without vehicle` — *driver licence B (C/D needed)* |
| ❌ no driver | leave Driver empty | the form refuses: *"Please select a Driver"* |
| ❌ vehicle busy | a bus already on an overlapping trip | *overlaps 1 other trip* |

**SQL**

```sql
CALL sp_assign_vehicle_to_trip(14, 9, 90500);   -- all five PASS, then Success
CALL sp_assign_vehicle_to_trip(1, 4, 200100);   -- vehicle is Maintenance
CALL sp_assign_vehicle_to_trip(8, 1, 150100);   -- driver licence B (C/D needed)
CALL sp_assign_vehicle_to_trip(2, 1, 150100);   -- overlaps 1 other trip
CALL sp_assign_vehicle_to_trip(14, 9, 1000);    -- mileage 1000 < recorded 90000
CALL sp_assign_vehicle_to_trip(1, 4, 1);        -- BOTH reasons at once
```

> The procedure always prints the full PASS/FAIL table first, then either
> assigns the vehicle or raises the error. In the GUI the table appears in the
> alert on success; on failure the alert names the reasons.

**Why a bus needs licence C or D** — that is the rule of section 2: more than
9 seats is a professional vehicle. With 9 seats or fewer any licence is fine
(`CALL sp_assign_vehicle_to_trip(8, 8, 20000)` passes with licence B).

---

## 3.1.3.3 - Auto-booking hotels (bonus 3)

**GUI** — Trips → select **trip 1** → **Auto-Book Accommodations 🏨** → confirm.

> *"Automatically booked 2 accommodation(s) for this trip."*
> Then **Show Trip Details**: Le Grand Paris 01–05 June, 1 room, $1000.00 and
> London Stay 05–10 June, 1 room, $300.00.

Press the button **twice** — still 2 bookings, not 4. It replaces, never doubles.

**SQL**

```sql
CALL sp_book_trip_accommodation(1);     -- Paris 1000 + London 300 = 1300
CALL sp_book_trip_accommodation(9999);  -- trip does not exist
```

**The interesting failure** — one leg fails, so the whole trip is cancelled:

```sql
UPDATE lodging SET lg_total_rooms = 0 WHERE lg_id = 2;   -- London full
CALL sp_book_trip_accommodation(1);
-- "no lodging in London with 1 free room(s)... All bookings of the trip were cancelled."
SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1;    -- 0, the Paris booking went too
UPDATE lodging SET lg_total_rooms = 30 WHERE lg_id = 2;
```

**Rooms = passengers ÷ 2** — trip 3 has 3 paid passengers → 2 rooms.

---

## 3.1.3.2 - Searching for accommodation

Not a button of its own; `sp_book_trip_accommodation` calls it for every leg.

```sql
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 2, @id);  -- Le Grand Paris
SELECT @id;
```

| Outcome | How to force it |
|---|---|
| nothing free | ask for more rooms than are left |
| lodging closed | `UPDATE lodging SET lg_status='Inactive' WHERE lg_id=1;` |
| ordering | cheapest first, then more stars, then better rating |

---

## 3.1.4.2 - Nights and cost are computed, never typed

**GUI** — after auto-booking, **Show Trip Details** shows nights and cost that
nobody entered.

**SQL**

```sql
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-01', '2026-10-04', 3);
SELECT ru_nights, ru_total_cost FROM room_usage WHERE ru_trip_id = 11;  -- 3, 1080.00
```

❌ the refused path — a stay must be at least one night:

```sql
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-05', '2026-10-05', 1);   -- check-out must be at least one day after check-in
```

---

## 3.1.4.3 - Completing a trip frees its vehicle

**GUI** — Universal Manager → table `trip` → select trip 14 → **Update Row** →
set `tr_status` = `COMPLETED` and `tr_km` = `350`. Then look at table `vehicle`:
vehicle 9 is `Available` again and its mileage grew by 350.

**SQL**

```sql
UPDATE trip SET tr_status = 'COMPLETED', tr_km = 350 WHERE tr_id = 14;
SELECT v_status, v_mileage FROM vehicle WHERE v_id = 9;    -- Available, +350
```

Setting a trip to `ACTIVE` instead does nothing to the vehicle — that is the
point of the `OLD.tr_status <> 'COMPLETED'` condition.

---

## 3.1.4.1 - The audit log (21 triggers)

**GUI** — Admin & Logs → **System Logs** → **Refresh Logs**.

> After a reset the log is **empty**, so everything in it is your demo. Add a
> customer on the Customers screen, then refresh: the INSERT is there with the
> account, the time and what changed.

**SQL**

```sql
SELECT log_table_name, log_action_type, log_dba_username, log_details
FROM log_actions ORDER BY log_id DESC LIMIT 10;
```

**The strong point** — the log cannot be bypassed, because
`log_actions.log_dba_username` is a foreign key to `dba_users`. An account that
is not a registered DBA cannot change any data at all:

```sql
DELETE FROM log_actions;
DELETE FROM dba_users WHERE dba_username = 'root';
INSERT INTO customer (cust_name, cust_lname) VALUES ('Not','ADba');  -- foreign key constraint fails
INSERT INTO dba_users (dba_username, dba_start_date) VALUES ('root', CURDATE());  -- put it back!
```

> If you run this, put the row back, or run `tests/reset_db.sh`.

---

## Reservation pricing - adult or child

**GUI** — Reservations → pick a customer, trip **1**, a free seat → **Book
Reservation**.

| Customer | Cost column |
|---|---|
| C1 … C15 (adults) | **500.00** |
| C16 … C20 (children) | **300.00** |

Nobody types the price: `sp_calculate_reservation_cost` reads the birth date and
takes the adult or the child price of the trip. A customer with no birth date is
charged as an adult.

Free seats: trip 1 has seats 1–3 taken, so the drop-down starts at **4**.

---

## The salary guard

**GUI** — Staff → select a worker → **Update Salary (+Trigger Test)**.

⚠️ **With the seeded data no branch is profitable** (one round of reservations
against a month of salaries), so every raise is denied:

> `Trigger Denied: Salary increase not allowed: branch is not profitable`

That is already a good demo. To also show a raise being **accepted**, make
branch 1 profitable first, in the SQL client:

```sql
UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1;   -- lowering is always allowed
```

Now, back in the GUI, on worker **AT101**:

| New salary | Result |
|---|---|
| `101` (+1 %) | ✅ accepted |
| `102` (+2 % exactly) | ✅ accepted — the limit itself |
| `110` (+10 %) | ❌ `Salary increase exceeds 2% limit` |
| anything, after `UPDATE reservation SET res_total_cost = 0;` | ❌ `branch is not profitable` |

Afterwards: `tests/reset_db.sh`.

---

## Branch financials

**GUI** — Admin & Logs → **Branch Financials** → pick a branch →
**Calculate Financials (Stored Proc)**.

> Revenue, expenses and profit ratio, from `sp_branch_financials` — the same
> procedure the salary trigger calls.

An unknown branch returns three NULLs instead of failing.

---

## 3.1.3.4 - 90 000 rows and two covering indexes

```sql
CALL sp_history_revenue('2021-01-01', '2021-12-31');

EXPLAIN SELECT SUM(th_revenue) FROM trip_history
WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
-- key: idx_hist_dep_rev, Extra: Using where; Using index
```

`Using index` is the phrase to point at: the query never touches the table, it
is answered from the index alone.

---

## 3.2.2 - Restricted input (asked about often)

The claim: **wherever the database knows the answer, the user picks it instead
of typing it.**

| Screen | What is a list, not a text box |
|---|---|
| Trips | branch, driver (with licence), guide, vehicle, status, dates, hours |
| Reservations | customer, trip, **free seats of that trip**, status |
| Lodgings | destination (**cities only**), type, stars, status |
| Vehicles | branch, type, status; seats and mileage are digits only |
| Staff | branch, category, licence, route, admin type, language |
| Universal Manager | built from the schema at runtime |

**Two live demos**

1. **Trips → Max seats.** Type `40` → 3 buses. Type `60` → one. Type `999` →
   *"No available vehicles with 999+ seats"*. The list is filtered by capacity
   **and** only shows vehicles that are `Available`. *(That is bonus 1.)*
2. **Lodgings → Type.** Pick `Hostel` → the Stars list greys out. Pick `Hotel` →
   it turns on. The database enforces the same rule, so the form cannot even
   offer the mistake.

**Universal Manager → Insert Row** on `travel_to`: `to_tr_id` and `to_dst_id`
are drop-downs of real rows, the dates get date pickers, the generated key is
not asked for. None of that is written per table — it is read from the schema.

---

## The rules the database refuses to break

Show these in the **Vehicles** and **Lodgings** forms; the error comes straight
from the database, not from Java.

| Try this in the GUI | Error |
|---|---|
| Vehicle: type `Car`, seats `30` | `chk_vehicle_type_seats` |
| Vehicle: type `Bus`, seats `8` | `chk_vehicle_type_seats` |
| Lodging: 6 stars | `lodging_chk_1` (stars are 1–5) |
| Universal Manager → `lodging`, set `lg_dst_id` to France | *lodging must belong to a city destination* |
| Universal Manager → `reservation`, same trip + seat twice | `Duplicate entry` |

> Point out that the **same** error appears in the Universal Manager as in the
> hand-written form — the rule lives in the database, so no screen can bypass it.

---

## Bonus features (3.2.3) - all on the Trips screen

1. **Smart vehicle selection** — the Max seats field filters the vehicle list in
   real time, by capacity and availability.
2. **Show Trip Details** — driver (name, licence, years), guide (name and the
   **languages they speak**, from the `languages` table), the booked hotels with
   nights and cost, and the passenger list.
3. **Auto-Book Accommodations** — one click books the whole trip through
   `sp_book_trip_accommodation`.

---

## The numbers to have in your head

| | |
|---|---|
| Trip 1 | 1–10 June 2026, Paris then London, 50 seats, 500 adult / 300 child |
| Trip 14 | Jan 2027, driver AT113 (licence **D**), the happy path for vehicle 9 |
| Trip 8 | driver AT114 (licence **B**) — use it to make the licence check fail |
| Vehicle 1 | 50-seat bus, Available, 150 000 km |
| Vehicle 4 | 55-seat bus, **Maintenance** — use it to make check 1 fail |
| Vehicle 9 | 52-seat bus, Available, 90 000 km |
| Customers | 1–15 adults, 16–20 children |
| Lodging 1 | Le Grand Paris, 5★, 100 rooms, 250/night |
| Lodging 2 | London Stay, hostel, 30 rooms, 60/night |
| Rows | 26 triggers, 8 procedures, 90 000 history rows |

---

## If something goes wrong

| Problem | Fix |
|---|---|
| The data is in a strange state | `tests/reset_db.sh` |
| "Connection Failed" in the status bar | `docker compose up -d`, wait for healthy |
| `foreign key constraint fails` on `dba_users` | the account was removed from `dba_users`; reconnect, or re-insert it |
| A trip cannot be deleted | reservations point at it — delete those first, or use the Universal Manager |
| Everything is broken | `docker compose down -v && docker compose up -d` (about a minute) |

## Three sentences to open with

> The database is a travel agency: branches, staff, trips, destinations,
> customers and reservations, plus vehicles, lodgings and a 90 000-row history.
>
> The rules of the description are enforced *in the database* — CHECK
> constraints, five stored procedures and 26 triggers — so no screen can bypass
> them, and every change is written to an audit log tied to a registered DBA.
>
> `queries/Tests.sql` proves it: 154 checks, every procedure and trigger shown
> both accepting valid data and refusing invalid data, run on the live database
> in under a second without changing a row.
