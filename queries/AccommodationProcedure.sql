USE baseisproject;

-- 3.1.3.2 Search for lodging with enough free rooms in a city and period
-- Free rooms = total rooms - rooms booked by other trips on overlapping dates.
-- p_first_lodging_id returns the first one of the list (NULL if none).

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_search_accommodation$$

CREATE PROCEDURE sp_search_accommodation(
    IN  p_dst_id           INT,
    IN  p_arrival          DATE,
    IN  p_departure        DATE,
    IN  p_required_rooms   INT,
    OUT p_first_lodging_id INT
)
BEGIN
    SET p_first_lodging_id = NULL;

    -- the best one (same query as the list below, first row only)
    SELECT lg_id INTO p_first_lodging_id
    FROM lodging l
    WHERE l.lg_dst_id = p_dst_id
      AND l.lg_status = 'Active'
      AND (l.lg_total_rooms - IFNULL((
              SELECT SUM(ru.ru_rooms_count)
              FROM room_usage ru
              WHERE ru.ru_lodging_id = l.lg_id
                AND ru.ru_checkin < p_departure AND ru.ru_checkout > p_arrival
          ), 0)) >= p_required_rooms
    ORDER BY l.lg_cost_per_night ASC, l.lg_stars DESC, l.lg_rating DESC
    LIMIT 1;

    -- the whole list
    SELECT
        l.lg_id             AS LodgingId,
        l.lg_name           AS Name,
        l.lg_type           AS Type,
        CONCAT(l.lg_address, ', ', l.lg_city, IFNULL(CONCAT(' ', l.lg_postal_code), '')) AS Address,
        l.lg_phone          AS Phone,
        l.lg_stars          AS Stars,
        l.lg_rating         AS Rating,
        l.lg_cost_per_night AS PricePerNight,
        CONCAT_WS(', ',
                  IF(l.lg_wifi = 1,              'WiFi',     NULL),
                  IF(l.lg_restaurant_bar = 1,    'Rest/Bar', NULL),
                  IF(l.lg_ac = 1,                'A/C',      NULL),
                  IF(l.lg_access_disability = 1, 'Access',   NULL)
        ) AS Amenities,
        (l.lg_total_rooms - IFNULL((
            SELECT SUM(ru.ru_rooms_count)
            FROM room_usage ru
            WHERE ru.ru_lodging_id = l.lg_id
              AND ru.ru_checkin < p_departure AND ru.ru_checkout > p_arrival
        ), 0)) AS AvailableRooms
    FROM lodging l
    WHERE l.lg_dst_id = p_dst_id
      AND l.lg_status = 'Active'
      AND (l.lg_total_rooms - IFNULL((
              SELECT SUM(ru.ru_rooms_count)
              FROM room_usage ru
              WHERE ru.ru_lodging_id = l.lg_id
                AND ru.ru_checkin < p_departure AND ru.ru_checkout > p_arrival
          ), 0)) >= p_required_rooms
    ORDER BY l.lg_cost_per_night ASC, l.lg_stars DESC, l.lg_rating DESC;
END$$

-- 3.1.4.2 Nights and cost of a new stay.
-- BEFORE INSERT because we change the row itself (NEW) before it is saved.

DROP TRIGGER IF EXISTS trg_calculate_accommodation_cost$$

CREATE TRIGGER trg_calculate_accommodation_cost
    BEFORE INSERT ON room_usage
    FOR EACH ROW
BEGIN
    DECLARE v_price_per_night DECIMAL(10,2);
    DECLARE v_nights INT;

    SELECT lg_cost_per_night INTO v_price_per_night
    FROM lodging WHERE lg_id = NEW.ru_lodging_id;

    SET v_nights = DATEDIFF(NEW.ru_checkout, NEW.ru_checkin);

    IF v_nights IS NULL OR v_nights < 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: check-out must be at least one day after check-in.';
    END IF;

    SET NEW.ru_nights     = v_nights;
    SET NEW.ru_total_cost = v_price_per_night * v_nights * NEW.ru_rooms_count;
END$$

DELIMITER ;
