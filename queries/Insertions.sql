USE baseisproject;

DELIMITER $$

CREATE PROCEDURE sp_generate_dummy_history()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_tr_id INT;

    -- temporarily disable safety checks to speed up the massive insertion
    SET FOREIGN_KEY_CHECKS = 0;
    SET UNIQUE_CHECKS = 0;
    SET SQL_LOG_BIN = 0;

    -- Loop 90,000 times
    WHILE i < 90000 DO
            -- A. Create a Dummy Trip
            INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_br_code)
            VALUES (
                       DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1500) DAY), -- Random Departure
                       DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1500) + 7 DAY), -- Random Return
                       50,
                       FLOOR(100 + RAND() * 400), -- Random Adult Cost (100-500)
                       FLOOR(50 + RAND() * 200),  -- Random Child Cost (50-250)
                       'COMPLETED',
                       1 -- Branch Code (Using 1 for simplicity)
                   );

            SET v_tr_id = LAST_INSERT_ID();

            -- B. Create the History Record for that trip
            INSERT INTO trip_history (th_trip_id, th_departure, th_return, th_dest_count, th_participants, th_revenue)
            VALUES (
                       v_tr_id,
                       (SELECT tr_departure FROM trip WHERE tr_id = v_tr_id),
                       (SELECT tr_return FROM trip WHERE tr_id = v_tr_id),
                       FLOOR(1 + RAND() * 5),       -- Random destinations (1-5)
                       FLOOR(10 + RAND() * 40),     -- Random participants (10-50)
                       FLOOR(1000 + RAND() * 10000) -- Random Revenue (1000-11000)
                   );

            SET i = i + 1;
        END WHILE;

    -- Re-enable safety checks
    SET FOREIGN_KEY_CHECKS = 1;
    SET UNIQUE_CHECKS = 1;
    SET SQL_LOG_BIN = 1;

    SELECT 'Success: 90,000 records generated.' AS msg;
END$$

DELIMITER ;

CALL sp_generate_dummy_history();

-- 1. Register yourself as DBA (Crucial for triggers!)
INSERT IGNORE INTO dba_users (dba_username, dba_start_date) VALUES (USER(), CURDATE());

-- 2. Clean Slate (Empty tables to avoid duplicate ID errors)
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE reservation;
TRUNCATE TABLE event;
TRUNCATE TABLE travel_to;
TRUNCATE TABLE trip;
TRUNCATE TABLE vehicle;
TRUNCATE TABLE languages;
TRUNCATE TABLE phones;
TRUNCATE TABLE manages;
TRUNCATE TABLE admin;
TRUNCATE TABLE driver;
TRUNCATE TABLE guide;
TRUNCATE TABLE worker;
TRUNCATE TABLE branch;
TRUNCATE TABLE destination;
TRUNCATE TABLE customer;
TRUNCATE TABLE language_ref;
TRUNCATE TABLE lodging;
TRUNCATE TABLE room_usage;
SET FOREIGN_KEY_CHECKS = 1;

-- Languages (Target: 6)
INSERT INTO language_ref (lang_code, lang_name) VALUES
                                                    ('EN', 'English'), ('FR', 'French'), ('DE', 'German'),
                                                    ('IT', 'Italian'), ('ES', 'Spanish'), ('GR', 'Greek');

-- Branches (Target: 6)
INSERT INTO branch (br_code, br_street, br_num, br_city) VALUES
                                                             (1, 'Panepistimiou', 56, 'Athens'),
                                                             (2, 'Tsimiski', 22, 'Thessaloniki'),
                                                             (3, 'Maizonos', 10, 'Patras'),
                                                             (4, 'Dikaiosinis', 5, 'Heraklion'),
                                                             (5, 'Dodonis', 33, 'Ioannina'),
                                                             (6, 'Farsalon', 12, 'Larisa');

-- Branch Phones (Target: 10)
INSERT INTO phones (ph_br_code, ph_number) VALUES
                                               (1, '2101234567'), (1, '2107654321'), (2, '2310123456'), (2, '2310999888'),
                                               (3, '2610111222'), (4, '2810333444'), (5, '2651055566'), (6, '2410777888'),
                                               (1, '2109990000'), (2, '2310888777');

