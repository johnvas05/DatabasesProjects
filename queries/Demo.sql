-- Demo of Part A, one question at a time.
-- Run one statement at a time (Ctrl+Enter), not the whole file: some
-- statements are supposed to fail.
-- Each block ends with ROLLBACK, so nothing is changed. If something goes
-- wrong, run Reset.sql.
--
-- Records used:
--   trip 1     1-10 Jun 2026, Paris then London, vehicle 1, driver AT111 (D)
--   trip 8     driver AT114 (licence B)
--   trip 14    driver AT113 (licence D)
--   vehicle 1  50-seat bus, 150 000 km     vehicle 4  bus in Maintenance
--   vehicle 8  9-seat van                  vehicle 9  52-seat bus, 90 000 km
--   vehicle 10 5-seat car
--   lodging 1 Le Grand Paris 250/night, 2 London Stay 60/night, 3 Berlin Plaza 120/night
--   customers 1-15 adults, 16-20 children


-- 3.1.1 Rows per table (we are 2 people, so 2x the minimum)
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


-- 3.1.2.1 Vehicles: the type must match the seats (CHECK)
START TRANSACTION;

SELECT v_id, v_license_plate, v_brand, v_model, v_type, v_seats, v_status, v_mileage, v_br_code
FROM vehicle ORDER BY v_id;

-- a car with 4 seats
INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
VALUES (1, 'DEMO-001', 'Yaris', 'Toyota', 'Car', 4);

-- should fail: chk_vehicle_type_seats
INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
VALUES (1, 'DEMO-002', 'Yaris', 'Toyota', 'Car', 30);

-- should fail: chk_vehicle_type_seats
INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
VALUES (1, 'DEMO-003', 'Tourismo', 'Mercedes', 'Bus', 8);

ROLLBACK;


-- 3.1.2.2 Lodging: only in a city, stars only for hotels/resorts
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

-- a hostel in the city of Paris
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_postal_code, lg_total_rooms, lg_cost_per_night)
VALUES (1, 'Demo Hostel', 'Hostel', 'Rue Demo 1', 'Paris', '75002', 10, 35);

-- should fail: must belong to a city destination
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
SELECT dst_id, 'Demo Country Hotel', 'Hotel', 'x', 'x', 10, 100 FROM destination WHERE dst_name = 'France';

-- should fail: chk_lodging_stars_type
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
VALUES (2, 'Demo Starred Hostel', 'Hostel', 4, 'x', 'London', 10, 30);

ROLLBACK;


-- 3.1.2.3 Trip history (90 000 rows)
SELECT COUNT(*) AS trips_in_history, MIN(th_departure) AS first_trip, MAX(th_departure) AS last_trip
FROM trip_history;

SELECT * FROM trip_history ORDER BY th_id LIMIT 5;


-- 3.1.2.4 DBAs: start date required, end date NULL while active
START TRANSACTION;

SELECT * FROM dba_users;

DESCRIBE log_actions;

-- a second DBA in the same period, still in the role (no end date)
INSERT INTO dba_users (dba_username, dba_start_date) VALUES ('demo_dba', '2026-10-01');

-- a DBA who has left the role
INSERT INTO dba_users (dba_username, dba_start_date, dba_end_date) VALUES ('demo_old', '2024-01-01', '2025-06-30');

-- should fail: cannot be null
INSERT INTO dba_users (dba_username, dba_start_date) VALUES ('demo_nodate', NULL);

SELECT * FROM dba_users;

ROLLBACK;


-- 3.1.3.1 sp_assign_vehicle_to_trip: one case per check
START TRANSACTION;

-- the trips and the vehicles of this scenario
SELECT t.tr_id, t.tr_departure, t.tr_return, t.tr_status, t.tr_vehicle_id,
       t.tr_drv_AT, d.drv_license,
       (SELECT COUNT(*) FROM reservation r
        WHERE r.res_tr_id = t.tr_id AND r.res_status IN ('CONFIRMED', 'PAID')) AS confirmed_or_paid
FROM trip t LEFT JOIN driver d ON d.drv_AT = t.tr_drv_AT
WHERE t.tr_id IN (1, 2, 3, 8, 11, 13, 14) ORDER BY t.tr_id;

