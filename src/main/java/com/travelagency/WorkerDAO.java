package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class WorkerDAO {

    public List<Worker> getAllWorkers() throws SQLException {
        List<Worker> list = new ArrayList<>();
        String query = "SELECT * FROM worker";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new Worker(
                        rs.getString("wrk_AT"),
                        rs.getString("wrk_name"),
                        rs.getString("wrk_lname"),
                        rs.getDouble("wrk_salary"),
                        rs.getInt("wrk_br_code")));
            }
        }
        return list;
    }

    /**
     * Adds a worker together with its category row (driver, guide or admin) in
     * one transaction: every worker belongs to exactly one category (section 2.3).
     *
     * @param category "DRIVER", "GUIDE" or "ADMIN"
     * @param detail1  driver licence (A-D) / guide CV / admin type
     * @param detail2  driver route (LOCAL, ABROAD) / guide language code / admin diploma
     * @param detail3  driver experience in years (ignored for the others)
     */
    public void addWorker(Worker w, String email, String category, String detail1, String detail2, Integer detail3)
            throws SQLException {
        Connection conn = DatabaseConnection.getConnection();
        boolean autoCommit = conn.getAutoCommit();
        conn.setAutoCommit(false);
        try {
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "INSERT INTO worker (wrk_AT, wrk_name, wrk_lname, wrk_email, wrk_salary, wrk_br_code) VALUES (?, ?, ?, ?, ?, ?)")) {
                pstmt.setString(1, w.getAT());
                pstmt.setString(2, w.getName());
                pstmt.setString(3, w.getLastName());
                pstmt.setString(4, email);
                pstmt.setDouble(5, w.getSalary());
                pstmt.setInt(6, w.getBranchCode());
                pstmt.executeUpdate();
            }
            switch (category) {
                case "DRIVER" -> {
                    try (PreparedStatement pstmt = conn.prepareStatement(
                            "INSERT INTO driver (drv_AT, drv_license, drv_route, drv_experience) VALUES (?, ?, ?, ?)")) {
                        pstmt.setString(1, w.getAT());
                        pstmt.setString(2, detail1);
                        pstmt.setString(3, detail2);
                        pstmt.setInt(4, detail3 == null ? 0 : detail3);
                        pstmt.executeUpdate();
                    }
                }
                case "GUIDE" -> {
                    try (PreparedStatement pstmt = conn.prepareStatement(
                            "INSERT INTO guide (gui_AT, gui_cv) VALUES (?, ?)")) {
                        pstmt.setString(1, w.getAT());
                        pstmt.setString(2, detail1);
                        pstmt.executeUpdate();
                    }
                    if (detail2 != null && !detail2.isBlank()) {
                        try (PreparedStatement pstmt = conn.prepareStatement(
                                "INSERT INTO languages (lng_gui_AT, lng_language_code) VALUES (?, ?)")) {
                            pstmt.setString(1, w.getAT());
                            pstmt.setString(2, detail2);
                            pstmt.executeUpdate();
                        }
                    }
                }
                case "ADMIN" -> {
                    try (PreparedStatement pstmt = conn.prepareStatement(
                            "INSERT INTO admin (adm_AT, adm_type, adm_diploma) VALUES (?, ?, ?)")) {
                        pstmt.setString(1, w.getAT());
                        pstmt.setString(2, detail1);
                        pstmt.setString(3, detail2);
                        pstmt.executeUpdate();
                    }
                }
                default -> throw new SQLException("Unknown worker category: " + category);
            }
            conn.commit();
        } catch (SQLException e) {
            conn.rollback();
            throw e;
        } finally {
            conn.setAutoCommit(autoCommit);
        }
    }

    /**
     * Drivers for the trip form (3.2.2), as "AT | Name Lastname (licence X,
     * ROUTE)". The licence decides which vehicles the trip may use
     * (sp_assign_vehicle_to_trip needs C or D for more than 9 seats), so it is
     * part of the label. Use UniversalTableManager.optionKey() to get the AT.
     */
    public List<String> getDriverOptions() throws SQLException {
        List<String> list = new ArrayList<>();
        String query = "SELECT d.drv_AT, w.wrk_name, w.wrk_lname, d.drv_license, d.drv_route "
                + "FROM driver d JOIN worker w ON w.wrk_AT = d.drv_AT ORDER BY d.drv_license DESC, w.wrk_lname";
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {
            while (rs.next()) {
                list.add(rs.getString(1) + " | " + rs.getString(2) + " " + rs.getString(3)
                        + " (licence " + rs.getString(4) + ", " + rs.getString(5) + ")");
            }
        }
        return list;
    }

    /**
     * Guides for the trip form (3.2.2), as "AT | Name Lastname (languages)".
     * Use UniversalTableManager.optionKey() to get the AT.
     */
    public List<String> getGuideOptions() throws SQLException {
        List<String> list = new ArrayList<>();
        String query = """
                    SELECT g.gui_AT, w.wrk_name, w.wrk_lname,
                           GROUP_CONCAT(DISTINCT COALESCE(lr.lang_name, l.lng_language_code)
                                        ORDER BY lr.lang_name SEPARATOR ', ') AS languages
                    FROM guide g
                    JOIN worker w ON w.wrk_AT = g.gui_AT
                    LEFT JOIN languages l ON l.lng_gui_AT = g.gui_AT
                    LEFT JOIN language_ref lr ON lr.lang_code = l.lng_language_code
                    GROUP BY g.gui_AT, w.wrk_name, w.wrk_lname
                    ORDER BY w.wrk_lname
                """;
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {
            while (rs.next()) {
                String languages = rs.getString("languages");
                list.add(rs.getString(1) + " | " + rs.getString(2) + " " + rs.getString(3)
                        + (languages == null || languages.isBlank() ? "" : " (" + languages + ")"));
            }
        }
        return list;
    }

    /** Language codes (language_ref) for the guide language list. */
    public List<String> getLanguageCodes() throws SQLException {
        List<String> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT lang_code, lang_name FROM language_ref ORDER BY lang_code")) {
            while (rs.next()) {
                list.add(rs.getString(1) + " | " + rs.getString(2));
            }
        }
        return list;
    }

    public void updateSalary(String AT, double newSalary) throws SQLException {
        // This should trigger trg_worker_salary_increase
        String query = "UPDATE worker SET wrk_salary = ? WHERE wrk_AT = ?";
        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {
            pstmt.setDouble(1, newSalary);
            pstmt.setString(2, AT);
            pstmt.executeUpdate();
        }
    }
}
