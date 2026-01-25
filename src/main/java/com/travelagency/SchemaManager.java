package com.travelagency;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

public class SchemaManager {

    public static void ensureSchema(Connection conn) throws SQLException {
        try (Statement stmt = conn.createStatement()) {
            // Requirement 3.1.2.1: Vehicles
            String createVehicleTable = """
                        CREATE TABLE IF NOT EXISTS vehicle (
                            veh_license_plate VARCHAR(20) PRIMARY KEY,
                            veh_model VARCHAR(50) NOT NULL,
                            veh_brand VARCHAR(50) NOT NULL,
                            veh_capacity INT NOT NULL,
                            veh_type ENUM('Bus', 'Mini-Bus', 'Van', 'Car') NOT NULL
                        );
                    """;
            stmt.execute(createVehicleTable);

            // Requirement 3.1.2.2: Accommodations (Basic structure for later)
            String createAccommodationTable = """
                        CREATE TABLE IF NOT EXISTS accommodation (
                            acc_id INT AUTO_INCREMENT PRIMARY KEY,
                            acc_name VARCHAR(100) NOT NULL,
                            acc_type ENUM('Hotel', 'Hostel', 'Apartment', 'Other') NOT NULL,
                            acc_stars INT,
                            acc_rating DECIMAL(3,2),
                            acc_active BOOLEAN DEFAULT TRUE,
                            acc_address TEXT,
                            acc_phone VARCHAR(20),
                            acc_email VARCHAR(100),
                            acc_rooms INT,
                            acc_price_per_night DECIMAL(10,2)
                        );
                    """;
            stmt.execute(createAccommodationTable);

            // Trip History (Req 3.1.2.3)
            String createHistoryTable = """
                        CREATE TABLE IF NOT EXISTS trip_history (
                            h_tr_id INT,
                            h_departure DATETIME,
                            h_return DATETIME,
                            h_maxseats INT,
                            h_participants INT,
                            h_revenue DECIMAL(10,2),
                            PRIMARY KEY (h_tr_id)
                        );
                    """;
            stmt.execute(createHistoryTable);

            // DBA Log (Req 3.1.2.4)
            String createLogTable = """
                        CREATE TABLE IF NOT EXISTS log (
                            log_id INT AUTO_INCREMENT PRIMARY KEY,
                            log_username VARCHAR(50),
                            log_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                            log_action VARCHAR(50),
                            log_table VARCHAR(50)
                        );
                    """;
            stmt.execute(createLogTable);

            System.out.println("Schema extensions verified/created.");
        }
    }
}