SELECT v_id, v_type, v_seats, v_status, v_mileage FROM vehicle WHERE v_id IN (1, 4, 8, 9, 10);

-- all five checks PASS: trip 14 (licence D) gets the 52-seat bus 9
CALL sp_assign_vehicle_to_trip(14, 9, 90500);

-- the result: the vehicle is InUse with the new reading, the trip points at it
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 9;
SELECT tr_id, tr_vehicle_id FROM trip WHERE tr_id = 14;

-- check 1 - the vehicle is already InUse (on trip 14, just now)
-- should fail: vehicle is InUse
CALL sp_assign_vehicle_to_trip(13, 9, 90600);

-- check 1 - the vehicle is in Maintenance
-- should fail: vehicle is Maintenance
CALL sp_assign_vehicle_to_trip(1, 4, 200100);

-- check 2 - trip 3 is popular: three more people pay, 6 in total,
--           and the car has only 5 seats
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (3, 4, 9, 'PAID', 600), (3, 5, 10, 'PAID', 600), (3, 6, 11, 'PAID', 600);
-- should fail: 5 seats < 6 reservations
CALL sp_assign_vehicle_to_trip(3, 10, 10100);

-- check 3 - the driver of trip 8 holds licence B, the bus has 50 seats
-- should fail: driver licence B (C/D needed)
CALL sp_assign_vehicle_to_trip(8, 1, 150100);

-- check 3 - the same driver with a 9-seat van: the licence does not matter
-- all five checks PASS
CALL sp_assign_vehicle_to_trip(8, 8, 20000);

-- check 4 - bus 1 is on trip 1 (1-10 June), trip 2 is 5-12 June
-- should fail: overlaps 1 other trip
CALL sp_assign_vehicle_to_trip(2, 1, 150100);

-- check 5 - bus 1 has 150 000 km, the reading says 1 000
-- should fail: mileage 1000 < recorded 150000
CALL sp_assign_vehicle_to_trip(11, 1, 1000);

-- two checks at once: every reason is reported
-- should fail: vehicle is Maintenance; mileage 1 < recorded 200000
CALL sp_assign_vehicle_to_trip(1, 4, 1);

-- a trip or a vehicle that does not exist
-- should fail: trip does not exist
CALL sp_assign_vehicle_to_trip(9999, 1, 1);
-- should fail: vehicle does not exist
CALL sp_assign_vehicle_to_trip(1, 9999, 1);

-- a refused assignment changed nothing
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id IN (1, 4);

ROLLBACK;


-- 3.1.3.2 sp_search_accommodation
START TRANSACTION;

-- Paris, 1-5 June, 2 rooms -> Le Grand Paris, 100 free rooms
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 2, @best);
SELECT @best AS best_lodging_id;

-- another trip books 95 of its 100 rooms for 3-7 June
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 1, '2026-06-03', '2026-06-07', 95);

-- 5 rooms are still free -> AvailableRooms = 5
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 5, @best);

-- 6 rooms are not -> an empty list and NULL
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 6, @best);
SELECT @best AS best_lodging_id;

-- two cheaper lodgings at the same price: the one with stars comes first
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_rating, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
VALUES (1, 'Demo Budget Inn', 'Hostel', NULL, 3.0, 'Rue X', 'Paris', 20, 30.00),
       (1, 'Demo Mid Hotel',  'Hotel',  3,    4.0, 'Rue Y', 'Paris', 20, 30.00);
-- Demo Mid Hotel, Demo Budget Inn, Le Grand Paris - in that order
CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @best);

-- a lodging that is not active is never offered
UPDATE lodging SET lg_status = 'Inactive' WHERE lg_id = 1;
-- Le Grand Paris is gone from the list
CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @best);

ROLLBACK;


-- 3.1.3.3 sp_book_trip_accommodation (Auto-Book button in the GUI)
START TRANSACTION;

