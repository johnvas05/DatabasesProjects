USE baseisproject;

-- =========================
-- language_ref
-- =========================
INSERT INTO language_ref (lang_code, lang_name) VALUES
                                                    ('EN', 'English'),
                                                    ('EL', 'Greek'),
                                                    ('FR', 'French');

-- =========================
-- branch
-- =========================
INSERT INTO branch (br_code, br_street, br_num, br_city, br_manager_AT) VALUES
                                                                            (1, 'Panepistimiou', 12, 'Athens', NULL),
                                                                            (2, 'Tsimiski', 45, 'Thessaloniki', NULL),
                                                                            (3, 'Korai', 8, 'Patras', NULL);

-- =========================
-- worker
-- =========================
INSERT INTO worker VALUES
                       ('AT00000001', 'Nikos', 'Papadopoulos', 'nikos@agency.gr', 1400.00, 1),
                       ('AT00000002', 'Maria', 'Ioannou', 'maria@agency.gr', 1350.00, 1),
                       ('AT00000003', 'Giorgos', 'Kostas', 'giorgos@agency.gr', 1500.00, 2),
                       ('AT00000004', 'Eleni', 'Dimitriou', 'eleni@agency.gr', 1300.00, 2),
                       ('AT00000005', 'Kostas', 'Nikolaou', 'kostas@agency.gr', 1450.00, 3),
                       ('AT00000006', 'Anna', 'Karagianni', 'anna@agency.gr', 1600.00, 3),
                       ('AT00000007', 'Petros', 'Alexiou', 'petros@agency.gr', 1200.00, 1),
                       ('AT00000008', 'Sofia', 'Lazarou', 'sofia@agency.gr', 1250.00, 2),
                       ('AT00000009', 'Dimitris', 'Vlachos', 'dimitris@agency.gr', 1550.00, 3),
                       ('AT00000010', 'Irini', 'Mousta', 'irini@agency.gr', 1400.00, 1),
                       ('AT00000011', 'Manos', 'Raptis', 'manos@agency.gr', 1500.00, 2),
                       ('AT00000012', 'Christina', 'Pappa', 'christina@agency.gr', 1350.00, 3),
                       ('AT00000013', 'Spyros', 'Andreou', 'spyros@agency.gr', 1450.00, 1);

-- =========================
-- admin
-- =========================
INSERT INTO admin VALUES
                      ('AT00000001', 'LOGISTICS', 'MBA Logistics'),
                      ('AT00000002', 'ADMINISTRATIVE', 'Business Administration'),
                      ('AT00000003', 'ACCOUNTING', 'Accounting Degree'),
                      ('AT00000004', 'LOGISTICS', 'Supply Chain'),
                      ('AT00000005', 'ADMINISTRATIVE', 'Tourism Management');

-- =========================
-- manages
-- =========================
INSERT INTO manages VALUES
                        ('AT00000001', 1),
                        ('AT00000002', 2),
                        ('AT00000003', 3);

-- =========================
-- update branch managers
-- =========================
UPDATE branch SET br_manager_AT = 'AT00000001' WHERE br_code = 1;
UPDATE branch SET br_manager_AT = 'AT00000002' WHERE br_code = 2;
UPDATE branch SET br_manager_AT = 'AT00000003' WHERE br_code = 3;

-- =========================
-- driver
-- =========================
INSERT INTO driver VALUES
                       ('AT00000006', 'B', 'LOCAL', 5),
                       ('AT00000007', 'C', 'ABROAD', 8),
                       ('AT00000008', 'D', 'LOCAL', 10),
                       ('AT00000009', 'B', 'ABROAD', 6);

-- =========================
-- guide
-- =========================
INSERT INTO guide VALUES
                      ('AT00000010', 'Certified tour guide – Athens'),
                      ('AT00000011', 'Museum guide – Thessaloniki'),
                      ('AT00000012', 'Cultural guide – Patras'),
                      ('AT00000013', 'International tour guide');

-- =========================
-- languages
-- =========================
INSERT INTO languages VALUES
                          ('AT00000010', 'EN'),
                          ('AT00000010', 'EL'),
                          ('AT00000011', 'EN'),
                          ('AT00000012', 'FR'),
                          ('AT00000013', 'EN');

-- =========================
-- phones
-- =========================
INSERT INTO phones VALUES
                       (1, '2101234567'),
                       (1, '2107654321'),
                       (2, '2310123456'),
                       (3, '2610123456'),
                       (3, '2610765432');

-- =========================
-- destination
-- =========================
INSERT INTO destination
(dst_name, dst_descr, dst_rtype, dst_language_code, dst_location) VALUES
                                                                      ('Acropolis', 'Historical site', 'LOCAL', 'EL', 1),
                                                                      ('Santorini', 'Island destination', 'LOCAL', 'EL', 2),
                                                                      ('Paris', 'City of lights', 'ABROAD', 'FR', 3),
                                                                      ('London', 'Capital of UK', 'ABROAD', 'EN', 4),
                                                                      ('Rome', 'Ancient city', 'ABROAD', 'EN', 5);

