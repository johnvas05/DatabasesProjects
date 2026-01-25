package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
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

        TableColumn<Lodging, Double> costCol = new TableColumn<>("Cost/Night");
        costCol.setCellValueFactory(new PropertyValueFactory<>("pricePerNight"));

        table.getColumns().addAll(nameCol, typeCol, starsCol, costCol);
        refreshTable();

        // Form
        ComboBox<Destination> cmbDest = new ComboBox<>();
        cmbDest.setPromptText("Select Destination");
        try {
            DestinationDAO dDao = new DestinationDAO();
            cmbDest.getItems().addAll(dDao.getAllDestinations());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        TextField txtName = new TextField();
        txtName.setPromptText("Name");
        TextField txtAddress = new TextField();
        txtAddress.setPromptText("Address");
        ComboBox<String> cmbType = new ComboBox<>();
        cmbType.getItems().addAll("Hotel", "Hostel", "Apartment", "Resort", "Room");
        cmbType.setPromptText("Type");
        TextField txtStars = new TextField();
        txtStars.setPromptText("Stars (1-5)");
        TextField txtCost = new TextField();
        txtCost.setPromptText("Price/Night");

        Button btnAdd = new Button("Add Lodging");
        btnAdd.setOnAction(e -> {
            if (cmbType.getValue() == null || cmbDest.getValue() == null) {
                showAlert("Validation Error", "Select Type and Destination.");
                return;
            }
            try {
                Lodging l = new Lodging(
                        cmbDest.getValue().getId(),
                        txtName.getText(),
                        cmbType.getValue(),
                        Integer.parseInt(txtStars.getText()),
                        0.0, // Default rating
                        "Active", // Default status
                        txtAddress.getText(),
                        "Pending City", // Default City
                        "00000", // Default Zip
                        "", // Phone
                        "", // Email
                        10, // Default rooms
                        Double.parseDouble(txtCost.getText()));
                lodgingDAO.addLodging(l);
                refreshTable();
                clearForm(txtName, txtAddress, txtStars, txtCost);
                cmbType.getSelectionModel().clearSelection();
                cmbDest.getSelectionModel().clearSelection();
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (NumberFormatException ex) {
                showAlert("Error", "Stars/Cost must be numbers.");
            } catch (Exception ex) {
                showAlert("Error", "Invalid Input: " + ex.getMessage());
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

        HBox form = new HBox(10, cmbDest, txtName, cmbType, txtAddress, txtStars, txtCost, btnAdd);

        layout.getChildren().addAll(title, table, form, btnDelete);
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
