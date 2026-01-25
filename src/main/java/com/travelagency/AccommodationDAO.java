package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AccommodationDAO {

    public List<Accommodation> getAllAccommodations() throws SQLException {
        List<Accommodation> list = new ArrayList<>();
        String query = "SELECT * FROM accommodation";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(mapResultSetToAccommodation(rs));
            }
        }
        return list;
    }

    // Requirement 3.1.3.2: Search functionality preparation (simple filter for now)
    public List<Accommodation> searchAccommodations(String activeOnly) throws SQLException {
        if (activeOnly == null || !activeOnly.equalsIgnoreCase("true"))
            return getAllAccommodations();

        List<Accommodation> list = new ArrayList<>();
        String query = "SELECT * FROM accommodation WHERE acc_active = TRUE";
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {
            while (rs.next()) {
                list.add(mapResultSetToAccommodation(rs));
            }
        }
        return list;
    }

    public void addAccommodation(Accommodation acc) throws SQLException {
        String query = "INSERT INTO accommodation (acc_name, acc_type, acc_stars, acc_rating, acc_active, acc_address, acc_phone, acc_email, acc_rooms, acc_price_per_night) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setString(1, acc.getName());
            pstmt.setString(2, acc.getType());
            pstmt.setInt(3, acc.getStars());
            pstmt.setDouble(4, acc.getRating());
            pstmt.setBoolean(5, acc.isActive());
            pstmt.setString(6, acc.getAddress());
            pstmt.setString(7, acc.getPhone());
            pstmt.setString(8, acc.getEmail());
            pstmt.setInt(9, acc.getRooms());
            pstmt.setDouble(10, acc.getPricePerNight());

            pstmt.executeUpdate();
        }
    }

    public void deleteAccommodation(int id) throws SQLException {
        String query = "DELETE FROM accommodation WHERE acc_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setInt(1, id);
            pstmt.executeUpdate();
        }
    }

    private Accommodation mapResultSetToAccommodation(ResultSet rs) throws SQLException {
        return new Accommodation(
                rs.getInt("acc_id"),
                rs.getString("acc_name"),
                rs.getString("acc_type"),
                rs.getInt("acc_stars"),
                rs.getDouble("acc_rating"),
                rs.getBoolean("acc_active"),
                rs.getString("acc_address"),
                rs.getString("acc_phone"),
                rs.getString("acc_email"),
                rs.getInt("acc_rooms"),
                rs.getDouble("acc_price_per_night"));
    }
}
