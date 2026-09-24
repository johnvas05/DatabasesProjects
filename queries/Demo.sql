-- #####################################################################
--
--  Demo.sql - the presentation, question by question (Part A)
--
-- #####################################################################
--
--  HOW TO USE IT
--  Open this file in the IDE (IntelliJ / DataGrip, connected to
--  baseisproject) and run it ONE STATEMENT AT A TIME: put the cursor on a
--  statement and press Ctrl+Enter (Cmd+Enter on a Mac). Do NOT run the
--  whole file at once - some statements are meant to be refused, and the
--  refusal is what you are showing.
--
--  The blocks follow the order of the assignment: 3.1.1, 3.1.2.x,
--  3.1.3.1 ... 3.1.3.4, 3.1.4.1 ... 3.1.4.3, then the procedures and the
--  trigger the GUI uses in Part B.
--
--  Every block starts with START TRANSACTION and ends with ROLLBACK, so the
--  database is back in the demo state before the next question, and the
--  whole file can be shown again and again. If a block is left half way
--  (or anything looks wrong), run queries/Reset.sql - it takes a second.
--
--  The numbers quoted below are those of the demo state. Blocks 3.1.1,
--  3.1.2.3, 3.1.2.4 and 3.1.3.4 read data the GUI never changes, so they
--  can be shown at any time. The other blocks show the numbers quoted only
--  before the GUI has changed the same records (e.g. 3.1.3.2 before hotels
--  are booked from the GUI). The test files in queries/tests/ do not have
--  this limit: they load the seed data themselves.
--
--  MARKERS
--    [OK]        the statement goes through - show the result
--    [REFUSED]   the statement is refused by the database on purpose - the
--                "expect:" text is part of the error message that appears
--    Say:        one sentence to explain what the examiner is looking at
--
--  Every case of every question is also checked automatically, with a
--  PASS/FAIL table, by the files in queries/tests/ (one per question) and
--  by queries/Tests.sql (all of them, 154 checks). Those run as a whole
--  file and change nothing either.
--
--  THE RECORDS USED
--    trip 1    1-10 Jun 2026, Paris then London, 50 seats, 500 adult / 300 child,
--              vehicle 1, driver AT111 (licence D), guide AT119
--    trip 8    Aug 2026, driver AT114 - licence B
--    trip 14   Jan 2027, driver AT113 - licence D
--    vehicle 1   50-seat bus,   Available,   150 000 km
--    vehicle 4   55-seat bus,   Maintenance, 200 000 km
--    vehicle 8   9-seat van,    Available,    20 000 km
--    vehicle 9   52-seat bus,   Available,    90 000 km
--    vehicle 10  5-seat car,    Available,    10 000 km
--    lodging 1 Le Grand Paris (hotel, 250/night)  lodging 2 London Stay (hostel, 60/night)
--    lodging 3 Berlin Plaza (hotel, 120/night)
--    customers 1-15 adults, 16-20 children
--
-- #####################################################################


-- =====================================================================
--  3.1.1  The data of the first phase
--  Say: every table of the first phase holds at least twice the minimum
--       of the assignment, because we are a team of two.
-- =====================================================================
SELECT 'worker' AS table_name, COUNT(*) AS rows_now, 26 AS minimum FROM worker
UNION ALL SELECT 'driver',       COUNT(*),  8 FROM driver
UNION ALL SELECT 'guide',        COUNT(*),  8 FROM guide
UNION ALL SELECT 'admin',        COUNT(*), 10 FROM admin
UNION ALL SELECT 'languages',    COUNT(*),  8 FROM languages
UNION ALL SELECT 'language_ref', COUNT(*),  6 FROM language_ref
UNION ALL SELECT 'branch',       COUNT(*),  6 FROM branch
UNION ALL SELECT 'manages',      COUNT(*),  6 FROM manages
UNION ALL SELECT 'phones',       COUNT(*), 10 FROM phones
UNION ALL SELECT 'customer',     COUNT(*), 20 FROM customer
UNION ALL SELECT 'destination',  COUNT(*), 10 FROM destination
UNION ALL SELECT 'trip',         COUNT(*), 14 FROM trip
UNION ALL SELECT 'travel_to',    COUNT(*), 14 FROM travel_to
UNION ALL SELECT 'event',        COUNT(*), 20 FROM event
UNION ALL SELECT 'reservation',  COUNT(*), 24 FROM reservation;


