package com.travelagency;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    // Database credentials
    private static final String URL = "jdbc:mysql://localhost:3306/baseis project?serverTimezone=UTC";
    private static final String USER = "Teo";
    private static final String PASSWORD = "Theodore2005!";

    private static Connection connection = null;

    private DatabaseConnection() {
        // Private constructor to prevent instantiation
    }

    public static Connection getConnection() throws SQLException {
        if (connection == null || connection.isClosed()) {
            try {
                // Ensure driver is loaded
                Class.forName("com.mysql.cj.jdbc.Driver");
                connection = DriverManager.getConnection(URL, USER, PASSWORD);
                System.out.println("Database connected successfully.");

                // Fix for log_actions Foreign Key Error:
                // Ensure the current DB user exists in 'dba_users' table.
                ensureUserExists(connection);

            } catch (ClassNotFoundException e) {
                throw new SQLException("MySQL JDBC Driver not found.", e);
            }
        }
        return connection;
    }

    private static void ensureUserExists(Connection conn) {
        try (java.sql.Statement stmt = conn.createStatement()) {
            System.out.println("DEBUG: Attempting to register DB user for logging/triggers...");

            // 1. Get variants
            String currentUser = "";
            String userFunc = "";

            java.sql.ResultSet rs = stmt.executeQuery("SELECT CURRENT_USER(), USER()");
            if (rs.next()) {
                currentUser = rs.getString(1); // e.g. Teo@localhost
                userFunc = rs.getString(2); // e.g. Teo@localhost
            }

            // 2. Prepare list of candidates to insert
            java.util.Set<String> candidates = new java.util.HashSet<>();
            if (currentUser != null)
                candidates.add(currentUser);
            if (userFunc != null)
                candidates.add(userFunc);
            // Add likely manual usernames based on known config
            candidates.add("Teo");
            candidates.add("Teo@localhost");
            candidates.add("root");
            candidates.add("root@localhost");

            // 3. Insert all
            String query = "INSERT IGNORE INTO dba_users (dba_username, dba_start_date) VALUES (?, CURDATE())";
            try (java.sql.PreparedStatement pstmt = conn.prepareStatement(query)) {
                for (String user : candidates) {
                    if (user == null || user.isEmpty())
                        continue;

                    try {
                        pstmt.setString(1, user);
                        int rows = pstmt.executeUpdate();
                        if (rows > 0) {
                            System.out.println("DEBUG: Registered new DB user: " + user);
                        } else {
                            // Already exists, which is fine
                            System.out.println("DEBUG: DB user already exists (skipped): " + user);
                        }
                    } catch (SQLException ex) {
                        System.out.println("DEBUG: Failed to register " + user + ": " + ex.getMessage());
                    }
                }
            }
            System.out.println("DEBUG: User registration check complete.");

        } catch (SQLException e) {
            System.err.println("CRITICAL WARNING: Could not register user in dba_users. Triggers may fail.");
            e.printStackTrace();
        }
    }

    public static void closeConnection() {
        if (connection != null) {
            try {
                connection.close();
                System.out.println("Database connection closed.");
            } catch (SQLException e) {
                System.err.println("Error closing connection: " + e.getMessage());
            }
        }
    }
}
