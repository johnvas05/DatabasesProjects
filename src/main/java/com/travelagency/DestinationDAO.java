package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DestinationDAO {

    public List<Destination> getAllDestinations() throws SQLException {
        List<Destination> list = new ArrayList<>();
        String query = "SELECT * FROM destination";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new Destination(
                        rs.getInt("dst_id"),
                        rs.getString("dst_name"),
                        rs.getString("dst_descr"),
                        rs.getString("dst_rtype")));
            }
        }
        return list;
    }

    /**
     * Destinations that are cities (not parents of other destinations). Lodging
     * can only be attached to these (spec 3.1.2.2).
     */
    public List<Destination> getCityDestinations() throws SQLException {
        List<Destination> list = new ArrayList<>();
        String query = "SELECT * FROM destination d WHERE NOT EXISTS (SELECT 1 FROM destination c WHERE c.dst_location = d.dst_id) ORDER BY dst_name";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new Destination(
                        rs.getInt("dst_id"),
                        rs.getString("dst_name"),
                        rs.getString("dst_descr"),
                        rs.getString("dst_rtype")));
            }
        }
        return list;
    }
}
