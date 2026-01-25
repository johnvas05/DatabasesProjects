USE baseisproject;

ALTER TABLE trip
    ADD COLUMN tr_vehicle_id INT,
    ADD FOREIGN KEY (tr_vehicle_id) REFERENCES vehicle(v_id);

DELIMITER $$

CREATE PROCEDURE sp_assign_vehicle_to_trip(
    IN p_trip_id INT,
    IN p_vehicle_id INT,
    IN p_current_mileage INT
)
BEGIN
    -- Variables to hold data for checks
    DECLARE v_seats INT;
    DECLARE v_vehicle_status ENUM('Available', 'InUse', 'Maintenance');
    DECLARE v_driver_license ENUM('A', 'B', 'C', 'D');
    DECLARE v_reservation_count INT;
    DECLARE v_trip_start DATETIME;
    DECLARE v_trip_end DATETIME;
    DECLARE v_driver_id CHAR(10);
    DECLARE v_overlap_count INT;

    -- 1. Get Trip Info (Driver, Dates)
    SELECT tr_drv_AT, tr_departure, tr_return
    INTO v_driver_id, v_trip_start, v_trip_end
    FROM trip WHERE tr_id = p_trip_id;

    -- 2. Get Vehicle Info (Seats, Status)
    SELECT v_seats, v_status
    INTO v_seats, v_vehicle_status
    FROM vehicle WHERE v_id = p_vehicle_id;

    -- 3. Get Driver License Info
    SELECT drv_license INTO v_driver_license
    FROM driver WHERE drv_AT = v_driver_id;

    -- 4. Count current reservations for this trip
    SELECT COUNT(*) INTO v_reservation_count
    FROM reservation
    WHERE res_tr_id = p_trip_id AND res_status IN ('CONFIRMED', 'PAID');

    -- START CHECKS --------------------------------------------

    -- Check A: Is the vehicle available?
    IF v_vehicle_status != 'Available' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Vehicle is not Available (InUse or Maintenance).';
    END IF;

    -- Check B: Are there enough seats?
    IF v_seats < v_reservation_count THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Vehicle capacity is insufficient for current reservations.';
    END IF;

    -- Check C: Driver License Check
    -- "For buses with > 9 seats, license C or D is required"
    IF v_seats > 9 AND v_driver_license NOT IN ('C', 'D') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Driver does not have the required license (C or D) for this vehicle.';
    END IF;

    -- Check D: Date Overlap
    -- Check if this vehicle is assigned to ANY other trip that overlaps with our dates
    SELECT COUNT(*) INTO v_overlap_count
    FROM trip
    WHERE tr_vehicle_id = p_vehicle_id
      AND tr_id != p_trip_id
      AND (
        (tr_departure BETWEEN v_trip_start AND v_trip_end) OR
        (tr_return BETWEEN v_trip_start AND v_trip_end) OR
        (v_trip_start BETWEEN tr_departure AND tr_return)
        );

    IF v_overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Vehicle is already assigned to another trip during this period.';
    END IF;

    -- IF ALL CHECKS PASS: -------------------------------------

    -- 1. Assign the vehicle to the trip
    UPDATE trip
    SET tr_vehicle_id = p_vehicle_id
    WHERE tr_id = p_trip_id;

    -- 2. Update Vehicle Status to 'InUse' and update Mileage
    UPDATE vehicle
    SET v_status = 'InUse',
        v_mileage = p_current_mileage
    WHERE v_id = p_vehicle_id;

    -- 3. Success Message
    SELECT 'Success: Vehicle assigned successfully.' AS result_message;

END$$

DELIMITER ;