-- trip 1: two stays, two confirmed passengers -> 1 room
SELECT tt.to_sequence, d.dst_name, tt.to_arrival, tt.to_departure
FROM travel_to tt JOIN destination d ON d.dst_id = tt.to_dst_id
WHERE tt.to_tr_id = 1 ORDER BY tt.to_sequence;
SELECT res_seatnum, res_cust_id, res_status FROM reservation WHERE res_tr_id = 1;

-- Le Grand Paris 4 nights 1000.00 + London Stay 5 nights 300.00 = 1300.00
CALL sp_book_trip_accommodation(1);

-- again: the bookings are replaced, still 2
CALL sp_book_trip_accommodation(1);
SELECT COUNT(*) AS bookings_of_trip_1 FROM room_usage WHERE ru_trip_id = 1;

-- trip 3 has 3 paid passengers -> 2 rooms per stay
CALL sp_book_trip_accommodation(3);

-- all or nothing: London Stay has no rooms left, so the Paris booking goes too
UPDATE lodging SET lg_total_rooms = 0 WHERE lg_id = 2;
-- should fail: no lodging in London with 1 free room(s)
CALL sp_book_trip_accommodation(1);
SELECT COUNT(*) AS bookings_of_trip_1 FROM room_usage WHERE ru_trip_id = 1;

-- the only passenger of trip 12 has not confirmed yet: nothing to book
UPDATE reservation SET res_status = 'PENDING' WHERE res_tr_id = 12;
-- should fail: no confirmed or paid reservations
CALL sp_book_trip_accommodation(12);

-- should fail: trip does not exist
CALL sp_book_trip_accommodation(9999);

ROLLBACK;


-- 3.1.3.4 History queries, with and without the indexes
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

-- the same query forbidden to use it: type ALL, the whole table
EXPLAIN SELECT th_departure FROM trip_history IGNORE INDEX (idx_hist_dc_dep)
WHERE th_dest_count = 3;

-- the time of (a) and of (b), each without and with its index
SET profiling = 1;
SELECT SUM(th_revenue) FROM trip_history IGNORE INDEX (idx_hist_dep_rev)
WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
SELECT SUM(th_revenue) FROM trip_history
WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
SELECT th_departure FROM trip_history IGNORE INDEX (idx_hist_dc_dep)
WHERE th_dest_count = 3;
SELECT th_departure FROM trip_history
WHERE th_dest_count = 3;
SHOW PROFILES;
SET profiling = 0;


-- 3.1.4.1 Log triggers
START TRANSACTION;

-- the log starts empty in the demo state
SELECT COUNT(*) AS log_rows FROM log_actions;

-- three changes to a customer
INSERT INTO customer (cust_name, cust_lname, cust_email, cust_birth_date)
VALUES ('Demo', 'Customer', 'demo@mail.com', '1990-05-05');
UPDATE customer SET cust_phone = '2101234567' WHERE cust_lname = 'Customer';
DELETE FROM customer WHERE cust_lname = 'Customer';

-- a vehicle goes to maintenance, a reservation is made
UPDATE vehicle SET v_status = 'Maintenance' WHERE v_id = 10;
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (5, 9, 1, 'PENDING', 550);

-- every change is there, with the account, the time and the details
SELECT log_id, log_timestamp, log_dba_username, log_table_name, log_action_type, log_details
FROM log_actions ORDER BY log_id;

-- the account must be a registered DBA: remove it and try again
DELETE FROM log_actions WHERE log_id > 0;
DELETE FROM dba_users WHERE dba_username = SUBSTRING_INDEX(USER(), '@', 1);
-- should fail: foreign key constraint fails
INSERT INTO customer (cust_name, cust_lname) VALUES ('Not', 'ADba');

ROLLBACK;

-- (the ROLLBACK brought the account back)
SELECT * FROM dba_users;


-- 3.1.4.2 Trigger: nights and cost of a stay
START TRANSACTION;

SELECT lg_id, lg_name, lg_cost_per_night FROM lodging WHERE lg_id = 3;

-- 1-4 October, 3 rooms at Berlin Plaza - no nights or cost given
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-01', '2026-10-04', 3);

-- 3 nights, 120 x 3 x 3 = 1080.00
SELECT ru_checkin, ru_checkout, ru_rooms_count, ru_nights, ru_total_cost
FROM room_usage WHERE ru_trip_id = 11;

