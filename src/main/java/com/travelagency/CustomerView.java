package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import java.sql.Date;
import java.sql.SQLException;
import java.util.List;

public class CustomerView {

    private TableView<Customer> table;
    private CustomerDAO dao;

    public CustomerView() {
        dao = new CustomerDAO();
        table = new TableView<>();
    }

    public VBox getView() {
        VBox layout = new VBox(10);
        layout.setPadding(new Insets(10));

        Label title = new Label("Customer Management");
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

        // Table Columns
        TableColumn<Customer, String> firstCol = new TableColumn<>("First Name");
        firstCol.setCellValueFactory(new PropertyValueFactory<>("firstName"));

        TableColumn<Customer, String> lastCol = new TableColumn<>("Last Name");
        lastCol.setCellValueFactory(new PropertyValueFactory<>("lastName"));

        TableColumn<Customer, String> emailCol = new TableColumn<>("Email");
        emailCol.setCellValueFactory(new PropertyValueFactory<>("email"));

        TableColumn<Customer, String> phoneCol = new TableColumn<>("Phone");
        phoneCol.setCellValueFactory(new PropertyValueFactory<>("phone"));

        table.getColumns().addAll(firstCol, lastCol, emailCol, phoneCol);
        refreshTable();

        // Form
        TextField txtFirst = new TextField();
        txtFirst.setPromptText("First Name");
        TextField txtLast = new TextField();
        txtLast.setPromptText("Last Name");
        TextField txtEmail = new TextField();
        txtEmail.setPromptText("Email");
        TextField txtPhone = new TextField();
        txtPhone.setPromptText("Phone");
        TextField txtAddress = new TextField();
        txtAddress.setPromptText("Address");
        DatePicker dobPicker = new DatePicker();
        dobPicker.setPromptText("Birth Date");

        Button btnAdd = new Button("Add Customer");
        btnAdd.setOnAction(e -> {
            try {
                if (dobPicker.getValue() == null)
                    throw new IllegalArgumentException("Birth Date required");

                Customer c = new Customer(
                        txtFirst.getText(),
                        txtLast.getText(),
                        txtEmail.getText(),
                        txtPhone.getText(),
                        txtAddress.getText(),
                        Date.valueOf(dobPicker.getValue()));
                dao.addCustomer(c);
                refreshTable();
                clearForm(txtFirst, txtLast, txtEmail, txtPhone, txtAddress);
                dobPicker.setValue(null);
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (IllegalArgumentException ex) {
                showAlert("Input Error", ex.getMessage());
            }
        });

        FlowPane form = Forms.row(
                Forms.field("First name *", txtFirst),
                Forms.field("Last name *", txtLast),
                Forms.field("Email", txtEmail, 200),
                Forms.field("Phone", txtPhone),
                Forms.field("Address", txtAddress, 200),
                Forms.field("Birth date * (decides adult/child price)", dobPicker, 180),
                Forms.action(btnAdd));

        layout.getChildren().addAll(title, table, form);
        return layout;
    }

    private void refreshTable() {
        try {
            List<Customer> list = dao.getAllCustomers();
            table.getItems().setAll(list);
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private void clearForm(TextField... fields) {
        for (TextField f : fields)
            f.clear();
    }

    private void showAlert(String title, String message) {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.setTitle(title);
        alert.setHeaderText(null);
        alert.setContentText(message);
        alert.showAndWait();
    }
}
