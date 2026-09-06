package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import java.sql.SQLException;
import java.util.List;

public class WorkerView {

    private TableView<Worker> table;
    private WorkerDAO dao;
    private BranchDAO branchDAO;

    public WorkerView() {
        dao = new WorkerDAO();
        branchDAO = new BranchDAO();
        table = new TableView<>();
    }

    public VBox getView() {
        VBox layout = new VBox(10);
        layout.setPadding(new Insets(10));

        Label title = new Label("Staff Management");
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

        // Table Columns
        TableColumn<Worker, String> atCol = new TableColumn<>("ID (AT)");
        atCol.setCellValueFactory(new PropertyValueFactory<>("AT"));

        TableColumn<Worker, String> nameCol = new TableColumn<>("Name");
        nameCol.setCellValueFactory(new PropertyValueFactory<>("name"));

        TableColumn<Worker, String> lnameCol = new TableColumn<>("Last Name");
        lnameCol.setCellValueFactory(new PropertyValueFactory<>("lastName"));

        TableColumn<Worker, Double> salaryCol = new TableColumn<>("Salary");
        salaryCol.setCellValueFactory(new PropertyValueFactory<>("salary"));

        TableColumn<Worker, Integer> branchCol = new TableColumn<>("Branch");
        branchCol.setCellValueFactory(new PropertyValueFactory<>("branchCode"));

        table.getColumns().addAll(atCol, nameCol, lnameCol, salaryCol, branchCol);
        refreshTable();

        // Form: worker data
        TextField txtAT = new TextField();
        txtAT.setPromptText("ID (AT), max 10");
        txtAT.setTextFormatter(new TextFormatter<>(c -> c.getControlNewText().length() <= 10 ? c : null));
        TextField txtName = new TextField();
        txtName.setPromptText("Name");
        TextField txtLName = new TextField();
        txtLName.setPromptText("Last Name");
        TextField txtEmail = new TextField();
        txtEmail.setPromptText("Email");
        TextField txtSalary = new TextField();
        txtSalary.setPromptText("Salary");
        txtSalary.setTextFormatter(new TextFormatter<>(c -> c.getControlNewText().matches("\\d*(\\.\\d*)?") ? c : null));

        ComboBox<Branch> cmbBranch = new ComboBox<>();
        cmbBranch.setPromptText("Select Branch");
        try {
            cmbBranch.getItems().addAll(branchDAO.getAllBranches());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Form: category (every worker is exactly one of driver / guide / admin)
        ComboBox<String> cmbCategory = new ComboBox<>();
        cmbCategory.getItems().addAll("DRIVER", "GUIDE", "ADMIN");
        cmbCategory.setPromptText("Category");

        ComboBox<String> cmbLicence = new ComboBox<>();
        cmbLicence.getItems().addAll("A", "B", "C", "D");
        cmbLicence.setPromptText("Licence");
        ComboBox<String> cmbRoute = new ComboBox<>();
        cmbRoute.getItems().addAll("LOCAL", "ABROAD");
        cmbRoute.setPromptText("Route");
        TextField txtExperience = new TextField();
        txtExperience.setPromptText("Experience (years)");
        txtExperience.setTextFormatter(new TextFormatter<>(c -> c.getControlNewText().matches("\\d*") ? c : null));

        TextField txtCv = new TextField();
        txtCv.setPromptText("Guide CV");
        ComboBox<String> cmbLanguage = new ComboBox<>();
        cmbLanguage.setPromptText("Language");
        try {
            cmbLanguage.getItems().addAll(dao.getLanguageCodes());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        ComboBox<String> cmbAdminType = new ComboBox<>();
        cmbAdminType.getItems().addAll("LOGISTICS", "ADMINISTRATIVE", "ACCOUNTING");
        cmbAdminType.setPromptText("Admin type");
        TextField txtDiploma = new TextField();
        txtDiploma.setPromptText("Diploma");

        HBox driverBox = new HBox(12,
                Forms.field("Licence *", cmbLicence, 110),
                Forms.field("Route *", cmbRoute, 130),
                Forms.field("Experience (years)", txtExperience, 140));
        HBox guideBox = new HBox(12,
                Forms.field("Guide CV", txtCv, 220),
                Forms.field("Language", cmbLanguage, 180));
        HBox adminBox = new HBox(12,
                Forms.field("Admin type *", cmbAdminType, 170),
                Forms.field("Diploma", txtDiploma, 180));
        driverBox.setVisible(false);
        guideBox.setVisible(false);
        adminBox.setVisible(false);
        driverBox.managedProperty().bind(driverBox.visibleProperty());
        guideBox.managedProperty().bind(guideBox.visibleProperty());
        adminBox.managedProperty().bind(adminBox.visibleProperty());
        cmbCategory.setOnAction(e -> {
            String c = cmbCategory.getValue();
            driverBox.setVisible("DRIVER".equals(c));
            guideBox.setVisible("GUIDE".equals(c));
            adminBox.setVisible("ADMIN".equals(c));
        });

        Button btnAdd = new Button("Add Worker");
        btnAdd.setOnAction(e -> {
            try {
                if (cmbBranch.getValue() == null || cmbCategory.getValue() == null) {
                    showAlert("Validation Error", "Select a branch and a category.");
                    return;
                }
                if (txtAT.getText().isBlank() || txtName.getText().isBlank() || txtLName.getText().isBlank()) {
                    showAlert("Validation Error", "ID, name and last name are required.");
                    return;
                }
                String category = cmbCategory.getValue();
                String d1 = null, d2 = null;
                Integer d3 = null;
                switch (category) {
                    case "DRIVER" -> {
                        if (cmbLicence.getValue() == null || cmbRoute.getValue() == null) {
                            showAlert("Validation Error", "Select the driver's licence and route.");
                            return;
                        }
                        d1 = cmbLicence.getValue();
                        d2 = cmbRoute.getValue();
                        d3 = txtExperience.getText().isBlank() ? 0 : Integer.parseInt(txtExperience.getText());
                    }
                    case "GUIDE" -> {
                        d1 = txtCv.getText();
                        d2 = cmbLanguage.getValue() == null ? null : cmbLanguage.getValue().split(" \\| ")[0];
                    }
                    case "ADMIN" -> {
                        if (cmbAdminType.getValue() == null) {
                            showAlert("Validation Error", "Select the admin type.");
                            return;
                        }
                        d1 = cmbAdminType.getValue();
                        d2 = txtDiploma.getText();
                    }
                }
                Worker w = new Worker(
                        txtAT.getText().trim(),
                        txtName.getText().trim(),
                        txtLName.getText().trim(),
                        Double.parseDouble(txtSalary.getText()),
                        cmbBranch.getValue().getId());
                dao.addWorker(w, txtEmail.getText().trim(), category, d1, d2, d3);
                refreshTable();
                clearForm(txtAT, txtName, txtLName, txtEmail, txtSalary, txtExperience, txtCv, txtDiploma);
                cmbBranch.getSelectionModel().clearSelection();
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (NumberFormatException ex) {
                showAlert("Error", "Salary is required and must be a number.");
            }
        });

        Button btnUpdateSalary = new Button("Update Salary (+Trigger Test)");
        btnUpdateSalary.setStyle("-fx-background-color: #ccffcc;");
        btnUpdateSalary.setOnAction(e -> {
            Worker selected = table.getSelectionModel().getSelectedItem();
            if (selected != null) {
                TextInputDialog dialog = new TextInputDialog(String.valueOf(selected.getSalary()));
                dialog.setTitle("Update Salary");
                dialog.setHeaderText("Update Salary for " + selected.getName());
                dialog.setContentText("New Salary:");

                dialog.showAndWait().ifPresent(newSal -> {
                    try {
                        dao.updateSalary(selected.getAT(), Double.parseDouble(newSal));
                        refreshTable();
                        showAlert("Success", "Salary updated successfully!");
                    } catch (SQLException ex) {
                        // This catches the trigger error!
                        showAlert("Trigger Denied", "Database Trigger prevented update:\n" + ex.getMessage());
                    } catch (NumberFormatException ex) {
                        showAlert("Error", "Salary must be a number.");
                    }
                });
            } else {
                showAlert("Warning", "Select a worker to update.");
            }
        });

        FlowPane form = Forms.row(
                Forms.field("ID (AT) *", txtAT, 120),
                Forms.field("Name *", txtName, 140),
                Forms.field("Last name *", txtLName, 140),
                Forms.field("Email", txtEmail, 180),
                Forms.field("Salary * €", txtSalary, 110),
                Forms.field("Branch *", cmbBranch, 190),
                Forms.field("Category *", cmbCategory, 140));
        FlowPane form2 = Forms.row(driverBox, guideBox, adminBox, Forms.action(btnAdd));

        layout.getChildren().addAll(title, table, form, form2, btnUpdateSalary);
        return layout;
    }

    private void refreshTable() {
        try {
            List<Worker> list = dao.getAllWorkers();
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
