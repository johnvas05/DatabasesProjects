-- =====================================================================
-- Tests.sql - the whole database test suite as one SQL script
-- =====================================================================
-- Checks the schema, the seed data, the business rules of section 2, every
-- stored procedure of 3.1.3, every trigger of 3.1.4 and the indexes of
-- 3.1.3.4, and prints a PASS/FAIL table at the end.
--
-- IT CHANGES NOTHING. Everything runs inside one transaction that is rolled
-- back before the report is printed, so it can be run during a presentation,
-- on the live database, as many times as you like. (The results survive the
-- rollback because they are kept in a MEMORY table, which is not
-- transactional - that is also why the client prints a warning about a
-- non-transactional table at the end. The warning is expected.)
--
-- Usage
--   docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/Tests.sql
--   or open it in any SQL client and run the whole file.
--
-- The procedures under test print their own result sets (the PASS/FAIL table
-- of sp_assign_vehicle_to_trip, the hotel list of sp_search_accommodation),
-- so those appear between the sections. The final table is the test report.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Test harness
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS test_results;
CREATE TEMPORARY TABLE test_results (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    section  VARCHAR(60),
    test     VARCHAR(200),
    status   VARCHAR(4),
    expected VARCHAR(255),
    actual   VARCHAR(255)
) ENGINE = MEMORY;   -- MEMORY, so the report survives the ROLLBACK

DELIMITER $$

DROP PROCEDURE IF EXISTS t_record$$
CREATE PROCEDURE t_record(IN p_section VARCHAR(60), IN p_test VARCHAR(200),
                          IN p_status VARCHAR(4), IN p_expected VARCHAR(255), IN p_actual VARCHAR(255))
BEGIN
    INSERT INTO test_results (section, test, status, expected, actual)
    VALUES (p_section, p_test, p_status, LEFT(p_expected, 255), LEFT(p_actual, 255));
END$$

-- the value must be exactly the expected one
DROP PROCEDURE IF EXISTS t_eq$$
CREATE PROCEDURE t_eq(IN p_section VARCHAR(60), IN p_test VARCHAR(200),
                      IN p_actual TEXT, IN p_expected TEXT)
BEGIN
    CALL t_record(p_section, p_test,
                  IF(p_actual <=> p_expected, 'PASS', 'FAIL'),
                  IFNULL(p_expected, 'NULL'), IFNULL(p_actual, 'NULL'));
END$$

-- the value must be at least the expected minimum (row counts of 3.1.1)
DROP PROCEDURE IF EXISTS t_min$$
CREATE PROCEDURE t_min(IN p_section VARCHAR(60), IN p_test VARCHAR(200),
                       IN p_actual BIGINT, IN p_min BIGINT)
BEGIN
    CALL t_record(p_section, p_test,
                  IF(p_actual >= p_min, 'PASS', 'FAIL'),
                  CONCAT('>= ', p_min), CAST(p_actual AS CHAR));
END$$

-- the value must contain the expected text
DROP PROCEDURE IF EXISTS t_has$$
CREATE PROCEDURE t_has(IN p_section VARCHAR(60), IN p_test VARCHAR(200),
                       IN p_actual TEXT, IN p_expected VARCHAR(255))
BEGIN
    CALL t_record(p_section, p_test,
                  IF(INSTR(IFNULL(p_actual, ''), p_expected) > 0, 'PASS', 'FAIL'),
                  CONCAT('contains "', p_expected, '"'), IFNULL(p_actual, 'NULL'));
END$$

-- the statement must be refused, with a message containing the expected text
DROP PROCEDURE IF EXISTS t_error$$
CREATE PROCEDURE t_error(IN p_section VARCHAR(60), IN p_test VARCHAR(200),
                         IN p_sql TEXT, IN p_expected VARCHAR(255))
BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;

    SET @t_sql = p_sql;
    PREPARE t_stmt FROM @t_sql;
    EXECUTE t_stmt;
    DEALLOCATE PREPARE t_stmt;

    IF v_msg = '' THEN
        CALL t_record(p_section, p_test, 'FAIL',
                      CONCAT('refused: "', p_expected, '"'), 'the statement was accepted');
    ELSE
        CALL t_record(p_section, p_test, IF(INSTR(v_msg, p_expected) > 0, 'PASS', 'FAIL'),
                      CONCAT('refused: "', p_expected, '"'), v_msg);
    END IF;
