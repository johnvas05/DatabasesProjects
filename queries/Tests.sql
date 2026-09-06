-- #####################################################################
--
--  Tests.sql - the database test suite of the travel agency project
--
-- #####################################################################
--
--  WHAT THIS FILE IS
--  Every requirement of Part A is checked here in plain SQL and the result
--  is printed as a PASS/FAIL table. For every stored procedure and every
--  trigger, *all* of its possible outcomes are exercised: the ones that
--  succeed and the ones that are refused. A rule that is never seen to
--  refuse anything has not really been shown to work.
--
--  IT CHANGES NOTHING
--  The whole suite runs inside one transaction that is rolled back before
--  the report is printed, so it is safe to run on the live database, in
--  front of an examiner, as many times as you like. The last result set
--  shows the data is untouched.
--  (The report survives the ROLLBACK because it is kept in a MEMORY table,
--  which is not transactional. That is also why the client prints a warning
--  about a non-transactional table at the end - the warning is expected.)
--
--  HOW TO RUN IT
--    docker exec -i baseis-mariadb mariadb -uroot -pjohn2005 -t baseisproject < queries/Tests.sql
--  or open the file in any SQL client and execute all of it.
--
--  Run it on a database in the demo state (tests/reset_db.sh); a few checks
--  quote the seeded numbers, e.g. the 500 EUR adult price of trip 1.
--
--  WHAT IS COVERED, AND WHERE IT IS IN THE PROJECT
--  ---------------------------------------------------------------------
--   Section  Part of the project                            Object tested
--   -------  --------------------------------------------  -------------
--    1       3.1.1  tables and rows of the first phase      seed data
--    2       3.1.2  new tables, columns and accounts        schema
--    3       section 2 - the business rules of the report   the data
--    4       section 2 - CHECK constraints                  chk_* constraints
--    5       3.1.2.2 lodging belongs to a city              trg_lodging_city_only_ins/_upd
--    6       3.1.4.2 nights and cost of a stay              trg_calculate_accommodation_cost
--    7       reservation pricing (used by the GUI)          sp_calculate_reservation_cost
--    8       3.1.3.2 searching for accommodation            sp_search_accommodation
--    9       3.1.3.3 booking a whole trip                   sp_book_trip_accommodation
--   10       3.1.3.1 assigning a vehicle to a trip          sp_assign_vehicle_to_trip
--   11       3.1.4.3 completing a trip frees the vehicle    trg_complete_trip_vehicle_update
--   12       3.1.4.1 the audit log                          the 21 trg_log_* triggers
--   13       branch financials (used by the GUI)            sp_branch_financials
--   14       the salary guard                               trg_worker_salary_increase
--   15       3.1.3.4 the history and its indexes            sp_history_* and idx_hist_*
--  ---------------------------------------------------------------------
--
--  The procedures under test print their own result sets (the PASS/FAIL
--  table of sp_assign_vehicle_to_trip, the hotel list of
--  sp_search_accommodation, the booking list of sp_book_trip_accommodation),
--  so those appear between the sections. The report is the LAST table.
--
-- #####################################################################


-- #####################################################################
--  THE TEST HARNESS
--  Six helper procedures record one line per check instead of stopping at
--  the first failure, so one run reports everything at once.
--  They are dropped again at the end of the file.
-- #####################################################################

DROP TEMPORARY TABLE IF EXISTS test_results;
CREATE TEMPORARY TABLE test_results (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    section  VARCHAR(60),
    test     VARCHAR(200),
    status   VARCHAR(4),
    expected VARCHAR(255),
    actual   VARCHAR(255)
) ENGINE = MEMORY;   -- MEMORY is not transactional: the report survives the ROLLBACK

DELIMITER $$

-- write one line of the report
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

-- the value must be at least the expected minimum (the row counts of 3.1.1)
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

-- THE REFUSED PATH: the statement must fail, with a message we expect.
-- The handler catches the SIGNAL raised by a trigger or a procedure, so the
-- suite can carry on and report it as a passing test.
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
                      CONCAT('refused: "', p_expected, '"'), 'the statement was ACCEPTED');
    ELSE
        CALL t_record(p_section, p_test, IF(INSTR(v_msg, p_expected) > 0, 'PASS', 'FAIL'),
                      CONCAT('refused: "', p_expected, '"'), v_msg);
    END IF;
END$$

-- THE ACCEPTED PATH: the statement must go through without an error
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


-- #####################################################################
--  Everything from here is undone by the ROLLBACK at the end of the file
-- #####################################################################
START TRANSACTION;


-- =====================================================================
--  SECTION 1 - 3.1.1  The tables of the preparatory phase
-- ---------------------------------------------------------------------
--  The description asks for a minimum number of rows per table for each
--  member of the team. This is a two-person project, so every minimum is
--  doubled. These are the tables that already existed in the first phase.
-- =====================================================================
CALL t_min('1. 3.1.1 seed data', 'worker has at least 26 rows',      (SELECT COUNT(*) FROM worker), 26);
CALL t_min('1. 3.1.1 seed data', 'guide has at least 8 rows',        (SELECT COUNT(*) FROM guide), 8);
CALL t_min('1. 3.1.1 seed data', 'driver has at least 8 rows',       (SELECT COUNT(*) FROM driver), 8);
CALL t_min('1. 3.1.1 seed data', 'languages has at least 8 rows',    (SELECT COUNT(*) FROM languages), 8);
CALL t_min('1. 3.1.1 seed data', 'language_ref has at least 6 rows', (SELECT COUNT(*) FROM language_ref), 6);
CALL t_min('1. 3.1.1 seed data', 'manages has at least 6 rows',      (SELECT COUNT(*) FROM manages), 6);
CALL t_min('1. 3.1.1 seed data', 'branch has at least 6 rows',       (SELECT COUNT(*) FROM branch), 6);
CALL t_min('1. 3.1.1 seed data', 'trip has at least 14 rows',        (SELECT COUNT(*) FROM trip), 14);
CALL t_min('1. 3.1.1 seed data', 'admin has at least 10 rows',       (SELECT COUNT(*) FROM admin), 10);
CALL t_min('1. 3.1.1 seed data', 'phones has at least 10 rows',      (SELECT COUNT(*) FROM phones), 10);
CALL t_min('1. 3.1.1 seed data', 'destination has at least 10 rows', (SELECT COUNT(*) FROM destination), 10);
CALL t_min('1. 3.1.1 seed data', 'travel_to has at least 14 rows',   (SELECT COUNT(*) FROM travel_to), 14);
CALL t_min('1. 3.1.1 seed data', 'event has at least 20 rows',       (SELECT COUNT(*) FROM event), 20);
CALL t_min('1. 3.1.1 seed data', 'reservation has at least 24 rows', (SELECT COUNT(*) FROM reservation), 24);
CALL t_min('1. 3.1.1 seed data', 'customer has at least 20 rows',    (SELECT COUNT(*) FROM customer), 20);