-- Destinations (Target: 10)
INSERT INTO destination (dst_name, dst_descr, dst_rtype, dst_language_code, dst_location) VALUES
                                                                                              ('Paris', 'France', 'ABROAD', 'FR', NULL),
                                                                                              ('London', 'UK', 'ABROAD', 'EN', NULL),
                                                                                              ('Berlin', 'Germany', 'ABROAD', 'DE', NULL),
                                                                                              ('Rome', 'Italy', 'ABROAD', 'IT', NULL),
                                                                                              ('Madrid', 'Spain', 'ABROAD', 'ES', NULL),
                                                                                              ('Nafplio', 'Peloponnese', 'LOCAL', 'GR', NULL),
                                                                                              ('Meteora', 'Thessaly', 'LOCAL', 'GR', NULL),
                                                                                              ('Delphi', 'Central Greece', 'LOCAL', 'GR', NULL),
                                                                                              ('New York', 'USA', 'ABROAD', 'EN', NULL),
                                                                                              ('Tokyo', 'Japan', 'ABROAD', 'EN', NULL);

-- 1. Insert 26 Base Workers (AT101 to AT126)
-- Admins (10)
INSERT INTO worker VALUES ('AT101', 'Nikos', 'Papadopoulos', 'nikos@ag.gr', 1500, 1);
INSERT INTO worker VALUES ('AT102', 'Maria', 'Georgiou', 'maria@ag.gr', 1400, 2);
INSERT INTO worker VALUES ('AT103', 'Yannis', 'Dimitriou', 'yannis@ag.gr', 1400, 3);
INSERT INTO worker VALUES ('AT104', 'Eleni', 'Alexiou', 'eleni@ag.gr', 1400, 4);
INSERT INTO worker VALUES ('AT105', 'Kostas', 'Kostas', 'kostas@ag.gr', 1400, 5);
INSERT INTO worker VALUES ('AT106', 'Anna', 'Vissi', 'anna@ag.gr', 1400, 6);
INSERT INTO worker VALUES ('AT107', 'Giorgos', 'Mazon', 'giorgos@ag.gr', 1200, 1);
INSERT INTO worker VALUES ('AT108', 'Despina', 'Vandi', 'despina@ag.gr', 1200, 1);
INSERT INTO worker VALUES ('AT109', 'Sakis', 'Rouvas', 'sakis@ag.gr', 1200, 2);
INSERT INTO worker VALUES ('AT110', 'Helena', 'Rizou', 'helena@ag.gr', 1200, 2);

-- Drivers (8)
INSERT INTO worker VALUES ('AT111', 'Takis', 'Volanis', 'takis@ag.gr', 1000, 1);
INSERT INTO worker VALUES ('AT112', 'Makis', 'Dimas', 'makis@ag.gr', 1000, 1);
INSERT INTO worker VALUES ('AT113', 'Lakis', 'Lazopoulos', 'lakis@ag.gr', 1000, 2);
INSERT INTO worker VALUES ('AT114', 'Akis', 'Petretzikis', 'akis@ag.gr', 1000, 2);
INSERT INTO worker VALUES ('AT115', 'Sakis', 'Boulas', 'sb@ag.gr', 1000, 3);
INSERT INTO worker VALUES ('AT116', 'Vakis', 'Vakakis', 'vv@ag.gr', 1000, 4);
INSERT INTO worker VALUES ('AT117', 'Mimis', 'Plessas', 'mp@ag.gr', 1000, 5);
INSERT INTO worker VALUES ('AT118', 'Babis', 'Stokas', 'bs@ag.gr', 1000, 6);

-- Guides (8)
INSERT INTO worker VALUES ('AT119', 'Zoi', 'Laskari', 'zoi@ag.gr', 1100, 1);
INSERT INTO worker VALUES ('AT120', 'Aliki', 'Vougiou', 'aliki@ag.gr', 1100, 1);
INSERT INTO worker VALUES ('AT121', 'Tzeni', 'Karezi', 'tzeni@ag.gr', 1100, 2);
INSERT INTO worker VALUES ('AT122', 'Rena', 'Vlachop', 'rena@ag.gr', 1100, 3);
INSERT INTO worker VALUES ('AT123', 'Dinos', 'Iliop', 'dinos@ag.gr', 1100, 4);
INSERT INTO worker VALUES ('AT124', 'Thanasis', 'Veggos', 'than@ag.gr', 1100, 5);
INSERT INTO worker VALUES ('AT125', 'Lambros', 'Konstan', 'lam@ag.gr', 1100, 6);
INSERT INTO worker VALUES ('AT126', 'Kostas', 'Voutsas', 'kv@ag.gr', 1100, 1);

