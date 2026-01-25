package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
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

        // Form
        TextField txtAT = new TextField();
        txtAT.setPromptText("ID (AT)");
        TextField txtName = new TextField();
        txtName.setPromptText("Name");
        TextField txtLName = new TextField();
        txtLName.setPromptText("Last Name");
        TextField txtSalary = new TextField();
        txtSalary.setPromptText("Salary");

        ComboBox<Branch> cmbBranch = new ComboBox<>();
        cmbBranch.setPromptText("Select Branch");
        try {
            cmbBranch.getItems().addAll(branchDAO.getAllBranches());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        Button btnAdd = new Button("Add Worker");
        btnAdd.setOnAction(e -> {
            try {
                if (cmbBranch.getValue() == null) {
                    showAlert("Validation Error", "Please select a branch.");
                    return;
                }
                Worker w = new Worker(
                        txtAT.getText(),
                        txtName.getText(),
                        txtLName.getText(),
                        Double.parseDouble(txtSalary.getText()),
                        cmbBranch.getValue().getId());
                dao.addWorker(w);
                refreshTable();
                clearForm(txtAT, txtName, txtLName, txtSalary);
                cmbBranch.getSelectionModel().clearSelection();
            } catch (SQLException ex) {
                showAlert("Error", "Database Error: " + ex.getMessage());
            } catch (NumberFormatException ex) {
                showAlert("Error", "Check numeric fields.");
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
                    }
                });
            } else {
                showAlert("Warning", "Select a worker to update.");
            }
        });

        HBox form = new HBox(10, txtAT, txtName, txtLName, txtSalary, cmbBranch, btnAdd);

        layout.getChildren().addAll(title, table, form, btnUpdateSalary);
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
