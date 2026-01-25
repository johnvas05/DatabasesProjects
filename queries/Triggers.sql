DELIMITER $$

-- ==========================================
-- LOG TRIGGERS FOR RESERVATION
-- ==========================================
CREATE TRIGGER trg_log_reservation_insert AFTER INSERT ON reservation FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'reservation', 'INSERT', CONCAT('New Res TripID: ', NEW.res_tr_id, ' CustID: ', NEW.res_cust_id));
END$$

CREATE TRIGGER trg_log_reservation_update AFTER UPDATE ON reservation FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'reservation', 'UPDATE', CONCAT('Res TripID: ', NEW.res_tr_id, ' Status: ', OLD.res_status, '->', NEW.res_status));
END$$

CREATE TRIGGER trg_log_reservation_delete AFTER DELETE ON reservation FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'reservation', 'DELETE', CONCAT('Deleted Res TripID: ', OLD.res_tr_id));
END$$

-- ==========================================
-- LOG TRIGGERS FOR CUSTOMER
-- ==========================================
CREATE TRIGGER trg_log_customer_insert AFTER INSERT ON customer FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'customer', 'INSERT', CONCAT('New Customer: ', NEW.cust_lname));
END$$

CREATE TRIGGER trg_log_customer_update AFTER UPDATE ON customer FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'customer', 'UPDATE', CONCAT('Customer ID: ', NEW.cust_id, ' Updated'));
END$$

CREATE TRIGGER trg_log_customer_delete AFTER DELETE ON customer FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'customer', 'DELETE', CONCAT('Deleted Customer ID: ', OLD.cust_id));
END$$

-- ==========================================
-- LOG TRIGGERS FOR DESTINATION
-- ==========================================
CREATE TRIGGER trg_log_destination_insert AFTER INSERT ON destination FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'destination', 'INSERT', CONCAT('New Dest: ', NEW.dst_name));
END$$

CREATE TRIGGER trg_log_destination_update AFTER UPDATE ON destination FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'destination', 'UPDATE', CONCAT('Dest ID: ', NEW.dst_id, ' Updated'));
END$$

CREATE TRIGGER trg_log_destination_delete AFTER DELETE ON destination FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'destination', 'DELETE', CONCAT('Deleted Dest: ', OLD.dst_name));
END$$

-- ==========================================
-- LOG TRIGGERS FOR VEHICLE
-- ==========================================
CREATE TRIGGER trg_log_vehicle_insert AFTER INSERT ON vehicle FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'vehicle', 'INSERT', CONCAT('New Vehicle: ', NEW.v_license_plate));
END$$

CREATE TRIGGER trg_log_vehicle_update AFTER UPDATE ON vehicle FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'vehicle', 'UPDATE', CONCAT('Vehicle: ', NEW.v_license_plate, ' Status: ', NEW.v_status));
END$$

CREATE TRIGGER trg_log_vehicle_delete AFTER DELETE ON vehicle FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'vehicle', 'DELETE', CONCAT('Deleted Vehicle: ', OLD.v_license_plate));
END$$

-- ==========================================
-- LOG TRIGGERS FOR LODGING
-- ==========================================
CREATE TRIGGER trg_log_lodging_insert AFTER INSERT ON lodging FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'lodging', 'INSERT', CONCAT('New Lodging: ', NEW.lg_name));
END$$

CREATE TRIGGER trg_log_lodging_update AFTER UPDATE ON lodging FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'lodging', 'UPDATE', CONCAT('Lodging: ', NEW.lg_name, ' Updated'));
END$$

CREATE TRIGGER trg_log_lodging_delete AFTER DELETE ON lodging FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'lodging', 'DELETE', CONCAT('Deleted Lodging: ', OLD.lg_name));
END$$

-- ==========================================
-- LOG TRIGGERS FOR ROOM_USAGE
-- ==========================================
CREATE TRIGGER trg_log_room_usage_insert AFTER INSERT ON room_usage FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'room_usage', 'INSERT', CONCAT('Booked Trip: ', NEW.ru_trip_id, ' Hotel: ', NEW.ru_lodging_id));
END$$

CREATE TRIGGER trg_log_room_usage_update AFTER UPDATE ON room_usage FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'room_usage', 'UPDATE', CONCAT('Updated Booking Trip: ', NEW.ru_trip_id));
END$$

CREATE TRIGGER trg_log_room_usage_delete AFTER DELETE ON room_usage FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'room_usage', 'DELETE', CONCAT('Deleted Booking Trip: ', OLD.ru_trip_id));
END$$

DELIMITER ;