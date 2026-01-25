package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import java.sql.SQLException;
import java.util.List;

public class AccommodationView {

    private TableView<Accommodation> table;
    private AccommodationDAO dao;

    public AccommodationView() {
        dao = new AccommodationDAO();
        table = new TableView<>();
    }

    public VBox getView() {
        VBox layout = new VBox(10);
        layout.setPadding(new Insets(10));

        Label title = new Label("Accommodation Management");
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

        // Table Columns
        TableColumn<Accommodation, String> nameCol = new TableColumn<>("Name");
        nameCol.setCellValueFactory(new PropertyValueFactory<>("name"));

        TableColumn<Accommodation, String> typeCol = new TableColumn<>("Type");
        typeCol.setCellValueFactory(new PropertyValueFactory<>("type"));

        TableColumn<Accommodation, Integer> starsCol = new TableColumn<>("Stars");
        starsCol.setCellValueFactory(new PropertyValueFactory<>("stars"));

        TableColumn<Accommodation, Double> priceCol = new TableColumn<>("Price/Night");
        priceCol.setCellValueFactory(new PropertyValueFactory<>("pricePerNight"));

        TableColumn<Accommodation, Integer> roomsCol = new TableColumn<>("Rooms");
        roomsCol.setCellValueFactory(new PropertyValueFactory<>("rooms"));

        table.getColumns().addAll(nameCol, typeCol, starsCol, priceCol, roomsCol);
        refreshTable();

        // Form
        TextField txtName = new TextField();
        txtName.setPromptText("Name");
        ComboBox<String> cmbType = new ComboBox<>();
        cmbType.getItems().addAll("Hotel", "Hostel", "Apartment", "Other");
        cmbType.setPromptText("Type");
        TextField txtStars = new TextField();
        txtStars.setPromptText("Stars (1-5)");
        TextField txtPrice = new TextField();
        txtPrice.setPromptText("Price");
        TextField txtAddress = new TextField();
        txtAddress.setPromptText("Address");
        CheckBox chkActive = new CheckBox("Active");
        chkActive.setSelected(true);

        Button btnAdd = new Button("Add Accommodation");
        btnAdd.setOnAction(e -> {
            try {
                Accommodation acc = new Accommodation(
                        txtName.getText(),
                        cmbType.getValue(),
                        txtStars.getText().isEmpty() ? 0 : Integer.parseInt(txtStars.getText()),
                        0.0, // rating default
                        chkActive.isSelected(),
                        txtAddress.getText(),
                        "", "", // phone, email skipped for brevity in form
                        10, // default rooms
                        Double.parseDouble(txtPrice.getText()));
                dao.addAccommodation(acc);
                refreshTable();
                clearForm(txtName, txtStars, txtPrice, txtAddress);
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (NumberFormatException ex) {
                showAlert("Error", "Check numeric fields.");
            }
        });

        Button btnDelete = new Button("Delete Selected");
        btnDelete.setStyle("-fx-background-color: #ffcccc;");
        btnDelete.setOnAction(e -> {
            Accommodation selected = table.getSelectionModel().getSelectedItem();
            if (selected != null) {
                try {
                    dao.deleteAccommodation(selected.getId());
                    refreshTable();
                } catch (SQLException ex) {
                    showAlert("Error", "Could not delete: " + ex.getMessage());
                }
            } else {
                showAlert("Warning", "Select an item to delete.");
            }
        });

        HBox form = new HBox(10, txtName, cmbType, txtStars, txtPrice, btnAdd);

        layout.getChildren().addAll(title, table, form, btnDelete);
        return layout;
    }

    private void refreshTable() {
        try {
            List<Accommodation> list = dao.getAllAccommodations();
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
