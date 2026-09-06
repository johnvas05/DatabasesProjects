USE baseisproject;

-- Salary increase guard: a raise is allowed only if the worker's branch is
-- profitable (sp_branch_financials) and the raise is at most 2%.

DELIMITER $$

DROP TRIGGER IF EXISTS trg_worker_salary_increase$$

CREATE TRIGGER trg_worker_salary_increase
    BEFORE UPDATE ON worker
    FOR EACH ROW
BEGIN
    DECLARE v_revenue      DECIMAL(10,2);
    DECLARE v_expenses     DECIMAL(10,2);
    DECLARE v_profit_ratio DECIMAL(10,4);
    DECLARE v_increase     DECIMAL(10,4);

    IF NEW.wrk_salary > OLD.wrk_salary THEN

        CALL sp_branch_financials(OLD.wrk_br_code, v_revenue, v_expenses, v_profit_ratio);

        IF v_profit_ratio IS NULL OR v_profit_ratio < 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Salary increase not allowed: branch is not profitable';
        END IF;

        SET v_increase = (NEW.wrk_salary - OLD.wrk_salary) / OLD.wrk_salary;

        IF v_increase > 0.02 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Salary increase exceeds 2% limit';
        END IF;

    END IF;
END$$

DELIMITER ;
