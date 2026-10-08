USE baseisproject;

-- Price of a reservation: adult price from 18 years old, else child price.
-- No birth date -> adult price. Called by the GUI after a new reservation.

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_calculate_reservation_cost$$

CREATE PROCEDURE sp_calculate_reservation_cost(
    IN p_trip_id  INT,
    IN p_seat_num INT,
    IN p_cust_id  INT
)
BEGIN
    UPDATE reservation r
        JOIN trip t     ON r.res_tr_id   = t.tr_id
        JOIN customer c ON r.res_cust_id = c.cust_id
    SET r.res_total_cost = CASE
            WHEN c.cust_birth_date IS NULL
              OR TIMESTAMPDIFF(YEAR, c.cust_birth_date, CURDATE()) >= 18
            THEN t.tr_cost_adult
            ELSE t.tr_cost_child
        END
    WHERE r.res_tr_id   = p_trip_id
      AND r.res_seatnum = p_seat_num
      AND r.res_cust_id = p_cust_id;
END$$

DELIMITER ;
