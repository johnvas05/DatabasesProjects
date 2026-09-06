USE baseisproject;

-- =====================================================================
-- 3.1.2.3  Trip history
-- Completed trips: trip id, departure, return, number of destinations,
-- number of participants, total revenue. Holds more than 90 000 rows.
-- Design decision (allowed by the spec): no foreign key to trip, because the
-- history is filled by a generator with synthetic trip ids and must survive
-- the deletion of old trips.
-- =====================================================================
CREATE TABLE IF NOT EXISTS trip_history (
    th_id           INT AUTO_INCREMENT PRIMARY KEY,
    th_trip_id      INT NOT NULL,
    th_departure    DATETIME,
    th_return       DATETIME,
    th_dest_count   INT,
    th_participants INT,
    th_revenue      DECIMAL(12,2)
);

DELIMITER $$

-- Generator used to fill the table with 90 000 random completed trips.
DROP PROCEDURE IF EXISTS sp_generate_dummy_history$$
CREATE PROCEDURE sp_generate_dummy_history()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_dep DATETIME;

    WHILE i < 90000 DO
        SET v_dep = DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1500) DAY);
        INSERT INTO trip_history (th_trip_id, th_departure, th_return, th_dest_count, th_participants, th_revenue)
        VALUES (
            100000 + i,
            v_dep,
            DATE_ADD(v_dep, INTERVAL FLOOR(3 + RAND() * 7) DAY),
            FLOOR(1 + RAND() * 5),
            FLOOR(10 + RAND() * 40),
            FLOOR(1000 + RAND() * 10000)
        );
        SET i = i + 1;
    END WHILE;
END$$

-- =====================================================================
-- 3.1.3.4 (a)  Total revenue of the trips between two dates
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_history_revenue$$
CREATE PROCEDURE sp_history_revenue(
    IN p_start DATE,
    IN p_end   DATE
)
BEGIN
    SELECT SUM(th_revenue) AS TotalRevenue
    FROM trip_history
    WHERE th_departure BETWEEN p_start AND p_end;
END$$

-- =====================================================================
-- 3.1.3.4 (b)  Dates of the trips that had exactly N destinations
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_history_destinations$$
CREATE PROCEDURE sp_history_destinations(
    IN p_dest_count INT
)
BEGIN
    SELECT th_departure
    FROM trip_history
    WHERE th_dest_count = p_dest_count;
END$$

DELIMITER ;

-- =====================================================================
-- 3.1.3.4  Indexes
-- Both procedures are answered entirely from a *covering* index: the WHERE
-- column is the leading key column and the SELECTed column is the second,
-- so the optimizer never touches the table rows ("Using index" in EXPLAIN).
-- A single-column index on th_departure / th_dest_count was NOT used by the
-- optimizer on this data: a one-year range or one of five dest_count values
-- selects ~20-25% of the 90 000 rows, and a full scan is cheaper than that
-- many random row look-ups. With the covering indexes the plans become
-- range / ref scans on the index (measured ~3x faster, see tests/db_tests.sh).
-- =====================================================================
CREATE INDEX idx_hist_dep_rev ON trip_history (th_departure, th_revenue);
CREATE INDEX idx_hist_dc_dep  ON trip_history (th_dest_count, th_departure);

-- Examples
-- CALL sp_history_revenue('2021-01-01', '2021-12-31');
-- CALL sp_history_destinations(3);
-- EXPLAIN SELECT SUM(th_revenue) FROM trip_history WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
-- EXPLAIN SELECT th_departure FROM trip_history WHERE th_dest_count = 3;