-- =====================================================================
--  SECTION 2 - 3.1.2  The tables and columns added in this phase
-- ---------------------------------------------------------------------
--  3.1.2.1  vehicle          (queries/cars.sql)
--  3.1.2.2  lodging, room_usage, and stays with real dates
--                            (queries/Accommodation.sql)
--  3.1.2.3  trip_history, 90 000 generated trips
--                            (queries/history.sql)
--  3.1.2.4  dba_users and log_actions, the accounts and the audit log
--                            (queries/AdminLog.sql)
-- =====================================================================
CALL t_min('2. 3.1.2 new tables', '3.1.2.1 vehicle holds at least 10 vehicles',   (SELECT COUNT(*) FROM vehicle), 10);
CALL t_min('2. 3.1.2 new tables', '3.1.2.2 lodging holds at least 10 lodgings',   (SELECT COUNT(*) FROM lodging), 10);
CALL t_min('2. 3.1.2 new tables', '3.1.2.3 trip_history holds 90 000 trips',      (SELECT COUNT(*) FROM trip_history), 90000);
CALL t_min('2. 3.1.2 new tables', '3.1.2.4 dba_users holds the DBA accounts',     (SELECT COUNT(*) FROM dba_users), 1);

-- the columns this phase added to existing tables
CALL t_eq('2. 3.1.2 new tables', 'travel_to.to_sequence (visit order) exists',
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'travel_to' AND column_name = 'to_sequence'), '1');
CALL t_eq('2. 3.1.2 new tables', 'to_sequence has the type of the relational model (tinyint)',
    (SELECT data_type FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'travel_to' AND column_name = 'to_sequence'), 'tinyint');
CALL t_eq('2. 3.1.2 new tables', 'room_usage.ru_nights (filled by the trigger) exists',
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'room_usage' AND column_name = 'ru_nights'), '1');
CALL t_eq('2. 3.1.2 new tables', 'trip.tr_km (kilometres of the trip) exists',
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'trip' AND column_name = 'tr_km'), '1');
CALL t_eq('2. 3.1.2 new tables', 'trip.tr_vehicle_id (the assigned vehicle) exists',
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'trip' AND column_name = 'tr_vehicle_id'), '1');
CALL t_eq('2. 3.1.2 new tables', 'a DBA account must have a start date',
    (SELECT is_nullable FROM information_schema.columns
     WHERE table_schema = DATABASE() AND table_name = 'dba_users' AND column_name = 'dba_start_date'), 'NO');

-- the objects of 3.1.3 and 3.1.4 are all installed
-- (21 log triggers + 2 lodging-city + 1 stay cost + 1 trip completion + 1 salary = 26)
CALL t_eq('2. 3.1.2 new tables', 'all 26 triggers are installed',
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = DATABASE()), '26');
-- the t_% procedures are this test harness, not part of the project
CALL t_eq('2. 3.1.2 new tables', 'all 8 stored procedures are installed',
    (SELECT COUNT(*) FROM information_schema.routines
     WHERE routine_schema = DATABASE() AND routine_name NOT LIKE 't\_%'), '8');


-- =====================================================================
--  SECTION 3 - The business rules of section 2 of the description
-- ---------------------------------------------------------------------
--  These are the rules of the entity/relationship model. Here they are
--  checked against the data itself: the query counts the rows that break
--  the rule, so the expected answer is always 0.
-- =====================================================================
CALL t_eq('3. section 2 rules', 'a worker is a driver, a guide or an admin - exactly one',
    (SELECT COUNT(*) FROM worker w
     WHERE (SELECT COUNT(*) FROM driver WHERE drv_AT = w.wrk_AT)
         + (SELECT COUNT(*) FROM guide  WHERE gui_AT = w.wrk_AT)
         + (SELECT COUNT(*) FROM admin  WHERE adm_AT = w.wrk_AT) <> 1), '0');
CALL t_eq('3. section 2 rules', 'every branch has a phone and is managed by an admin',
    (SELECT COUNT(*) FROM branch b LEFT JOIN admin a ON a.adm_AT = b.br_manager_AT
     WHERE a.adm_AT IS NULL OR NOT EXISTS (SELECT 1 FROM phones p WHERE p.ph_br_code = b.br_code)), '0');
CALL t_eq('3. section 2 rules', 'every trip has at least one event',
    (SELECT COUNT(*) FROM trip t WHERE NOT EXISTS (SELECT 1 FROM event e WHERE e.ev_tr_id = t.tr_id)), '0');
CALL t_eq('3. section 2 rules', 'every trip states its minimum number of participants',
    (SELECT COUNT(*) FROM trip WHERE tr_min_participants IS NULL OR tr_min_participants < 1), '0');
CALL t_eq('3. section 2 rules', 'every guide speaks at least one language',
    (SELECT COUNT(*) FROM guide g WHERE NOT EXISTS (SELECT 1 FROM languages l WHERE l.lng_gui_AT = g.gui_AT)), '0');
CALL t_eq('3. section 2 rules', 'a driver only drives trips of their route (local/abroad)',
    (SELECT COUNT(*) FROM trip t
       JOIN driver d      ON d.drv_AT = t.tr_drv_AT
       JOIN travel_to x   ON x.to_tr_id = t.tr_id
       JOIN destination s ON s.dst_id = x.to_dst_id
     WHERE s.dst_rtype <> d.drv_route), '0');
CALL t_eq('3. section 2 rules', 'a driver of a vehicle with more than 9 seats holds licence C or D',
    (SELECT COUNT(*) FROM trip t
       JOIN vehicle v ON v.v_id = t.tr_vehicle_id
       JOIN driver d  ON d.drv_AT = t.tr_drv_AT
     WHERE v.v_seats > 9 AND d.drv_license NOT IN ('C', 'D')), '0');
CALL t_eq('3. section 2 rules', 'the number of seats matches the type of the vehicle',
    (SELECT COUNT(*) FROM vehicle
     WHERE NOT ((v_type = 'Bus'      AND v_seats > 20)
             OR (v_type = 'Mini-Bus' AND v_seats BETWEEN 10 AND 20)
             OR (v_type = 'Van'      AND v_seats BETWEEN 6 AND 9)
             OR (v_type = 'Car'      AND v_seats <= 5))), '0');
CALL t_eq('3. section 2 rules', 'only hotels and resorts carry stars',
    (SELECT COUNT(*) FROM lodging WHERE (lg_type IN ('Hotel', 'Resort')) <> (lg_stars IS NOT NULL)), '0');
CALL t_eq('3. section 2 rules', 'every lodging has a full address with a postal code',
    (SELECT COUNT(*) FROM lodging WHERE lg_postal_code IS NULL OR lg_address = '' OR lg_city = ''), '0');
CALL t_eq('3. section 2 rules', 'a city can belong to a country: Paris -> France',
    (SELECT p.dst_name FROM destination c JOIN destination p ON p.dst_id = c.dst_location
     WHERE c.dst_name = 'Paris'), 'France');
CALL t_eq('3. section 2 rules', 'no stay is shorter than one night',
    (SELECT COUNT(*) FROM travel_to WHERE DATEDIFF(to_departure, to_arrival) < 1), '0');
CALL t_eq('3. section 2 rules', 'every stay lies inside the dates of its trip',
    (SELECT COUNT(*) FROM travel_to tt JOIN trip t ON t.tr_id = tt.to_tr_id
     WHERE DATE(tt.to_arrival) < DATE(t.tr_departure)
        OR DATE(tt.to_departure) > DATE(t.tr_return)), '0');