END$$

-- the statement must be accepted
DROP PROCEDURE IF EXISTS t_ok$$
CREATE PROCEDURE t_ok(IN p_section VARCHAR(60), IN p_test VARCHAR(200), IN p_sql TEXT)
BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;

    SET @t_sql = p_sql;
    PREPARE t_stmt FROM @t_sql;
    EXECUTE t_stmt;
    DEALLOCATE PREPARE t_stmt;

    CALL t_record(p_section, p_test, IF(v_msg = '', 'PASS', 'FAIL'), 'accepted',
                  IF(v_msg = '', 'accepted', v_msg));
END$$

DELIMITER ;

-- =====================================================================
-- Everything from here is undone by the ROLLBACK at the end
-- =====================================================================
START TRANSACTION;

-- ---------------------------------------------------------------------
-- 3.1.1  The tables of the preparatory phase hold enough rows
--        (2-person team = 2 x the per-person minimum)
-- ---------------------------------------------------------------------
CALL t_min('3.1.1 seed data', 'worker has at least 26 rows',        (SELECT COUNT(*) FROM worker), 26);
CALL t_min('3.1.1 seed data', 'guide has at least 8 rows',          (SELECT COUNT(*) FROM guide), 8);
CALL t_min('3.1.1 seed data', 'driver has at least 8 rows',         (SELECT COUNT(*) FROM driver), 8);
CALL t_min('3.1.1 seed data', 'languages has at least 8 rows',      (SELECT COUNT(*) FROM languages), 8);
CALL t_min('3.1.1 seed data', 'language_ref has at least 6 rows',   (SELECT COUNT(*) FROM language_ref), 6);
CALL t_min('3.1.1 seed data', 'manages has at least 6 rows',        (SELECT COUNT(*) FROM manages), 6);
CALL t_min('3.1.1 seed data', 'branch has at least 6 rows',         (SELECT COUNT(*) FROM branch), 6);
CALL t_min('3.1.1 seed data', 'trip has at least 14 rows',          (SELECT COUNT(*) FROM trip), 14);
CALL t_min('3.1.1 seed data', 'admin has at least 10 rows',         (SELECT COUNT(*) FROM admin), 10);
CALL t_min('3.1.1 seed data', 'phones has at least 10 rows',        (SELECT COUNT(*) FROM phones), 10);
CALL t_min('3.1.1 seed data', 'destination has at least 10 rows',   (SELECT COUNT(*) FROM destination), 10);
CALL t_min('3.1.1 seed data', 'travel_to has at least 14 rows',     (SELECT COUNT(*) FROM travel_to), 14);
CALL t_min('3.1.1 seed data', 'event has at least 20 rows',         (SELECT COUNT(*) FROM event), 20);
CALL t_min('3.1.1 seed data', 'reservation has at least 24 rows',   (SELECT COUNT(*) FROM reservation), 24);
CALL t_min('3.1.1 seed data', 'customer has at least 20 rows',      (SELECT COUNT(*) FROM customer), 20);

-- ---------------------------------------------------------------------
-- 3.1.2  The new tables and columns of this phase
-- ---------------------------------------------------------------------
CALL t_min('3.1.2 new tables', 'vehicle has at least 10 rows',      (SELECT COUNT(*) FROM vehicle), 10);
CALL t_min('3.1.2 new tables', 'lodging has at least 10 rows',      (SELECT COUNT(*) FROM lodging), 10);
CALL t_min('3.1.2 new tables', 'trip_history has 90 000 rows',      (SELECT COUNT(*) FROM trip_history), 90000);
CALL t_min('3.1.2 new tables', 'dba_users holds the DBA accounts',  (SELECT COUNT(*) FROM dba_users), 1);

