USE baseisproject;
CREATE TABLE trip_history (
                              th_id INT AUTO_INCREMENT PRIMARY KEY,       -- Unique ID for the history log
                              th_trip_id INT NOT NULL,                    -- The ID of the original trip
                              th_departure DATETIME,                      -- When it departed
                              th_return DATETIME,                         -- When it returned
                              th_dest_count INT,                          -- Calculated count of destinations
                              th_participants INT,                        -- Calculated count of people
                              th_revenue DECIMAL(12,2),                   -- Final revenue calculated

    -- The "Realistic" Foreign Key Constraint
    -- This ensures every history record corresponds to a real trip in the 'trip' table.
                              FOREIGN KEY (th_trip_id) REFERENCES trip(tr_id)
                                  ON DELETE CASCADE                       -- If the trip is deleted, the history is also removed
);

DELIMITER $$

-- Procedure A: Revenue between two dates
CREATE PROCEDURE sp_history_revenue(
    IN p_start DATE,
    IN p_end DATE
)
BEGIN
    SELECT SUM(th_revenue) AS TotalRevenue
    FROM trip_history
    WHERE th_departure BETWEEN p_start AND p_end;
END$$

-- Procedure B: Find trips with specific number of destinations
CREATE PROCEDURE sp_history_destinations(
    IN p_dest_count INT
)
BEGIN
    SELECT th_departure
    FROM trip_history
    WHERE th_dest_count = p_dest_count;
END$$

DELIMITER ;

-- Test A: Large date range
CALL sp_history_revenue('2020-01-01', '2025-01-01');

-- Test B: Find trips with exactly 3 destinations
CALL sp_history_destinations(3);

-- Index for Procedure A (Dates)
CREATE INDEX idx_history_departure ON trip_history(th_departure);

-- Index for Procedure B (Destination Count)
CREATE INDEX idx_history_dest_count ON trip_history(th_dest_count);