-- =====================================================================
--  3.1.2.1  Vehicles
--  Say: the number of seats must match the type of the vehicle; the
--       database itself refuses a mismatch with a CHECK constraint.
-- =====================================================================
START TRANSACTION;

SELECT v_id, v_license_plate, v_brand, v_model, v_type, v_seats, v_status, v_mileage, v_br_code
FROM vehicle ORDER BY v_id;

-- [OK] a car with 4 seats
INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
VALUES (1, 'DEMO-001', 'Yaris', 'Toyota', 'Car', 4);

-- [REFUSED] expect: chk_vehicle_type_seats
INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
VALUES (1, 'DEMO-002', 'Yaris', 'Toyota', 'Car', 30);

-- [REFUSED] expect: chk_vehicle_type_seats
INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
VALUES (1, 'DEMO-003', 'Tourismo', 'Mercedes', 'Bus', 8);

ROLLBACK;


-- =====================================================================
--  3.1.2.2  Lodging, room usage and stays with real dates
--  Say: a lodging belongs to a city, never to a country - Paris belongs to
--       France, so a hotel "in France" is refused by a trigger. Only hotels
--       and resorts may have stars. Each stay of a trip has its own dates
--       and its place in the order of the trip (to_sequence).
-- =====================================================================
START TRANSACTION;

SELECT lg_id, lg_name, lg_type, lg_stars, lg_city, lg_postal_code, lg_total_rooms, lg_cost_per_night, lg_status
FROM lodging ORDER BY lg_id;

-- a city and the country it belongs to
SELECT c.dst_name AS city, p.dst_name AS belongs_to
FROM destination c JOIN destination p ON p.dst_id = c.dst_location;

-- the stays of trip 1, in visit order, with their dates
SELECT tt.to_sequence, d.dst_name, tt.to_arrival, tt.to_departure
FROM travel_to tt JOIN destination d ON d.dst_id = tt.to_dst_id
WHERE tt.to_tr_id = 1 ORDER BY tt.to_sequence;

-- [OK] a hostel in the city of Paris
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_postal_code, lg_total_rooms, lg_cost_per_night)
VALUES (1, 'Demo Hostel', 'Hostel', 'Rue Demo 1', 'Paris', '75002', 10, 35);

-- [REFUSED] expect: must belong to a city destination
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
SELECT dst_id, 'Demo Country Hotel', 'Hotel', 'x', 'x', 10, 100 FROM destination WHERE dst_name = 'France';

-- [REFUSED] expect: chk_lodging_stars_type
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
VALUES (2, 'Demo Starred Hostel', 'Hostel', 4, 'x', 'London', 10, 30);

ROLLBACK;


-- =====================================================================
--  3.1.2.3  The history of 90 000 trips
--  Say: generated by sp_generate_dummy_history; the queries on it are
--       shown in 3.1.3.4.
-- =====================================================================
SELECT COUNT(*) AS trips_in_history, MIN(th_departure) AS first_trip, MAX(th_departure) AS last_trip
FROM trip_history;

SELECT * FROM trip_history ORDER BY th_id LIMIT 5;


-- =====================================================================
--  3.1.2.4  The DBA accounts and the audit log
--  Say: every change is logged with the account that made it, and that
--       account must be a registered DBA (foreign key) - shown in 3.1.4.1.
-- =====================================================================
SELECT * FROM dba_users;

DESCRIBE log_actions;


-- =====================================================================
--  3.1.3.1  Assigning a vehicle to a trip - sp_assign_vehicle_to_trip
--  Say: five checks - the vehicle is Available, it has enough seats for
--       the confirmed/paid reservations, a vehicle of more than 9 seats
--       needs a driver with licence C or D, the vehicle is not on another
--       trip on those dates, and the odometer does not go backwards. The
--       procedure prints the result of every check; only if all five pass
--       does it assign the vehicle, set it InUse and record the mileage.
-- =====================================================================
START TRANSACTION;

