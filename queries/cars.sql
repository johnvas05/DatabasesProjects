use baseisproject;

-- 1. Create the Vehicle table
CREATE TABLE vehicle (
                         v_id INT AUTO_INCREMENT PRIMARY KEY,        -- Internal unique code [cite: 137]
                         v_br_code INT NOT NULL,                     -- Branch owner (from context of assigning vehicles)
                         v_license_plate VARCHAR(20) UNIQUE NOT NULL,-- License plate [cite: 138]
                         v_model VARCHAR(50) NOT NULL,               -- Model [cite: 138]
                         v_brand VARCHAR(50) NOT NULL,               -- Brand [cite: 138]
                         v_type ENUM('Bus', 'Mini-Bus', 'Van', 'Car') NOT NULL, -- Vehicle Type [cite: 140-144]
                         v_seats INT NOT NULL,                       -- Passenger capacity [cite: 138]
                         v_status ENUM('Available', 'InUse', 'Maintenance') DEFAULT 'Available', -- Status [cite: 145]
                         v_mileage INT DEFAULT 0,                    -- Total mileage [cite: 147]
                         FOREIGN KEY (v_br_code) REFERENCES branch(br_code) ON DELETE CASCADE
);