-- should fail: check-out must be at least one day after check-in
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-05', '2026-10-05', 1);

-- should fail: check-out must be at least one day after check-in
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-05', '2026-10-02', 1);

ROLLBACK;


-- 3.1.4.3 Trigger: completing a trip frees the vehicle
START TRANSACTION;

-- put bus 9 on trip 14 through the procedure of 3.1.3.1: InUse, 90 500 km
CALL sp_assign_vehicle_to_trip(14, 9, 90500);
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 9;

-- the trip is over, 350 km
UPDATE trip SET tr_status = 'COMPLETED', tr_km = 350 WHERE tr_id = 14;

-- Available, 90 850 km
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 9;

-- changing the km of a trip that is already COMPLETED adds nothing
UPDATE trip SET tr_km = 400 WHERE tr_id = 14;
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 9;

-- another status (ACTIVE) leaves the vehicle of trip 2 alone
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 2;
UPDATE trip SET tr_status = 'ACTIVE' WHERE tr_id = 2;
SELECT v_id, v_status, v_mileage FROM vehicle WHERE v_id = 2;

ROLLBACK;


-- ---------------------------------------------------------------------
-- Part B: what runs behind the GUI buttons
-- ---------------------------------------------------------------------


-- GUI Reservations: sp_calculate_reservation_cost (adult/child price)
START TRANSACTION;

SELECT tr_id, tr_cost_adult, tr_cost_child FROM trip WHERE tr_id = 1;
SELECT cust_id, cust_name, cust_birth_date,
       TIMESTAMPDIFF(YEAR, cust_birth_date, CURDATE()) AS age
FROM customer WHERE cust_id IN (1, 20);

-- an adult: 500.00
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 10, 1, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 10, 1);

-- a child: 300.00
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 11, 20, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 11, 20);

SELECT res_seatnum, res_cust_id, res_total_cost FROM reservation
WHERE res_tr_id = 1 AND res_seatnum IN (10, 11);

-- should fail: Duplicate entry
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status)
VALUES (1, 10, 2, 'PENDING');

ROLLBACK;


-- GUI Admin: sp_branch_financials
CALL sp_branch_financials(1, @revenue, @expenses, @ratio);
SELECT @revenue AS revenue, @expenses AS expenses, @ratio AS profit_ratio;

-- an unknown branch: three NULLs, not an error
CALL sp_branch_financials(999, @revenue, @expenses, @ratio);
SELECT @revenue AS revenue, @expenses AS expenses, @ratio AS profit_ratio;


-- GUI Staff: salary trigger (profit needed, max +2%)
START TRANSACTION;

-- with the seed data branch 1 pays more than it takes in
-- should fail: branch is not profitable
UPDATE worker SET wrk_salary = wrk_salary * 1.01 WHERE wrk_AT = 'AT101';

-- lowering is always allowed: branch 1 now earns more than it pays
UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1;
CALL sp_branch_financials(1, @revenue, @expenses, @ratio);
SELECT @revenue AS revenue, @expenses AS expenses, @ratio AS profit_ratio;

-- +1 %
UPDATE worker SET wrk_salary = 101 WHERE wrk_AT = 'AT101';

-- exactly +2 % is still allowed (100 -> 102)
UPDATE worker SET wrk_salary = 100 WHERE wrk_AT = 'AT101';
UPDATE worker SET wrk_salary = 102 WHERE wrk_AT = 'AT101';

-- should fail: exceeds 2% limit
UPDATE worker SET wrk_salary = 110 WHERE wrk_AT = 'AT101';

SELECT wrk_AT, wrk_salary FROM worker WHERE wrk_AT = 'AT101';

ROLLBACK;


-- check: same numbers as before the demo
SELECT (SELECT COUNT(*) FROM customer)    AS customers,
       (SELECT COUNT(*) FROM reservation) AS reservations,
       (SELECT COUNT(*) FROM room_usage)  AS room_usage_rows,
       (SELECT COUNT(*) FROM log_actions) AS log_rows,
       (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9) AS vehicle_9,
       (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101')                AS salary_AT101;