CALL t_eq('3.1.2 new tables', 'travel_to.to_sequence exists',
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'travel_to' AND column_name = 'to_sequence'), '1');
CALL t_eq('3.1.2 new tables', 'to_sequence has the type of the relational model',
    (SELECT data_type FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'travel_to' AND column_name = 'to_sequence'), 'tinyint');
CALL t_eq('3.1.2 new tables', 'room_usage.ru_nights exists',
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'room_usage' AND column_name = 'ru_nights'), '1');
CALL t_eq('3.1.2 new tables', 'trip.tr_km exists',
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'trip' AND column_name = 'tr_km'), '1');
CALL t_eq('3.1.2 new tables', 'dba_users.dba_start_date is mandatory',
    (SELECT is_nullable FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'dba_users' AND column_name = 'dba_start_date'), 'NO');

CALL t_eq('3.1.2 new tables', 'the database has 26 triggers',
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = DATABASE()), '26');
-- the t_% procedures are this test harness, not part of the project
CALL t_eq('3.1.2 new tables', 'the database has 8 stored procedures',
    (SELECT COUNT(*) FROM information_schema.routines
     WHERE routine_schema = DATABASE() AND routine_name NOT LIKE 't\_%'), '8');

-- ---------------------------------------------------------------------
-- Section 2  The business rules of the description hold in the data
-- ---------------------------------------------------------------------
CALL t_eq('section 2 rules', 'every worker is in exactly one category',
    (SELECT COUNT(*) FROM worker w
     WHERE (SELECT COUNT(*) FROM driver WHERE drv_AT = w.wrk_AT)
         + (SELECT COUNT(*) FROM guide  WHERE gui_AT = w.wrk_AT)
         + (SELECT COUNT(*) FROM admin  WHERE adm_AT = w.wrk_AT) <> 1), '0');
CALL t_eq('section 2 rules', 'every branch has a phone and an admin manager',
    (SELECT COUNT(*) FROM branch b LEFT JOIN admin a ON a.adm_AT = b.br_manager_AT
     WHERE a.adm_AT IS NULL OR NOT EXISTS (SELECT 1 FROM phones p WHERE p.ph_br_code = b.br_code)), '0');
CALL t_eq('section 2 rules', 'every trip has at least one event',
    (SELECT COUNT(*) FROM trip t WHERE NOT EXISTS (SELECT 1 FROM event e WHERE e.ev_tr_id = t.tr_id)), '0');
CALL t_eq('section 2 rules', 'every trip has a number of minimum participants',
    (SELECT COUNT(*) FROM trip WHERE tr_min_participants IS NULL OR tr_min_participants < 1), '0');
CALL t_eq('section 2 rules', 'every guide speaks at least one language',
    (SELECT COUNT(*) FROM guide g WHERE NOT EXISTS (SELECT 1 FROM languages l WHERE l.lng_gui_AT = g.gui_AT)), '0');
CALL t_eq('section 2 rules', 'the route of a driver matches the trips they drive',
    (SELECT COUNT(*) FROM trip t
       JOIN driver d      ON d.drv_AT = t.tr_drv_AT
       JOIN travel_to x   ON x.to_tr_id = t.tr_id
       JOIN destination s ON s.dst_id = x.to_dst_id
     WHERE s.dst_rtype <> d.drv_route), '0');
CALL t_eq('section 2 rules', 'a driver of a vehicle with more than 9 seats holds C or D',
    (SELECT COUNT(*) FROM trip t
       JOIN vehicle v ON v.v_id = t.tr_vehicle_id
       JOIN driver d  ON d.drv_AT = t.tr_drv_AT
     WHERE v.v_seats > 9 AND d.drv_license NOT IN ('C', 'D')), '0');
CALL t_eq('section 2 rules', 'the number of seats matches the type of the vehicle',
    (SELECT COUNT(*) FROM vehicle
     WHERE NOT ((v_type = 'Bus'      AND v_seats > 20)
             OR (v_type = 'Mini-Bus' AND v_seats BETWEEN 10 AND 20)
             OR (v_type = 'Van'      AND v_seats BETWEEN 6 AND 9)
             OR (v_type = 'Car'      AND v_seats <= 5))), '0');