-- the trips and the vehicles of this scenario
SELECT t.tr_id, t.tr_departure, t.tr_return, t.tr_status, t.tr_vehicle_id,
       t.tr_drv_AT, d.drv_license,
       (SELECT COUNT(*) FROM reservation r
        WHERE r.res_tr_id = t.tr_id AND r.res_status IN ('CONFIRMED', 'PAID')) AS confirmed_or_paid
FROM trip t LEFT JOIN driver d ON d.drv_AT = t.tr_drv_AT
WHERE t.tr_id IN (1, 2, 3, 8, 11, 13, 14) ORDER BY t.tr_id;

SELECT v_id, v_type, v_seats, v_status, v_mileage FROM vehicle WHERE v_id IN (1, 4, 8, 9, 10);

-- [OK] all five checks PASS: trip 14 (licence D) gets the 52-seat bus 9
CALL sp_assign_vehicle_to_trip(14, 9, 90500);

-- the result: the vehicle is InUse with the new reading, the trip points at it
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 9;
SELECT tr_id, tr_vehicle_id FROM trip WHERE tr_id = 14;

-- check 1 - the vehicle is already InUse (on trip 14, just now)
-- [REFUSED] expect: vehicle is InUse
CALL sp_assign_vehicle_to_trip(13, 9, 90600);

-- check 1 - the vehicle is in Maintenance
-- [REFUSED] expect: vehicle is Maintenance
CALL sp_assign_vehicle_to_trip(1, 4, 200100);

-- check 2 - trip 3 is popular: three more people pay, 6 in total,
--           and the car has only 5 seats
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (3, 4, 9, 'PAID', 600), (3, 5, 10, 'PAID', 600), (3, 6, 11, 'PAID', 600);
-- [REFUSED] expect: 5 seats < 6 reservations
CALL sp_assign_vehicle_to_trip(3, 10, 10100);

-- check 3 - the driver of trip 8 holds licence B, the bus has 50 seats
-- [REFUSED] expect: driver licence B (C/D needed)
CALL sp_assign_vehicle_to_trip(8, 1, 150100);

-- check 3 - the same driver with a 9-seat van: the licence does not matter
-- [OK] all five checks PASS
CALL sp_assign_vehicle_to_trip(8, 8, 20000);

-- check 4 - bus 1 is on trip 1 (1-10 June), trip 2 is 5-12 June
-- [REFUSED] expect: overlaps 1 other trip
CALL sp_assign_vehicle_to_trip(2, 1, 150100);

-- check 5 - bus 1 has 150 000 km, the reading says 1 000
-- [REFUSED] expect: mileage 1000 < recorded 150000
CALL sp_assign_vehicle_to_trip(11, 1, 1000);

-- two checks at once: every reason is reported
-- [REFUSED] expect: vehicle is Maintenance; mileage 1 < recorded 200000
CALL sp_assign_vehicle_to_trip(1, 4, 1);

-- a trip or a vehicle that does not exist
-- [REFUSED] expect: trip does not exist
CALL sp_assign_vehicle_to_trip(9999, 1, 1);
-- [REFUSED] expect: vehicle does not exist
CALL sp_assign_vehicle_to_trip(1, 9999, 1);

-- a refused assignment changed nothing
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id IN (1, 4);

ROLLBACK;


-- =====================================================================
--  3.1.3.2  Searching for accommodation - sp_search_accommodation
--  Say: for a destination, dates and number of rooms it lists the active
--       lodgings that still have enough free rooms - rooms already booked
--       for an overlapping period are subtracted - cheapest first, then
--       more stars, then a better rating. The OUT parameter returns the
--       best one.
-- =====================================================================
START TRANSACTION;

-- [OK] Paris, 1-5 June, 2 rooms -> Le Grand Paris, 100 free rooms
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 2, @best);
SELECT @best AS best_lodging_id;

-- another trip books 95 of its 100 rooms for 3-7 June
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 1, '2026-06-03', '2026-06-07', 95);

