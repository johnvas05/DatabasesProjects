USE baseisproject;

-- 3.1.2.3 Trip history (completed trips)
-- No foreign key to trip: the 90 000 rows are made up and their ids are not
-- in trip, and the history should stay even if an old trip is deleted.
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

-- Fills the table with 90 000 random trips.
-- The return date is departure + 3..9 days so it is never before departure.
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

-- 3.1.3.4 (a) total revenue of the trips between two dates
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

-- 3.1.3.4 (b) dates of the trips with exactly N destinations
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

-- 3.1.3.4 Indexes
-- Each index has the WHERE column first and the selected column second, so
-- the query is answered from the index only ("Using index" in EXPLAIN).
-- We first tried one-column indexes but MySQL did not use them: each query
-- returns about 20% of the rows, so a full scan was cheaper.
CREATE INDEX idx_hist_dep_rev ON trip_history (th_departure, th_revenue);
CREATE INDEX idx_hist_dc_dep  ON trip_history (th_dest_count, th_departure);

-- examples
-- CALL sp_history_revenue('2021-01-01', '2021-12-31');
-- CALL sp_history_destinations(3);
-- EXPLAIN SELECT SUM(th_revenue) FROM trip_history WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
-- EXPLAIN SELECT th_departure FROM trip_history WHERE th_dest_count = 3;