CALL t_eq('section 2 rules', 'only hotels and resorts carry stars',
    (SELECT COUNT(*) FROM lodging WHERE (lg_type IN ('Hotel', 'Resort')) <> (lg_stars IS NOT NULL)), '0');
CALL t_eq('section 2 rules', 'every lodging has a full address',
    (SELECT COUNT(*) FROM lodging WHERE lg_postal_code IS NULL OR lg_address = '' OR lg_city = ''), '0');
CALL t_eq('section 2 rules', 'a city can belong to a country: Paris -> France',
    (SELECT p.dst_name FROM destination c JOIN destination p ON p.dst_id = c.dst_location
     WHERE c.dst_name = 'Paris'), 'France');
CALL t_eq('section 2 rules', 'no stay is shorter than one night',
    (SELECT COUNT(*) FROM travel_to WHERE DATEDIFF(to_departure, to_arrival) < 1), '0');
CALL t_eq('section 2 rules', 'every stay lies inside the dates of its trip',
    (SELECT COUNT(*) FROM travel_to tt JOIN trip t ON t.tr_id = tt.to_tr_id
     WHERE DATE(tt.to_arrival) < DATE(t.tr_departure)
        OR DATE(tt.to_departure) > DATE(t.tr_return)), '0');
CALL t_eq('section 2 rules', 'every reservation has a price',
    (SELECT COUNT(*) FROM reservation WHERE res_total_cost IS NULL OR res_total_cost = 0), '0');
CALL t_eq('section 2 rules', 'every logged action belongs to a registered DBA',
    (SELECT COUNT(*) FROM log_actions l LEFT JOIN dba_users d ON d.dba_username = l.log_dba_username
     WHERE d.dba_username IS NULL), '0');

-- ---------------------------------------------------------------------
-- The database refuses data that breaks the rules
-- ---------------------------------------------------------------------
CALL t_error('constraints', 'a Car with 30 seats is refused',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'TST-0001', 'M', 'B', 'Car', 30)", 'chk_vehicle_type_seats');
CALL t_error('constraints', 'a Bus with 8 seats is refused',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'TST-0002', 'M', 'B', 'Bus', 8)", 'chk_vehicle_type_seats');
CALL t_error('constraints', 'a hostel with stars is refused',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     VALUES (2, 'Bad Hostel', 'Hostel', 3, 'a', 'London', 5, 10)", 'chk_lodging_stars_type');
CALL t_error('constraints', 'a lodging in a country instead of a city is refused',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     SELECT dst_id, 'Bad', 'Hotel', 'a', 'b', 5, 10 FROM destination WHERE dst_name = 'France'",
    'must belong to a city destination');
CALL t_error('constraints', 'a vehicle of an unknown branch is refused',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (999, 'TST-0003', 'M', 'B', 'Car', 4)", 'foreign key constraint fails');
CALL t_error('constraints', 'the same seat cannot be booked twice on a trip',
    "INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status)
     VALUES (1, 1, 5, 'PENDING')", 'Duplicate entry');

-- ---------------------------------------------------------------------
-- 3.1.4.2  The trigger that computes the nights and the cost of a stay
-- ---------------------------------------------------------------------
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-01', '2026-10-04', 3);
CALL t_eq('3.1.4.2 stay cost', '3 nights are computed from the dates',
    (SELECT ru_nights FROM room_usage WHERE ru_trip_id = 11), '3');
CALL t_eq('3.1.4.2 stay cost', 'the cost is 120 per night x 3 nights x 3 rooms',
    (SELECT ru_total_cost FROM room_usage WHERE ru_trip_id = 11), '1080.00');
CALL t_error('3.1.4.2 stay cost', 'a stay that ends on the day it starts is refused',
    "INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
     VALUES (11, 3, '2026-10-05', '2026-10-05', 1)", 'check-out must be at least one day after check-in');
DELETE FROM room_usage WHERE ru_trip_id = 11;

-- ---------------------------------------------------------------------
-- Reservation price: the adult or the child price, by the customer's age
-- ---------------------------------------------------------------------
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 41, 1, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 41, 1);
CALL t_eq('reservation price', 'an adult pays the adult price of trip 1 (500)',
    (SELECT res_total_cost FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 41), '500.00');

INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 42, 20, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 42, 20);
CALL t_eq('reservation price', 'a child pays the child price of trip 1 (300)',
    (SELECT res_total_cost FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 42), '300.00');
DELETE FROM reservation WHERE res_tr_id = 1 AND res_seatnum IN (41, 42);

-- ---------------------------------------------------------------------
-- 3.1.3.2  Searching for accommodation
-- ---------------------------------------------------------------------
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 2, @lodging_id);
CALL t_eq('3.1.3.2 search', 'the hotel of Paris is found and returned',
    (SELECT lg_name FROM lodging WHERE lg_id = @lodging_id), 'Le Grand Paris');

-- 95 of the 100 rooms are taken for a period that overlaps
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 1, '2026-06-03', '2026-06-07', 95);
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 6, @lodging_id);
CALL t_eq('3.1.3.2 search', 'a hotel without enough free rooms is not offered',
    IFNULL(CAST(@lodging_id AS CHAR), 'NULL'), 'NULL');