-- [OK] 5 rooms are still free -> AvailableRooms = 5
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 5, @best);

-- [OK] 6 rooms are not -> an empty list and NULL
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 6, @best);
SELECT @best AS best_lodging_id;

-- two cheaper lodgings at the same price: the one with stars comes first
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_rating, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
VALUES (1, 'Demo Budget Inn', 'Hostel', NULL, 3.0, 'Rue X', 'Paris', 20, 30.00),
       (1, 'Demo Mid Hotel',  'Hotel',  3,    4.0, 'Rue Y', 'Paris', 20, 30.00);
-- [OK] Demo Mid Hotel, Demo Budget Inn, Le Grand Paris - in that order
CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @best);

-- a lodging that is not active is never offered
UPDATE lodging SET lg_status = 'Inactive' WHERE lg_id = 1;
-- [OK] Le Grand Paris is gone from the list
CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @best);

ROLLBACK;


-- =====================================================================
--  3.1.3.3  Booking a whole trip - sp_book_trip_accommodation
--  Say: for every stay of the trip, in visit order, it books the best
--       lodging that sp_search_accommodation offers, for the dates of that
--       stay. One room per two confirmed/paid passengers. If one stay
--       cannot be booked, every booking of the trip is cancelled - all or
--       nothing. Running it again replaces the bookings.
--       (This is the "Auto-Book Accommodations" button of the GUI.)
-- =====================================================================
START TRANSACTION;

-- trip 1: two stays, two confirmed passengers -> 1 room
SELECT tt.to_sequence, d.dst_name, tt.to_arrival, tt.to_departure
FROM travel_to tt JOIN destination d ON d.dst_id = tt.to_dst_id
WHERE tt.to_tr_id = 1 ORDER BY tt.to_sequence;
SELECT res_seatnum, res_cust_id, res_status FROM reservation WHERE res_tr_id = 1;

-- [OK] Le Grand Paris 4 nights 1000.00 + London Stay 5 nights 300.00 = 1300.00
CALL sp_book_trip_accommodation(1);

-- [OK] again: the bookings are replaced, still 2
CALL sp_book_trip_accommodation(1);
SELECT COUNT(*) AS bookings_of_trip_1 FROM room_usage WHERE ru_trip_id = 1;

-- [OK] trip 3 has 3 paid passengers -> 2 rooms per stay
CALL sp_book_trip_accommodation(3);

-- all or nothing: London Stay has no rooms left, so the Paris booking goes too
UPDATE lodging SET lg_total_rooms = 0 WHERE lg_id = 2;
-- [REFUSED] expect: no lodging in London with 1 free room(s)
CALL sp_book_trip_accommodation(1);
SELECT COUNT(*) AS bookings_of_trip_1 FROM room_usage WHERE ru_trip_id = 1;

-- the only passenger of trip 12 has not confirmed yet: nothing to book
UPDATE reservation SET res_status = 'PENDING' WHERE res_tr_id = 12;
-- [REFUSED] expect: no confirmed or paid reservations
CALL sp_book_trip_accommodation(12);

-- [REFUSED] expect: trip does not exist
CALL sp_book_trip_accommodation(9999);

ROLLBACK;


-- =====================================================================
--  3.1.3.4  Queries on the history, and their indexes
--  Say: two reports on the 90 000 trips. Each has a covering index - the
--       WHERE column first, the SELECTed column second - so the answer
--       comes from the index alone, without reading the table:
--       "Using index" in EXPLAIN. Without the index it is a full scan.
-- =====================================================================
SHOW INDEX FROM trip_history;

-- (a) the revenue of the trips between two dates
CALL sp_history_revenue('2021-01-01', '2021-12-31');

-- with the index: type range, key idx_hist_dep_rev, Extra "Using index"
EXPLAIN SELECT SUM(th_revenue) FROM trip_history
WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';

-- the same query forbidden to use it: type ALL, the whole table
EXPLAIN SELECT SUM(th_revenue) FROM trip_history IGNORE INDEX (idx_hist_dep_rev)
WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';

