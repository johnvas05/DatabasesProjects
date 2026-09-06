package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import java.sql.SQLException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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

        // Form (3.2.2): customer and trip from the database, seat from the free
        // seats of the chosen trip, status from the allowed values. The cost is
        // computed by sp_calculate_reservation_cost (adult/child price by age).
        ComboBox<Customer> cmbCustomer = new ComboBox<>();
        cmbCustomer.setPromptText("Select Customer");

        ComboBox<Trip> cmbTrip = new ComboBox<>();
        cmbTrip.setPromptText("Select Trip");

        ComboBox<Integer> cmbSeat = new ComboBox<>();
        cmbSeat.setPromptText("Free seat");

        try {
            cmbCustomer.getItems().addAll(cDao.getAllCustomers());
            cmbTrip.getItems().addAll(tDao.getAllTrips());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        cmbTrip.setOnAction(e -> {
            cmbSeat.getItems().clear();
            Trip trip = cmbTrip.getValue();
            if (trip == null) {
                return;
            }
            try {
                Set<Integer> taken = new HashSet<>();
                for (Reservation r : rDao.getReservationsByTripId(trip.getId())) {
                    taken.add(r.getSeatNum());
                }
                for (int seat = 1; seat <= trip.getMaxSeats(); seat++) {
                    if (!taken.contains(seat)) {
                        cmbSeat.getItems().add(seat);
                    }
                }
                cmbSeat.setPromptText(cmbSeat.getItems().isEmpty() ? "Trip is full"
                        : "Free seat (" + cmbSeat.getItems().size() + " left)");
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        });

        ComboBox<String> cmbStatus = new ComboBox<>();
        cmbStatus.getItems().addAll("PENDING", "CONFIRMED", "PAID", "CANCELLED");
        cmbStatus.setValue("PENDING");

        Button btnAdd = new Button("Book Reservation");
        btnAdd.setOnAction(e -> {
            try {
                if (cmbCustomer.getValue() == null || cmbTrip.getValue() == null || cmbSeat.getValue() == null) {
                    showAlert("Validation Error", "Select a customer, a trip and a free seat.");
                    return;
                }
                Reservation r = new Reservation(
                        cmbTrip.getValue().getId(),
                        cmbSeat.getValue(),
                        cmbCustomer.getValue().getId(),
                        cmbStatus.getValue(),
                        0);
                rDao.addReservation(r);
                refreshTable();
                cmbTrip.getOnAction().handle(null); // refresh the free seats
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            }
        });

        FlowPane form = Forms.row(
                Forms.field("Customer * (age decides the price)", cmbCustomer, 230),
                Forms.field("Trip *", cmbTrip, 230),
                Forms.field("Seat * (free seats of the trip)", cmbSeat, 180),
                Forms.field("Status", cmbStatus, 140),
                Forms.action(btnAdd));

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