CALL sp_search_accommodation(1, '2026-06-07', '2026-06-09', 6, @lodging_id);
CALL t_eq('3.1.3.2 search', 'a period that does not overlap is unaffected',
    CAST(@lodging_id AS CHAR), '1');
DELETE FROM room_usage WHERE ru_trip_id = 11;

UPDATE lodging SET lg_status = 'Inactive' WHERE lg_id = 1;
CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @lodging_id);
CALL t_eq('3.1.3.2 search', 'a lodging that is not active is not offered',
    IFNULL(CAST(@lodging_id AS CHAR), 'NULL'), 'NULL');
UPDATE lodging SET lg_status = 'Active' WHERE lg_id = 1;

-- ---------------------------------------------------------------------
-- 3.1.3.3  Booking the accommodation of a whole trip
-- ---------------------------------------------------------------------
CALL sp_book_trip_accommodation(1);
CALL t_eq('3.1.3.3 auto-booking', 'one lodging is booked per destination of trip 1',
    (SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1), '2');
CALL t_eq('3.1.3.3 auto-booking', 'the Paris leg costs 4 nights x 250',
    (SELECT ru_total_cost FROM room_usage ru JOIN lodging l ON l.lg_id = ru.ru_lodging_id
     WHERE ru.ru_trip_id = 1 AND l.lg_name = 'Le Grand Paris'), '1000.00');
CALL t_eq('3.1.3.3 auto-booking', 'the London leg costs 5 nights x 60',
    (SELECT ru_total_cost FROM room_usage ru JOIN lodging l ON l.lg_id = ru.ru_lodging_id
     WHERE ru.ru_trip_id = 1 AND l.lg_name = 'London Stay'), '300.00');
CALL t_eq('3.1.3.3 auto-booking', 'the whole trip costs 1300 in accommodation',
    (SELECT SUM(ru_total_cost) FROM room_usage WHERE ru_trip_id = 1), '1300.00');

CALL sp_book_trip_accommodation(1);
CALL t_eq('3.1.3.3 auto-booking', 'booking again replaces the bookings, it does not add to them',
    (SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1), '2');

CALL sp_book_trip_accommodation(3);
CALL t_eq('3.1.3.3 auto-booking', 'one room per two passengers: 3 passengers need 2 rooms',
    (SELECT DISTINCT ru_rooms_count FROM room_usage WHERE ru_trip_id = 3), '2');

CALL t_error('3.1.3.3 auto-booking', 'an unknown trip is refused',
    'CALL sp_book_trip_accommodation(9999)', 'trip does not exist');

UPDATE reservation SET res_status = 'PENDING' WHERE res_tr_id = 12;
CALL t_error('3.1.3.3 auto-booking', 'a trip without confirmed reservations is refused',
    'CALL sp_book_trip_accommodation(12)', 'no confirmed or paid reservations');
UPDATE reservation SET res_status = 'CONFIRMED' WHERE res_tr_id = 12;

-- a destination that cannot be booked cancels the whole booking, not half of it
UPDATE lodging SET lg_total_rooms = 0 WHERE lg_id = 2;
CALL t_error('3.1.3.3 auto-booking', 'a destination without a free room is named in the error',
    'CALL sp_book_trip_accommodation(1)', 'no lodging in London with 1 free room(s)');
