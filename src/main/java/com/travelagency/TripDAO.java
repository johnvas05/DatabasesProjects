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

    /**
     * Calls stored procedure to automatically book accommodations for all trip
     * destinations
     * Requirement 3.2.3 (Bonus): Use stored procedure sp_book_trip_accommodation
     * 
     * @param tripId The trip to book accommodations for
     * @return Success message or error details
     * @throws SQLException if procedure fails or no rooms available
     */
    public String autoBookAccommodations(int tripId) throws SQLException {
        String sql = "{CALL sp_book_trip_accommodation(?)}";

        try (Connection conn = DatabaseConnection.getConnection();
                CallableStatement stmt = conn.prepareCall(sql)) {

            stmt.setInt(1, tripId);

            // Execute the procedure
            stmt.execute();

            // Count how many accommodations were booked
            String countQuery = "SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(countQuery)) {
                pstmt.setInt(1, tripId);
                ResultSet rs = pstmt.executeQuery();
                if (rs.next()) {
                    int count = rs.getInt(1);
                    if (count > 0) {
                        return "✅ Success!\n\n" +
                                "Automatically booked " + count + " accommodation(s) for this trip.\n\n" +
                                "View details in 'Show Trip Details' → Accommodations section.";
                    } else {
                        return "⚠️ No accommodations booked.\n\n" +
                                "This trip may not have destinations in the travel_to table.";
                    }
                }
            }

            return "Stored procedure executed successfully!";

        } catch (SQLException e) {
            // Check if it's a stored procedure error (SIGNAL SQLSTATE '45000')
            if (e.getSQLState() != null && e.getSQLState().equals("45000")) {
                throw new SQLException("Booking Failed: " + e.getMessage());
            }
            throw e;
        }
    }
}
