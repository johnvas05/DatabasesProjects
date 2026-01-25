USE baseisproject;

DELIMITER $$

CREATE PROCEDURE sp_search_accommodation(
    IN p_dst_id INT,             -- Destination ID
    IN p_arrival DATE,           -- Arrival Date
    IN p_departure DATE,         -- Departure Date
    IN p_required_rooms INT,     -- Number of rooms needed
    OUT p_first_lodging_id INT   -- Output: ID of the top result
)
BEGIN
    -- Initialize output to NULL in case no results are found
    SET p_first_lodging_id = NULL;

    -- 1. Find the ID of the best matching accommodation (First result)
    -- We do this separately to set the OUT parameter
    SELECT lg_id INTO p_first_lodging_id
    FROM lodging l
    WHERE l.lg_dst_id = p_dst_id
      AND l.lg_status = 'Active'
      AND (l.lg_total_rooms - IFNULL((
                                         -- Subquery to sum up rooms ALREADY booked for these dates
                                         SELECT SUM(ru.ru_rooms_count)
                                         FROM room_usage ru
                                         WHERE ru.ru_lodging_id = l.lg_id
                                           AND (ru.ru_checkin < p_departure AND ru.ru_checkout > p_arrival) -- Overlap check
                                     ), 0)) >= p_required_rooms
    ORDER BY l.lg_cost_per_night ASC, l.lg_stars DESC, l.lg_rating DESC
    LIMIT 1;

    -- 2. Display the full list of results for the user
    SELECT
        l.lg_name AS Name,
        l.lg_type AS Type,
        l.lg_address AS Address,
        l.lg_phone AS Phone,
        l.lg_stars AS Stars,
        l.lg_rating AS Rating,
        l.lg_cost_per_night AS PricePerNight,
        -- Concatenate amenities for a cleaner display
        CONCAT_WS(', ',
                  IF(l.lg_wifi=1, 'WiFi', NULL),
                  IF(l.lg_restaurant_bar=1, 'Rest/Bar', NULL),
                  IF(l.lg_ac=1, 'A/C', NULL),
                  IF(l.lg_access_disability=1, 'Access', NULL)
        ) AS Amenities,
        -- Calculate and show the actual available rooms
        (l.lg_total_rooms - IFNULL((
                                       SELECT SUM(ru.ru_rooms_count)
                                       FROM room_usage ru
                                       WHERE ru.ru_lodging_id = l.lg_id
                                         AND (ru.ru_checkin < p_departure AND ru.ru_checkout > p_arrival)
                                   ), 0)) AS AvailableRooms
    FROM lodging l
    WHERE l.lg_dst_id = p_dst_id
      AND l.lg_status = 'Active'
      AND (l.lg_total_rooms - IFNULL((
                                         SELECT SUM(ru.ru_rooms_count)
                                         FROM room_usage ru
                                         WHERE ru.ru_lodging_id = l.lg_id
                                           AND (ru.ru_checkin < p_departure AND ru.ru_checkout > p_arrival)
                                     ), 0)) >= p_required_rooms
    ORDER BY l.lg_cost_per_night ASC, l.lg_stars DESC, l.lg_rating DESC;

END$$

DELIMITER ;


