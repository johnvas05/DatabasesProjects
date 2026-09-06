package com.travelagency;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class DatabaseConnection {
    // Defaults match docker-compose.yml. Override with the environment
    // variables DB_URL, DB_USER and DB_PASSWORD when using another server.
    private static final String URL = env("DB_URL",
            "jdbc:mysql://localhost:3307/baseisproject?serverTimezone=UTC");
    private static final String USER = env("DB_USER", "root");
    private static final String PASSWORD = env("DB_PASSWORD", "john2005");

    private static Connection connection = null;
    // The DAOs open the shared connection in a try-with-resources, so it is
    // reopened on nearly every call. Announce it once instead of on every query.
    private static boolean announced = false;

    private DatabaseConnection() {
        // Private constructor to prevent instantiation
    }

    private static String env(String name, String defaultValue) {
        String value = System.getenv(name);
        return (value == null || value.isBlank()) ? defaultValue : value;
    }

    public static String describe() {
        return USER + " @ " + URL.replaceFirst("\\?.*$", "");
    }

    public static Connection getConnection() throws SQLException {
        if (connection == null || connection.isClosed()) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                connection = DriverManager.getConnection(URL, USER, PASSWORD);
                if (!announced) {
                    System.out.println("Database connected successfully as " + describe());
                    announced = true;
                }
                registerDba(connection);
            } catch (ClassNotFoundException e) {
                throw new SQLException("MySQL JDBC Driver not found.", e);
            }
        }
        return connection;
    }

    /**
     * The log triggers (3.1.4.1) record SUBSTRING_INDEX(USER(), '@', 1) and
     * log_actions.log_dba_username references dba_users. The GUI is used by
     * DBAs, so the connecting account is registered as a DBA (start date =
     * today) the first time it connects. Nothing else is inserted.
     */
    private static void registerDba(Connection conn) {
        try (Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT SUBSTRING_INDEX(USER(), '@', 1)")) {
            if (!rs.next()) {
                return;
            }
            String dbaUser = rs.getString(1);
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "INSERT IGNORE INTO dba_users (dba_username, dba_start_date) VALUES (?, CURDATE())")) {
                pstmt.setString(1, dbaUser);
                if (pstmt.executeUpdate() > 0) {
                    System.out.println("Registered DBA account '" + dbaUser + "' in dba_users.");
                }
            }
        } catch (SQLException e) {
            System.err.println("WARNING: could not register the DBA account in dba_users; "
                    + "log triggers will reject changes: " + e.getMessage());
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
