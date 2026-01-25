USE baseisproject;

-- 2a. Create the Accommodation/Lodging table
CREATE TABLE lodging (
                         lg_id INT AUTO_INCREMENT PRIMARY KEY,       -- Unique code [cite: 150]
                         lg_dst_id INT NOT NULL,                     -- Located in a destination [cite: 159]
                         lg_name VARCHAR(100) NOT NULL,              -- Commercial name [cite: 150]
                         lg_type ENUM('Hotel', 'Hostel', 'Resort', 'Apartment', 'Room') NOT NULL, -- Type [cite: 151]
                         lg_stars TINYINT DEFAULT NULL CHECK (lg_stars BETWEEN 1 AND 5), -- Stars (1-5) [cite: 152]
                         lg_rating DECIMAL(3,2) DEFAULT 0.00 CHECK (lg_rating BETWEEN 0.00 AND 5.00), -- Rating [cite: 153]
                         lg_status ENUM('Active', 'Inactive') DEFAULT 'Active', -- Status [cite: 154]
                         lg_address VARCHAR(100) NOT NULL,           -- Street, number [cite: 155]
                         lg_city VARCHAR(50) NOT NULL,               -- City [cite: 156]
                         lg_postal_code VARCHAR(10),                 -- Postal Code [cite: 156]
                         lg_phone VARCHAR(20),                       -- Phone [cite: 156]
                         lg_email VARCHAR(100),                      -- Email [cite: 156]
                         lg_total_rooms INT NOT NULL,                -- Total rooms [cite: 160]
                         lg_cost_per_night DECIMAL(10,2) NOT NULL,   -- Price per room/night [cite: 161]
                         FOREIGN KEY (lg_dst_id) REFERENCES destination(dst_id) ON DELETE CASCADE
);

-- 2b. Create a table for Amenities (Many-to-Many relationship implicitly or flags)
-- The PDF lists specific amenities: WiFi, Restaurant/Bar, AC, Accessibility[cite: 162].
-- We can add these as boolean columns to the lodging table OR a separate table.
-- A separate table is cleaner for database normalization, but simple columns are easier for queries.
-- Given the specific list, let's add them as columns to the 'lodging' table above or update it:
ALTER TABLE lodging
    ADD COLUMN lg_wifi TINYINT(1) DEFAULT 0,
    ADD COLUMN lg_restaurant_bar TINYINT(1) DEFAULT 0,
    ADD COLUMN lg_ac TINYINT(1) DEFAULT 0,
    ADD COLUMN lg_access_disability TINYINT(1) DEFAULT 0;

-- 2c. Create a table to link Trips to Lodgings (for reservations made by the agency)
-- Requirement 3.1.3.3 mentions booking accommodation for a trip.
CREATE TABLE room_usage (
                            ru_trip_id INT,
                            ru_lodging_id INT,
                            ru_checkin DATE,
                            ru_checkout DATE,
                            ru_rooms_count INT DEFAULT 0,
                            ru_total_cost DECIMAL(10,2) DEFAULT 0.00,
                            PRIMARY KEY (ru_trip_id, ru_lodging_id, ru_checkin),
                            FOREIGN KEY (ru_trip_id) REFERENCES trip(tr_id) ON DELETE CASCADE,
                            FOREIGN KEY (ru_lodging_id) REFERENCES lodging(lg_id) ON DELETE CASCADE
);