CALL t_eq('3.1.3.3 auto-booking', 'and every booking of that trip is rolled back',
    (SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1), '0');
UPDATE lodging SET lg_total_rooms = 30 WHERE lg_id = 2;
DELETE FROM room_usage;

-- ---------------------------------------------------------------------
-- 3.1.3.1  Assigning a vehicle to a trip: five checks
-- ---------------------------------------------------------------------
CALL t_error('3.1.3.1 vehicle', 'a vehicle in maintenance is refused',
    'CALL sp_assign_vehicle_to_trip(1, 4, 200100)', 'vehicle is Maintenance');
CALL t_error('3.1.3.1 vehicle', 'an unknown trip is refused',
    'CALL sp_assign_vehicle_to_trip(9999, 1, 1)', 'trip does not exist');
CALL t_error('3.1.3.1 vehicle', 'an unknown vehicle is refused',
    'CALL sp_assign_vehicle_to_trip(1, 9999, 1)', 'vehicle does not exist');
CALL t_error('3.1.3.1 vehicle', 'a driver with licence B is refused on a bus',
    'CALL sp_assign_vehicle_to_trip(8, 1, 150100)', 'driver licence B (C/D needed)');
CALL t_error('3.1.3.1 vehicle', 'a vehicle already used on overlapping dates is refused',
    'CALL sp_assign_vehicle_to_trip(2, 1, 150100)', 'overlaps 1 other trip');
CALL t_error('3.1.3.1 vehicle', 'a mileage below the recorded one is refused',
    'CALL sp_assign_vehicle_to_trip(14, 9, 1000)', 'mileage 1000 < recorded 90000');
CALL t_error('3.1.3.1 vehicle', 'when two checks fail, both reasons are reported',
    'CALL sp_assign_vehicle_to_trip(1, 4, 1)', 'vehicle is Maintenance; mileage 1 < recorded 200000');

UPDATE vehicle SET v_seats = 2 WHERE v_id = 10;
CALL t_error('3.1.3.1 vehicle', 'a vehicle with fewer seats than reservations is refused',
    'CALL sp_assign_vehicle_to_trip(3, 10, 10100)', '2 seats < 3 reservations');
UPDATE vehicle SET v_seats = 5 WHERE v_id = 10;

CALL t_eq('3.1.3.1 vehicle', 'a refused assignment changes nothing',
    (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 4), 'Maintenance/200000');

-- the assignment that passes every check
CALL t_ok('3.1.3.1 vehicle', 'a valid assignment is accepted',
    'CALL sp_assign_vehicle_to_trip(14, 9, 90500)');
CALL t_eq('3.1.3.1 vehicle', 'the vehicle is taken and its mileage updated',
    (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9), 'InUse/90500');
CALL t_eq('3.1.3.1 vehicle', 'the trip points at the vehicle',
    (SELECT tr_vehicle_id FROM trip WHERE tr_id = 14), '9');
CALL t_has('3.1.3.1 vehicle', 'the change of the vehicle is written to the log',
    (SELECT log_details FROM log_actions WHERE log_table_name = 'vehicle' ORDER BY log_id DESC LIMIT 1),
    'status Available -> InUse, mileage 90000 -> 90500');

-- ---------------------------------------------------------------------
-- 3.1.4.3  Completing a trip frees the vehicle and adds its kilometres
-- ---------------------------------------------------------------------
UPDATE trip SET tr_status = 'COMPLETED', tr_km = 350 WHERE tr_id = 14;
CALL t_eq('3.1.4.3 trip done', 'the vehicle is free again and the kilometres are added',
    (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9), 'Available/90850');
CALL t_has('3.1.4.3 trip done', 'the completion is written to the log with the kilometres',
    (SELECT log_details FROM log_actions WHERE log_table_name = 'trip' ORDER BY log_id DESC LIMIT 1),
    'km 0 -> 350');

