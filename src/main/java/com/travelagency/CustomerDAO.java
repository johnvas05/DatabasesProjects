package com.travelagency;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CustomerDAO {

    public List<Customer> getAllCustomers() throws SQLException {
        List<Customer> list = new ArrayList<>();
        String query = "SELECT * FROM customer ORDER BY cust_lname, cust_name";

        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            while (rs.next()) {
                list.add(new Customer(
                        rs.getInt("cust_id"),
                        rs.getString("cust_name"),
                        rs.getString("cust_lname"),
                        rs.getString("cust_email"),
                        rs.getString("cust_phone"),
                        rs.getString("cust_address"),
                        rs.getDate("cust_birth_date")));
            }
        }
        return list;
    }

    public void addCustomer(Customer c) throws SQLException {
        String query = "INSERT INTO customer (cust_name, cust_lname, cust_email, cust_phone, cust_address, cust_birth_date) VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {

            pstmt.setString(1, c.getFirstName());
            pstmt.setString(2, c.getLastName());
            pstmt.setString(3, c.getEmail());
            pstmt.setString(4, c.getPhone());
            pstmt.setString(5, c.getAddress());
            pstmt.setDate(6, c.getBirthDate());

            pstmt.executeUpdate();
        }
    }

    // No delete needed immediately, but good practice usually
    public void deleteCustomer(int id) throws SQLException {
        String query = "DELETE FROM customer WHERE cust_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(query)) {
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
        }
    }
}
