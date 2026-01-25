package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AdminDAO {

    public List<LogEntry> getAllLogs() throws SQLException {
        List<LogEntry> list = new ArrayList<>();
        String query = "SELECT * FROM log ORDER BY log_timestamp DESC";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new LogEntry(
                        rs.getInt("log_id"),
                        rs.getString("log_username"),
                        rs.getTimestamp("log_timestamp"),
                        rs.getString("log_action"),
                        rs.getString("log_table")));
            }
        }
        return list;
    }

    // Call Stored Procedure: sp_branch_financials
    public String getBranchFinancials(int branchCode) throws SQLException {
        String result = "";
        String sql = "{CALL sp_branch_financials(?, ?, ?, ?)}";

        try (Connection conn = DatabaseConnection.getConnection();
                CallableStatement stmt = conn.prepareCall(sql)) {

            stmt.setInt(1, branchCode);
            stmt.registerOutParameter(2, Types.DECIMAL); // Revenue
            stmt.registerOutParameter(3, Types.DECIMAL); // Expenses
            stmt.registerOutParameter(4, Types.DECIMAL); // Profit Ratio

            stmt.execute();

            double revenue = stmt.getDouble(2);
            double expenses = stmt.getDouble(3);
            double profitRatio = stmt.getDouble(4);

            if (stmt.wasNull()) {
                return "Branch " + branchCode + " not found or no data.";
            }

            result = String.format("""
                    Branch Code: %d
                    Revenue: %.2f
                    Expenses: %.2f
                    Profit Ratio: %.4f
                    """, branchCode, revenue, expenses, profitRatio);
        }
        return result;
    }
}