UPDATE vehicle SET v_status = 'InUse' WHERE v_id = 2;
UPDATE trip SET tr_status = 'ACTIVE' WHERE tr_id = 2;
CALL t_eq('3.1.4.3 trip done', 'another status leaves the vehicle alone',
    (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 2), 'InUse/80000');

-- ---------------------------------------------------------------------
-- 3.1.4.1  Every change on the seven tables is logged
-- ---------------------------------------------------------------------
SET @log_before = (SELECT COUNT(*) FROM log_actions);

INSERT INTO customer (cust_name, cust_lname, cust_birth_date) VALUES ('Log', 'Test', '1990-01-01');
UPDATE customer SET cust_phone = '123' WHERE cust_lname = 'Test';
DELETE FROM customer WHERE cust_lname = 'Test';

INSERT INTO destination (dst_name, dst_rtype, dst_language_code) VALUES ('Logville', 'LOCAL', 'EN');
UPDATE destination SET dst_descr = 'x' WHERE dst_name = 'Logville';
DELETE FROM destination WHERE dst_name = 'Logville';

INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
VALUES (1, 'LOG-0001', 'M', 'B', 'Car', 4);
UPDATE vehicle SET v_status = 'Maintenance' WHERE v_license_plate = 'LOG-0001';
DELETE FROM vehicle WHERE v_license_plate = 'LOG-0001';

INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
VALUES (1, 'Log Lodge', 'Hotel', 'a', 'Paris', 5, 10);
UPDATE lodging SET lg_cost_per_night = 11 WHERE lg_name = 'Log Lodge';
DELETE FROM lodging WHERE lg_name = 'Log Lodge';

INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 1, '2026-10-02', '2026-10-04', 1);
UPDATE room_usage SET ru_rooms_count = 2 WHERE ru_trip_id = 11;
DELETE FROM room_usage WHERE ru_trip_id = 11;

INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status) VALUES (5, 9, 1, 'PENDING');
UPDATE reservation SET res_status = 'CONFIRMED' WHERE res_tr_id = 5 AND res_seatnum = 9;
DELETE FROM reservation WHERE res_tr_id = 5 AND res_seatnum = 9;

INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_br_code)
VALUES ('2027-03-01', '2027-03-05', 10, 100, 50, 'PLANNED', 1);
UPDATE trip SET tr_status = 'CANCELLED' WHERE tr_departure = '2027-03-01';
DELETE FROM trip WHERE tr_departure = '2027-03-01';

CALL t_eq('3.1.4.1 audit log', '7 tables x 3 actions produce 21 log rows',
    (SELECT COUNT(*) - @log_before FROM log_actions), '21');
