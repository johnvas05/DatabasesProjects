package com.travelagency;

import java.sql.*;
import java.util.*;

public class UniversalTableManager {

    /**
     * Get all table names in the database
     */
    public static List<String> getAllTableNames() throws SQLException {
        Set<String> tablesSet = new LinkedHashSet<>(); // Use Set to automatically deduplicate
        try (Connection conn = DatabaseConnection.getConnection()) {
            DatabaseMetaData metaData = conn.getMetaData();
            String catalog = conn.getCatalog(); // Get current database name

            // Query only tables from the current catalog to avoid duplicates
            ResultSet rs = metaData.getTables(catalog, null, "%", new String[] { "TABLE" });

            while (rs.next()) {
                String tableName = rs.getString("TABLE_NAME");
                // Filter out system tables
                if (!tableName.toLowerCase().startsWith("sys_")) {
                    tablesSet.add(tableName);
                }
            }
        }
        List<String> tables = new ArrayList<>(tablesSet);
        Collections.sort(tables);
        return tables;
    }

    /**
     * Get column metadata for a specific table
     */
    public static List<ColumnInfo> getTableColumns(String tableName) throws SQLException {
        List<ColumnInfo> columns = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            DatabaseMetaData metaData = conn.getMetaData();
            ResultSet rs = metaData.getColumns(null, null, tableName, "%");

            while (rs.next()) {
                ColumnInfo col = new ColumnInfo();
                col.name = rs.getString("COLUMN_NAME");
                col.type = rs.getInt("DATA_TYPE");
                col.typeName = rs.getString("TYPE_NAME");
                col.nullable = rs.getInt("NULLABLE") == DatabaseMetaData.columnNullable;
                col.autoIncrement = rs.getString("IS_AUTOINCREMENT").equals("YES");
                columns.add(col);
            }
        }
        return columns;
    }

    /**
     * Get primary key columns for a table
     */
    public static List<String> getPrimaryKeys(String tableName) throws SQLException {
        List<String> pkColumns = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            DatabaseMetaData metaData = conn.getMetaData();
            ResultSet rs = metaData.getPrimaryKeys(null, null, tableName);

            while (rs.next()) {
                pkColumns.add(rs.getString("COLUMN_NAME"));
            }
        }
        return pkColumns;
    }

    /**
     * Get all rows from a table
     */
    public static List<Map<String, Object>> getAllRows(String tableName) throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();
        String query = "SELECT * FROM " + tableName;

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                for (int i = 1; i <= columnCount; i++) {
                    row.put(metaData.getColumnName(i), rs.getObject(i));
                }
                rows.add(row);
            }
        }
        return rows;
    }

    /**
     * Insert a new row
     */
    public static void executeInsert(String tableName, Map<String, Object> values) throws SQLException {
        StringBuilder sql = new StringBuilder("INSERT INTO " + tableName + " (");
        StringBuilder placeholders = new StringBuilder("VALUES (");

        List<String> columns = new ArrayList<>(values.keySet());
        for (int i = 0; i < columns.size(); i++) {
            sql.append(columns.get(i));
            placeholders.append("?");
            if (i < columns.size() - 1) {
                sql.append(", ");
                placeholders.append(", ");
            }
        }
        sql.append(") ").append(placeholders).append(")");

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {

            int index = 1;
            for (String col : columns) {
                pstmt.setObject(index++, values.get(col));
            }
            pstmt.executeUpdate();
        }
    }

    /**
     * Update an existing row
     */
    public static void executeUpdate(String tableName, Map<String, Object> values,
            Map<String, Object> whereClause) throws SQLException {
        StringBuilder sql = new StringBuilder("UPDATE " + tableName + " SET ");

        List<String> setCols = new ArrayList<>(values.keySet());
        for (int i = 0; i < setCols.size(); i++) {
            sql.append(setCols.get(i)).append(" = ?");
            if (i < setCols.size() - 1) {
                sql.append(", ");
            }
        }

        sql.append(" WHERE ");
        List<String> whereCols = new ArrayList<>(whereClause.keySet());
        for (int i = 0; i < whereCols.size(); i++) {
            sql.append(whereCols.get(i)).append(" = ?");
            if (i < whereCols.size() - 1) {
                sql.append(" AND ");
            }
        }

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {

            int index = 1;
            for (String col : setCols) {
                pstmt.setObject(index++, values.get(col));
            }
            for (String col : whereCols) {
                pstmt.setObject(index++, whereClause.get(col));
            }
            pstmt.executeUpdate();
        }
    }

    /**
     * Delete a row
     */
    public static void executeDelete(String tableName, Map<String, Object> whereClause) throws SQLException {
        StringBuilder sql = new StringBuilder("DELETE FROM " + tableName + " WHERE ");

        List<String> whereCols = new ArrayList<>(whereClause.keySet());
        for (int i = 0; i < whereCols.size(); i++) {
            sql.append(whereCols.get(i)).append(" = ?");
            if (i < whereCols.size() - 1) {
                sql.append(" AND ");
            }
        }

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {

            int index = 1;
            for (String col : whereCols) {
                pstmt.setObject(index++, whereClause.get(col));
            }
            pstmt.executeUpdate();
        }
    }

    /**
     * Column metadata holder
     */
    public static class ColumnInfo {
        public String name;
        public int type;
        public String typeName;
        public boolean nullable;
        public boolean autoIncrement;
    }
}