-- (b) the dates of the trips that had exactly 3 destinations
CALL sp_history_destinations(3);

-- with the index: key idx_hist_dc_dep, Extra "Using index"
EXPLAIN SELECT th_departure FROM trip_history WHERE th_dest_count = 3;

-- the time, with and without the index
SET profiling = 1;
SELECT SUM(th_revenue) FROM trip_history IGNORE INDEX (idx_hist_dep_rev)
WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
SELECT SUM(th_revenue) FROM trip_history
WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
SHOW PROFILES;
SET profiling = 0;


-- =====================================================================
--  3.1.4.1  The audit log - 21 triggers
--  Say: INSERT, UPDATE and DELETE on trip, reservation, customer,
--       destination, vehicle, lodging and room_usage are each written to
--       log_actions: who, when, which table, what kind of change, and what
--       changed. The account must be a registered DBA (foreign key), so
--       nobody can change the data without leaving a trace.
-- =====================================================================
START TRANSACTION;

-- the log starts empty in the demo state
SELECT COUNT(*) AS log_rows FROM log_actions;

-- [OK] three changes to a customer
INSERT INTO customer (cust_name, cust_lname, cust_email, cust_birth_date)
VALUES ('Demo', 'Customer', 'demo@mail.com', '1990-05-05');
UPDATE customer SET cust_phone = '2101234567' WHERE cust_lname = 'Customer';
DELETE FROM customer WHERE cust_lname = 'Customer';

-- [OK] a vehicle goes to maintenance, a reservation is made
UPDATE vehicle SET v_status = 'Maintenance' WHERE v_id = 10;
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (5, 9, 1, 'PENDING', 550);

-- every change is there, with the account, the time and the details
SELECT log_id, log_timestamp, log_dba_username, log_table_name, log_action_type, log_details
FROM log_actions ORDER BY log_id;

-- the account must be a registered DBA: remove it and try again
-- (WHERE covers every row; it is there so IntelliJ does not stop to ask)
DELETE FROM log_actions WHERE log_id > 0;
DELETE FROM dba_users WHERE dba_username = SUBSTRING_INDEX(USER(), '@', 1);
-- [REFUSED] expect: foreign key constraint fails
INSERT INTO customer (cust_name, cust_lname) VALUES ('Not', 'ADba');

ROLLBACK;

-- (the ROLLBACK brought the account back)
SELECT * FROM dba_users;


-- =====================================================================
--  3.1.4.2  The nights and the cost of a stay - trigger on room_usage
--  Say: when a stay is booked, the trigger computes the nights from the
--       two dates and the cost as price x nights x rooms - neither is ever
--       typed in. A stay of less than one night is refused.
-- =====================================================================
START TRANSACTION;

SELECT lg_id, lg_name, lg_cost_per_night FROM lodging WHERE lg_id = 3;

-- [OK] 1-4 October, 3 rooms at Berlin Plaza - no nights or cost given
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-01', '2026-10-04', 3);

-- 3 nights, 120 x 3 x 3 = 1080.00
SELECT ru_checkin, ru_checkout, ru_rooms_count, ru_nights, ru_total_cost
FROM room_usage WHERE ru_trip_id = 11;

-- [REFUSED] expect: check-out must be at least one day after check-in
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-05', '2026-10-05', 1);

-- [REFUSED] expect: check-out must be at least one day after check-in
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-05', '2026-10-02', 1);

ROLLBACK;


-- =====================================================================
--  3.1.4.3  Completing a trip frees its vehicle - trigger on trip
--  Say: when a trip becomes COMPLETED, its vehicle is Available again and
--       the kilometres of the trip are added to its odometer. Any other
--       status leaves the vehicle alone, and a trip that is already
--       completed does not add the kilometres twice.
-- =====================================================================
START TRANSACTION;

-- put bus 9 on trip 14 through the procedure of 3.1.3.1: InUse, 90 500 km
CALL sp_assign_vehicle_to_trip(14, 9, 90500);
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 9;

-- [OK] the trip is over, 350 km
UPDATE trip SET tr_status = 'COMPLETED', tr_km = 350 WHERE tr_id = 14;

