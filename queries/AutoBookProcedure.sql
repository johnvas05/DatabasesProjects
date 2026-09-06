USE baseisproject;

-- =====================================================================
-- 3.1.3.3  Book accommodation for every destination of a trip
-- Argument: trip id.
-- For each destination (in visit order) the first lodging returned by
-- sp_search_accommodation (3.1.3.2) is booked. The nights and cost of each
-- booking are filled in by trg_calculate_accommodation_cost (3.1.4.2).
-- Rooms needed = CEIL(confirmed/paid reservations / 2)  (double rooms).
-- If any destination cannot be booked, every booking made for the trip is
-- deleted and an error explains which destination/period failed.
-- Existing bookings of the trip are replaced.
-- =====================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_book_trip_accommodation$$

CREATE PROCEDURE sp_book_trip_accommodation(
    IN p_trip_id INT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_dst_id            INT;
    DECLARE v_dst_name          VARCHAR(100);
    DECLARE v_arrival           DATETIME;
    DECLARE v_departure         DATETIME;
    DECLARE v_lodging_id        INT;
    DECLARE v_rooms_needed      INT;
    DECLARE v_reservation_count INT;
    DECLARE v_trip_exists       INT DEFAULT 0;
    DECLARE v_msg               VARCHAR(255);

    DECLARE cur_destinations CURSOR FOR
        SELECT tt.to_dst_id, d.dst_name, tt.to_arrival, tt.to_departure
        FROM travel_to tt
        JOIN destination d ON d.dst_id = tt.to_dst_id
        WHERE tt.to_tr_id = p_trip_id
        ORDER BY tt.to_sequence ASC, tt.to_arrival ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SELECT COUNT(*) INTO v_trip_exists FROM trip WHERE tr_id = p_trip_id;
    IF v_trip_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: trip does not exist.';
    END IF;

    -- 1. Rooms needed (2 persons per room)
    SELECT COUNT(*) INTO v_reservation_count
    FROM reservation
    WHERE res_tr_id = p_trip_id AND res_status IN ('CONFIRMED', 'PAID');

    SET v_rooms_needed = CEIL(v_reservation_count / 2);

    IF v_rooms_needed = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: no confirmed or paid reservations for this trip, nothing to book.';
    END IF;

    -- 2. Replace any previous bookings of this trip
    DELETE FROM room_usage WHERE ru_trip_id = p_trip_id;

    OPEN cur_destinations;

    read_loop: LOOP
        FETCH cur_destinations INTO v_dst_id, v_dst_name, v_arrival, v_departure;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- 3. Best available lodging for this leg
        CALL sp_search_accommodation(v_dst_id, DATE(v_arrival), DATE(v_departure), v_rooms_needed, v_lodging_id);

        IF v_lodging_id IS NULL THEN
            -- roll back everything booked so far for this trip
            DELETE FROM room_usage WHERE ru_trip_id = p_trip_id;
            CLOSE cur_destinations;
            SET v_msg = LEFT(CONCAT('Error: no lodging in ', v_dst_name, ' with ', v_rooms_needed,
                                    ' free room(s) for ', DATE(v_arrival), ' to ', DATE(v_departure),
                                    '. All bookings of the trip were cancelled.'), 128);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;

        -- 4. Book it (nights and cost are computed by the trigger)
        INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count)
        VALUES (p_trip_id, v_lodging_id, DATE(v_arrival), DATE(v_departure), v_rooms_needed);
    END LOOP;

    CLOSE cur_destinations;

    -- 5. One line per booked lodging
    SELECT
        l.lg_name          AS Accommodation,
        d.dst_name         AS Destination,
        ru.ru_checkin      AS CheckIn,
        ru.ru_checkout     AS CheckOut,
        ru.ru_nights       AS Nights,
        ru.ru_rooms_count  AS Rooms,
        ru.ru_total_cost   AS Cost
    FROM room_usage ru
    JOIN lodging l     ON l.lg_id = ru.ru_lodging_id
    JOIN destination d ON d.dst_id = l.lg_dst_id
    WHERE ru.ru_trip_id = p_trip_id
    ORDER BY ru.ru_checkin;

    -- 6. Total accommodation cost of the trip
    SELECT SUM(ru_total_cost) AS TotalTripAccommodationCost
    FROM room_usage
    WHERE ru_trip_id = p_trip_id;
END$$

DELIMITER ;
