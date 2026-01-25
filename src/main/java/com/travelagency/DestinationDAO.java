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
}
