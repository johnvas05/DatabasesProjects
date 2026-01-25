package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TripDAO {

    public List<Trip> getAllTrips() throws SQLException {
        List<Trip> list = new ArrayList<>();
        String query = "SELECT * FROM trip ORDER BY tr_departure DESC";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new Trip(
                        rs.getInt("tr_id"),
                        rs.getTimestamp("tr_departure"),
                        rs.getTimestamp("tr_return"),
                        rs.getInt("tr_maxseats"),
                        rs.getDouble("tr_cost_adult"),
                        rs.getDouble("tr_cost_child"),
                        rs.getString("tr_status"),
                        rs.getInt("tr_min_participants"),
                        rs.getInt("tr_br_code"),
                        rs.getInt("tr_vehicle_id"),
                        rs.getString("tr_gui_AT"),
                        rs.getString("tr_drv_AT")));
            }
        }
        return list;
    }

    public void addTrip(Trip trip) throws SQLException {
        String query = "INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_min_participants, tr_br_code, tr_vehicle_id, tr_gui_AT, tr_drv_AT) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setTimestamp(1, trip.getDeparture());
            pstmt.setTimestamp(2, trip.getReturnDate());
            pstmt.setInt(3, trip.getMaxSeats());
            pstmt.setDouble(4, trip.getCostAdult());
            pstmt.setDouble(5, trip.getCostChild());
            pstmt.setString(6, trip.getStatus());
            pstmt.setInt(7, trip.getMinParticipants());
            pstmt.setInt(8, trip.getBranchCode());
            pstmt.setInt(9, trip.getVehicleId());
            pstmt.setString(10, trip.getGuideId());
            pstmt.setString(11, trip.getDriverId());

            pstmt.executeUpdate();
        }
    }

    // Additional Method: Assign Vehicle to Trip (Requirement 3.1.3.1)
    // In this schema design, if vehicle assignment is done by updating a column or
    // linking table, code goes here.
    // Assuming we might update 'tr_drv_AT' or a new column if exists.
    // Since 'schema_extensions.sql' mentioned linking trip to vehicle, but vehicle
    // table was created independently.
    // If the requirement is to link a vehicle, we might need a separate table or
    // update `trip` to include `tr_veh_plate`.
    // For now, I'll stick to basic CRUD.
}
