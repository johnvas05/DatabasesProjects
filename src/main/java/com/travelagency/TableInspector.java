package com.travelagency;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

public class TableInspector {
    public static void main(String[] args) {
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement()) {

            ResultSet rs = stmt.executeQuery("SHOW CREATE TABLE log");
            if (rs.next()) {
                System.out.println("Log Table Definition:");
                System.out.println(rs.getString(2));
            }

            rs = stmt.executeQuery("SHOW CREATE TABLE branch");
            if (rs.next()) {
                System.out.println("Branch Table Definition:");
                System.out.println(rs.getString(2));
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
