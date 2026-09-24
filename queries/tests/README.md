# One file per question

Generated from `queries/Tests.sql` by `tests/split_sql_tests.sh` - edit
Tests.sql, then run the script again. Every file runs on its own, checks
one part of the project inside a transaction that is rolled back, prints
its own PASS/FAIL report and changes nothing.

Each file starts from the seed data of the report, loaded inside its
transaction, so it passes whatever was done in the GUI before - you can
show a feature in the GUI and run its test right after.

```bash
docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/tests/3.1.3.1_assign_vehicle.sql
```

Or open a file in a SQL client and execute all of it.

| File | What it checks |
|---|---|
| [`3.1.1_seed_data.sql`](3.1.1_seed_data.sql) | 3.1.1  The tables of the preparatory phase |
| [`3.1.2_new_tables.sql`](3.1.2_new_tables.sql) | 3.1.2  The tables and columns added in this phase |
| [`rules_section2_data.sql`](rules_section2_data.sql) | The business rules of section 2 of the description |
| [`rules_section2_check_constraints.sql`](rules_section2_check_constraints.sql) | section 2 rules the database ENFORCES (CHECK constraints) |
| [`3.1.2.2_lodging_in_a_city.sql`](3.1.2.2_lodging_in_a_city.sql) | 3.1.2.2  A lodging belongs to a city, never to a country |
| [`3.1.4.2_stay_nights_and_cost.sql`](3.1.4.2_stay_nights_and_cost.sql) | 3.1.4.2  The nights and the cost of a stay |
| [`gui_reservation_price.sql`](gui_reservation_price.sql) | The price of a reservation |
| [`3.1.3.2_search_accommodation.sql`](3.1.3.2_search_accommodation.sql) | 3.1.3.2  Searching for accommodation |
| [`3.1.3.3_book_whole_trip.sql`](3.1.3.3_book_whole_trip.sql) | 3.1.3.3  Booking the accommodation of a whole trip |
| [`3.1.3.1_assign_vehicle.sql`](3.1.3.1_assign_vehicle.sql) | 3.1.3.1  Assigning a vehicle to a trip |
| [`3.1.4.3_trip_completion.sql`](3.1.4.3_trip_completion.sql) | 3.1.4.3  Completing a trip frees its vehicle |
| [`3.1.4.1_audit_log.sql`](3.1.4.1_audit_log.sql) | 3.1.4.1  The audit log |
| [`gui_branch_financials.sql`](gui_branch_financials.sql) | The financial state of a branch |
| [`gui_salary_guard.sql`](gui_salary_guard.sql) | The salary guard |
| [`3.1.3.4_history_and_indexes.sql`](3.1.3.4_history_and_indexes.sql) | 3.1.3.4  The 90 000-row history and its indexes |
