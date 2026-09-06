USE baseisproject;

-- =====================================================================
-- 3.1.4.1  Log triggers
-- Every INSERT / UPDATE / DELETE on trip, reservation, customer, destination,
-- vehicle, lodging and room_usage writes a row to log_actions with the
-- timestamp (default CURRENT_TIMESTAMP) and the DBA username.
-- The username is stored without the host part so that the same DBA is
-- logged identically from localhost, the Docker network or the GUI, and so
-- that it matches dba_users.dba_username (FK).
--
-- 3.1.4.3  Trip completion trigger (trg_complete_trip_vehicle_update)
-- =====================================================================

DELIMITER $$

-- ---------------------------------------------------------------- trip
DROP TRIGGER IF EXISTS trg_log_trip_insert$$
CREATE TRIGGER trg_log_trip_insert AFTER INSERT ON trip FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'trip', 'INSERT',
            CONCAT('Trip ', NEW.tr_id, ' created: ', NEW.tr_departure, ' -> ', NEW.tr_return,
                   ', status ', NEW.tr_status, ', branch ', IFNULL(NEW.tr_br_code, '-')));
END$$

DROP TRIGGER IF EXISTS trg_log_trip_update$$
CREATE TRIGGER trg_log_trip_update AFTER UPDATE ON trip FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'trip', 'UPDATE',
            CONCAT('Trip ', OLD.tr_id, ': status ', OLD.tr_status, ' -> ', NEW.tr_status,
                   ', vehicle ', IFNULL(OLD.tr_vehicle_id, '-'), ' -> ', IFNULL(NEW.tr_vehicle_id, '-'),
                   ', km ', IFNULL(OLD.tr_km, 0), ' -> ', IFNULL(NEW.tr_km, 0)));
END$$

DROP TRIGGER IF EXISTS trg_log_trip_delete$$
CREATE TRIGGER trg_log_trip_delete AFTER DELETE ON trip FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'trip', 'DELETE',
            CONCAT('Trip ', OLD.tr_id, ' deleted (', OLD.tr_departure, ' -> ', OLD.tr_return, ')'));
END$$

-- --------------------------------------------------------- reservation
DROP TRIGGER IF EXISTS trg_log_reservation_insert$$
CREATE TRIGGER trg_log_reservation_insert AFTER INSERT ON reservation FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'reservation', 'INSERT',
            CONCAT('Reservation trip ', NEW.res_tr_id, ' seat ', NEW.res_seatnum,
                   ' customer ', IFNULL(NEW.res_cust_id, '-'), ' status ', IFNULL(NEW.res_status, '-')));
END$$

DROP TRIGGER IF EXISTS trg_log_reservation_update$$
CREATE TRIGGER trg_log_reservation_update AFTER UPDATE ON reservation FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'reservation', 'UPDATE',
            CONCAT('Reservation trip ', NEW.res_tr_id, ' seat ', NEW.res_seatnum,
                   ': status ', IFNULL(OLD.res_status, '-'), ' -> ', IFNULL(NEW.res_status, '-'),
                   ', cost ', IFNULL(OLD.res_total_cost, 0), ' -> ', IFNULL(NEW.res_total_cost, 0)));
END$$

DROP TRIGGER IF EXISTS trg_log_reservation_delete$$
CREATE TRIGGER trg_log_reservation_delete AFTER DELETE ON reservation FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'reservation', 'DELETE',
            CONCAT('Reservation trip ', OLD.res_tr_id, ' seat ', OLD.res_seatnum, ' deleted'));
END$$

-- ------------------------------------------------------------ customer
DROP TRIGGER IF EXISTS trg_log_customer_insert$$
CREATE TRIGGER trg_log_customer_insert AFTER INSERT ON customer FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'customer', 'INSERT',
            CONCAT('Customer ', NEW.cust_id, ' ', IFNULL(NEW.cust_name, ''), ' ', IFNULL(NEW.cust_lname, '')));
END$$

DROP TRIGGER IF EXISTS trg_log_customer_update$$
CREATE TRIGGER trg_log_customer_update AFTER UPDATE ON customer FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'customer', 'UPDATE',
            CONCAT('Customer ', NEW.cust_id, ' updated'));
END$$

DROP TRIGGER IF EXISTS trg_log_customer_delete$$
CREATE TRIGGER trg_log_customer_delete AFTER DELETE ON customer FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'customer', 'DELETE',
            CONCAT('Customer ', OLD.cust_id, ' ', IFNULL(OLD.cust_name, ''), ' ', IFNULL(OLD.cust_lname, ''), ' deleted'));
END$$

-- --------------------------------------------------------- destination
DROP TRIGGER IF EXISTS trg_log_destination_insert$$
CREATE TRIGGER trg_log_destination_insert AFTER INSERT ON destination FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'destination', 'INSERT',
            CONCAT('Destination ', NEW.dst_id, ' ', IFNULL(NEW.dst_name, '')));
END$$

DROP TRIGGER IF EXISTS trg_log_destination_update$$
CREATE TRIGGER trg_log_destination_update AFTER UPDATE ON destination FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'destination', 'UPDATE',
            CONCAT('Destination ', NEW.dst_id, ' ', IFNULL(NEW.dst_name, ''), ' updated'));
END$$

DROP TRIGGER IF EXISTS trg_log_destination_delete$$
CREATE TRIGGER trg_log_destination_delete AFTER DELETE ON destination FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'destination', 'DELETE',
            CONCAT('Destination ', OLD.dst_id, ' ', IFNULL(OLD.dst_name, ''), ' deleted'));
