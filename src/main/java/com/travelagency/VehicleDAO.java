package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VehicleDAO {

    public List<Vehicle> getAllVehicles() throws SQLException {
        List<Vehicle> list = new ArrayList<>();
        String query = "SELECT * FROM vehicle";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new Vehicle(
                        rs.getInt("v_id"),
                        rs.getString("v_license_plate"),
                        rs.getString("v_model"),
                        rs.getString("v_brand"),
                        rs.getString("v_type"),
                        rs.getInt("v_seats"),
                        rs.getString("v_status"),
                        rs.getInt("v_mileage"),
                        rs.getInt("v_br_code")));
            }
        }
        return list;
    }

    /**
     * Get only available vehicles with minimum seat capacity (Smart Filter for
     * Bonus 3.2.3)
     */
    public List<Vehicle> getAvailableVehicles(int minSeats) throws SQLException {
        List<Vehicle> list = new ArrayList<>();
        String query = "SELECT * FROM vehicle WHERE v_status = 'Available' AND v_seats >= ? ORDER BY v_seats ASC";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setInt(1, minSeats);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                list.add(new Vehicle(
                        rs.getInt("v_id"),
                        rs.getString("v_license_plate"),
                        rs.getString("v_model"),
                        rs.getString("v_brand"),
                        rs.getString("v_type"),
                        rs.getInt("v_seats"),
                        rs.getString("v_status"),
                        rs.getInt("v_mileage"),
                        rs.getInt("v_br_code")));
            }
        }
        return list;
    }

    public void addVehicle(Vehicle v) throws SQLException {
        String query = "INSERT INTO vehicle (v_license_plate, v_model, v_brand, v_type, v_seats, v_status, v_mileage, v_br_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setString(1, v.getLicensePlate());
            pstmt.setString(2, v.getModel());
            pstmt.setString(3, v.getBrand());
            pstmt.setString(4, v.getType());
            pstmt.setInt(5, v.getSeats());
            pstmt.setString(6, v.getStatus());
            pstmt.setInt(7, v.getMileage());
            pstmt.setInt(8, v.getBranchCode());

            pstmt.executeUpdate();
        }
    }

    public void updateVehicle(Vehicle v) throws SQLException {
        String query = "UPDATE vehicle SET v_license_plate=?, v_model=?, v_brand=?, v_type=?, v_seats=?, v_status=?, v_mileage=?, v_br_code=? WHERE v_id=?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setString(1, v.getLicensePlate());
            pstmt.setString(2, v.getModel());
            pstmt.setString(3, v.getBrand());
            pstmt.setString(4, v.getType());
            pstmt.setInt(5, v.getSeats());
            pstmt.setString(6, v.getStatus());
            pstmt.setInt(7, v.getMileage());
            pstmt.setInt(8, v.getBranchCode());
            pstmt.setInt(9, v.getId());

            pstmt.executeUpdate();
        }
    }

    public void deleteVehicle(int id) throws SQLException {
        String query = "DELETE FROM vehicle WHERE v_id=?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setInt(1, id);
            pstmt.executeUpdate();
        }
    }
}
