USE baseisproject;

-- 3.1.2.2 Lodging
CREATE TABLE lodging (
                         lg_id INT AUTO_INCREMENT PRIMARY KEY,
                         lg_dst_id INT NOT NULL,                     -- the city it is in
                         lg_name VARCHAR(100) NOT NULL,
                         lg_type ENUM('Hotel', 'Hostel', 'Resort', 'Apartment', 'Room') NOT NULL,
                         lg_stars TINYINT DEFAULT NULL CHECK (lg_stars BETWEEN 1 AND 5),
                         lg_rating DECIMAL(3,2) DEFAULT 0.00 CHECK (lg_rating BETWEEN 0.00 AND 5.00),
                         lg_status ENUM('Active', 'Inactive') DEFAULT 'Active',
                         lg_address VARCHAR(100) NOT NULL,           -- street and number
                         lg_city VARCHAR(50) NOT NULL,
                         lg_postal_code VARCHAR(10),
                         lg_phone VARCHAR(20),
                         lg_email VARCHAR(100),
                         lg_total_rooms INT NOT NULL,
                         lg_cost_per_night DECIMAL(10,2) NOT NULL,   -- per double room
                         FOREIGN KEY (lg_dst_id) REFERENCES destination(dst_id) ON DELETE CASCADE,
                         -- only hotels and resorts have stars
                         CONSTRAINT chk_lodging_stars_type CHECK (lg_type IN ('Hotel', 'Resort') OR lg_stars IS NULL)
);

-- Amenities: the list is fixed (4 items), so one 0/1 column each.
-- A separate amenity table would also work but needs a join every time.
ALTER TABLE lodging
    ADD COLUMN lg_wifi TINYINT(1) DEFAULT 0,
    ADD COLUMN lg_restaurant_bar TINYINT(1) DEFAULT 0,
    ADD COLUMN lg_ac TINYINT(1) DEFAULT 0,
    ADD COLUMN lg_access_disability TINYINT(1) DEFAULT 0;

-- Stays booked for a trip (filled by 3.1.3.3).
-- checkin is part of the key so a trip can stay at the same place twice.
CREATE TABLE room_usage (
                            ru_trip_id INT,
                            ru_lodging_id INT,
                            ru_checkin DATE,
                            ru_checkout DATE,
                            ru_nights INT DEFAULT 0,            -- set by the trigger of 3.1.4.2
                            ru_rooms_count INT DEFAULT 0,
                            ru_total_cost DECIMAL(10,2) DEFAULT 0.00,
                            PRIMARY KEY (ru_trip_id, ru_lodging_id, ru_checkin),
                            FOREIGN KEY (ru_trip_id) REFERENCES trip(tr_id) ON DELETE CASCADE,
                            FOREIGN KEY (ru_lodging_id) REFERENCES lodging(lg_id) ON DELETE CASCADE
);