-- 2. Assign Roles
-- Admins (10)
INSERT INTO admin (adm_AT, adm_type, adm_diploma) VALUES
                                                      ('AT101', 'ADMINISTRATIVE', 'MBA'), ('AT102', 'ACCOUNTING', 'Econ'),
                                                      ('AT103', 'LOGISTICS', 'Logistics'), ('AT104', 'ADMINISTRATIVE', 'BSc'),
                                                      ('AT105', 'LOGISTICS', 'MSc'), ('AT106', 'ACCOUNTING', 'PhD'),
                                                      ('AT107', 'ADMINISTRATIVE', 'Diploma'), ('AT108', 'LOGISTICS', 'Cert'),
                                                      ('AT109', 'ACCOUNTING', 'BSc'), ('AT110', 'ADMINISTRATIVE', 'MBA');

-- Managers (6) - Assigning Admins to manage branches
INSERT INTO manages (mng_adm_AT, mng_br_code) VALUES
                                                  ('AT101', 1), ('AT102', 2), ('AT103', 3),
                                                  ('AT104', 4), ('AT105', 5), ('AT106', 6);

UPDATE branch SET br_manager_AT = 'AT101' WHERE br_code = 1;
UPDATE branch SET br_manager_AT = 'AT102' WHERE br_code = 2;
UPDATE branch SET br_manager_AT = 'AT103' WHERE br_code = 3;
UPDATE branch SET br_manager_AT = 'AT104' WHERE br_code = 4;
UPDATE branch SET br_manager_AT = 'AT105' WHERE br_code = 5;
UPDATE branch SET br_manager_AT = 'AT106' WHERE br_code = 6;

-- Drivers (8)
INSERT INTO driver (drv_AT, drv_license, drv_route, drv_experience) VALUES
                                                                        ('AT111', 'D', 'ABROAD', 10), ('AT112', 'C', 'LOCAL', 5),
                                                                        ('AT113', 'D', 'ABROAD', 12), ('AT114', 'B', 'LOCAL', 3),
                                                                        ('AT115', 'D', 'ABROAD', 8), ('AT116', 'C', 'LOCAL', 4),
                                                                        ('AT117', 'D', 'ABROAD', 15), ('AT118', 'B', 'LOCAL', 2);

-- Guides (8)
INSERT INTO guide (gui_AT, gui_cv) VALUES
                                       ('AT119', 'Art Hist'), ('AT120', 'Arch'), ('AT121', 'Lang'), ('AT122', 'Hist'),
                                       ('AT123', 'Geog'), ('AT124', 'Culture'), ('AT125', 'Nature'), ('AT126', 'Food');

-- Guide Languages
INSERT INTO languages (lng_gui_AT, lng_language_code) VALUES
                                                          ('AT119', 'FR'), ('AT120', 'EN'), ('AT121', 'DE'), ('AT122', 'IT'),
                                                          ('AT123', 'ES'), ('AT124', 'GR'), ('AT125', 'EN'), ('AT126', 'FR');

-- Vehicles (10 Vehicles)
INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats, v_status, v_mileage) VALUES
                                                                                                             (1, 'IAA-1001', 'Tourismo', 'Mercedes', 'Bus', 50, 'Available', 150000),
                                                                                                             (1, 'IAA-1002', 'Sprinter', 'Mercedes', 'Mini-Bus', 20, 'Available', 80000),
                                                                                                             (2, 'IBB-2001', 'Transit', 'Ford', 'Van', 9, 'Available', 45000),
                                                                                                             (2, 'IBB-2002', 'Irizar', 'Scania', 'Bus', 55, 'Maintenance', 200000),
                                                                                                             (3, 'ICC-3001', 'Vito', 'Mercedes', 'Van', 8, 'Available', 30000),
                                                                                                             (3, 'ICC-3002', 'Setra', 'Setra', 'Bus', 60, 'Available', 120000),
                                                                                                             (4, 'IDD-4001', 'Daily', 'Iveco', 'Mini-Bus', 18, 'Available', 50000),
                                                                                                             (5, 'IEE-5001', 'Traveller', 'Peugeot', 'Van', 9, 'Available', 20000),
                                                                                                             (6, 'IFF-6001', 'Lion', 'Man', 'Bus', 52, 'Available', 90000),
                                                                                                             (1, 'IAA-1003', 'Yaris', 'Toyota', 'Car', 5, 'Available', 10000);

