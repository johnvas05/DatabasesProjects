package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.FlowPane;
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
        TableColumn<Vehicle, Integer> idCol = new TableColumn<>("ID");
        idCol.setCellValueFactory(new PropertyValueFactory<>("id"));
        TableColumn<Vehicle, String> plateCol = new TableColumn<>("Plate");
        plateCol.setCellValueFactory(new PropertyValueFactory<>("licensePlate"));
        TableColumn<Vehicle, String> brandCol = new TableColumn<>("Brand");
        brandCol.setCellValueFactory(new PropertyValueFactory<>("brand"));
        TableColumn<Vehicle, String> modelCol = new TableColumn<>("Model");
        modelCol.setCellValueFactory(new PropertyValueFactory<>("model"));
        TableColumn<Vehicle, String> typeCol = new TableColumn<>("Type");
        typeCol.setCellValueFactory(new PropertyValueFactory<>("type"));
        TableColumn<Vehicle, Integer> seatsCol = new TableColumn<>("Seats");
        seatsCol.setCellValueFactory(new PropertyValueFactory<>("seats"));
        TableColumn<Vehicle, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(new PropertyValueFactory<>("status"));
        TableColumn<Vehicle, Integer> mileageCol = new TableColumn<>("Mileage");
        mileageCol.setCellValueFactory(new PropertyValueFactory<>("mileage"));
        TableColumn<Vehicle, Integer> branchCol = new TableColumn<>("Branch");
        branchCol.setCellValueFactory(new PropertyValueFactory<>("branchCode"));

        table.getColumns().addAll(idCol, plateCol, brandCol, modelCol, typeCol, seatsCol, statusCol, mileageCol,
                branchCol);
        refreshTable();

        // Form (3.2.2: lists for branch, type and status; numeric-only seats and mileage)
        TextField txtPlate = new TextField();
        txtPlate.setPromptText("License Plate");
        TextField txtBrand = new TextField();
        txtBrand.setPromptText("Brand");
        TextField txtModel = new TextField();
        txtModel.setPromptText("Model");

        ComboBox<String> cmbType = new ComboBox<>();
        cmbType.getItems().addAll("Bus", "Mini-Bus", "Van", "Car");
        cmbType.setPromptText("Type");

        TextField txtSeats = new TextField();
        txtSeats.setPromptText("Seats");
        txtSeats.setTextFormatter(new TextFormatter<>(c -> c.getControlNewText().matches("\\d*") ? c : null));
        cmbType.setOnAction(e -> {
            String t = cmbType.getValue();
            if (t != null) {
                txtSeats.setPromptText(switch (t) {
                    case "Bus" -> "Seats (> 20)";
                    case "Mini-Bus" -> "Seats (10-20)";
                    case "Van" -> "Seats (6-9)";
                    default -> "Seats (1-5)";
                });
            }
        });

        ComboBox<String> cmbStatus = new ComboBox<>();
        cmbStatus.getItems().addAll("Available", "InUse", "Maintenance");
        cmbStatus.setValue("Available");

        TextField txtMileage = new TextField("0");
        txtMileage.setPromptText("Mileage (km)");
        txtMileage.setTextFormatter(new TextFormatter<>(c -> c.getControlNewText().matches("\\d*") ? c : null));

        ComboBox<Branch> cmbBranch = new ComboBox<>();
        cmbBranch.setPromptText("Select Branch");
        try {
            cmbBranch.getItems().addAll(new BranchDAO().getAllBranches());
        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        Button btnAdd = new Button("Add Vehicle");
        btnAdd.setOnAction(e -> {
            try {
                if (cmbBranch.getValue() == null || cmbType.getValue() == null) {
                    showAlert("Validation Error", "Select a branch and a vehicle type.");
                    return;
                }
                if (txtPlate.getText().isBlank() || txtBrand.getText().isBlank() || txtModel.getText().isBlank()) {
                    showAlert("Validation Error", "Plate, brand and model are required.");
                    return;
                }
                Vehicle v = new Vehicle(
                        txtPlate.getText().trim(),
                        txtModel.getText().trim(),
                        txtBrand.getText().trim(),
                        cmbType.getValue(),
                        Integer.parseInt(txtSeats.getText()),
                        cmbStatus.getValue(),
                        txtMileage.getText().isBlank() ? 0 : Integer.parseInt(txtMileage.getText()),
                        cmbBranch.getValue().getId());
                vehicleDAO.addVehicle(v);
                refreshTable();
                txtPlate.clear();
                txtModel.clear();
                txtBrand.clear();
                txtSeats.clear();
                txtMileage.setText("0");
                cmbType.getSelectionModel().clearSelection();
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (NumberFormatException ex) {
                showAlert("Error", "Seats are required and must be a number.");
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

        FlowPane form = Forms.row(
                Forms.field("License plate *", txtPlate, 140),
                Forms.field("Brand *", txtBrand, 130),
                Forms.field("Model *", txtModel, 130),
                Forms.field("Type *", cmbType, 130),
                Forms.field("Seats * (must match the type)", txtSeats, 180));
        FlowPane form2 = Forms.row(
                Forms.field("Status", cmbStatus, 140),
                Forms.field("Mileage (km)", txtMileage, 120),
                Forms.field("Branch *", cmbBranch, 190),
                Forms.action(btnAdd),
                Forms.action(btnDelete));

        layout.getChildren().addAll(title, table, form, form2);
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

    private void showAlert(String title, String message) {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.setTitle(title);
        alert.setHeaderText(null);
        alert.setContentText(message);
        alert.showAndWait();
    }
}