CALL t_eq('3. section 2 rules', 'every reservation has a price',
    (SELECT COUNT(*) FROM reservation WHERE res_total_cost IS NULL OR res_total_cost = 0), '0');
CALL t_eq('3. section 2 rules', 'every logged action belongs to a registered DBA',
    (SELECT COUNT(*) FROM log_actions l LEFT JOIN dba_users d ON d.dba_username = l.log_dba_username
     WHERE d.dba_username IS NULL), '0');


-- =====================================================================
--  SECTION 4 - section 2 rules the database ENFORCES (CHECK constraints)
-- ---------------------------------------------------------------------
--  Section 3 showed the data obeys the rules. This section shows the
--  database would not let you break them, and that correct data still
--  goes in - a constraint that refuses everything is not useful either.
--
--  chk_vehicle_type_seats : Bus > 20, Mini-Bus 10-20, Van 6-9, Car 1-5
--  chk_lodging_stars_type : only a Hotel or a Resort may have stars
--  lodging_chk_1          : stars are 1 to 5
--  lodging_chk_2          : the rating is 0.00 to 5.00
-- =====================================================================

-- --- the accepted path: valid rows of every vehicle type go in ---------
CALL t_ok('4. CHECK constraints', 'a Car with 5 seats is accepted',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'CHK-0001', 'M', 'B', 'Car', 5)");
CALL t_ok('4. CHECK constraints', 'a Van with 9 seats is accepted',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'CHK-0002', 'M', 'B', 'Van', 9)");
CALL t_ok('4. CHECK constraints', 'a Mini-Bus with 20 seats is accepted',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'CHK-0003', 'M', 'B', 'Mini-Bus', 20)");
CALL t_ok('4. CHECK constraints', 'a Bus with 21 seats is accepted',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'CHK-0004', 'M', 'B', 'Bus', 21)");