-- Customers (Target: 20)
INSERT INTO customer (cust_name, cust_lname, cust_phone) VALUES
                                                             ('C1', 'Lname1', '6901'), ('C2', 'Lname2', '6902'), ('C3', 'Lname3', '6903'),
                                                             ('C4', 'Lname4', '6904'), ('C5', 'Lname5', '6905'), ('C6', 'Lname6', '6906'),
                                                             ('C7', 'Lname7', '6907'), ('C8', 'Lname8', '6908'), ('C9', 'Lname9', '6909'),
                                                             ('C10', 'Lname10', '6910'), ('C11', 'Lname11', '6911'), ('C12', 'Lname12', '6912'),
                                                             ('C13', 'Lname13', '6913'), ('C14', 'Lname14', '6914'), ('C15', 'Lname15', '6915'),
                                                             ('C16', 'Lname16', '6916'), ('C17', 'Lname17', '6917'), ('C18', 'Lname18', '6918'),
                                                             ('C19', 'Lname19', '6919'), ('C20', 'Lname20', '6920');

-- Trips (Target: 14)
-- We map different drivers (AT111-AT118) and guides (AT119-AT126) and vehicles.
INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_br_code, tr_gui_AT, tr_drv_AT, tr_vehicle_id) VALUES
                                                                                                                                                      ('2026-06-01', '2026-06-10', 50, 500, 300, 'PLANNED', 1, 'AT119', 'AT111', 1),
                                                                                                                                                      ('2026-06-05', '2026-06-12', 20, 400, 200, 'CONFIRMED', 1, 'AT120', 'AT112', 2),
                                                                                                                                                      ('2026-06-10', '2026-06-15', 50, 600, 350, 'COMPLETED', 2, 'AT121', 'AT113', 4),
                                                                                                                                                      ('2026-07-01', '2026-07-05', 9, 300, 150, 'PLANNED', 2, 'AT122', 'AT114', 3),
                                                                                                                                                      ('2026-07-05', '2026-07-10', 60, 550, 275, 'PLANNED', 3, 'AT123', 'AT115', 6),
                                                                                                                                                      ('2026-07-15', '2026-07-20', 8, 250, 125, 'COMPLETED', 3, 'AT124', 'AT115', 5),
                                                                                                                                                      ('2026-08-01', '2026-08-08', 18, 450, 225, 'PLANNED', 4, 'AT125', 'AT116', 7),
                                                                                                                                                      ('2026-08-10', '2026-08-15', 9, 350, 175, 'CONFIRMED', 5, 'AT126', 'AT117', 8),
                                                                                                                                                      ('2026-09-01', '2026-09-10', 52, 700, 350, 'PLANNED', 6, 'AT119', 'AT118', 9),
                                                                                                                                                      ('2026-09-15', '2026-09-20', 5, 200, 100, 'COMPLETED', 1, 'AT120', 'AT111', 10),
                                                                                                                                                      ('2026-10-01', '2026-10-10', 50, 500, 250, 'PLANNED', 1, 'AT121', 'AT112', 1),
                                                                                                                                                      ('2026-11-01', '2026-11-05', 20, 300, 150, 'PLANNED', 2, 'AT122', 'AT113', 2),
                                                                                                                                                      ('2026-12-20', '2026-12-27', 50, 800, 400, 'PLANNED', 3, 'AT123', 'AT115', 6),
                                                                                                                                                      ('2027-01-05', '2027-01-10', 50, 600, 300, 'PLANNED', 4, 'AT124', 'AT116', 9);

-- Link Destinations (One per trip to satisfy 'Travel_To' target of 14)
INSERT INTO travel_to (to_tr_id, to_dst_id, to_arrival, to_departure) VALUES
                                                                          (1,1,NOW(),NOW()), (2,2,NOW(),NOW()), (3,3,NOW(),NOW()), (4,4,NOW(),NOW()),
                                                                          (5,5,NOW(),NOW()), (6,6,NOW(),NOW()), (7,7,NOW(),NOW()), (8,8,NOW(),NOW()),
                                                                          (9,9,NOW(),NOW()), (10,10,NOW(),NOW()), (11,1,NOW(),NOW()), (12,2,NOW(),NOW()),
                                                                          (13,3,NOW(),NOW()), (14,4,NOW(),NOW());

