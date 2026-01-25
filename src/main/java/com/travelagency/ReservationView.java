package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import java.sql.SQLException;
import java.util.List;

public class ReservationView {

    private TableView<Reservation> table;
    private ReservationDAO rDao;
    private CustomerDAO cDao;
    private TripDAO tDao;

    public ReservationView() {
        rDao = new ReservationDAO();
        cDao = new CustomerDAO();
        tDao = new TripDAO();
        table = new TableView<>();
    }

    public VBox getView() {
        VBox layout = new VBox(10);
        layout.setPadding(new Insets(10));

        Label title = new Label("Reservation Management");
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

        // Table Columns
        TableColumn<Reservation, String> trCol = new TableColumn<>("Trip");
        trCol.setCellValueFactory(new PropertyValueFactory<>("tripInfo"));

        TableColumn<Reservation, String> custCol = new TableColumn<>("Customer");
        custCol.setCellValueFactory(new PropertyValueFactory<>("customerName"));

        TableColumn<Reservation, Integer> seatCol = new TableColumn<>("Seat #");
        seatCol.setCellValueFactory(new PropertyValueFactory<>("seatNum"));

        TableColumn<Reservation, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(new PropertyValueFactory<>("status"));

        TableColumn<Reservation, Double> costCol = new TableColumn<>("Cost");
        costCol.setCellValueFactory(new PropertyValueFactory<>("totalCost"));

        table.getColumns().addAll(trCol, custCol, seatCol, statusCol, costCol);
        refreshTable();

        // Form
        // We need ComboBoxes for selecting Client and Trip
        ComboBox<Customer> cmbCustomer = new ComboBox<>();
        cmbCustomer.setPromptText("Select Customer");

        ComboBox<Trip> cmbTrip = new ComboBox<>();
        cmbTrip.setPromptText("Select Trip");

        // Populate combos
        try {
            cmbCustomer.getItems().addAll(cDao.getAllCustomers());
            cmbTrip.getItems().addAll(tDao.getAllTrips());

            // Need toString helper in Trip too for nice display
        } catch (SQLException e) {
            e.printStackTrace();
        }

        TextField txtSeat = new TextField();
        txtSeat.setPromptText("Seat Num");
        ComboBox<String> cmbStatus = new ComboBox<>();
        cmbStatus.getItems().addAll("PENDING", "PAID", "CONFIRMED", "CANCELLED");
        cmbStatus.setValue("PENDING");
        cmbStatus.setPromptText("Status");

        TextField txtCost = new TextField();
        txtCost.setPromptText("Cost");

        Button btnAdd = new Button("Book Reservation");
        btnAdd.setOnAction(e -> {
            try {
                if (cmbCustomer.getValue() == null || cmbTrip.getValue() == null) {
                    showAlert("Warning", "Select Customer and Trip.");
                    return;
                }

                Reservation r = new Reservation(
                        cmbTrip.getValue().getId(),
                        Integer.parseInt(txtSeat.getText()),
                        cmbCustomer.getValue().getId(),
                        cmbStatus.getValue(), // Selected status
                        Double.parseDouble(txtCost.getText()));
                rDao.addReservation(r);
                refreshTable();
                txtSeat.clear();
                txtCost.clear();
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (NumberFormatException ex) {
                showAlert("Error", "Check numeric fields.");
            }
        });

        HBox form = new HBox(10, cmbCustomer, cmbTrip, txtSeat, cmbStatus, txtCost, btnAdd);

        layout.getChildren().addAll(title, table, form);
        return layout;
    }

    private void refreshTable() {
        try {
            List<Reservation> list = rDao.getAllReservations();
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
