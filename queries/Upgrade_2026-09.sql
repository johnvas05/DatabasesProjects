USE baseisproject;

-- =====================================================================
-- Upgrade script for the 2026-01-25 dump.
-- Run ONCE on a database loaded from that dump, then (re)load the
-- routine/trigger files:
--   VechicleProcedure.sql, AccommodationProcedure.sql, AutoBookProcedure.sql,
--   CalculateReservationCost.sql, Triggers.sql, TRIGGER.sql, PROCEDURE.sql
-- The regenerated dump (baseisproject_dump.sql) already contains all of this.
-- =====================================================================

-- 0. The log triggers of the January dump wrote USER() ('root@localhost');
--    they are dropped here and recreated by Triggers.sql with the plain
--    username, so the data fixes below can run after step 6.
DROP TRIGGER IF EXISTS trg_log_trip_insert;
DROP TRIGGER IF EXISTS trg_log_trip_update;
DROP TRIGGER IF EXISTS trg_log_trip_delete;

-- 1. travel_to: visit order of the destinations (to_sequence, spec section 2.6)
ALTER TABLE travel_to ADD COLUMN to_sequence INT NOT NULL DEFAULT 1 AFTER to_dst_id;

-- 2. room_usage: the number of nights is stored on the record (spec 3.1.4.2)
ALTER TABLE room_usage ADD COLUMN ru_nights INT DEFAULT 0 AFTER ru_checkout;

-- 3. trip_history: no referential integrity (spec 3.1.2.3 explicitly allows it).
--    The 90 000 generated rows reference synthetic trip ids, so the old FK was
--    violated anyway (it only loaded because the dump disables FK checks).
ALTER TABLE trip_history DROP FOREIGN KEY trip_history_ibfk_1;

-- 4. Indexes for 3.1.3.4: covering indexes replace the single-column ones.
--    With 5 evenly spread destination counts and 4 years of dates the optimizer
--    ignored the single-column indexes (full scan of 90 000 rows). A covering
--    index answers each procedure entirely from the index (see history.sql).
DROP INDEX idx_history_departure ON trip_history;
DROP INDEX idx_history_dest_count ON trip_history;
CREATE INDEX idx_hist_dep_rev ON trip_history (th_departure, th_revenue);
CREATE INDEX idx_hist_dc_dep ON trip_history (th_dest_count, th_departure);

-- 5. Real stay dates. Every travel_to row had been stamped with NOW() at insert
--    time, so every stay was 0 nights and every accommodation cost was 0.00.
UPDATE travel_to tt
    JOIN trip t ON t.tr_id = tt.to_tr_id
SET tt.to_arrival   = TIMESTAMP(DATE(t.tr_departure), '14:00:00'),
    tt.to_departure = TIMESTAMP(DATE(t.tr_return),    '11:00:00');

--    Trips 1-4 become two-destination trips (to_sequence 1 and 2).
UPDATE travel_to SET to_departure = '2026-06-05 11:00:00' WHERE to_tr_id = 1 AND to_dst_id = 1;
INSERT INTO travel_to (to_tr_id, to_dst_id, to_sequence, to_arrival, to_departure)
VALUES (1, 2, 2, '2026-06-05 14:00:00', '2026-06-10 11:00:00');

UPDATE travel_to SET to_departure = '2026-06-09 11:00:00' WHERE to_tr_id = 2 AND to_dst_id = 2;
INSERT INTO travel_to (to_tr_id, to_dst_id, to_sequence, to_arrival, to_departure)
VALUES (2, 3, 2, '2026-06-09 14:00:00', '2026-06-12 11:00:00');

UPDATE travel_to SET to_departure = '2026-06-13 11:00:00' WHERE to_tr_id = 3 AND to_dst_id = 3;
INSERT INTO travel_to (to_tr_id, to_dst_id, to_sequence, to_arrival, to_departure)
VALUES (3, 4, 2, '2026-06-13 14:00:00', '2026-06-15 11:00:00');

UPDATE travel_to SET to_departure = '2026-07-03 11:00:00' WHERE to_tr_id = 4 AND to_dst_id = 4;
INSERT INTO travel_to (to_tr_id, to_dst_id, to_sequence, to_arrival, to_departure)
VALUES (4, 5, 2, '2026-07-03 14:00:00', '2026-07-05 11:00:00');

