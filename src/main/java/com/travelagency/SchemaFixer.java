package com.travelagency;

import java.sql.Connection;
import java.sql.Statement;

public class SchemaFixer {
    public static void main(String[] args) {
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement()) {

            System.out.println("Applying fix: Adding AUTO_INCREMENT to trip.tr_id...");
            // We need to disable FK checks temporarily usually if modifying referenced PK,
            // but MODIFY INT AUTO_INCREMENT is usually safe if values unique.
            stmt.execute("SET FOREIGN_KEY_CHECKS=0");

            System.out.println("Applying fix: Adding AUTO_INCREMENT to trip.tr_id...");
            stmt.execute("ALTER TABLE trip MODIFY tr_id INT AUTO_INCREMENT");

            System.out.println("Applying fix: Adding AUTO_INCREMENT to customer.cust_id...");
            stmt.execute("ALTER TABLE customer MODIFY cust_id INT AUTO_INCREMENT");

            stmt.execute("SET FOREIGN_KEY_CHECKS=1");

            System.out.println("Fix applied successfully!");

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
