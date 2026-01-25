USE `baseis project`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_calculate_reservation_cost$$

-- Stored Procedure: Calculate reservation cost based on customer age
-- Automatically applies child or adult pricing
CREATE PROCEDURE sp_calculate_reservation_cost(
    IN p_trip_id INT,
    IN p_seat_num INT,
    IN p_cust_id INT
)
BEGIN
    UPDATE reservation r
        JOIN trip t ON r.res_tr_id = t.tr_id
        JOIN customer c ON r.res_cust_id = c.cust_id
    SET r.res_total_cost = CASE
        -- If customer is > 18 years old, charge Adult price
        WHEN DATEDIFF(CURDATE(), c.cust_birth_date) / 365.25 > 18 
            THEN t.tr_cost_adult
        -- Otherwise, charge Child price
        ELSE t.tr_cost_child
        END
    WHERE r.res_tr_id = p_trip_id 
      AND r.res_seatnum = p_seat_num
      AND r.res_cust_id = p_cust_id;
END$$

DELIMITER;