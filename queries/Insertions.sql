USE baseisproject;

-- Seed data for the extended database (2-person team: 2 x the per-person minimum
-- of the preparatory phase). Run after the tables exist (Query.sql, cars.sql,
-- Accommodation.sql, history.sql, AdminLog.sql). The 90 000 trip_history rows
-- are generated at the end by sp_generate_dummy_history (defined in history.sql).

-- 1. Register yourself as DBA (Crucial for triggers!)
INSERT IGNORE INTO dba_users (dba_username, dba_start_date) VALUES
    (SUBSTRING_INDEX(USER(), '@', 1), CURDATE()),   -- the account running this script
    ('Teo', '2025-11-01');

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
-- a country destination: Paris belongs to France (dst_location)
INSERT INTO destination (dst_name, dst_descr, dst_rtype, dst_language_code, dst_location) VALUES ('France', 'Country', 'ABROAD', 'FR', NULL);
UPDATE destination SET dst_location = LAST_INSERT_ID() WHERE dst_name = 'Paris';


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
                                                                        ('AT111', 'D', 'ABROAD', 10), ('AT112', 'C', 'ABROAD', 5),
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
                                                                                                                                                      ('2026-07-01', '2026-07-05', 9, 300, 150, 'PLANNED', 2, 'AT122', 'AT117', 3),
                                                                                                                                                      ('2026-07-05', '2026-07-10', 60, 550, 275, 'PLANNED', 3, 'AT123', 'AT115', 6),
                                                                                                                                                      ('2026-07-15', '2026-07-20', 8, 250, 125, 'COMPLETED', 3, 'AT124', 'AT116', 5),
                                                                                                                                                      ('2026-08-01', '2026-08-08', 18, 450, 225, 'PLANNED', 4, 'AT125', 'AT116', 7),
                                                                                                                                                      ('2026-08-10', '2026-08-15', 9, 350, 175, 'CONFIRMED', 5, 'AT126', 'AT114', 8),
                                                                                                                                                      ('2026-09-01', '2026-09-10', 52, 700, 350, 'PLANNED', 6, 'AT119', 'AT111', 9),
                                                                                                                                                      ('2026-09-15', '2026-09-20', 5, 200, 100, 'COMPLETED', 1, 'AT120', 'AT111', 10),
                                                                                                                                                      ('2026-10-01', '2026-10-10', 50, 500, 250, 'PLANNED', 1, 'AT121', 'AT112', 1),
                                                                                                                                                      ('2026-11-01', '2026-11-05', 20, 300, 150, 'PLANNED', 2, 'AT122', 'AT113', 2),
                                                                                                                                                      ('2026-12-20', '2026-12-27', 50, 800, 400, 'PLANNED', 3, 'AT123', 'AT115', 6),
                                                                                                                                                      ('2027-01-05', '2027-01-10', 50, 600, 300, 'PLANNED', 4, 'AT124', 'AT113', 9);
-- minimum participants: 20% of the seats, at least 2
UPDATE trip SET tr_min_participants = GREATEST(2, FLOOR(tr_maxseats / 5));


-- Destinations of each trip with real stay dates and visit order (to_sequence).
-- Trips 1-4 visit two destinations.
INSERT INTO travel_to (to_tr_id, to_dst_id, to_sequence, to_arrival, to_departure) VALUES
 (1, 1, 1, '2026-06-01 14:00:00', '2026-06-05 11:00:00'), (1, 2, 2, '2026-06-05 14:00:00', '2026-06-10 11:00:00'),
 (2, 2, 1, '2026-06-05 14:00:00', '2026-06-09 11:00:00'), (2, 3, 2, '2026-06-09 14:00:00', '2026-06-12 11:00:00'),
 (3, 3, 1, '2026-06-10 14:00:00', '2026-06-13 11:00:00'), (3, 4, 2, '2026-06-13 14:00:00', '2026-06-15 11:00:00'),
 (4, 4, 1, '2026-07-01 14:00:00', '2026-07-03 11:00:00'), (4, 5, 2, '2026-07-03 14:00:00', '2026-07-05 11:00:00'),
 (5, 5, 1, '2026-07-05 14:00:00', '2026-07-10 11:00:00'),
 (6, 6, 1, '2026-07-15 14:00:00', '2026-07-20 11:00:00'),
 (7, 7, 1, '2026-08-01 14:00:00', '2026-08-08 11:00:00'),
 (8, 8, 1, '2026-08-10 14:00:00', '2026-08-15 11:00:00'),
 (9, 9, 1, '2026-09-01 14:00:00', '2026-09-10 11:00:00'),
 (10, 10, 1, '2026-09-15 14:00:00', '2026-09-20 11:00:00'),
 (11, 1, 1, '2026-10-01 14:00:00', '2026-10-10 11:00:00'),
 (12, 2, 1, '2026-11-01 14:00:00', '2026-11-05 11:00:00'),
 (13, 3, 1, '2026-12-20 14:00:00', '2026-12-27 11:00:00'),
 (14, 4, 1, '2027-01-05 14:00:00', '2027-01-10 11:00:00');

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
-- more events (every trip has at least one event; 20 rows = 2 x 10 minimum)
INSERT INTO event (ev_tr_id, ev_start, ev_end, ev_descr) VALUES
    (13, '2026-12-21 10:00:00', '2026-12-21 13:00:00', 'Christmas market walk'),
    (14, '2027-01-06 10:00:00', '2027-01-06 12:30:00', 'Guided city tour'),
    (10, '2026-09-16 09:00:00', '2026-09-16 12:00:00', 'Manhattan walking tour'),
    (11, '2026-10-02 10:00:00', '2026-10-02 13:00:00', 'Louvre visit'),
    (12, '2026-11-02 10:00:00', '2026-11-02 12:00:00', 'Thames boat tour');


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


INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_rating, lg_status, lg_address, lg_city, lg_postal_code, lg_phone, lg_email, lg_total_rooms, lg_cost_per_night, lg_wifi, lg_restaurant_bar, lg_ac, lg_access_disability) VALUES
                                                                                                                                                                                                                           (1, 'Le Grand Paris', 'Hotel', 5, 4.8, 'Active', '10 Rue de Rivoli', 'Paris', '75001', '3310000001', 'contact@grandparis.fr', 100, 250.00, 1, 1, 1, 1),
                                                                                                                                                                                                                           (2, 'London Stay', 'Hostel', NULL, 3.5, 'Active', '22 Baker St', 'London', 'NW1 6XE', '4420000002', 'info@londonstay.uk', 30, 60.00, 1, 0, 0, 0),
                                                                                                                                                                                                                           (3, 'Berlin Plaza', 'Hotel', 4, 4.2, 'Active', 'Alexanderplatz 1', 'Berlin', '10178', '4930000003', 'booking@berlinplaza.de', 80, 120.00, 1, 1, 1, 1),
                                                                                                                                                                                                                           (4, 'Roma Bella', 'Apartment', NULL, 4.9, 'Active', 'Via Roma 10', 'Rome', '00184', '3906000004', 'hello@romabella.it', 5, 150.00, 1, 0, 1, 0),
                                                                                                                                                                                                                           (5, 'Madrid Sol', 'Hotel', 3, 4.0, 'Active', 'Puerta del Sol', 'Madrid', '28013', '3491000005', 'reception@madridsol.es', 50, 90.00, 1, 0, 1, 1),
                                                                                                                                                                                                                           (6, 'Nafplio Palace', 'Resort', 5, 4.7, 'Active', 'Acronafplia', 'Nafplio', '21100', '3027520006', 'reservations@nafplio.gr', 60, 200.00, 1, 1, 1, 1),
                                                                                                                                                                                                                           (7, 'Meteora View', 'Room', NULL, 4.5, 'Active', 'Kalambaka Main Rd', 'Kalambaka', '42200', '3024320007', 'rooms@meteora.gr', 10, 50.00, 0, 0, 1, 0),
                                                                                                                                                                                                                           (8, 'Delphi Omni', 'Hotel', 3, 3.8, 'Active', 'Apollonos St', 'Delphi', '33054', '3022650008', 'info@delphiomni.gr', 40, 80.00, 1, 1, 1, 0),
                                                                                                                                                                                                                           (9, 'NYC Central', 'Hotel', 4, 4.3, 'Active', '5th Avenue', 'New York', '10118', '1212000009', 'stay@nyccentral.us', 200, 300.00, 1, 1, 1, 1),
                                                                                                                                                                                                                           (10, 'Tokyo Capsule', 'Hostel', NULL, 4.1, 'Active', 'Shinjuku', 'Tokyo', '160-0022', '8130000010', 'sleep@tokyo.jp', 500, 40.00, 1, 0, 1, 1);

-- Trip history (3.1.2.3): 90 000 generated completed trips
CALL sp_generate_dummy_history();
