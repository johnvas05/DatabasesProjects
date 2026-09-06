package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class LodgingDAO {

    public List<Lodging> getAllLodgings() throws SQLException {
        List<Lodging> lodgings = new ArrayList<>();
        String query = "SELECT * FROM lodging"; // Renamed from accommodation

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                lodgings.add(new Lodging(
                        rs.getInt("lg_id"),
                        rs.getInt("lg_dst_id"),
                        rs.getString("lg_name"),
                        rs.getString("lg_type"),
                        rs.getInt("lg_stars"),
                        rs.getDouble("lg_rating"),
                        rs.getString("lg_status"),
                        rs.getString("lg_address"),
                        rs.getString("lg_city"),
                        rs.getString("lg_postal_code"),
                        rs.getString("lg_phone"),
                        rs.getString("lg_email"),
                        rs.getInt("lg_total_rooms"),
                        rs.getDouble("lg_cost_per_night")));
            }
        }
        return lodgings;
    }

    public void addLodging(Lodging lodging) throws SQLException {
        String query = "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_rating, lg_status, lg_address, lg_city, lg_postal_code, lg_phone, lg_email, lg_total_rooms, lg_cost_per_night) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setInt(1, lodging.getDestinationId());
            pstmt.setString(2, lodging.getName());
            pstmt.setString(3, lodging.getType());
            if (lodging.getStars() > 0) {
                pstmt.setInt(4, lodging.getStars());
            } else {
                pstmt.setNull(4, Types.INTEGER);
            }
            pstmt.setDouble(5, lodging.getRating());
            pstmt.setString(6, lodging.getStatus());
            pstmt.setString(7, lodging.getAddress());
            pstmt.setString(8, lodging.getCity());
            pstmt.setString(9, lodging.getPostalCode());
            pstmt.setString(10, lodging.getPhone());
            pstmt.setString(11, lodging.getEmail());
            pstmt.setInt(12, lodging.getTotalRooms());
            pstmt.setDouble(13, lodging.getPricePerNight());

            pstmt.executeUpdate();
        }
    }

    public void deleteLodging(int id) throws SQLException {
        String query = "DELETE FROM lodging WHERE lg_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setInt(1, id);
            pstmt.executeUpdate();
        }
    }
}
