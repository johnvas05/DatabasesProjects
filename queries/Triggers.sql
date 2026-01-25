USE baseisproject;

DELIMITER $$

-- 1a. Log INSERT on 'trip'
CREATE TRIGGER trg_log_trip_insert AFTER INSERT ON trip
    FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'trip', 'INSERT', CONCAT('New Trip ID: ', NEW.tr_id));
END$$

-- 1b. Log UPDATE on 'trip'
CREATE TRIGGER trg_log_trip_update AFTER UPDATE ON trip
    FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'trip', 'UPDATE', CONCAT('Trip ID: ', OLD.tr_id, ' Status changed from ', OLD.tr_status, ' to ', NEW.tr_status));
END$$

-- 1c. Log DELETE on 'trip'
CREATE TRIGGER trg_log_trip_delete AFTER DELETE ON trip
    FOR EACH ROW
BEGIN
    INSERT INTO log_actions (log_dba_username, log_table_name, log_action_type, log_details)
    VALUES (USER(), 'trip', 'DELETE', CONCAT('Deleted Trip ID: ', OLD.tr_id));
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_calculate_accommodation_cost
    BEFORE INSERT ON room_usage
    FOR EACH ROW
BEGIN
    DECLARE v_price_per_night DECIMAL(10,2);
    DECLARE v_nights INT;

    -- 1. Find the price per night for this lodging
    SELECT lg_cost_per_night INTO v_price_per_night
    FROM lodging
    WHERE lg_id = NEW.ru_lodging_id;

    -- 2. Calculate number of nights
    SET v_nights = DATEDIFF(NEW.ru_checkout, NEW.ru_checkin);

    -- 3. Calculate Total Cost
    -- Formula: Price * Nights * Rooms
    SET NEW.ru_total_cost = v_price_per_night * v_nights * NEW.ru_rooms_count;
END$$

DELIMITER ;

ALTER TABLE trip ADD COLUMN tr_km INT DEFAULT 0;

DELIMITER $$

CREATE TRIGGER trg_complete_trip_vehicle_update
    AFTER UPDATE ON trip
    FOR EACH ROW
BEGIN
    -- Check if status changed to COMPLETED
    IF NEW.tr_status = 'COMPLETED' AND OLD.tr_status != 'COMPLETED' THEN

        -- Update the vehicle used in this trip
        UPDATE vehicle
        SET
            v_status = 'Available',                 -- Free up the vehicle
            v_mileage = v_mileage + NEW.tr_km       -- Add trip distance to total mileage
        WHERE v_id = NEW.tr_vehicle_id;

    END IF;
END$$

DELIMITER ;