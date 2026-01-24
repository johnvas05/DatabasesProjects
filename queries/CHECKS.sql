USE baseisproject;

CALL sp_branch_financials(999, @rev, @exp, @profit);
SELECT @rev, @exp, @profit;

UPDATE worker
SET wrk_salary = wrk_salary * 1.01
WHERE wrk_AT = 'AT00000001';

INSERT INTO reservation
(res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES
    (1, 10, 1, 'PAID', 6000);


UPDATE worker
SET wrk_salary = wrk_salary * 1.02
WHERE wrk_AT = 'AT00000010';

SELECT wrk_AT, wrk_salary
FROM worker
WHERE wrk_AT = 'AT00000010';

UPDATE worker
SET wrk_salary = wrk_salary * 1.05
WHERE wrk_AT = 'AT00000010';

SELECT wrk_AT, wrk_salary, wrk_br_code
FROM worker
WHERE wrk_AT IN ('AT00000001', 'AT00000010');

SELECT t.tr_br_code, SUM(r.res_total_cost) AS revenue
FROM reservation r
         JOIN trip t ON r.res_tr_id = t.tr_id
GROUP BY t.tr_br_code;

SELECT wrk_br_code, SUM(wrk_salary) AS expenses
FROM worker
GROUP BY wrk_br_code;

CALL sp_branch_financials(999, @rev, @exp, @profit);
SELECT @rev, @exp, @profit;

DELETE FROM reservation
WHERE res_tr_id = 1 AND res_total_cost = 6000;


UPDATE worker
SET wrk_salary = wrk_salary * 1.01
WHERE wrk_AT = 'AT00000001';

INSERT INTO reservation
(res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost)
VALUES
    (1, 25, 1, 'PAID', 6000);

UPDATE worker
SET wrk_salary = wrk_salary * 1.02
WHERE wrk_AT = 'AT00000010';

SELECT wrk_AT, wrk_salary
FROM worker
WHERE wrk_AT = 'AT00000010';

UPDATE worker
SET wrk_salary = wrk_salary * 1.05
WHERE wrk_AT = 'AT00000010';



