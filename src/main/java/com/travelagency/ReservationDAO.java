package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ReservationDAO {

    public List<Reservation> getAllReservations() throws SQLException {
        List<Reservation> list = new ArrayList<>();
        // Join with Customer and Trip to get readable names/dates
        String query = """
                    SELECT r.*, c.cust_name, c.cust_lname, t.tr_departure
                    FROM reservation r
                    JOIN customer c ON r.res_cust_id = c.cust_id
                    JOIN trip t ON r.res_tr_id = t.tr_id
                    ORDER BY t.tr_departure DESC, r.res_seatnum ASC
                """;

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new Reservation(
                        rs.getInt("res_tr_id"),
                        rs.getInt("res_seatnum"),
                        rs.getInt("res_cust_id"),
                        rs.getString("res_status"),
                        rs.getDouble("res_total_cost"),
                        rs.getString("cust_name") + " " + rs.getString("cust_lname"),
                        "Trip ID: " + rs.getInt("res_tr_id") + " (" + rs.getTimestamp("tr_departure") + ")"));
            }
        }
        return list;
    }

    public void addReservation(Reservation res) throws SQLException {
        String query = "INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setInt(1, res.getTr_id());
            pstmt.setInt(2, res.getSeatNum());
            pstmt.setInt(3, res.getCust_id());
            pstmt.setString(4, res.getStatus());
            pstmt.setDouble(5, res.getTotalCost());

            pstmt.executeUpdate();
        }
    }

    public List<Reservation> getReservationsByTripId(int tripId) throws SQLException {
        List<Reservation> list = new ArrayList<>();
        String query = """
                    SELECT r.*, c.cust_name, c.cust_lname, t.tr_departure
                    FROM reservation r
                    JOIN customer c ON r.res_cust_id = c.cust_id
                    JOIN trip t ON r.res_tr_id = t.tr_id
                    WHERE r.res_tr_id = ?
                    ORDER BY r.res_seatnum ASC
                """;

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setInt(1, tripId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    list.add(new Reservation(
                            rs.getInt("res_tr_id"),
                            rs.getInt("res_seatnum"),
                            rs.getInt("res_cust_id"),
                            rs.getString("res_status"),
                            rs.getDouble("res_total_cost"),
                            rs.getString("cust_name") + " " + rs.getString("cust_lname"),
                            "Trip ID: " + rs.getInt("res_tr_id")));
                }
            }
        }
        return list;
    }
}
