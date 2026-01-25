USE baseisproject;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Wipe Old Tables
TRUNCATE TABLE reservation;
TRUNCATE TABLE travel_to;
TRUNCATE TABLE event;
TRUNCATE TABLE trip;
TRUNCATE TABLE languages;
TRUNCATE TABLE phones;
TRUNCATE TABLE manages;
TRUNCATE TABLE admin;
TRUNCATE TABLE driver;
TRUNCATE TABLE guide;
TRUNCATE TABLE worker;
TRUNCATE TABLE branch;
TRUNCATE TABLE destination;
TRUNCATE TABLE customer;

-- 2. Wipe New Tables
TRUNCATE TABLE room_usage;
TRUNCATE TABLE trip_history;
TRUNCATE TABLE vehicle;
TRUNCATE TABLE lodging;
TRUNCATE TABLE log_actions;
TRUNCATE TABLE dba_users;

SET FOREIGN_KEY_CHECKS = 1;

-- A. Setup Basic Data
INSERT INTO branch (br_code, br_street, br_num, br_city) VALUES (1, 'Main St', 10, 'Athens');
INSERT INTO destination (dst_name, dst_rtype, dst_language_code, dst_location) VALUES ('Paris', 'ABROAD', 'EN', NULL);

-- B. Setup Worker & Driver (License D for Bus)
INSERT INTO worker (wrk_AT, wrk_name, wrk_lname, wrk_salary, wrk_br_code) VALUES ('AT100', 'John', 'Doe', 1000, 1);
INSERT INTO driver (drv_AT, drv_license, drv_route, drv_experience) VALUES ('AT100', 'D', 'ABROAD', 5);

-- C. Setup New Resources (Vehicle & Hotel)
INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats, v_status, v_mileage)
VALUES (1, 'ABC-1234', 'Sprinter', 'Mercedes', 'Bus', 50, 'Available', 10000);

INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_rating, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
VALUES (1, 'Hotel Paris', 'Hotel', 4, 4.5, 'Champs Elysees', 'Paris', 20, 100.00);

-- D. Create a Trip & Reservation
-- Register the current system user as a DBA
INSERT INTO dba_users (dba_username, dba_start_date)
VALUES (USER(), CURDATE());
INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_br_code, tr_drv_AT)
VALUES ('2026-06-01', '2026-06-10', 50, 500, 300, 'PLANNED', 1, 'AT100');

INSERT INTO travel_to (to_tr_id, to_dst_id, to_arrival, to_departure)
VALUES (1, 1, '2026-06-01', '2026-06-05');

INSERT INTO customer (cust_name, cust_lname) VALUES ('George', 'Papadopoulos');
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status) VALUES (1, 1, 1, 'CONFIRMED');

SELECT tr_id, tr_departure FROM trip;

-- Link destination to Trip #2 (Replace 2 if your ID is different)
INSERT INTO travel_to (to_tr_id, to_dst_id, to_arrival, to_departure)
VALUES (2, 1, '2026-06-01', '2026-06-05');

-- Add Customer
INSERT INTO customer (cust_name, cust_lname) VALUES ('George', 'Papadopoulos');

-- Create Reservation for Trip #2
-- Note: cust_id is likely 1, but if you had failures there too, check 'SELECT * FROM customer'
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status)
VALUES (2, 1, 1, 'CONFIRMED');

-- Assign vehicle 1 to trip 2
CALL sp_assign_vehicle_to_trip(2, 1, 10050);

CALL sp_book_trip_accommodation(2);