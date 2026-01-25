package com.travelagency;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class SchemaTest {
    public static void main(String[] args) {
        System.out.println("Starting Schema Verification...");

        try (Connection conn = DatabaseConnection.getConnection()) {
            if (conn != null) {
                System.out.println("Connection successful!");

                checkTable(conn, "worker", "SELECT wrk_AT FROM worker LIMIT 1");
                checkTable(conn, "customer", "SELECT cust_id FROM customer LIMIT 1");
                checkTable(conn, "trip", "SELECT tr_id, tr_vehicle_id FROM trip LIMIT 1");
                checkTable(conn, "reservation", "SELECT res_tr_id FROM reservation LIMIT 1");
                checkTable(conn, "vehicle", "SELECT v_id, v_license_plate FROM vehicle LIMIT 1");
                checkTable(conn, "lodging", "SELECT lg_id FROM lodging LIMIT 1");
                // checkTable(conn, "trip_history", "SELECT th_id FROM trip_history LIMIT 1");
                // // Might be empty or exist

                System.out.println("Schema Verification Completed Successfully.");
            } else {
                System.err.println("Failed to establish connection.");
            }
        } catch (SQLException e) {
            System.err.println("Database Error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void checkTable(Connection conn, String tableName, String query) {
        try (Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {
            System.out.println("Table '" + tableName + "' check: OK");
        } catch (SQLException e) {
            System.err.println("Table '" + tableName + "' check: FAILED (" + e.getMessage() + ")");
        }
    }
}