END$$

-- ------------------------------------------------------------- vehicle
DROP TRIGGER IF EXISTS trg_log_vehicle_insert$$
CREATE TRIGGER trg_log_vehicle_insert AFTER INSERT ON vehicle FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'vehicle', 'INSERT',
            CONCAT('Vehicle ', NEW.v_id, ' ', NEW.v_license_plate, ' (', NEW.v_type, ', ', NEW.v_seats, ' seats)'));
END$$

DROP TRIGGER IF EXISTS trg_log_vehicle_update$$
CREATE TRIGGER trg_log_vehicle_update AFTER UPDATE ON vehicle FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'vehicle', 'UPDATE',
            CONCAT('Vehicle ', NEW.v_id, ' ', NEW.v_license_plate, ': status ', OLD.v_status, ' -> ', NEW.v_status,
                   ', mileage ', OLD.v_mileage, ' -> ', NEW.v_mileage));
END$$

DROP TRIGGER IF EXISTS trg_log_vehicle_delete$$
CREATE TRIGGER trg_log_vehicle_delete AFTER DELETE ON vehicle FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'vehicle', 'DELETE',
            CONCAT('Vehicle ', OLD.v_id, ' ', OLD.v_license_plate, ' deleted'));
END$$

-- ------------------------------------------------------------- lodging
DROP TRIGGER IF EXISTS trg_log_lodging_insert$$
CREATE TRIGGER trg_log_lodging_insert AFTER INSERT ON lodging FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'lodging', 'INSERT',
            CONCAT('Lodging ', NEW.lg_id, ' ', NEW.lg_name, ' (', NEW.lg_type, ', ', NEW.lg_city, ')'));
END$$

DROP TRIGGER IF EXISTS trg_log_lodging_update$$
CREATE TRIGGER trg_log_lodging_update AFTER UPDATE ON lodging FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'lodging', 'UPDATE',
            CONCAT('Lodging ', NEW.lg_id, ' ', NEW.lg_name, ': status ', OLD.lg_status, ' -> ', NEW.lg_status,
                   ', price ', OLD.lg_cost_per_night, ' -> ', NEW.lg_cost_per_night));
END$$

DROP TRIGGER IF EXISTS trg_log_lodging_delete$$
CREATE TRIGGER trg_log_lodging_delete AFTER DELETE ON lodging FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'lodging', 'DELETE',
            CONCAT('Lodging ', OLD.lg_id, ' ', OLD.lg_name, ' deleted'));
END$$

-- ---------------------------------------------- room_usage (bookings)
DROP TRIGGER IF EXISTS trg_log_room_usage_insert$$
CREATE TRIGGER trg_log_room_usage_insert AFTER INSERT ON room_usage FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'room_usage', 'INSERT',
            CONCAT('Trip ', NEW.ru_trip_id, ' booked lodging ', NEW.ru_lodging_id, ' ',
                   NEW.ru_checkin, ' -> ', NEW.ru_checkout, ', ', NEW.ru_rooms_count, ' room(s), ',
                   NEW.ru_nights, ' night(s), cost ', NEW.ru_total_cost));
END$$

DROP TRIGGER IF EXISTS trg_log_room_usage_update$$
CREATE TRIGGER trg_log_room_usage_update AFTER UPDATE ON room_usage FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'room_usage', 'UPDATE',
            CONCAT('Trip ', NEW.ru_trip_id, ' booking at lodging ', NEW.ru_lodging_id, ' updated'));
END$$

DROP TRIGGER IF EXISTS trg_log_room_usage_delete$$
CREATE TRIGGER trg_log_room_usage_delete AFTER DELETE ON room_usage FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (SUBSTRING_INDEX(USER(), '@', 1), 'room_usage', 'DELETE',
            CONCAT('Trip ', OLD.ru_trip_id, ' booking at lodging ', OLD.ru_lodging_id, ' (',
                   OLD.ru_checkin, ' -> ', OLD.ru_checkout, ') deleted'));
END$$

-- =====================================================================
-- 3.1.4.3  When a trip is completed and its final kilometres are recorded,
-- add them to the vehicle's mileage and set the vehicle back to Available.
-- =====================================================================
DROP TRIGGER IF EXISTS trg_complete_trip_vehicle_update$$
CREATE TRIGGER trg_complete_trip_vehicle_update AFTER UPDATE ON trip FOR EACH ROW
BEGIN
    IF NEW.tr_status = 'COMPLETED' AND OLD.tr_status <> 'COMPLETED' AND NEW.tr_vehicle_id IS NOT NULL THEN
        UPDATE vehicle
        SET v_status  = 'Available',
            v_mileage = v_mileage + IFNULL(NEW.tr_km, 0)
        WHERE v_id = NEW.tr_vehicle_id;
    END IF;
END$$

-- =====================================================================
-- Spec 3.1.2.2: lodging is attached only to city destinations, never to
-- country (parent) destinations, i.e. destinations that other destinations
-- point to through dst_location.
-- =====================================================================
DROP TRIGGER IF EXISTS trg_lodging_city_only_ins$$
CREATE TRIGGER trg_lodging_city_only_ins BEFORE INSERT ON lodging FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM destination WHERE dst_location = NEW.lg_dst_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: lodging must belong to a city destination, not a country.';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_lodging_city_only_upd$$
CREATE TRIGGER trg_lodging_city_only_upd BEFORE UPDATE ON lodging FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM destination WHERE dst_location = NEW.lg_dst_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: lodging must belong to a city destination, not a country.';
    END IF;
END$$


DELIMITER ;