-- Available, 90 850 km
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 9;

-- [OK] changing the km of a trip that is already COMPLETED adds nothing
UPDATE trip SET tr_km = 400 WHERE tr_id = 14;
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 9;

-- [OK] another status (ACTIVE) leaves the vehicle of trip 2 alone
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 2;
UPDATE trip SET tr_status = 'ACTIVE' WHERE tr_id = 2;
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 2;

ROLLBACK;


-- #####################################################################
--  PART B SUPPORT - the procedures and the trigger the GUI calls
--  (show these if you are asked "what happens behind this button")
-- #####################################################################


-- =====================================================================
--  Reservations screen -> sp_calculate_reservation_cost
--  Say: the price is never typed in: the adult price of the trip, or the
--       child price when the customer is under 18.
-- =====================================================================
START TRANSACTION;

SELECT tr_id, tr_cost_adult, tr_cost_child FROM trip WHERE tr_id = 1;
SELECT cust_id, cust_name, cust_birth_date,
       TIMESTAMPDIFF(YEAR, cust_birth_date, CURDATE()) AS age
FROM customer WHERE cust_id IN (1, 20);

-- [OK] an adult: 500.00
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 10, 1, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 10, 1);

-- [OK] a child: 300.00
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 11, 20, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 11, 20);

SELECT res_seatnum, res_cust_id, res_total_cost FROM reservation
WHERE res_tr_id = 1 AND res_seatnum IN (10, 11);

-- [REFUSED] expect: Duplicate entry
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status)
VALUES (1, 10, 2, 'PENDING');

ROLLBACK;


-- =====================================================================
--  Admin & Logs screen -> sp_branch_financials
--  Say: revenue = the reservations of the trips of the branch, expenses =
--       the salaries of its workers, ratio = (revenue - expenses) / expenses.
-- =====================================================================
CALL sp_branch_financials(1, @revenue, @expenses, @ratio);
SELECT @revenue AS revenue, @expenses AS expenses, @ratio AS profit_ratio;

-- an unknown branch: three NULLs, not an error
CALL sp_branch_financials(999, @revenue, @expenses, @ratio);
SELECT @revenue AS revenue, @expenses AS expenses, @ratio AS profit_ratio;


-- =====================================================================
--  Staff screen -> trg_worker_salary_increase
--  Say: a raise is allowed only if the branch is profitable AND it is at
--       most 2 %. Lowering a salary is always allowed.
-- =====================================================================
START TRANSACTION;

-- with the seed data branch 1 pays more than it takes in
-- [REFUSED] expect: branch is not profitable
UPDATE worker SET wrk_salary = wrk_salary * 1.01 WHERE wrk_AT = 'AT101';

-- [OK] lowering is always allowed: branch 1 now earns more than it pays
UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1;
CALL sp_branch_financials(1, @revenue, @expenses, @ratio);
SELECT @revenue AS revenue, @expenses AS expenses, @ratio AS profit_ratio;

-- [OK] +1 %
UPDATE worker SET wrk_salary = 101 WHERE wrk_AT = 'AT101';

-- [OK] exactly +2 % is still allowed (100 -> 102)
UPDATE worker SET wrk_salary = 100 WHERE wrk_AT = 'AT101';
UPDATE worker SET wrk_salary = 102 WHERE wrk_AT = 'AT101';

-- [REFUSED] expect: exceeds 2% limit
UPDATE worker SET wrk_salary = 110 WHERE wrk_AT = 'AT101';

SELECT wrk_AT, wrk_salary FROM worker WHERE wrk_AT = 'AT101';

ROLLBACK;


-- #####################################################################
--  The database is exactly as it was (compare with queries/Reset.sql)
-- #####################################################################
SELECT (SELECT COUNT(*) FROM customer)    AS customers,
       (SELECT COUNT(*) FROM reservation) AS reservations,
       (SELECT COUNT(*) FROM room_usage)  AS room_usage_rows,
       (SELECT COUNT(*) FROM log_actions) AS log_rows,
       (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9) AS vehicle_9,
       (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101')                AS salary_AT101;
