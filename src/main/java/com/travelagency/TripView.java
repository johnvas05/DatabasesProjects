package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import javafx.scene.Scene;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

public class TripView {

    private TableView<Trip> table;
    private TripDAO dao;
    private BranchDAO branchDAO;
    private VehicleDAO vehicleDAO;

    public TripView() {
        dao = new TripDAO();
        branchDAO = new BranchDAO();
        vehicleDAO = new VehicleDAO();
        table = new TableView<>();
    }

    public VBox getView() {
        VBox layout = new VBox(10);
        layout.setPadding(new Insets(10));

        Label title = new Label("Trip Management");
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

        // Table Columns
        TableColumn<Trip, Integer> idCol = new TableColumn<>("ID");
        idCol.setCellValueFactory(new PropertyValueFactory<>("id"));

        TableColumn<Trip, Timestamp> depCol = new TableColumn<>("Departure");
        depCol.setCellValueFactory(new PropertyValueFactory<>("departure"));
        depCol.setCellFactory(column -> new TableCell<Trip, Timestamp>() {
            @Override
            protected void updateItem(Timestamp item, boolean empty) {
                super.updateItem(item, empty);
                if (empty || item == null) {
                    setText(null);
                } else {
                    // Remove trailing .0 if present
                    setText(item.toString().split("\\.")[0]);
                }
            }
        });

        TableColumn<Trip, Timestamp> retCol = new TableColumn<>("Return");
        retCol.setCellValueFactory(new PropertyValueFactory<>("returnDate"));
        retCol.setCellFactory(column -> new TableCell<Trip, Timestamp>() {
            @Override
            protected void updateItem(Timestamp item, boolean empty) {
                super.updateItem(item, empty);
                if (empty || item == null) {
                    setText(null);
                } else {
                    setText(item.toString().split("\\.")[0]);
                }
            }
        });

        TableColumn<Trip, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(new PropertyValueFactory<>("status"));

        TableColumn<Trip, Integer> seatsCol = new TableColumn<>("Max Seats");
        seatsCol.setCellValueFactory(new PropertyValueFactory<>("maxSeats"));

        TableColumn<Trip, Double> costCol = new TableColumn<>("Cost (Adult)");
        costCol.setCellValueFactory(new PropertyValueFactory<>("costAdult"));

        table.getColumns().addAll(idCol, depCol, retCol, statusCol, seatsCol, costCol);
        refreshTable();

        // Form
        Label lblInfo = new Label("Add Trip");
        lblInfo.setStyle("-fx-font-weight: bold;");

        // Dates are picked, not typed (3.2.2): date picker + hour list
        DatePicker dpDep = new DatePicker(LocalDate.now().plusDays(7));
        dpDep.setPromptText("Departure date");
        ComboBox<String> cmbDepTime = new ComboBox<>();
        DatePicker dpRet = new DatePicker(LocalDate.now().plusDays(12));
        dpRet.setPromptText("Return date");
        ComboBox<String> cmbRetTime = new ComboBox<>();
        for (int h = 0; h < 24; h++) {
            String hh = String.format("%02d:00", h);
            cmbDepTime.getItems().add(hh);
            cmbRetTime.getItems().add(hh);
        }
        cmbDepTime.setValue("08:00");
        cmbRetTime.setValue("20:00");

        ComboBox<String> cmbStatus = new ComboBox<>();
        cmbStatus.getItems().addAll("PLANNED", "CANCELLED", "CONFIRMED", "COMPLETED", "ACTIVE");
        cmbStatus.setValue("PLANNED");
        cmbStatus.setPromptText("Status");

        TextField txtSeats = new TextField("40");
        txtSeats.setPromptText("Max Seats");
        TextField txtCost = new TextField("500.00");
        txtCost.setPromptText("Cost Adult");

        // Dynamic Dropdowns
        ComboBox<Branch> cmbBranch = new ComboBox<>();
        cmbBranch.setPromptText("Select Branch");
        ComboBox<Vehicle> cmbVehicle = new ComboBox<>();
        cmbVehicle.setPromptText("Select Vehicle");
        // Driver and guide come from the database as well (3.2.2). The driver is
        // required: sp_assign_vehicle_to_trip refuses a vehicle with more than 9
        // seats unless the driver holds a C or D licence.
        ComboBox<String> cmbDriver = new ComboBox<>();
        cmbDriver.setPromptText("Select Driver");
        ComboBox<String> cmbGuide = new ComboBox<>();
        cmbGuide.setPromptText("Select Guide");

        try {
            cmbBranch.getItems().addAll(branchDAO.getAllBranches());
            // Smart Vehicle Selection: Load only available vehicles with 40+ seats by
            // default
            cmbVehicle.getItems().addAll(vehicleDAO.getAvailableVehicles(40));
            WorkerDAO workerDAO = new WorkerDAO();
            cmbDriver.getItems().addAll(workerDAO.getDriverOptions());
            cmbGuide.getItems().addAll(workerDAO.getGuideOptions());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Smart Vehicle Selection (Bonus 3.2.3): Update vehicles when max seats changes
        txtSeats.textProperty().addListener((obs, oldVal, newVal) -> {
            if (newVal != null && !newVal.trim().isEmpty()) {
                try {
                    int maxSeats = Integer.parseInt(newVal);
                    List<Vehicle> availableVehicles = vehicleDAO.getAvailableVehicles(maxSeats);
                    cmbVehicle.getItems().setAll(availableVehicles);

                    // Show info about filtering
                    if (availableVehicles.isEmpty()) {
                        cmbVehicle.setPromptText("No available vehicles with " + maxSeats + "+ seats");
                    } else {
                        cmbVehicle.setPromptText("Select Vehicle (" + availableVehicles.size() + " available)");
                    }
                } catch (NumberFormatException ex) {
                    // Invalid number, ignore
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
        });

        Button btnAdd = new Button("Add Trip");
        btnAdd.setOnAction(e -> {
            try {
                if (cmbBranch.getValue() == null || cmbVehicle.getValue() == null) {
                    showAlert("Validation Error", "Please select a Branch and a Vehicle.");
                    return;
                }
                if (cmbDriver.getValue() == null) {
                    showAlert("Validation Error",
                            "Please select a Driver: the vehicle can only be assigned to a trip that has one.");
                    return;
                }

                if (dpDep.getValue() == null || dpRet.getValue() == null) {
                    showAlert("Validation Error", "Pick a departure and a return date.");
                    return;
                }
                Timestamp dep = Timestamp.valueOf(LocalDateTime.of(dpDep.getValue(), LocalTime.parse(cmbDepTime.getValue())));
                Timestamp ret = Timestamp.valueOf(LocalDateTime.of(dpRet.getValue(), LocalTime.parse(cmbRetTime.getValue())));
                if (!ret.after(dep)) {
                    showAlert("Validation Error", "Return must be after departure.");
                    return;
                }

                Trip t = new Trip(
                        dep,
                        ret,
                        Integer.parseInt(txtSeats.getText()),
                        Double.parseDouble(txtCost.getText()),
                        Double.parseDouble(txtCost.getText()) / 2, // Child cost default
                        cmbStatus.getValue(),
                        10, // Min participants
                        cmbBranch.getValue().getId(),
                        0, // vehicle is assigned below through sp_assign_vehicle_to_trip
                        UniversalTableManager.optionKey(cmbGuide.getValue()),
                        UniversalTableManager.optionKey(cmbDriver.getValue()));
                int tripId = dao.addTrip(t);
                Vehicle v = cmbVehicle.getValue();
                try {
                    // Requirement 3.1.3.1: the stored procedure runs all checks and sets the vehicle InUse
                    String report = dao.assignVehicle(tripId, v.getId(), v.getMileage());
                    refreshTable();
                    showAlert("Trip " + tripId + " created", report);
                } catch (SQLException ex) {
                    refreshTable();
                    showAlert("Trip " + tripId + " created without vehicle", ex.getMessage());
                }
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (IllegalArgumentException ex) {
                showAlert("Format Error", "Max seats and cost must be numbers.");
            }
        });

        FlowPane form = Forms.row(
                Forms.field("Departure date", dpDep),
                Forms.field("Departure time", cmbDepTime, 100),
                Forms.field("Return date", dpRet),
                Forms.field("Return time", cmbRetTime, 100),
                Forms.field("Status", cmbStatus, 130),
                Forms.field("Max seats", txtSeats, 90),
                Forms.field("Cost (adult) €", txtCost, 110));
        FlowPane form2 = Forms.row(
                Forms.field("Branch", cmbBranch, 190),
                Forms.field("Driver (licence decides the vehicle)", cmbDriver, 260),
                Forms.field("Guide", cmbGuide, 220),
                Forms.field("Vehicle (available, enough seats)", cmbVehicle, 240),
                Forms.action(btnAdd));

        Button btnDetails = new Button("Show Trip Details (Bonus 3.2.3)");
        btnDetails.setStyle("-fx-background-color: #e6e6fa;");
        btnDetails.setOnAction(e -> {
            Trip selected = table.getSelectionModel().getSelectedItem();
            if (selected != null) {
                showTripDetails(selected);
            } else {
                showAlert("Warning", "Select a trip to view details.");
            }
        });

        Button btnAutoBook = new Button("Auto-Book Accommodations ");
        btnAutoBook.setStyle("-fx-background-color: #90ee90; -fx-font-weight: bold;");
        btnAutoBook.setOnAction(e -> {
            Trip selected = table.getSelectionModel().getSelectedItem();
            if (selected != null) {
                // Confirm before booking
                Alert confirm = new Alert(Alert.AlertType.CONFIRMATION);
                confirm.setTitle("Auto-Book Accommodations");
                confirm.setHeaderText("Book hotels for Trip #" + selected.getId() + "?");
                confirm.setContentText("This will automatically book accommodations for ALL destinations.\n" +
                        "Note: Any existing bookings for this trip will be removed first.");

                confirm.showAndWait().ifPresent(response -> {
                    if (response == ButtonType.OK) {
                        try {
                            // First, delete any existing accommodations for this trip
                            try (Connection conn = DatabaseConnection.getConnection();
                                    PreparedStatement pstmt = conn.prepareStatement(
                                            "DELETE FROM room_usage WHERE ru_trip_id = ?")) {
                                pstmt.setInt(1, selected.getId());
                                pstmt.executeUpdate();
                            }

                            // Now call the stored procedure
                            String result = dao.autoBookAccommodations(selected.getId());
                            refreshTable();
                            showAlert("Success - Stored Procedure Executed!", result);
                        } catch (SQLException ex) {
                            showAlert("Booking Failed", ex.getMessage());
                        }
                    }
                });
            } else {
                showAlert("Warning", "Select a trip to book accommodations for.");
            }
        });

        HBox buttonBox = new HBox(10, btnDetails, btnAutoBook);
        layout.getChildren().addAll(title, table, lblInfo, form, form2, buttonBox);
        return layout;
    }

    private void showTripDetails(Trip trip) {
        Stage stage = new Stage();
        stage.setTitle("Trip Details: ID " + trip.getId());

        VBox root = new VBox(12);
        root.setPadding(new Insets(15));
        root.setStyle("-fx-background-color: #f5f5f5;");

        // Trip Info Section
        Label lblHeader = new Label("Trip Information");
        lblHeader.setStyle("-fx-font-weight: bold; -fx-font-size: 16px; -fx-text-fill: #2c3e50;");

        TextArea txtInfo = new TextArea();
        txtInfo.setEditable(false);
        txtInfo.setPrefRowCount(3);
        txtInfo.setStyle("-fx-font-family: monospace;");
        txtInfo.setText(
                "Departure: " + trip.getDeparture() + "\n" +
                        "Return: " + trip.getReturnDate() + "\n" +
                        "Cost (Adult): $" + trip.getCostAdult() + " | Status: " + trip.getStatus());

        // Driver & Guide Section (Bonus 3.2.3)
        Label lblStaff = new Label("Staff Assignment");
        lblStaff.setStyle("-fx-font-weight: bold; -fx-font-size: 14px; -fx-text-fill: #2c3e50;");

        TextArea txtStaff = new TextArea();
        txtStaff.setEditable(false);
        txtStaff.setPrefRowCount(4);
        txtStaff.setStyle("-fx-font-family: monospace; -fx-background-color: #e8f4f8;");

        StringBuilder staffInfo = new StringBuilder();

        // Driver of the trip
        try {
            TripDAO.StaffInfo driver = dao.getDriverInfo(trip.getDriverId());
            if (driver != null) {
                staffInfo.append("🚗 DRIVER:\n");
                staffInfo.append("   Name: ").append(driver.name).append(" ").append(driver.lastName).append("\n");
                staffInfo.append("   License: ").append(driver.licence).append("\n");
                staffInfo.append("   Experience: ").append(driver.experience).append(" years\n");
            } else {
                staffInfo.append("🚗 DRIVER: Not assigned\n");
            }
        } catch (SQLException ex) {
            staffInfo.append("🚗 DRIVER: Error loading info\n");
        }

        staffInfo.append("\n");

        // Guide of the trip, with the languages they speak (languages table)
        try {
            TripDAO.StaffInfo guide = dao.getGuideInfo(trip.getGuideId());
            if (guide != null) {
                staffInfo.append("🗣️ GUIDE:\n");
                staffInfo.append("   Name: ").append(guide.name).append(" ").append(guide.lastName).append("\n");
                staffInfo.append("   Languages: ")
                        .append(guide.languages.isEmpty() ? "-" : guide.languages).append("\n");
            } else {
                staffInfo.append("🗣️ GUIDE: Not assigned\n");
            }
        } catch (SQLException ex) {
            staffInfo.append("🗣️ GUIDE: Error loading info\n");
        }

        txtStaff.setText(staffInfo.toString());

        // Accommodations Section (Bonus 3.2.3)
        Label lblAccom = new Label("Accommodations Booked");
        lblAccom.setStyle("-fx-font-weight: bold; -fx-font-size: 14px; -fx-text-fill: #2c3e50;");

        TextArea txtAccom = new TextArea();
        txtAccom.setEditable(false);
        txtAccom.setPrefRowCount(5);
        txtAccom.setStyle("-fx-font-family: monospace; -fx-background-color: #fff3cd;");

        StringBuilder accomInfo = new StringBuilder();
        try {
            List<TripDAO.AccommodationInfo> booked = dao.getAccommodations(trip.getId());
            if (booked.isEmpty()) {
                accomInfo
                        .append("No accommodations booked yet.\nUse 'Auto-Book Hotels' feature to book automatically.");
            } else {
                for (TripDAO.AccommodationInfo a : booked) {
                    accomInfo.append("🏨 ").append(a.lodgingName);
                    // only hotels and resorts have official stars (CHECK constraint)
                    accomInfo.append(" (").append(a.stars == null ? "" : a.stars + "-star ")
                            .append(a.type).append(")\n");
                    accomInfo.append("   Check-in: ").append(a.checkIn).append("\n");
                    accomInfo.append("   Check-out: ").append(a.checkOut).append("\n");
                    accomInfo.append("   Rooms: ").append(a.rooms)
                            .append(" | Cost: $").append(String.format("%.2f", a.cost))
                            .append("\n\n");
                }
            }
        } catch (SQLException ex) {
            accomInfo.append("Error loading accommodation info: ").append(ex.getMessage());
        }

        txtAccom.setText(accomInfo.toString());

        // Passengers Section
        Label lblPass = new Label("Passengers & Reservations");
        lblPass.setStyle("-fx-font-weight: bold; -fx-font-size: 14px; -fx-text-fill: #2c3e50;");

        TableView<Reservation> resTable = new TableView<>();
        resTable.setPrefHeight(150);

        TableColumn<Reservation, String> nameCol = new TableColumn<>("Customer Name");
        nameCol.setCellValueFactory(new PropertyValueFactory<>("customerName"));

        TableColumn<Reservation, Integer> seatCol = new TableColumn<>("Seat");
        seatCol.setCellValueFactory(new PropertyValueFactory<>("seatNum"));

        TableColumn<Reservation, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(new PropertyValueFactory<>("status"));

        resTable.getColumns().addAll(nameCol, seatCol, statusCol);

        // Load Data
        try {
            ReservationDAO rDao = new ReservationDAO();
            List<Reservation> passList = rDao.getReservationsByTripId(trip.getId());
            resTable.getItems().setAll(passList);
        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        root.getChildren().addAll(
                lblHeader, txtInfo,
                new Separator(),
                lblStaff, txtStaff,
                new Separator(),
                lblAccom, txtAccom,
                new Separator(),
                lblPass, resTable);

        ScrollPane scrollPane = new ScrollPane(root);
        scrollPane.setFitToWidth(true);

        Scene scene = new Scene(scrollPane, 600, 650);
        stage.setScene(scene);
        stage.show();
    }

    private void refreshTable() {
        try {
            List<Trip> list = dao.getAllTrips();
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
