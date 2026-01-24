USE baseisproject;
DELIMITER $$

CREATE PROCEDURE sp_branch_financials (
    IN p_br_code INT,
    OUT p_revenue DECIMAL(10,2),
    OUT p_expenses DECIMAL(10,2),
    OUT p_profit_ratio DECIMAL(10,4)
)
BEGIN
    DECLARE v_exists INT;

    -- check if branch exists
    SELECT COUNT(*) INTO v_exists
    FROM branch
    WHERE br_code = p_br_code;

    IF v_exists = 0 THEN
        SET p_revenue = NULL;
        SET p_expenses = NULL;
        SET p_profit_ratio = NULL;
    ELSE
        -- revenues
        SELECT IFNULL(SUM(r.res_total_cost), 0)
        INTO p_revenue
        FROM reservation r
                 JOIN trip t ON r.res_tr_id = t.tr_id
        WHERE t.tr_br_code = p_br_code;

        -- expenses
        SELECT IFNULL(SUM(w.wrk_salary), 0)
        INTO p_expenses
        FROM worker w
        WHERE w.wrk_br_code = p_br_code;

        -- profit ratio
        IF p_expenses = 0 THEN
            SET p_profit_ratio = NULL;
        ELSE
            SET p_profit_ratio = (p_revenue - p_expenses) / p_expenses;
        END IF;
    END IF;
END$$

DELIMITER ;
