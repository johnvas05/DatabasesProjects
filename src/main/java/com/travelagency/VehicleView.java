package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import java.sql.SQLException;
import java.util.List;

public class VehicleView {

    private TableView<Vehicle> table;
    private VehicleDAO vehicleDAO;

    public VehicleView() {
        vehicleDAO = new VehicleDAO();
        table = new TableView<>();
    }

    public VBox getView() {
        VBox layout = new VBox(10);
        layout.setPadding(new Insets(10));

        Label title = new Label("Vehicle Management");
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

        // Table Columns
        TableColumn<Vehicle, String> plateCol = new TableColumn<>("License Plate");
        plateCol.setCellValueFactory(new PropertyValueFactory<>("licensePlate"));

        TableColumn<Vehicle, String> modelCol = new TableColumn<>("Model");
        modelCol.setCellValueFactory(new PropertyValueFactory<>("model"));

        TableColumn<Vehicle, String> brandCol = new TableColumn<>("Brand");
        brandCol.setCellValueFactory(new PropertyValueFactory<>("brand"));

        TableColumn<Vehicle, String> typeCol = new TableColumn<>("Type");
        typeCol.setCellValueFactory(new PropertyValueFactory<>("type"));

        TableColumn<Vehicle, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(new PropertyValueFactory<>("status"));

        TableColumn<Vehicle, Integer> mileageCol = new TableColumn<>("Mileage");
        mileageCol.setCellValueFactory(new PropertyValueFactory<>("mileage"));

        table.getColumns().addAll(plateCol, modelCol, brandCol, typeCol, statusCol, mileageCol);
        refreshTable();

        // Form
        TextField txtPlate = new TextField();
        txtPlate.setPromptText("License Plate");
        TextField txtModel = new TextField();
        txtModel.setPromptText("Model");
        TextField txtBrand = new TextField();
        txtBrand.setPromptText("Brand");
        TextField txtStatus = new TextField(); // Could be ComboBox
        txtStatus.setPromptText("Status");
        TextField txtMileage = new TextField();
        txtMileage.setPromptText("Mileage");
        TextField txtSeats = new TextField();
        txtSeats.setPromptText("Seats");

        ComboBox<Branch> cmbBranch = new ComboBox<>();
        cmbBranch.setPromptText("Select Branch");
        try {
            BranchDAO branchDAO = new BranchDAO();
            cmbBranch.getItems().addAll(branchDAO.getAllBranches());
        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        ComboBox<String> cmbType = new ComboBox<>();
        cmbType.getItems().addAll("Bus", "Mini-Bus", "Van", "Car");
        cmbType.setPromptText("Type");

        Button btnAdd = new Button("Add Vehicle");
        btnAdd.setOnAction(e -> {
            try {
                if (cmbBranch.getValue() == null) {
                    showAlert("Validation Error", "Please select a Branch.");
                    return;
                }

                ComboBox<String> cmbStatus = new ComboBox<>();
                cmbStatus.getItems().addAll("Available", "InUse", "Maintenance");
                cmbStatus.setValue("Available");

                Vehicle v = new Vehicle(
                        txtPlate.getText(),
                        txtModel.getText(),
                        txtBrand.getText(),
                        cmbType.getValue(),
                        Integer.parseInt(txtSeats.getText()),
                        txtStatus.getText().isEmpty() ? "Available" : txtStatus.getText(),
                        Integer.parseInt(txtMileage.getText()),
                        cmbBranch.getValue().getId());
                vehicleDAO.addVehicle(v);
                refreshTable();
                clearForm(txtPlate, txtModel, txtBrand, txtStatus, txtMileage);
                cmbType.getSelectionModel().clearSelection();
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (NumberFormatException ex) {
                showAlert("Error", "Mileage must be a number.");
            } catch (Exception ex) {
                showAlert("Error", "Invalid Input: " + ex.getMessage());
            }
        });

        Button btnDelete = new Button("Delete Selected");
        btnDelete.setStyle("-fx-background-color: #ffcccc;");
        btnDelete.setOnAction(e -> {
            Vehicle selected = table.getSelectionModel().getSelectedItem();
            if (selected != null) {
                try {
                    vehicleDAO.deleteVehicle(selected.getId());
                    refreshTable();
                } catch (SQLException ex) {
                    showAlert("Error", "Could not delete: " + ex.getMessage());
                }
            } else {
                showAlert("Warning", "Select a vehicle to delete.");
            }
        });

        HBox form = new HBox(10, txtPlate, txtBrand, txtModel, cmbType, txtStatus, txtMileage, btnAdd);

        layout.getChildren().addAll(title, table, form, btnDelete);
        return layout;
    }

    private void refreshTable() {
        try {
            List<Vehicle> list = vehicleDAO.getAllVehicles();
            table.getItems().setAll(list);
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private void clearForm(TextField... fields) {
        for (TextField f : fields)
            f.clear();
    }

    private void clearForm(TextField t1, TextField t2, TextField t3, TextField t4, ComboBox<String> c1) {
        t1.clear();
        t2.clear();
        t3.clear();
        t4.clear();
        c1.getSelectionModel().clearSelection();
    }

    private void showAlert(String title, String message) {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.setTitle(title);
        alert.setHeaderText(null);
        alert.setContentText(message);
        alert.showAndWait();
    }
}
