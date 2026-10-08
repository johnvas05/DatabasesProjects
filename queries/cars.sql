USE baseisproject;

-- 3.1.2.1 Vehicles, each one belongs to a branch
CREATE TABLE vehicle (
    v_id            INT AUTO_INCREMENT PRIMARY KEY,
    v_br_code       INT NOT NULL,
    v_license_plate VARCHAR(20) UNIQUE NOT NULL,
    v_model         VARCHAR(50) NOT NULL,
    v_brand         VARCHAR(50) NOT NULL,
    v_type          ENUM('Bus', 'Mini-Bus', 'Van', 'Car') NOT NULL,
    v_seats         INT NOT NULL,
    v_status        ENUM('Available', 'InUse', 'Maintenance') DEFAULT 'Available',
    v_mileage       INT DEFAULT 0,
    FOREIGN KEY (v_br_code) REFERENCES branch(br_code) ON DELETE CASCADE,
    -- the type must match the number of seats
    CONSTRAINT chk_vehicle_type_seats CHECK (
           (v_type = 'Bus'      AND v_seats > 20)
        OR (v_type = 'Mini-Bus' AND v_seats BETWEEN 10 AND 20)
        OR (v_type = 'Van'      AND v_seats BETWEEN 6 AND 9)
        OR (v_type = 'Car'      AND v_seats BETWEEN 1 AND 5))
);

-- the vehicle of the trip (NULL until one is assigned, 3.1.3.1)
-- and the km driven, filled in when the trip is completed (3.1.4.3)
ALTER TABLE trip
    ADD COLUMN tr_vehicle_id INT NULL,
    ADD COLUMN tr_km INT DEFAULT 0,
    ADD FOREIGN KEY (tr_vehicle_id) REFERENCES vehicle(v_id);
