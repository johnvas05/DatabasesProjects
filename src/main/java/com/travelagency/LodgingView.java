package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import java.sql.SQLException;
import java.util.List;

public class LodgingView {

    private TableView<Lodging> table;
    private LodgingDAO lodgingDAO;

    public LodgingView() {
        lodgingDAO = new LodgingDAO();
        table = new TableView<>();
    }

    public VBox getView() {
        VBox layout = new VBox(10);
        layout.setPadding(new Insets(10));

        Label title = new Label("Lodging Management");
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

        // Table Columns
        TableColumn<Lodging, String> nameCol = new TableColumn<>("Name");
        nameCol.setCellValueFactory(new PropertyValueFactory<>("name"));
        TableColumn<Lodging, String> typeCol = new TableColumn<>("Type");
        typeCol.setCellValueFactory(new PropertyValueFactory<>("type"));
        TableColumn<Lodging, Integer> starsCol = new TableColumn<>("Stars");
        starsCol.setCellValueFactory(new PropertyValueFactory<>("stars"));
        TableColumn<Lodging, String> cityCol = new TableColumn<>("City");
        cityCol.setCellValueFactory(new PropertyValueFactory<>("city"));
        TableColumn<Lodging, Integer> roomsCol = new TableColumn<>("Rooms");
        roomsCol.setCellValueFactory(new PropertyValueFactory<>("totalRooms"));
        TableColumn<Lodging, Double> costCol = new TableColumn<>("Cost/Night");
        costCol.setCellValueFactory(new PropertyValueFactory<>("pricePerNight"));
        TableColumn<Lodging, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(new PropertyValueFactory<>("status"));

        table.getColumns().addAll(nameCol, typeCol, starsCol, cityCol, roomsCol, costCol, statusCol);
        refreshTable();

        // Form (3.2.2): destination, type, stars and status from lists; numeric-only rooms and price
        ComboBox<Destination> cmbDest = new ComboBox<>();
        cmbDest.setPromptText("City destination");
        try {
            // lodging belongs to city destinations only (3.1.2.2)
            cmbDest.getItems().addAll(new DestinationDAO().getCityDestinations());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        TextField txtName = new TextField();
        txtName.setPromptText("Name");
        ComboBox<String> cmbType = new ComboBox<>();
        cmbType.getItems().addAll("Hotel", "Hostel", "Resort", "Apartment", "Room");
        cmbType.setPromptText("Type");

        ComboBox<Integer> cmbStars = new ComboBox<>();
        cmbStars.getItems().addAll(1, 2, 3, 4, 5);
        cmbStars.setPromptText("Stars");
        cmbStars.setDisable(true); // only hotels and resorts have official stars
        cmbType.setOnAction(e -> {
            boolean starred = "Hotel".equals(cmbType.getValue()) || "Resort".equals(cmbType.getValue());
            cmbStars.setDisable(!starred);
            if (!starred) {
                cmbStars.getSelectionModel().clearSelection();
            }
        });

        ComboBox<String> cmbStatus = new ComboBox<>();
        cmbStatus.getItems().addAll("Active", "Inactive");
        cmbStatus.setValue("Active");

        TextField txtAddress = new TextField();
        txtAddress.setPromptText("Street and number");
        TextField txtCity = new TextField();
        txtCity.setPromptText("City");
        TextField txtPostal = new TextField();
        txtPostal.setPromptText("Postal code");
        TextField txtPhone = new TextField();
        txtPhone.setPromptText("Phone");
        TextField txtEmail = new TextField();
        txtEmail.setPromptText("Email");
        TextField txtRooms = new TextField();
        txtRooms.setPromptText("Total rooms");
        txtRooms.setTextFormatter(new TextFormatter<>(c -> c.getControlNewText().matches("\\d*") ? c : null));
        TextField txtCost = new TextField();
        txtCost.setPromptText("Price/night");
        txtCost.setTextFormatter(new TextFormatter<>(c -> c.getControlNewText().matches("\\d*(\\.\\d*)?") ? c : null));

        Button btnAdd = new Button("Add Lodging");
        btnAdd.setOnAction(e -> {
            if (cmbType.getValue() == null || cmbDest.getValue() == null) {
                showAlert("Validation Error", "Select the type and the destination.");
                return;
            }
            if (txtName.getText().isBlank() || txtAddress.getText().isBlank() || txtCity.getText().isBlank()) {
                showAlert("Validation Error", "Name, address and city are required.");
                return;
            }
            try {
                Lodging l = new Lodging(
                        cmbDest.getValue().getId(),
                        txtName.getText().trim(),
                        cmbType.getValue(),
                        cmbStars.getValue() == null ? 0 : cmbStars.getValue(),
                        0.0, // rating: from customer reviews, starts at 0
                        cmbStatus.getValue(),
                        txtAddress.getText().trim(),
                        txtCity.getText().trim(),
                        txtPostal.getText().trim(),
                        txtPhone.getText().trim(),
                        txtEmail.getText().trim(),
                        Integer.parseInt(txtRooms.getText()),
                        Double.parseDouble(txtCost.getText()));
                lodgingDAO.addLodging(l);
                refreshTable();
                clearForm(txtName, txtAddress, txtCity, txtPostal, txtPhone, txtEmail, txtRooms, txtCost);
                cmbType.getSelectionModel().clearSelection();
                cmbStars.getSelectionModel().clearSelection();
                cmbDest.getSelectionModel().clearSelection();
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (NumberFormatException ex) {
                showAlert("Error", "Total rooms and price per night are required numbers.");
            }
        });

        Button btnDelete = new Button("Delete Selected");
        btnDelete.setStyle("-fx-background-color: #ffcccc;");
        btnDelete.setOnAction(e -> {
            Lodging selected = table.getSelectionModel().getSelectedItem();
            if (selected != null) {
                try {
                    lodgingDAO.deleteLodging(selected.getId());
                    refreshTable();
                } catch (SQLException ex) {
                    showAlert("Error", "Could not delete: " + ex.getMessage());
                }
            } else {
                showAlert("Warning", "Select a lodging to delete.");
            }
        });

        FlowPane form = Forms.row(
                Forms.field("Destination * (cities only)", cmbDest, 190),
                Forms.field("Name *", txtName, 170),
                Forms.field("Type *", cmbType, 130),
                Forms.field("Stars (hotels and resorts only)", cmbStars, 190),
                Forms.field("Status", cmbStatus, 120),
                Forms.field("Total rooms *", txtRooms, 110),
                Forms.field("Price/night €", txtCost, 110));
        FlowPane form2 = Forms.row(
                Forms.field("Street and number *", txtAddress, 180),
                Forms.field("City *", txtCity, 140),
                Forms.field("Postal code", txtPostal, 110),
                Forms.field("Phone", txtPhone, 140),
                Forms.field("Email", txtEmail, 180),
                Forms.action(btnAdd),
                Forms.action(btnDelete));

        layout.getChildren().addAll(title, table, form, form2);
        return layout;
    }

    private void refreshTable() {
        try {
            List<Lodging> list = lodgingDAO.getAllLodgings();
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