-- Reservations (Target: 24)
INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status) VALUES
                                                                              (1,1,1,'CONFIRMED'), (1,2,2,'CONFIRMED'), (1,3,3,'PENDING'),
                                                                              (2,1,4,'CONFIRMED'), (2,2,5,'PAID'),
                                                                              (3,1,6,'PAID'), (3,2,7,'PAID'), (3,3,8,'PAID'), -- Changed from COMPLETED
                                                                              (4,1,9,'CONFIRMED'),
                                                                              (5,1,10,'CONFIRMED'), (5,2,11,'CONFIRMED'),
                                                                              (6,1,12,'PAID'), -- Changed from COMPLETED
                                                                              (7,1,13,'CONFIRMED'), (7,2,14,'CONFIRMED'),
                                                                              (8,1,15,'CONFIRMED'),
                                                                              (9,1,16,'CONFIRMED'), (9,2,17,'PENDING'),
                                                                              (10,1,18,'PAID'), -- Changed from COMPLETED
                                                                              (11,1,19,'CONFIRMED'),
                                                                              (12,1,20,'CONFIRMED'),
                                                                              (13,1,1,'PAID'), (13,2,2,'PAID'),
                                                                              (14,1,3,'CONFIRMED'), (14,2,4,'PENDING');

-- Events (Target: 20)
-- Just adding generic events for the first 10 trips (2 per trip)
INSERT INTO event (ev_tr_id, ev_start, ev_end, ev_descr) VALUES
                                                             (1, '2026-06-02 10:00', '2026-06-02 12:00', 'Museum'), (1, '2026-06-03 18:00', '2026-06-03 20:00', 'Dinner'),
                                                             (2, '2026-06-06 10:00', '2026-06-06 12:00', 'Walk'), (2, '2026-06-07 18:00', '2026-06-07 20:00', 'Show'),
                                                             (3, '2026-06-11 10:00', '2026-06-11 12:00', 'Tour'), (3, '2026-06-12 18:00', '2026-06-12 20:00', 'Party'),
                                                             (4, '2026-07-02 10:00', '2026-07-02 12:00', 'Visit'), (4, '2026-07-03 18:00', '2026-07-03 20:00', 'Eat'),
                                                             (5, '2026-07-06 10:00', '2026-07-06 12:00', 'Swim'), (5, '2026-07-07 18:00', '2026-07-07 20:00', 'Drink'),
                                                             (6, '2026-07-16 10:00', '2026-07-16 12:00', 'Run'), (6, '2026-07-17 18:00', '2026-07-17 20:00', 'Sleep'),
                                                             (7, '2026-08-02 10:00', '2026-08-02 12:00', 'Hike'), (7, '2026-08-03 18:00', '2026-08-03 20:00', 'Camp'),
                                                             (8, '2026-08-11 10:00', '2026-08-11 12:00', 'Drive'), (8, '2026-08-12 18:00', '2026-08-12 20:00', 'Stop'),
                                                             (9, '2026-09-02 10:00', '2026-09-02 12:00', 'Fly'), (9, '2026-09-03 18:00', '2026-09-03 20:00', 'Land');

-- 1. Update Emails (Pattern: name.lname@mail.com)
UPDATE customer
SET cust_email = CONCAT(LOWER(cust_name), '.', LOWER(cust_lname), '@mail.com');

-- 2. Update Addresses (Generic dummy addresses)
UPDATE customer
SET cust_address = CONCAT('Street ', cust_id, ', City ', (cust_id % 5) + 1);

-- 3. Update Birth Dates (Crucial for Pricing)
-- We will make the first 15 customers Adults (born 1980-1990)
UPDATE customer
SET cust_birth_date = DATE_ADD('1980-01-01', INTERVAL FLOOR(RAND() * 3650) DAY)
WHERE cust_id <= 15;

-- We will make the last 5 customers Children (born 2015-2020)
-- This ensures you can test "Child Pricing" logic later
UPDATE customer
SET cust_birth_date = DATE_ADD('2015-01-01', INTERVAL FLOOR(RAND() * 1800) DAY)
WHERE cust_id > 15;