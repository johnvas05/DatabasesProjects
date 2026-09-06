USE baseisproject;

-- =====================================================================
-- 3.1.3.1  Assign a vehicle to a trip
-- Arguments: trip id, vehicle id, current odometer reading of the vehicle.
-- Every check is evaluated and reported (PASS/FAIL result set). Only when
-- all checks pass is the vehicle assigned, set to 'InUse' and its mileage
-- recorded; otherwise the procedure raises an error listing the failures.
-- (The trip/trip.tr_vehicle_id and tr_km columns are added in cars.sql.)
-- =====================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_assign_vehicle_to_trip$$

CREATE PROCEDURE sp_assign_vehicle_to_trip(
    IN p_trip_id         INT,
    IN p_vehicle_id      INT,
    IN p_current_mileage INT
)
BEGIN
    DECLARE l_trip_exists       INT DEFAULT 0;
    DECLARE l_vehicle_exists    INT DEFAULT 0;
    DECLARE l_driver_id         CHAR(10);
    DECLARE l_driver_license    VARCHAR(2);
    DECLARE l_trip_start        DATETIME;
    DECLARE l_trip_end          DATETIME;
    DECLARE l_seats             INT;
    DECLARE l_vehicle_status    VARCHAR(20);
    DECLARE l_old_mileage       INT;
    DECLARE l_reservation_count INT;
    DECLARE l_overlap_count     INT;

    DECLARE chk_available VARCHAR(4) DEFAULT 'PASS';
    DECLARE chk_capacity  VARCHAR(4) DEFAULT 'PASS';
    DECLARE chk_license   VARCHAR(4) DEFAULT 'PASS';
    DECLARE chk_overlap   VARCHAR(4) DEFAULT 'PASS';
    DECLARE chk_mileage   VARCHAR(4) DEFAULT 'PASS';
    DECLARE l_failures    VARCHAR(255) DEFAULT '';

    -- 0. Existence of trip and vehicle
    SELECT COUNT(*) INTO l_trip_exists    FROM trip    WHERE tr_id = p_trip_id;
    SELECT COUNT(*) INTO l_vehicle_exists FROM vehicle WHERE v_id  = p_vehicle_id;
    IF l_trip_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: trip does not exist.';
    END IF;
    IF l_vehicle_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: vehicle does not exist.';
    END IF;

    -- 1. Gather data (table aliases avoid the column/variable name clash)
    SELECT t.tr_drv_AT, t.tr_departure, t.tr_return
      INTO l_driver_id, l_trip_start, l_trip_end
      FROM trip t WHERE t.tr_id = p_trip_id;

    SELECT v.v_seats, v.v_status, v.v_mileage
      INTO l_seats, l_vehicle_status, l_old_mileage
      FROM vehicle v WHERE v.v_id = p_vehicle_id;

    SELECT d.drv_license INTO l_driver_license
      FROM driver d WHERE d.drv_AT = l_driver_id;

    SELECT COUNT(*) INTO l_reservation_count
      FROM reservation r
     WHERE r.res_tr_id = p_trip_id AND r.res_status IN ('CONFIRMED', 'PAID');

    SELECT COUNT(*) INTO l_overlap_count
      FROM trip t
     WHERE t.tr_vehicle_id = p_vehicle_id
       AND t.tr_id <> p_trip_id
       AND t.tr_status NOT IN ('COMPLETED', 'CANCELLED')
       AND t.tr_departure < l_trip_end
       AND t.tr_return    > l_trip_start;

    -- 2. Checks
    IF l_vehicle_status <> 'Available' THEN
        SET chk_available = 'FAIL';
        SET l_failures = CONCAT(l_failures, 'vehicle is ', l_vehicle_status, '; ');
    END IF;

    IF l_seats < l_reservation_count THEN
        SET chk_capacity = 'FAIL';
        SET l_failures = CONCAT(l_failures, l_seats, ' seats < ', l_reservation_count, ' reservations; ');
    END IF;

    -- vehicles with more than 9 seats need a category C or D licence
    IF l_seats > 9 AND (l_driver_license IS NULL OR l_driver_license NOT IN ('C', 'D')) THEN
        SET chk_license = 'FAIL';
        SET l_failures = CONCAT(l_failures, 'driver licence ', IFNULL(l_driver_license, 'missing'), ' (C/D needed); ');
    END IF;

    IF l_overlap_count > 0 THEN
        SET chk_overlap = 'FAIL';
        SET l_failures = CONCAT(l_failures, 'overlaps ', l_overlap_count, ' other trip(s); ');
    END IF;

    IF p_current_mileage < l_old_mileage THEN
        SET chk_mileage = 'FAIL';
        SET l_failures = CONCAT(l_failures, 'mileage ', p_current_mileage, ' < recorded ', l_old_mileage, '; ');
    END IF;

    -- 3. Report the result of every check
    SELECT 'Vehicle available' AS check_name, chk_available AS result,
           CONCAT('vehicle status = ', l_vehicle_status) AS details
    UNION ALL
    SELECT 'Seat capacity', chk_capacity,
           CONCAT(l_seats, ' seats for ', l_reservation_count, ' confirmed/paid reservation(s)')
    UNION ALL
    SELECT 'Driver licence', chk_license,
           CONCAT('driver ', IFNULL(l_driver_id, '(none)'), ', licence ', IFNULL(l_driver_license, '(none)'),
                  IF(l_seats > 9, ' - C or D required', ' - any licence'))
    UNION ALL
    SELECT 'No date overlap', chk_overlap,
           CONCAT(l_overlap_count, ' other trip(s) use this vehicle in the same period')
    UNION ALL
    SELECT 'Mileage reading', chk_mileage,
           CONCAT('reading ', p_current_mileage, ' km, recorded ', l_old_mileage, ' km');

    -- 4. Assign only if everything passed
    IF l_failures <> '' THEN
        SET l_failures = LEFT(CONCAT('Assignment rejected: ', l_failures), 128);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = l_failures;
    END IF;

    UPDATE trip    SET tr_vehicle_id = p_vehicle_id WHERE tr_id = p_trip_id;
    UPDATE vehicle SET v_status = 'InUse', v_mileage = p_current_mileage WHERE v_id = p_vehicle_id;

    SELECT CONCAT('Success: vehicle ', p_vehicle_id, ' assigned to trip ', p_trip_id,
                  ' (status InUse, mileage ', p_current_mileage, ' km)') AS result_message;
END$$

DELIMITER ;