-- log_action_type is an ENUM, so it sorts in the order it was declared
CALL t_eq('3.1.4.1 audit log', 'insert, update and delete are logged on customer',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'customer' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');
CALL t_eq('3.1.4.1 audit log', 'insert, update and delete are logged on trip',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'trip' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');
CALL t_eq('3.1.4.1 audit log', 'all seven tables are covered',
    (SELECT COUNT(DISTINCT log_table_name) FROM log_actions WHERE log_id > @log_before), '7');
CALL t_eq('3.1.4.1 audit log', 'the account that made the change is recorded',
    (SELECT COUNT(DISTINCT log_dba_username) FROM log_actions WHERE log_id > @log_before), '1');
CALL t_eq('3.1.4.1 audit log', 'every log row has a timestamp',
    (SELECT COUNT(*) FROM log_actions WHERE log_timestamp IS NULL), '0');

-- ---------------------------------------------------------------------
-- Salary trigger: a raise needs a profitable branch and stays under 2 %
-- ---------------------------------------------------------------------
UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1;   -- lowering is always allowed
CALL t_eq('salary trigger', 'lowering a salary is always allowed',
    (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'), '100.00');

CALL sp_branch_financials(1, @revenue, @expenses, @ratio);
CALL t_eq('salary trigger', 'branch 1 is profitable now, so a raise may be considered',
    IF(@ratio > 0, 'profitable', CONCAT('ratio ', @ratio)), 'profitable');

CALL t_ok('salary trigger', 'a raise of 1 % in a profitable branch is accepted',
    "UPDATE worker SET wrk_salary = 101 WHERE wrk_AT = 'AT101'");
CALL t_error('salary trigger', 'a raise above 2 % is refused',
    "UPDATE worker SET wrk_salary = 110 WHERE wrk_AT = 'AT101'", 'exceeds 2% limit');
CALL t_eq('salary trigger', 'the refused raise did not change the salary',
    (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'), '101.00');

UPDATE reservation SET res_total_cost = 0;   -- the branch stops making money
CALL t_error('salary trigger', 'a raise in a branch that makes no profit is refused',
    "UPDATE worker SET wrk_salary = 102 WHERE wrk_AT = 'AT101'", 'branch is not profitable');

-- ---------------------------------------------------------------------
-- Branch financials
-- ---------------------------------------------------------------------
CALL sp_branch_financials(999, @revenue, @expenses, @ratio);
CALL t_eq('branch financials', 'an unknown branch gives no numbers instead of failing',
    CONCAT(IFNULL(CAST(@revenue AS CHAR), 'NULL'), '/', IFNULL(CAST(@ratio AS CHAR), 'NULL')), 'NULL/NULL');

-- ---------------------------------------------------------------------
-- 3.1.3.4  The 90 000-row history and its covering indexes
-- ---------------------------------------------------------------------
CALL t_eq('3.1.3.4 history', 'the index for the revenue report exists',
    (SELECT COUNT(DISTINCT index_name) FROM information_schema.statistics
     WHERE table_schema = DATABASE() AND table_name = 'trip_history'
       AND index_name = 'idx_hist_dep_rev'), '1');
CALL t_eq('3.1.3.4 history', 'it covers departure and revenue, in that order',
    (SELECT GROUP_CONCAT(column_name ORDER BY seq_in_index) FROM information_schema.statistics
     WHERE table_schema = DATABASE() AND table_name = 'trip_history'
       AND index_name = 'idx_hist_dep_rev'), 'th_departure,th_revenue');
CALL t_eq('3.1.3.4 history', 'the index for the destination report exists',
    (SELECT GROUP_CONCAT(column_name ORDER BY seq_in_index) FROM information_schema.statistics
     WHERE table_schema = DATABASE() AND table_name = 'trip_history'
       AND index_name = 'idx_hist_dc_dep'), 'th_dest_count,th_departure');
CALL t_min('3.1.3.4 history', 'the revenue of 2021 is reported',
    (SELECT SUM(th_revenue) FROM trip_history
     WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31'), 1);
CALL t_min('3.1.3.4 history', 'trips with 3 destinations are found',
    (SELECT COUNT(*) FROM trip_history WHERE th_dest_count = 3), 1000);

-- =====================================================================
-- Undo everything the tests did
-- =====================================================================
ROLLBACK;

-- ---------------------------------------------------------------------
-- The report
-- ---------------------------------------------------------------------
SELECT id, section, test, status FROM test_results ORDER BY id;

SELECT status, expected, actual, section, test
FROM test_results WHERE status = 'FAIL' ORDER BY id;

SELECT COUNT(*)                AS total,
       SUM(status = 'PASS')    AS passed,
       SUM(status = 'FAIL')    AS failed,
       IF(SUM(status = 'FAIL') = 0, 'ALL TESTS PASSED', 'THERE ARE FAILURES') AS result
FROM test_results;

-- proof that the database was left exactly as it was
SELECT 'the tests changed nothing' AS note,
       (SELECT COUNT(*) FROM customer)     AS customers,
       (SELECT COUNT(*) FROM reservation)  AS reservations,
       (SELECT COUNT(*) FROM room_usage)   AS room_usage_rows,
       (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9) AS vehicle_9,
       (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101')                AS salary_AT101;

-- ---------------------------------------------------------------------
-- Clean up the harness
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS t_record;
DROP PROCEDURE IF EXISTS t_eq;
DROP PROCEDURE IF EXISTS t_min;
DROP PROCEDURE IF EXISTS t_has;
DROP PROCEDURE IF EXISTS t_error;
DROP PROCEDURE IF EXISTS t_ok;
DROP TEMPORARY TABLE IF EXISTS test_results;
