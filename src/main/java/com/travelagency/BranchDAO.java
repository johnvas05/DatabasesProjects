package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class BranchDAO {

    public List<Branch> getAllBranches() throws SQLException {
        List<Branch> list = new ArrayList<>();
        String query = "SELECT * FROM branch";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new Branch(
                        rs.getInt("br_code"),
                        rs.getString("br_street"),
                        rs.getInt("br_num"),
                        rs.getString("br_city"),
                        rs.getString("br_manager_AT") // Keeping as String/AT
                ));
            }
        }
        return list;
    }
}