-- --- the refused path: one for every branch of the constraint ----------
CALL t_error('4. CHECK constraints', 'a Car with 30 seats is refused',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'CHK-0005', 'M', 'B', 'Car', 30)", 'chk_vehicle_type_seats');
CALL t_error('4. CHECK constraints', 'a Bus with 8 seats is refused',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'CHK-0006', 'M', 'B', 'Bus', 8)", 'chk_vehicle_type_seats');
CALL t_error('4. CHECK constraints', 'a Mini-Bus with 25 seats is refused (that is a Bus)',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'CHK-0007', 'M', 'B', 'Mini-Bus', 25)", 'chk_vehicle_type_seats');
CALL t_error('4. CHECK constraints', 'a Van with 12 seats is refused (that is a Mini-Bus)',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (1, 'CHK-0008', 'M', 'B', 'Van', 12)", 'chk_vehicle_type_seats');
-- the same rule on UPDATE, not only on INSERT
CALL t_error('4. CHECK constraints', 'turning a Bus into a Car is refused as well',
    "UPDATE vehicle SET v_type = 'Car' WHERE v_id = 1", 'chk_vehicle_type_seats');

-- --- lodging: stars belong to hotels and resorts only ------------------
CALL t_ok('4. CHECK constraints', 'a hotel WITH stars is accepted',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     VALUES (2, 'Chk Hotel', 'Hotel', 4, 'a', 'London', 5, 10)");
CALL t_ok('4. CHECK constraints', 'a hotel that has not been rated yet is accepted (stars may be unknown)',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     VALUES (2, 'Chk Unrated', 'Hotel', 'a', 'London', 5, 10)");
CALL t_ok('4. CHECK constraints', 'a hostel WITHOUT stars is accepted',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     VALUES (2, 'Chk Hostel', 'Hostel', 'a', 'London', 5, 10)");
CALL t_error('4. CHECK constraints', 'a hostel WITH stars is refused',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     VALUES (2, 'Chk Bad Hostel', 'Hostel', 3, 'a', 'London', 5, 10)", 'chk_lodging_stars_type');
CALL t_error('4. CHECK constraints', 'giving stars to an apartment by UPDATE is refused',
    "UPDATE lodging SET lg_stars = 4 WHERE lg_name = 'Roma Bella'", 'chk_lodging_stars_type');
CALL t_error('4. CHECK constraints', 'a 6-star hotel is refused (stars are 1 to 5)',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     VALUES (2, 'Chk Six Star', 'Hotel', 6, 'a', 'London', 5, 10)", 'lodging_chk_1');
CALL t_error('4. CHECK constraints', 'a rating of 9 is refused (the rating is 0 to 5)',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_rating, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     VALUES (2, 'Chk Rating', 'Hostel', 9.0, 'a', 'London', 5, 10)", 'lodging_chk_2');

-- --- referential integrity --------------------------------------------
CALL t_error('4. CHECK constraints', 'a vehicle of a branch that does not exist is refused',
    "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats)
     VALUES (999, 'CHK-0009', 'M', 'B', 'Car', 4)", 'foreign key constraint fails');
CALL t_error('4. CHECK constraints', 'the same seat cannot be booked twice on one trip',
    "INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status)
     VALUES (1, 1, 5, 'PENDING')", 'Duplicate entry');

DELETE FROM vehicle WHERE v_license_plate LIKE 'CHK-%';
DELETE FROM lodging WHERE lg_name LIKE 'Chk %';


-- =====================================================================
--  SECTION 5 - 3.1.2.2  A lodging belongs to a city, never to a country
-- ---------------------------------------------------------------------
--  Triggers: trg_lodging_city_only_ins, trg_lodging_city_only_upd
--  A destination is a country when another destination points at it
--  (destination.dst_location). France is the parent of Paris, so nothing
--  may be accommodated "in France" - only in Paris.
--  Outcomes: accepted for a city / refused for a country, on INSERT and on
--  UPDATE. Both triggers and both outcomes are tested.
-- =====================================================================
CALL t_ok('5. lodging in a city', 'INSERT: a lodging in the city of Paris is accepted',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     VALUES (1, 'City Test Lodge', 'Hostel', 'a', 'Paris', 5, 10)");
CALL t_error('5. lodging in a city', 'INSERT: a lodging in the country France is refused',
    "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
     SELECT dst_id, 'Country Test Lodge', 'Hostel', 'a', 'b', 5, 10 FROM destination WHERE dst_name = 'France'",
    'must belong to a city destination');
CALL t_error('5. lodging in a city', 'UPDATE: moving a lodging to the country France is refused too',
    "UPDATE lodging SET lg_dst_id = (SELECT dst_id FROM destination WHERE dst_name = 'France')
     WHERE lg_name = 'City Test Lodge'", 'must belong to a city destination');
CALL t_ok('5. lodging in a city', 'UPDATE: moving a lodging to another city is accepted',
    "UPDATE lodging SET lg_dst_id = 2 WHERE lg_name = 'City Test Lodge'");
DELETE FROM lodging WHERE lg_name = 'City Test Lodge';


-- =====================================================================
--  SECTION 6 - 3.1.4.2  The nights and the cost of a stay
-- ---------------------------------------------------------------------
--  Trigger: trg_calculate_accommodation_cost (BEFORE INSERT ON room_usage)
--  It fills in ru_nights and ru_total_cost, so neither is ever typed in:
--      nights = check-out - check-in
--      cost   = price per night x nights x rooms
--  Outcomes: computed for a valid stay / refused when the stay is not at
--  least one night (same day, or check-out before check-in). All tested.
--  Lodging 3 is Berlin Plaza at 120.00 per night.
-- =====================================================================
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-01', '2026-10-04', 3);
CALL t_eq('6. 3.1.4.2 stay cost', 'the nights are computed from the two dates (1 -> 4 Oct = 3)',
    (SELECT ru_nights FROM room_usage WHERE ru_trip_id = 11), '3');
CALL t_eq('6. 3.1.4.2 stay cost', 'the cost is 120 per night x 3 nights x 3 rooms',
    (SELECT ru_total_cost FROM room_usage WHERE ru_trip_id = 11), '1080.00');
DELETE FROM room_usage WHERE ru_trip_id = 11;

-- the cost follows the number of rooms
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 3, '2026-10-01', '2026-10-04', 1);
CALL t_eq('6. 3.1.4.2 stay cost', 'the same stay for one room costs a third of that',
    (SELECT ru_total_cost FROM room_usage WHERE ru_trip_id = 11), '360.00');
DELETE FROM room_usage WHERE ru_trip_id = 11;

CALL t_error('6. 3.1.4.2 stay cost', 'a stay that ends on the day it starts is refused',
    "INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
     VALUES (11, 3, '2026-10-05', '2026-10-05', 1)", 'check-out must be at least one day after check-in');
CALL t_error('6. 3.1.4.2 stay cost', 'a stay that ends before it starts is refused',
    "INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
     VALUES (11, 3, '2026-10-05', '2026-10-02', 1)", 'check-out must be at least one day after check-in');


-- =====================================================================
--  SECTION 7 - The price of a reservation
-- ---------------------------------------------------------------------
--  Procedure: sp_calculate_reservation_cost(trip, seat, customer)
--  Used by the GUI right after a booking (ReservationDAO.addReservation),
--  so the price is never typed in by hand. It takes the adult price of the
--  trip, or the child price when the customer is under 18 on the day.
--  Outcomes: adult price / child price / adult price when the birth date
--  is unknown. All three are tested.
--  Trip 1 costs 500 for an adult and 300 for a child.
-- =====================================================================
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 41, 1, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 41, 1);
CALL t_eq('7. reservation price', 'an adult (customer 1) pays the adult price of trip 1',
    (SELECT res_total_cost FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 41), '500.00');

INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 42, 20, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 42, 20);
CALL t_eq('7. reservation price', 'a child (customer 20) pays the child price of trip 1',
    (SELECT res_total_cost FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 42), '300.00');

-- a customer whose birth date is unknown is charged as an adult
INSERT INTO customer (cust_name, cust_lname, cust_birth_date) VALUES ('No', 'Birthdate', NULL);
SET @no_dob = LAST_INSERT_ID();
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (1, 43, @no_dob, 'PENDING', 0);
CALL sp_calculate_reservation_cost(1, 43, @no_dob);
CALL t_eq('7. reservation price', 'a customer without a birth date is charged as an adult',
    (SELECT res_total_cost FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 43), '500.00');

DELETE FROM reservation WHERE res_tr_id = 1 AND res_seatnum IN (41, 42, 43);
DELETE FROM customer WHERE cust_id = @no_dob;


-- =====================================================================
--  SECTION 8 - 3.1.3.2  Searching for accommodation
-- ---------------------------------------------------------------------
--  Procedure: sp_search_accommodation(destination, arrival, departure,
--                                     rooms, OUT first_lodging_id)
--  It lists the lodgings of a destination that still have enough free
--  rooms in that period, cheapest first (then more stars, then a better
--  rating), and returns the id of the best one in the OUT parameter.
--  Rooms already booked in room_usage for an overlapping period are
--  subtracted from the free rooms.
--  Outcomes: a match is found / nothing is found because there are not
--  enough rooms, because the lodging is inactive, or because the
--  destination has none at all. All are tested, plus the ordering.
--  Destination 1 is Paris; lodging 1 is Le Grand Paris, 100 rooms, 250/night.
-- =====================================================================
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 2, @lodging_id);
CALL t_eq('8. 3.1.3.2 search', 'FOUND: the hotel of Paris is returned in the OUT parameter',
    (SELECT lg_name FROM lodging WHERE lg_id = @lodging_id), 'Le Grand Paris');

-- 95 of the 100 rooms are taken for a period that overlaps the search
INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
VALUES (11, 1, '2026-06-03', '2026-06-07', 95);
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 5, @lodging_id);
CALL t_eq('8. 3.1.3.2 search', 'existing bookings reduce the free rooms: 5 are still free',
    CAST(@lodging_id AS CHAR), '1');
CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 6, @lodging_id);
CALL t_eq('8. 3.1.3.2 search', 'NOT FOUND: asking for 6 of the 5 free rooms returns NULL',
    IFNULL(CAST(@lodging_id AS CHAR), 'NULL'), 'NULL');
CALL sp_search_accommodation(1, '2026-06-07', '2026-06-09', 6, @lodging_id);
CALL t_eq('8. 3.1.3.2 search', 'a period that does not overlap the booking is unaffected',
    CAST(@lodging_id AS CHAR), '1');
DELETE FROM room_usage WHERE ru_trip_id = 11;

-- an inactive lodging is not offered at all
UPDATE lodging SET lg_status = 'Inactive' WHERE lg_id = 1;
CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @lodging_id);
CALL t_eq('8. 3.1.3.2 search', 'NOT FOUND: a lodging that is Inactive is never offered',
    IFNULL(CAST(@lodging_id AS CHAR), 'NULL'), 'NULL');
UPDATE lodging SET lg_status = 'Active' WHERE lg_id = 1;

-- a destination with no lodging at all
INSERT INTO destination (dst_name, dst_rtype, dst_language_code) VALUES ('Nowhere', 'LOCAL', 'EN');
SET @nowhere = LAST_INSERT_ID();
CALL sp_search_accommodation(@nowhere, '2026-09-01', '2026-09-03', 1, @lodging_id);
CALL t_eq('8. 3.1.3.2 search', 'NOT FOUND: a destination without any lodging returns NULL',
    IFNULL(CAST(@lodging_id AS CHAR), 'NULL'), 'NULL');
DELETE FROM destination WHERE dst_id = @nowhere;

-- the order is: cheapest first, then more stars, then a better rating.
-- Two lodgings at the same price - the one with stars must win.
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_rating, lg_address, lg_city, lg_total_rooms, lg_cost_per_night)
VALUES (1, 'Sort Budget Inn', 'Hostel', NULL, 3.0, 'Rue X', 'Paris', 20, 30.00),
       (1, 'Sort Mid Hotel',  'Hotel',  3,    4.0, 'Rue Y', 'Paris', 20, 30.00);
CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @lodging_id);
CALL t_eq('8. 3.1.3.2 search', 'the cheapest is offered first (30.00 beats 250.00)',
    (SELECT lg_cost_per_night FROM lodging WHERE lg_id = @lodging_id), '30.00');
CALL t_eq('8. 3.1.3.2 search', 'at the same price the one with stars comes first',
    (SELECT lg_name FROM lodging WHERE lg_id = @lodging_id), 'Sort Mid Hotel');
DELETE FROM lodging WHERE lg_name LIKE 'Sort %';


-- =====================================================================
--  SECTION 9 - 3.1.3.3  Booking the accommodation of a whole trip
-- ---------------------------------------------------------------------
--  Procedure: sp_book_trip_accommodation(trip)
--  The "Auto-Book Accommodations" button of the Trips screen. For every
--  destination of the trip, in visit order, it books the best lodging
--  sp_search_accommodation offers, for the dates of that stay.
--  Rooms needed = CEIL(confirmed or paid reservations / 2) - double rooms.
--  Outcomes:
--    A. booked, one lodging per destination                     (tested)
--    B. run again -> the previous bookings are replaced, not added (tested)
--    C. refused: the trip does not exist                        (tested)
--    D. refused: nobody has confirmed or paid, so nothing to book (tested)
--    E. refused: one destination has no free room -> EVERY booking
--       of the trip is cancelled, not just that one              (tested)
--    F. a trip with no destinations books nothing and fails not  (tested)
--  Trip 1 visits Paris (1-5 June) and London (5-10 June).
-- =====================================================================

-- A. the normal case
CALL sp_book_trip_accommodation(1);
CALL t_eq('9. 3.1.3.3 auto-booking', 'A. one lodging is booked per destination of trip 1',
    (SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1), '2');
CALL t_eq('9. 3.1.3.3 auto-booking', 'A. the Paris leg is 4 nights x 250 for one room',
    (SELECT ru_total_cost FROM room_usage ru JOIN lodging l ON l.lg_id = ru.ru_lodging_id
     WHERE ru.ru_trip_id = 1 AND l.lg_name = 'Le Grand Paris'), '1000.00');
CALL t_eq('9. 3.1.3.3 auto-booking', 'A. the London leg is 5 nights x 60 for one room',
    (SELECT ru_total_cost FROM room_usage ru JOIN lodging l ON l.lg_id = ru.ru_lodging_id
     WHERE ru.ru_trip_id = 1 AND l.lg_name = 'London Stay'), '300.00');
CALL t_eq('9. 3.1.3.3 auto-booking', 'A. the accommodation of the whole trip costs 1300',
    (SELECT SUM(ru_total_cost) FROM room_usage WHERE ru_trip_id = 1), '1300.00');
CALL t_eq('9. 3.1.3.3 auto-booking', 'A. the stays are booked for the dates of the trip',
    (SELECT CONCAT(MIN(ru_checkin), ' to ', MAX(ru_checkout)) FROM room_usage WHERE ru_trip_id = 1),
    '2026-06-01 to 2026-06-10');

-- B. booking again replaces, it does not add
CALL sp_book_trip_accommodation(1);
CALL t_eq('9. 3.1.3.3 auto-booking', 'B. running it again replaces the bookings (still 2, not 4)',
    (SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1), '2');

-- rooms follow the number of passengers: trip 3 has 3 paid reservations
CALL sp_book_trip_accommodation(3);
CALL t_eq('9. 3.1.3.3 auto-booking', 'one room per two passengers: 3 passengers need 2 rooms',
    (SELECT DISTINCT ru_rooms_count FROM room_usage WHERE ru_trip_id = 3), '2');

-- C. and D. the refused paths
CALL t_error('9. 3.1.3.3 auto-booking', 'C. an unknown trip is refused',
    'CALL sp_book_trip_accommodation(9999)', 'trip does not exist');
UPDATE reservation SET res_status = 'PENDING' WHERE res_tr_id = 12;
CALL t_error('9. 3.1.3.3 auto-booking', 'D. a trip where nobody has confirmed or paid is refused',
    'CALL sp_book_trip_accommodation(12)', 'no confirmed or paid reservations');
UPDATE reservation SET res_status = 'CONFIRMED' WHERE res_tr_id = 12;

-- E. a leg that cannot be booked cancels the whole trip, not half of it
UPDATE lodging SET lg_total_rooms = 0 WHERE lg_id = 2;   -- London Stay has no rooms left
CALL t_error('9. 3.1.3.3 auto-booking', 'E. a destination without a free room is named in the error',
    'CALL sp_book_trip_accommodation(1)', 'no lodging in London with 1 free room(s)');
CALL t_eq('9. 3.1.3.3 auto-booking', 'E. and the Paris booking is cancelled as well - all or nothing',
    (SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1), '0');
UPDATE lodging SET lg_total_rooms = 30 WHERE lg_id = 2;

-- F. a trip that visits nowhere yet
INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child,
                  tr_status, tr_min_participants, tr_br_code)
VALUES ('2027-06-01', '2027-06-05', 10, 100, 50, 'PLANNED', 2, 1);
SET @empty_trip = LAST_INSERT_ID();
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES (@empty_trip, 1, 1, 'CONFIRMED', 100);
CALL t_ok('9. 3.1.3.3 auto-booking', 'F. a trip without destinations is not an error',
    CONCAT('CALL sp_book_trip_accommodation(', @empty_trip, ')'));
CALL t_eq('9. 3.1.3.3 auto-booking', 'F. and nothing is booked for it',
    (SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = @empty_trip), '0');
DELETE FROM reservation WHERE res_tr_id = @empty_trip;
DELETE FROM trip WHERE tr_id = @empty_trip;

DELETE FROM room_usage;


-- =====================================================================
--  SECTION 10 - 3.1.3.1  Assigning a vehicle to a trip
-- ---------------------------------------------------------------------
--  Procedure: sp_assign_vehicle_to_trip(trip, vehicle, current mileage)
--  The heart of the Trips screen ("Add Trip"). It runs five checks, prints
--  the result of every one of them as a PASS/FAIL table, and only if all
--  five pass does it attach the vehicle to the trip, set the vehicle to
--  InUse and record the new odometer reading.
--
--  Outcomes:
--    error   the trip does not exist                            (tested)
--    error   the vehicle does not exist                         (tested)
--    check 1 the vehicle must be Available   - Maintenance / InUse (both tested)
--    check 2 seats >= confirmed or paid reservations            (both ways tested)
--    check 3 more than 9 seats needs licence C or D - wrong licence,
--            no driver at all, and the case where 9 seats or fewer
--            make the licence irrelevant                        (all tested)
--    check 4 the vehicle is free on those dates - and trips that are
--            CANCELLED or COMPLETED do not count as a clash      (both tested)
--    check 5 the odometer may not go backwards - lower is refused,
--            equal is accepted                                  (both tested)
--    success everything passes and the data is written           (tested)
--    several checks may fail at once and all reasons are listed  (tested)
--
--  Seed data used here: trip 14 (Jan 2027, driver AT113 licence D),
--  vehicle 9 (52-seat bus, Available, 90 000 km), vehicle 4 (Maintenance),
--  trip 8 (driver AT114 licence B), vehicle 8 (9-seat van, 20 000 km).
-- =====================================================================

-- --- the two "does not exist" errors -----------------------------------
CALL t_error('10. 3.1.3.1 vehicle', 'the trip must exist',
    'CALL sp_assign_vehicle_to_trip(9999, 1, 1)', 'trip does not exist');
CALL t_error('10. 3.1.3.1 vehicle', 'the vehicle must exist',
    'CALL sp_assign_vehicle_to_trip(1, 9999, 1)', 'vehicle does not exist');

-- --- check 1: the vehicle has to be free -------------------------------
CALL t_error('10. 3.1.3.1 vehicle', 'check 1 FAILS: the vehicle is in Maintenance',
    'CALL sp_assign_vehicle_to_trip(1, 4, 200100)', 'vehicle is Maintenance');
UPDATE vehicle SET v_status = 'InUse' WHERE v_id = 6;
CALL t_error('10. 3.1.3.1 vehicle', 'check 1 FAILS: the vehicle is already InUse',
    'CALL sp_assign_vehicle_to_trip(13, 6, 120000)', 'vehicle is InUse');
UPDATE vehicle SET v_status = 'Available' WHERE v_id = 6;

-- --- check 2: enough seats for the people who booked -------------------
UPDATE vehicle SET v_seats = 2 WHERE v_id = 10;
CALL t_error('10. 3.1.3.1 vehicle', 'check 2 FAILS: 2 seats for 3 paid reservations',
    'CALL sp_assign_vehicle_to_trip(3, 10, 10100)', '2 seats < 3 reservations');
UPDATE vehicle SET v_seats = 5 WHERE v_id = 10;

-- --- check 3: the licence of the driver --------------------------------
CALL t_error('10. 3.1.3.1 vehicle', 'check 3 FAILS: licence B may not drive a 50-seat bus',
    'CALL sp_assign_vehicle_to_trip(8, 1, 150100)', 'driver licence B (C/D needed)');
-- a trip that has no driver yet cannot take a bus either
INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child,
                  tr_status, tr_min_participants, tr_br_code, tr_drv_AT)
VALUES ('2027-07-01', '2027-07-05', 40, 100, 50, 'PLANNED', 2, 1, NULL);
SET @no_driver_trip = LAST_INSERT_ID();
CALL t_error('10. 3.1.3.1 vehicle', 'check 3 FAILS: a trip with no driver may not take a bus',
    CONCAT('CALL sp_assign_vehicle_to_trip(', @no_driver_trip, ', 9, 90000)'),
    'driver licence missing (C/D needed)');
DELETE FROM trip WHERE tr_id = @no_driver_trip;
-- with 9 seats or fewer the licence does not matter: trip 8's driver holds B
CALL t_ok('10. 3.1.3.1 vehicle', 'check 3 PASSES: licence B is fine for a 9-seat van',
    'CALL sp_assign_vehicle_to_trip(8, 8, 20000)');
CALL t_eq('10. 3.1.3.1 vehicle', 'check 5 PASSES: the same reading as recorded is accepted',
    (SELECT v_mileage FROM vehicle WHERE v_id = 8), '20000');
-- put it back for the checks that follow
UPDATE trip SET tr_vehicle_id = 8 WHERE tr_id = 8;
UPDATE vehicle SET v_status = 'Available' WHERE v_id = 8;

-- --- check 4: the vehicle must be free on those dates ------------------
CALL t_error('10. 3.1.3.1 vehicle', 'check 4 FAILS: the bus is on trip 1 during those days',
    'CALL sp_assign_vehicle_to_trip(2, 1, 150100)', 'overlaps 1 other trip');
-- a trip that was called off does not block its vehicle any more
UPDATE trip SET tr_status = 'CANCELLED' WHERE tr_id = 1;
CALL t_ok('10. 3.1.3.1 vehicle', 'check 4 PASSES: a CANCELLED trip does not block its vehicle',
    'CALL sp_assign_vehicle_to_trip(2, 1, 150100)');
UPDATE trip SET tr_status = 'PLANNED', tr_vehicle_id = 1 WHERE tr_id = 1;
UPDATE trip SET tr_vehicle_id = 2 WHERE tr_id = 2;
UPDATE vehicle SET v_status = 'Available', v_mileage = 150000 WHERE v_id = 1;

-- --- check 5: the odometer may not go backwards ------------------------
CALL t_error('10. 3.1.3.1 vehicle', 'check 5 FAILS: a reading below the recorded one',
    'CALL sp_assign_vehicle_to_trip(14, 9, 1000)', 'mileage 1000 < recorded 90000');

-- --- several checks failing at once ------------------------------------
CALL t_error('10. 3.1.3.1 vehicle', 'two checks fail: BOTH reasons are reported',
    'CALL sp_assign_vehicle_to_trip(1, 4, 1)',
    'vehicle is Maintenance; mileage 1 < recorded 200000');
CALL t_eq('10. 3.1.3.1 vehicle', 'a refused assignment changes nothing at all',
    (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 4), 'Maintenance/200000');

-- --- the assignment that passes every check ----------------------------
CALL t_ok('10. 3.1.3.1 vehicle', 'SUCCESS: all five checks pass, the vehicle is assigned',
    'CALL sp_assign_vehicle_to_trip(14, 9, 90500)');
CALL t_eq('10. 3.1.3.1 vehicle', 'SUCCESS: the vehicle is now InUse with the new reading',
    (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9), 'InUse/90500');
CALL t_eq('10. 3.1.3.1 vehicle', 'SUCCESS: the trip now points at the vehicle',
    (SELECT tr_vehicle_id FROM trip WHERE tr_id = 14), '9');
CALL t_has('10. 3.1.3.1 vehicle', 'SUCCESS: the change is written to the audit log',
    (SELECT log_details FROM log_actions WHERE log_table_name = 'vehicle' ORDER BY log_id DESC LIMIT 1),
    'status Available -> InUse, mileage 90000 -> 90500');


-- =====================================================================
--  SECTION 11 - 3.1.4.3  Completing a trip frees its vehicle
-- ---------------------------------------------------------------------
--  Trigger: trg_complete_trip_vehicle_update (AFTER UPDATE ON trip)
--  When a trip is set to COMPLETED, its vehicle goes back to Available and
--  the kilometres of the trip (tr_km) are added to the odometer.
--  Outcomes:
--    A. COMPLETED + a vehicle  -> the vehicle is freed and the km added
--    B. any other status       -> the vehicle is left alone
--    C. already COMPLETED      -> the km are not added a second time
--    D. COMPLETED without a vehicle -> nothing happens, and no error
--  All four are tested. Vehicle 9 stands at 90 500 km from section 10.
-- =====================================================================
UPDATE trip SET tr_status = 'COMPLETED', tr_km = 350 WHERE tr_id = 14;
CALL t_eq('11. 3.1.4.3 trip done', 'A. the vehicle is Available again and 350 km are added',
    (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9), 'Available/90850');
CALL t_has('11. 3.1.4.3 trip done', 'A. the completion is written to the audit log with the km',
    (SELECT log_details FROM log_actions WHERE log_table_name = 'trip' ORDER BY log_id DESC LIMIT 1),
    'km 0 -> 350');

-- C. it only fires on the change INTO completed
UPDATE trip SET tr_km = 400 WHERE tr_id = 14;
CALL t_eq('11. 3.1.4.3 trip done', 'C. a trip that is already COMPLETED does not add the km twice',
    (SELECT v_mileage FROM vehicle WHERE v_id = 9), '90850');

-- B. another status leaves the vehicle where it is
UPDATE vehicle SET v_status = 'InUse' WHERE v_id = 2;
UPDATE trip SET tr_status = 'ACTIVE' WHERE tr_id = 2;
CALL t_eq('11. 3.1.4.3 trip done', 'B. setting a trip to ACTIVE leaves its vehicle InUse',
    (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 2), 'InUse/80000');

-- D. a trip with no vehicle can be completed without an error
INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child,
                  tr_status, tr_min_participants, tr_br_code)
VALUES ('2027-08-01', '2027-08-05', 10, 100, 50, 'PLANNED', 2, 1);
SET @no_vehicle_trip = LAST_INSERT_ID();
CALL t_ok('11. 3.1.4.3 trip done', 'D. completing a trip that has no vehicle is not an error',
    CONCAT('UPDATE trip SET tr_status = ''COMPLETED'', tr_km = 100 WHERE tr_id = ', @no_vehicle_trip));
DELETE FROM trip WHERE tr_id = @no_vehicle_trip;


-- =====================================================================
--  SECTION 12 - 3.1.4.1  The audit log
-- ---------------------------------------------------------------------
--  21 triggers: INSERT, UPDATE and DELETE on each of the seven tables
--  trip, reservation, customer, destination, vehicle, lodging, room_usage.
--  Each one writes a row into log_actions with the account, the time, the
--  table, the kind of action and a readable description.
--  log_actions.log_dba_username is a foreign key to dba_users, so an
--  account that is not a registered DBA cannot change the data at all.
--  Outcomes: every table logs all three actions (tested one by one), and
--  the refused path where the account is not registered (tested last,
--  because it empties the log).
-- =====================================================================
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

CALL t_eq('12. 3.1.4.1 audit log', '7 tables x 3 actions produce exactly 21 log rows',
    (SELECT COUNT(*) - @log_before FROM log_actions), '21');

-- one check per table: all three actions have to be there.
-- log_action_type is an ENUM, so it sorts in the order it was declared.
CALL t_eq('12. 3.1.4.1 audit log', 'customer logs INSERT, UPDATE and DELETE',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'customer' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');
CALL t_eq('12. 3.1.4.1 audit log', 'destination logs INSERT, UPDATE and DELETE',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'destination' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');
CALL t_eq('12. 3.1.4.1 audit log', 'vehicle logs INSERT, UPDATE and DELETE',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'vehicle' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');
CALL t_eq('12. 3.1.4.1 audit log', 'lodging logs INSERT, UPDATE and DELETE',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'lodging' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');
CALL t_eq('12. 3.1.4.1 audit log', 'room_usage logs INSERT, UPDATE and DELETE',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'room_usage' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');
CALL t_eq('12. 3.1.4.1 audit log', 'reservation logs INSERT, UPDATE and DELETE',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'reservation' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');
CALL t_eq('12. 3.1.4.1 audit log', 'trip logs INSERT, UPDATE and DELETE',
    (SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions
     WHERE log_table_name = 'trip' AND log_id > @log_before), 'INSERT,UPDATE,DELETE');

CALL t_eq('12. 3.1.4.1 audit log', 'all seven tables of the requirement are covered',
    (SELECT COUNT(DISTINCT log_table_name) FROM log_actions WHERE log_id > @log_before), '7');
CALL t_eq('12. 3.1.4.1 audit log', 'the account that made the change is recorded',
    (SELECT COUNT(DISTINCT log_dba_username) FROM log_actions WHERE log_id > @log_before), '1');
CALL t_eq('12. 3.1.4.1 audit log', 'the account is stored without the host name',
    (SELECT DISTINCT log_dba_username FROM log_actions WHERE log_id > @log_before),
    (SELECT SUBSTRING_INDEX(USER(), '@', 1)));
CALL t_eq('12. 3.1.4.1 audit log', 'every log row carries the time of the change',
    (SELECT COUNT(*) FROM log_actions WHERE log_timestamp IS NULL), '0');
CALL t_has('12. 3.1.4.1 audit log', 'the log says what changed, not only that something did',
    (SELECT log_details FROM log_actions
     WHERE log_table_name = 'vehicle' AND log_action_type = 'UPDATE' AND log_id > @log_before
     ORDER BY log_id DESC LIMIT 1), 'Available -> Maintenance');

-- the refused path: an account that is not a registered DBA may change nothing.
-- (The log has to be emptied first, because log_actions references dba_users.)
DELETE FROM log_actions;
DELETE FROM dba_users WHERE dba_username = SUBSTRING_INDEX(USER(), '@', 1);
CALL t_error('12. 3.1.4.1 audit log', 'an account that is not a registered DBA cannot change data',
    "INSERT INTO customer (cust_name, cust_lname) VALUES ('Not', 'ADba')",
    'foreign key constraint fails');
INSERT INTO dba_users (dba_username, dba_start_date) VALUES (SUBSTRING_INDEX(USER(), '@', 1), CURDATE());
CALL t_ok('12. 3.1.4.1 audit log', 'once the account is registered again the change goes through',
    "INSERT INTO customer (cust_name, cust_lname) VALUES ('Now', 'ADba')");
DELETE FROM customer WHERE cust_lname = 'ADba';


-- =====================================================================
--  SECTION 13 - The financial state of a branch
-- ---------------------------------------------------------------------
--  Procedure: sp_branch_financials(branch, OUT revenue, OUT expenses,
--                                  OUT profit ratio)
--  Behind "Calculate Financials" on the Admin screen, and used by the
--  salary trigger of section 14.
--     revenue  = the reservations of the trips of that branch
--     expenses = the salaries of the workers of that branch
--     ratio    = (revenue - expenses) / expenses
--  Outcomes: a real branch gives three numbers / an unknown branch gives
--  three NULLs instead of failing / a branch with no salaries has no
--  ratio to compute (NULL). All three are tested.
-- =====================================================================
CALL sp_branch_financials(1, @revenue, @expenses, @ratio);
CALL t_eq('13. branch financials', 'a real branch reports the money it takes in',
    CAST(@revenue AS CHAR), (SELECT CAST(SUM(r.res_total_cost) AS CHAR) FROM reservation r
                             JOIN trip t ON t.tr_id = r.res_tr_id WHERE t.tr_br_code = 1));
CALL t_eq('13. branch financials', 'a real branch reports the salaries it pays',
    CAST(@expenses AS CHAR), (SELECT CAST(SUM(wrk_salary) AS CHAR) FROM worker WHERE wrk_br_code = 1));
CALL t_eq('13. branch financials', 'the profit ratio is (revenue - expenses) / expenses',
    CAST(@ratio AS CHAR), CAST(ROUND((@revenue - @expenses) / @expenses, 4) AS CHAR));

CALL sp_branch_financials(999, @revenue, @expenses, @ratio);
CALL t_eq('13. branch financials', 'an unknown branch gives no numbers instead of failing',
    CONCAT(IFNULL(CAST(@revenue AS CHAR), 'NULL'), '/', IFNULL(CAST(@ratio AS CHAR), 'NULL')), 'NULL/NULL');

-- a brand new branch has no workers, so there is no ratio to compute
INSERT INTO branch (br_code, br_street, br_num, br_city, br_manager_AT)
VALUES (99, 'Test Street', 1, 'Testtown', 'AT101');
CALL sp_branch_financials(99, @revenue, @expenses, @ratio);
CALL t_eq('13. branch financials', 'a branch that pays no salaries has no profit ratio',
    CONCAT(CAST(@expenses AS CHAR), '/', IFNULL(CAST(@ratio AS CHAR), 'NULL')), '0.00/NULL');
DELETE FROM branch WHERE br_code = 99;


-- =====================================================================
--  SECTION 14 - The salary guard
-- ---------------------------------------------------------------------
--  Trigger: trg_worker_salary_increase (BEFORE UPDATE ON worker)
--  Behind "Update Salary" on the Staff screen. A raise is only allowed
--  when the branch is profitable AND the raise is at most 2 %.
--  Outcomes - every branch of the trigger is exercised:
--    A. the salary goes DOWN            -> always allowed (no check at all)
--    B. the salary does not change      -> allowed
--    C. raise of 1 %, branch profitable -> ALLOWED
--    D. raise of exactly 2 %            -> ALLOWED (the limit itself)
--    E. raise above 2 %                 -> REFUSED
--    F. any raise, branch not profitable-> REFUSED
--
--  With the seeded salaries no branch is profitable (one round of
--  reservations against a month of salaries), so the salaries of branch 1
--  are lowered first - which is outcome A, and allowed.
-- =====================================================================

-- A. lowering is always allowed, no matter what the branch earns
CALL t_ok('14. salary guard', 'A. lowering a salary is always allowed',
    'UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1');
CALL t_eq('14. salary guard', 'A. the lower salary is stored',
    (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'), '100.00');

-- B. an update that does not touch the salary is not a raise
CALL t_ok('14. salary guard', 'B. changing something else about the worker is allowed',
    "UPDATE worker SET wrk_email = 'changed@ag.gr' WHERE wrk_AT = 'AT101'");

-- branch 1 now earns more than it pays
CALL sp_branch_financials(1, @revenue, @expenses, @ratio);
CALL t_eq('14. salary guard', 'branch 1 is profitable now, so a raise may be considered',
    IF(@ratio > 0, 'profitable', CONCAT('ratio ', @ratio)), 'profitable');

-- C. a small raise in a profitable branch
CALL t_ok('14. salary guard', 'C. a raise of 1 % in a profitable branch is ALLOWED',
    "UPDATE worker SET wrk_salary = 101 WHERE wrk_AT = 'AT101'");
CALL t_eq('14. salary guard', 'C. the new salary is stored',
    (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'), '101.00');

-- D. exactly on the limit
UPDATE worker SET wrk_salary = 100 WHERE wrk_AT = 'AT101';
CALL t_ok('14. salary guard', 'D. a raise of exactly 2 % is ALLOWED (the limit itself)',
    "UPDATE worker SET wrk_salary = 102 WHERE wrk_AT = 'AT101'");
CALL t_eq('14. salary guard', 'D. the salary on the limit is stored',
    (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'), '102.00');

-- E. over the limit
CALL t_error('14. salary guard', 'E. a raise above 2 % is REFUSED',
    "UPDATE worker SET wrk_salary = 110 WHERE wrk_AT = 'AT101'", 'exceeds 2% limit');
CALL t_eq('14. salary guard', 'E. the refused raise did not change the salary',
    (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'), '102.00');

-- F. the branch stops making money: no raise at all, however small
UPDATE reservation SET res_total_cost = 0;
CALL t_error('14. salary guard', 'F. even a 1 % raise is REFUSED when the branch makes no profit',
    "UPDATE worker SET wrk_salary = 103 WHERE wrk_AT = 'AT101'", 'branch is not profitable');
CALL t_ok('14. salary guard', 'F. but lowering a salary is still allowed',
    "UPDATE worker SET wrk_salary = 50 WHERE wrk_AT = 'AT101'");


-- =====================================================================
--  SECTION 15 - 3.1.3.4  The 90 000-row history and its indexes
-- ---------------------------------------------------------------------
--  Table trip_history holds 90 000 generated completed trips
--  (sp_generate_dummy_history, which is not run here: it takes minutes and
--  the rows are already there).
--  Two reports and one covering index each, so neither has to read the
--  table itself:
--     sp_history_revenue(from, to)  -> idx_hist_dep_rev (departure, revenue)
--     sp_history_destinations(n)    -> idx_hist_dc_dep  (dest_count, departure)
--  Outcomes: both indexes exist with the right columns in the right order,
--  and both reports return data.
-- =====================================================================
CALL t_eq('15. 3.1.3.4 history', 'the revenue index covers departure and revenue, in that order',
    (SELECT GROUP_CONCAT(column_name ORDER BY seq_in_index) FROM information_schema.statistics
     WHERE table_schema = DATABASE() AND table_name = 'trip_history'
       AND index_name = 'idx_hist_dep_rev'), 'th_departure,th_revenue');
CALL t_eq('15. 3.1.3.4 history', 'the destination index covers dest_count and departure',
    (SELECT GROUP_CONCAT(column_name ORDER BY seq_in_index) FROM information_schema.statistics
     WHERE table_schema = DATABASE() AND table_name = 'trip_history'
       AND index_name = 'idx_hist_dc_dep'), 'th_dest_count,th_departure');
CALL t_min('15. 3.1.3.4 history', 'the revenue report of 2021 returns money',
    (SELECT SUM(th_revenue) FROM trip_history
     WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31'), 1);
CALL t_min('15. 3.1.3.4 history', 'there are trips with exactly 3 destinations to report on',
    (SELECT COUNT(*) FROM trip_history WHERE th_dest_count = 3), 1000);
CALL t_ok('15. 3.1.3.4 history', 'sp_history_revenue runs',
    "CALL sp_history_revenue('2021-01-01', '2021-12-31')");
CALL t_ok('15. 3.1.3.4 history', 'sp_history_destinations runs',
    'CALL sp_history_destinations(3)');


-- #####################################################################
--  Undo everything the tests did
-- #####################################################################
ROLLBACK;


-- #####################################################################
--  THE REPORT
-- #####################################################################

-- 1. every check, in order
SELECT id, section, test, status FROM test_results ORDER BY id;

-- 2. the failures on their own, with what was expected and what came back
SELECT id, section, test, expected, actual
FROM test_results WHERE status = 'FAIL' ORDER BY id;

-- 3. the summary
SELECT COUNT(*)             AS total,
       SUM(status = 'PASS') AS passed,
       SUM(status = 'FAIL') AS failed,
       IF(SUM(status = 'FAIL') = 0, 'ALL TESTS PASSED', 'THERE ARE FAILURES') AS result
FROM test_results;

-- 4. the proof that the database was left exactly as it was found
SELECT 'the tests changed nothing' AS note,
       (SELECT COUNT(*) FROM customer)    AS customers,
       (SELECT COUNT(*) FROM reservation) AS reservations,
       (SELECT COUNT(*) FROM room_usage)  AS room_usage_rows,
       (SELECT COUNT(*) FROM log_actions) AS log_rows,
       (SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9) AS vehicle_9,
       (SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101')                AS salary_AT101;


-- #####################################################################
--  Remove the harness again
-- #####################################################################
DROP PROCEDURE IF EXISTS t_record;
DROP PROCEDURE IF EXISTS t_eq;
DROP PROCEDURE IF EXISTS t_min;
DROP PROCEDURE IF EXISTS t_has;
DROP PROCEDURE IF EXISTS t_error;
DROP PROCEDURE IF EXISTS t_ok;
DROP TEMPORARY TABLE IF EXISTS test_results;