-- =========================
-- trip
-- =========================
INSERT INTO trip
(tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child,
 tr_status, tr_min_participants, tr_br_code, tr_gui_AT, tr_drv_AT) VALUES
                                                                       ('2025-06-01 08:00', '2025-06-05 20:00', 40, 500, 300, 'PLANNED', 10, 1, 'AT00000010', 'AT00000006'),
                                                                       ('2025-07-10 07:00', '2025-07-15 21:00', 35, 600, 350, 'CONFIRMED', 12, 2, 'AT00000011', 'AT00000007'),
                                                                       ('2025-08-01 06:00', '2025-08-08 22:00', 45, 800, 500, 'ACTIVE', 15, 3, 'AT00000012', 'AT00000008'),
                                                                       ('2025-09-05 09:00', '2025-09-10 19:00', 30, 450, 250, 'PLANNED', 8, 1, 'AT00000013', 'AT00000009'),
                                                                       ('2025-10-01 08:30', '2025-10-04 20:00', 25, 400, 200, 'PLANNED', 6, 2, 'AT00000010', 'AT00000006'),
                                                                       ('2025-11-10 07:30', '2025-11-15 22:00', 50, 900, 600, 'CONFIRMED', 20, 3, 'AT00000011', 'AT00000007'),
                                                                       ('2025-12-01 09:00', '2025-12-06 21:00', 40, 700, 450, 'PLANNED', 10, 1, 'AT00000012', 'AT00000008');

-- =========================
-- event
-- =========================
INSERT INTO event VALUES
                      (1, '2025-06-01 10:00', '2025-06-01 13:00', 'City tour'),
                      (1, '2025-06-02 09:00', '2025-06-02 12:00', 'Museum visit'),
                      (2, '2025-07-11 10:00', '2025-07-11 14:00', 'Guided walk'),
                      (2, '2025-07-12 09:00', '2025-07-12 13:00', 'Boat tour'),
                      (3, '2025-08-02 08:00', '2025-08-02 11:00', 'Historical tour'),
                      (3, '2025-08-03 10:00', '2025-08-03 15:00', 'Free time'),
                      (4, '2025-09-06 09:00', '2025-09-06 12:00', 'City center walk'),
                      (5, '2025-10-02 10:00', '2025-10-02 13:00', 'Excursion'),
                      (6, '2025-11-11 09:00', '2025-11-11 12:00', 'Sightseeing'),
                      (7, '2025-12-02 10:00', '2025-12-02 14:00', 'Cultural visit');

-- =========================
-- travel_to
-- =========================
INSERT INTO travel_to VALUES
                          (1, 1, '2025-06-01 12:00', '2025-06-05 18:00'),
                          (2, 2, '2025-07-10 14:00', '2025-07-15 17:00'),
                          (3, 3, '2025-08-01 15:00', '2025-08-08 16:00'),
                          (4, 4, '2025-09-05 16:00', '2025-09-10 15:00'),
                          (5, 5, '2025-10-01 13:00', '2025-10-04 14:00'),
                          (6, 1, '2025-11-10 12:00', '2025-11-15 18:00'),
                          (7, 2, '2025-12-01 11:00', '2025-12-06 19:00');

-- =========================
-- customer
-- =========================
INSERT INTO customer
(cust_name, cust_lname, cust_email, cust_phone, cust_address, cust_birth_date) VALUES
                                                                                   ('John', 'Smith', 'john@mail.com', '6900000001', 'Athens', '1990-01-01'),
                                                                                   ('Anna', 'Brown', 'anna@mail.com', '6900000002', 'Thessaloniki', '1988-02-14'),
                                                                                   ('George', 'White', 'george@mail.com', '6900000003', 'Patras', '1995-03-10'),
                                                                                   ('Maria', 'Green', 'maria@mail.com', '6900000004', 'Athens', '1992-04-22'),
                                                                                   ('Nick', 'Black', 'nick@mail.com', '6900000005', 'Larisa', '1985-05-30'),
                                                                                   ('Helen', 'Gray', 'helen@mail.com', '6900000006', 'Volos', '1993-06-18'),
                                                                                   ('Chris', 'Blue', 'chris@mail.com', '6900000007', 'Kavala', '1991-07-07'),
                                                                                   ('Eva', 'Red', 'eva@mail.com', '6900000008', 'Athens', '1996-08-08'),
                                                                                   ('Tom', 'Gold', 'tom@mail.com', '6900000009', 'Serres', '1989-09-09'),
                                                                                   ('Lucy', 'Silver', 'lucy@mail.com', '6900000010', 'Drama', '1994-10-10');

-- =========================
-- reservation
-- =========================
INSERT INTO reservation VALUES
                            (1, 1, 1, 'CONFIRMED', 500),
                            (1, 2, 2, 'PAID', 500),
                            (2, 1, 3, 'PAID', 600),
                            (2, 2, 4, 'CONFIRMED', 600),
                            (3, 1, 5, 'PAID', 800),
                            (3, 2, 6, 'CONFIRMED', 800),
                            (4, 1, 7, 'PENDING', 450),
                            (4, 2, 8, 'CONFIRMED', 450),
                            (5, 1, 9, 'PAID', 400),
                            (6, 1, 10, 'CONFIRMED', 900),
                            (7, 1, 1, 'PENDING', 700),
                            (7, 2, 2, 'PAID', 700);
