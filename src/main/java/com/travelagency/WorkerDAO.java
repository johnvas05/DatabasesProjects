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

    public void addWorker(Worker w) throws SQLException {
        String query = "INSERT INTO worker (wrk_AT, wrk_name, wrk_lname, wrk_salary, wrk_br_code) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setString(1, w.getAT());
            pstmt.setString(2, w.getName());
            pstmt.setString(3, w.getLastName());
            pstmt.setDouble(4, w.getSalary());
            pstmt.setInt(5, w.getBranchCode());

            pstmt.executeUpdate();
        }
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
