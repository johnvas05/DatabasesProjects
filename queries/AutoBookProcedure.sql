USE baseisproject;

DELIMITER $$

CREATE PROCEDURE sp_book_trip_accommodation(
    IN p_trip_id INT
)
BEGIN
    -- Variables for cursor loop
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_dst_id INT;
    DECLARE v_arrival DATETIME;
    DECLARE v_departure DATETIME;

    -- Variables for booking logic
    DECLARE v_lodging_id INT;
    DECLARE v_rooms_needed INT;
    DECLARE v_reservation_count INT;

    -- Cursor: Get all destinations for this trip in chronological order
    DECLARE cur_destinations CURSOR FOR
        SELECT to_dst_id, to_arrival, to_departure
        FROM travel_to
        WHERE to_tr_id = p_trip_id
        ORDER BY to_arrival ASC;

    -- Handler to stop the loop
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- 1. Calculate Rooms Needed
    -- Count confirmed reservations for this trip
    SELECT COUNT(*) INTO v_reservation_count
    FROM reservation
    WHERE res_tr_id = p_trip_id AND res_status IN ('CONFIRMED', 'PAID');

    -- Assumption: 2 people per room (Standard travel agency logic)
    SET v_rooms_needed = CEIL(v_reservation_count / 2);

    -- Safety Check: If nobody is booked, stop.
    IF v_rooms_needed = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No confirmed reservations found for this trip.';
    END IF;

    -- Start Transaction (All or Nothing)
    START TRANSACTION;

    OPEN cur_destinations;

    read_loop: LOOP
        FETCH cur_destinations INTO v_dst_id, v_arrival, v_departure;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- 2. Find best accommodation
        -- Calls the Search Procedure we made in Step 3.1.3.2
        -- v_lodging_id will store the result
        CALL sp_search_accommodation(v_dst_id, DATE(v_arrival), DATE(v_departure), v_rooms_needed, v_lodging_id);

        -- 3. Check for Failure
        IF v_lodging_id IS NULL THEN
            -- FAILURE: No room found for this specific leg of the trip.
            -- Rollback: Delete any bookings already made for this trip ID
            DELETE FROM room_usage WHERE ru_trip_id = p_trip_id;

            CLOSE cur_destinations;
            COMMIT; -- Commit the deletion so the clean-up is saved

            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Error: Could not find accommodation for a destination. All bookings cancelled.';
        END IF;

        -- 4. Make the Reservation
        -- We insert with 0 cost. The TRIGGER (3.1.4.2) will calculate the cost automatically.
        INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count, ru_total_cost)
        VALUES (p_trip_id, v_lodging_id, DATE(v_arrival), DATE(v_departure), v_rooms_needed, 0);

    END LOOP;

    CLOSE cur_destinations;
    COMMIT; -- Save changes

    -- 5. Final Output (Success Summary)
    SELECT
        l.lg_name AS Accommodation,
        ru.ru_checkin AS CheckIn,
        ru.ru_checkout AS CheckOut,
        ru.ru_rooms_count AS Rooms,
        ru.ru_total_cost AS Cost
    FROM room_usage ru
             JOIN lodging l ON ru.ru_lodging_id = l.lg_id
    WHERE ru.ru_trip_id = p_trip_id;

    -- Show Grand Total
    SELECT SUM(ru_total_cost) AS 'Total Trip Accommodation Cost'
    FROM room_usage
    WHERE ru_trip_id = p_trip_id;

END$$

DELIMITER ;

UPDATE reservation r
    JOIN trip t ON r.res_tr_id = t.tr_id
    JOIN customer c ON r.res_cust_id = c.cust_id
SET r.res_total_cost = CASE
    -- If customer is > 18 years old, charge Adult price
                           WHEN DATEDIFF(CURDATE(), c.cust_birth_date) / 365.25 > 18 THEN t.tr_cost_adult
    -- Otherwise, charge Child price
                           ELSE t.tr_cost_child
    END;