-- 6. DBA accounts are stored as plain usernames (the log triggers write
--    SUBSTRING_INDEX(USER(), '@', 1)), so the same DBA is logged identically
--    whether connecting from localhost, a container network or the GUI.
INSERT INTO dba_users (dba_username, dba_start_date, dba_end_date) VALUES
    ('root', '2026-01-25', NULL),
    ('Teo',  '2025-11-01', NULL);
UPDATE log_actions SET log_dba_username = 'root' WHERE log_dba_username = 'root@localhost';
DELETE FROM dba_users WHERE dba_username = 'root@localhost';

-- 7. Lodging seed (the dump had an empty lodging table; same rows as Insertions.sql)
INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_rating, lg_status, lg_address, lg_city, lg_phone, lg_email, lg_total_rooms, lg_cost_per_night, lg_wifi, lg_restaurant_bar, lg_ac, lg_access_disability) VALUES
    (1,  'Le Grand Paris', 'Hotel',     5,    4.8, 'Active', '10 Rue de Rivoli',   'Paris',     '3310000001', 'contact@grandparis.fr',   100, 250.00, 1, 1, 1, 1),
    (2,  'London Stay',    'Hostel',    NULL, 3.5, 'Active', '22 Baker St',        'London',    '4420000002', 'info@londonstay.uk',       30,  60.00, 1, 0, 0, 0),
    (3,  'Berlin Plaza',   'Hotel',     4,    4.2, 'Active', 'Alexanderplatz 1',   'Berlin',    '4930000003', 'booking@berlinplaza.de',   80, 120.00, 1, 1, 1, 1),
    (4,  'Roma Bella',     'Apartment', NULL, 4.9, 'Active', 'Via Roma 10',        'Rome',      '3906000004', 'hello@romabella.it',        5, 150.00, 1, 0, 1, 0),
    (5,  'Madrid Sol',     'Hotel',     3,    4.0, 'Active', 'Puerta del Sol',     'Madrid',    '3491000005', 'reception@madridsol.es',   50,  90.00, 1, 0, 1, 1),
    (6,  'Nafplio Palace', 'Resort',    5,    4.7, 'Active', 'Acronafplia',        'Nafplio',   '3027520006', 'reservations@nafplio.gr',  60, 200.00, 1, 1, 1, 1),
    (7,  'Meteora View',   'Room',      NULL, 4.5, 'Active', 'Kalambaka Main Rd',  'Kalambaka', '3024320007', 'rooms@meteora.gr',         10,  50.00, 0, 0, 1, 0),
    (8,  'Delphi Omni',    'Hotel',     3,    3.8, 'Active', 'Apollonos St',       'Delphi',    '3022650008', 'info@delphiomni.gr',       40,  80.00, 1, 1, 1, 0),
    (9,  'NYC Central',    'Hotel',     4,    4.3, 'Active', '5th Avenue',         'New York',  '1212000009', 'stay@nyccentral.us',      200, 300.00, 1, 1, 1, 1),
    (10, 'Tokyo Capsule',  'Hostel',    NULL, 4.1, 'Active', 'Shinjuku',           'Tokyo',     '8130000010', 'sleep@tokyo.jp',          500,  40.00, 1, 0, 1, 1);

-- 8. Reservation prices were never set (all 0/NULL), which made every branch
--    look loss-making. Apply the adult/child price of the trip by age.
UPDATE reservation r
    JOIN trip t     ON r.res_tr_id   = t.tr_id
    JOIN customer c ON r.res_cust_id = c.cust_id
SET r.res_total_cost = CASE
        WHEN c.cust_birth_date IS NULL
          OR TIMESTAMPDIFF(YEAR, c.cust_birth_date, CURDATE()) >= 18
        THEN t.tr_cost_adult
        ELSE t.tr_cost_child
    END
WHERE r.res_total_cost IS NULL OR r.res_total_cost = 0;

-- 9. event: 18 rows were 2 short of the 2-person minimum (10 per person).
INSERT INTO event (ev_tr_id, ev_start, ev_end, ev_descr) VALUES
    (13, '2026-12-21 10:00:00', '2026-12-21 13:00:00', 'Christmas market walk'),
    (14, '2027-01-06 10:00:00', '2027-01-06 12:30:00', 'Guided city tour');

