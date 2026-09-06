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

    /** Inserts the trip and returns its generated id. A vehicle id of 0 means "no vehicle yet". */
    public int addTrip(Trip trip) throws SQLException {
        String query = "INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_min_participants, tr_br_code, tr_vehicle_id, tr_gui_AT, tr_drv_AT) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query, Statement.RETURN_GENERATED_KEYS)) {

            pstmt.setTimestamp(1, trip.getDeparture());
            pstmt.setTimestamp(2, trip.getReturnDate());
            pstmt.setInt(3, trip.getMaxSeats());
            pstmt.setDouble(4, trip.getCostAdult());
            pstmt.setDouble(5, trip.getCostChild());
            pstmt.setString(6, trip.getStatus());
            pstmt.setInt(7, trip.getMinParticipants());
            pstmt.setInt(8, trip.getBranchCode());
            if (trip.getVehicleId() > 0) {
                pstmt.setInt(9, trip.getVehicleId());
            } else {
                pstmt.setNull(9, Types.INTEGER);
            }
            pstmt.setString(10, trip.getGuideId());
            pstmt.setString(11, trip.getDriverId());

            pstmt.executeUpdate();
            try (ResultSet keys = pstmt.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    /**
     * Requirement 3.1.3.1: assign a vehicle through the stored procedure, which
     * checks availability, capacity, driver licence, date overlap and mileage.
     * Returns the PASS/FAIL report of the checks; throws SQLException (with the
     * list of failed checks) when the assignment is rejected.
     */
    public String assignVehicle(int tripId, int vehicleId, int currentMileage) throws SQLException {
        StringBuilder report = new StringBuilder();
        Connection conn = DatabaseConnection.getConnection();
        try (CallableStatement stmt = conn.prepareCall("{CALL sp_assign_vehicle_to_trip(?, ?, ?)}")) {
            stmt.setInt(1, tripId);
            stmt.setInt(2, vehicleId);
            stmt.setInt(3, currentMileage);
            try {
                boolean hasResults = stmt.execute();
                while (hasResults) {
                    try (ResultSet rs = stmt.getResultSet()) {
                        int cols = rs.getMetaData().getColumnCount();
                        while (rs.next()) {
                            for (int i = 1; i <= cols; i++) {
                                report.append(rs.getString(i)).append(i < cols ? " | " : "\n");
                            }
                        }
                    }
                    hasResults = stmt.getMoreResults();
                }
            } catch (SQLException e) {
                // the procedure reports every check first, then raises the error
                throw new SQLException(e.getMessage() + (report.length() > 0 ? "\n\n" + report : ""), e);
            }
        }
        return report.toString();
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

    /** One staff member as shown in the Trip Details window (3.2.3). */
    public static class StaffInfo {
        public String name;
        public String lastName;
        public String licence; // drivers only
        public int experience; // drivers only
        public String languages; // guides only, e.g. "French, English"
    }

    /** One booked accommodation as shown in the Trip Details window (3.2.3). */
    public static class AccommodationInfo {
        public String lodgingName;
        public String type;
        public Integer stars; // null for hostels, apartments and rooms
        public Date checkIn;
        public Date checkOut;
        public int rooms;
        public double cost;
    }

    /**
     * Driver of a trip for the Trip Details window. Returns null when the trip
     * has no driver or the worker no longer exists.
     */
    public StaffInfo getDriverInfo(String driverAT) throws SQLException {
        if (driverAT == null || driverAT.isBlank()) {
            return null;
        }
        String query = "SELECT w.wrk_name, w.wrk_lname, d.drv_license, d.drv_experience "
                + "FROM worker w JOIN driver d ON w.wrk_AT = d.drv_AT WHERE d.drv_AT = ?";
        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {
            pstmt.setString(1, driverAT);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                StaffInfo info = new StaffInfo();
                info.name = rs.getString("wrk_name");
                info.lastName = rs.getString("wrk_lname");
                info.licence = rs.getString("drv_license");
                info.experience = rs.getInt("drv_experience");
                return info;
            }
        }
    }

    /**
     * Guide of a trip for the Trip Details window. The languages come from the
     * languages table (a guide speaks one or more languages, section 2.3), named
     * through language_ref; guides without a language give an empty string.
     */
    public StaffInfo getGuideInfo(String guideAT) throws SQLException {
        if (guideAT == null || guideAT.isBlank()) {
            return null;
        }
        String query = """
                    SELECT w.wrk_name, w.wrk_lname,
                           GROUP_CONCAT(DISTINCT COALESCE(lr.lang_name, l.lng_language_code)
                                        ORDER BY lr.lang_name SEPARATOR ', ') AS languages
                    FROM worker w
                    JOIN guide g ON w.wrk_AT = g.gui_AT
                    LEFT JOIN languages l ON l.lng_gui_AT = g.gui_AT
                    LEFT JOIN language_ref lr ON lr.lang_code = l.lng_language_code
                    WHERE g.gui_AT = ?
                    GROUP BY w.wrk_name, w.wrk_lname
                """;
        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {
            pstmt.setString(1, guideAT);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                StaffInfo info = new StaffInfo();
                info.name = rs.getString("wrk_name");
                info.lastName = rs.getString("wrk_lname");
                String languages = rs.getString("languages");
                info.languages = languages == null ? "" : languages;
                return info;
            }
        }
    }

    /** Accommodations booked for a trip (room_usage), oldest check-in first. */
    public List<AccommodationInfo> getAccommodations(int tripId) throws SQLException {
        List<AccommodationInfo> list = new ArrayList<>();
        String query = "SELECT l.lg_name, l.lg_type, l.lg_stars, ru.ru_checkin, ru.ru_checkout, "
                + "ru.ru_rooms_count, ru.ru_total_cost "
                + "FROM room_usage ru JOIN lodging l ON ru.ru_lodging_id = l.lg_id "
                + "WHERE ru.ru_trip_id = ? ORDER BY ru.ru_checkin";
        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {
            pstmt.setInt(1, tripId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    AccommodationInfo a = new AccommodationInfo();
                    a.lodgingName = rs.getString("lg_name");
                    a.type = rs.getString("lg_type");
                    int stars = rs.getInt("lg_stars");
                    a.stars = rs.wasNull() ? null : stars;
                    a.checkIn = rs.getDate("ru_checkin");
                    a.checkOut = rs.getDate("ru_checkout");
                    a.rooms = rs.getInt("ru_rooms_count");
                    a.cost = rs.getDouble("ru_total_cost");
                    list.add(a);
                }
            }
        }
        return list;
    }

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