-- 10. to_sequence has the type of the relational model (tinyint)
ALTER TABLE travel_to MODIFY COLUMN to_sequence TINYINT NOT NULL DEFAULT 1;

-- 11. Every trip has at least one event (spec section 2.7): trips 10-12 had none
INSERT INTO event (ev_tr_id, ev_start, ev_end, ev_descr) VALUES
    (10, '2026-09-16 09:00:00', '2026-09-16 12:00:00', 'Manhattan walking tour'),
    (11, '2026-10-02 10:00:00', '2026-10-02 13:00:00', 'Louvre visit'),
    (12, '2026-11-02 10:00:00', '2026-11-02 12:00:00', 'Thames boat tour');

-- 12. Minimum participants were NULL for every trip
UPDATE trip SET tr_min_participants = GREATEST(2, FLOOR(tr_maxseats / 5));

-- 13. Drivers: the route (LOCAL/ABROAD) and licence of each trip's driver must
--     match the trip's destinations and vehicle (sections 2.3, 3.1.3.1).
UPDATE driver SET drv_route = 'ABROAD' WHERE drv_AT = 'AT112';          -- drives only abroad trips (2, 11)
UPDATE trip SET tr_drv_AT = 'AT117' WHERE tr_id = 4;   -- ABROAD trip, van:      ABROAD driver, licence D
UPDATE trip SET tr_drv_AT = 'AT116' WHERE tr_id = 6;   -- LOCAL trip, van:       LOCAL driver
UPDATE trip SET tr_drv_AT = 'AT114' WHERE tr_id = 8;   -- LOCAL trip, van:       LOCAL driver, licence B is enough
UPDATE trip SET tr_drv_AT = 'AT111' WHERE tr_id = 9;   -- ABROAD trip, 52-seat bus: licence D
UPDATE trip SET tr_drv_AT = 'AT113' WHERE tr_id = 14;  -- ABROAD trip, 52-seat bus: licence D

-- 14. Full lodging address: postal codes (spec 3.1.2.2)
UPDATE lodging SET lg_postal_code = CASE lg_id
    WHEN 1 THEN '75001' WHEN 2 THEN 'NW1 6XE' WHEN 3 THEN '10178' WHEN 4 THEN '00184'
    WHEN 5 THEN '28013' WHEN 6 THEN '21100'   WHEN 7 THEN '42200' WHEN 8 THEN '33054'
    WHEN 9 THEN '10118' WHEN 10 THEN '160-0022' END
WHERE lg_id BETWEEN 1 AND 10;

-- 15. Integrity rules from the description
--     vehicle types by seat count: Bus > 20, Mini-Bus 10-20, Van 6-9, Car <= 5
ALTER TABLE vehicle ADD CONSTRAINT chk_vehicle_type_seats CHECK (
       (v_type = 'Bus'      AND v_seats > 20)
    OR (v_type = 'Mini-Bus' AND v_seats BETWEEN 10 AND 20)
    OR (v_type = 'Van'      AND v_seats BETWEEN 6 AND 9)
    OR (v_type = 'Car'      AND v_seats BETWEEN 1 AND 5));
--     official stars exist only for hotels and resorts
ALTER TABLE lodging ADD CONSTRAINT chk_lodging_stars_type CHECK (
    lg_type IN ('Hotel', 'Resort') OR lg_stars IS NULL);
--     a destination may belong to a parent destination (city -> country)
ALTER TABLE destination ADD CONSTRAINT destination_ibfk_2
    FOREIGN KEY (dst_location) REFERENCES destination (dst_id);

-- 16. A country destination to demonstrate city/country destinations:
--     Paris belongs to France. Lodging may only be attached to city destinations
--     (trigger trg_lodging_city_only in Accommodation.sql).
INSERT INTO destination (dst_name, dst_descr, dst_rtype, dst_language_code)
VALUES ('France', 'Country', 'ABROAD', 'FR');
UPDATE destination SET dst_location = LAST_INSERT_ID() WHERE dst_name = 'Paris';
