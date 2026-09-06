package com.travelagency;

import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.List;

public class AdminView {

    private TableView<LogEntry> table;
    private AdminDAO dao;

    public AdminView() {
        dao = new AdminDAO();
        table = new TableView<>();
    }

    public VBox getView() {
        VBox layout = new VBox(10);
        layout.setPadding(new Insets(10));

        TabPane tabs = new TabPane();

        // Tab 1: Logs
        Tab logTab = new Tab("System Logs", createLogView());
        logTab.setClosable(false);

        // Tab 2: Financials
        Tab finTab = new Tab("Branch Financials", createFinancialView());
        finTab.setClosable(false);

        tabs.getTabs().addAll(logTab, finTab);

        Label title = new Label("Admin Dashboard");
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

        layout.getChildren().addAll(title, tabs);
        return layout;
    }

    private VBox createLogView() {
        VBox box = new VBox(10);
        box.setPadding(new Insets(10));

        TableColumn<LogEntry, Timestamp> timeCol = new TableColumn<>("Time");
        timeCol.setCellValueFactory(new PropertyValueFactory<>("timestamp"));

        TableColumn<LogEntry, String> userCol = new TableColumn<>("User");
        userCol.setCellValueFactory(new PropertyValueFactory<>("username"));

        TableColumn<LogEntry, String> actionCol = new TableColumn<>("Action");
        actionCol.setCellValueFactory(new PropertyValueFactory<>("action"));

        TableColumn<LogEntry, String> tableCol = new TableColumn<>("Table");
        tableCol.setCellValueFactory(new PropertyValueFactory<>("tableName"));

        table.getColumns().addAll(timeCol, userCol, actionCol, tableCol);

        Button btnRefresh = new Button("Refresh Logs");
        btnRefresh.setOnAction(e -> refreshLogs());

        box.getChildren().addAll(btnRefresh, table);
        refreshLogs();
        return box;
    }

    private VBox createFinancialView() {
        VBox box = new VBox(10);
        box.setPadding(new Insets(10));

        ComboBox<Branch> cmbBranch = new ComboBox<>();
        cmbBranch.setPromptText("Select Branch");
        // Populating branch combo using a temporary DAO (or make it a field)
        try {
            BranchDAO bDao = new BranchDAO();
            cmbBranch.getItems().addAll(bDao.getAllBranches());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        TextArea txtResult = new TextArea();
        txtResult.setEditable(false);
        txtResult.setPrefRowCount(10);

        Button btnCalc = new Button("Calculate Financials (Stored Proc)");
        btnCalc.setOnAction(e -> {
            try {
                if (cmbBranch.getValue() == null) {
                    txtResult.setText("Please select a Branch.");
                    return;
                }
                String res = dao.getBranchFinancials(cmbBranch.getValue().getId());
                txtResult.setText(res);
            } catch (SQLException ex) {
                txtResult.setText("Error calling procedure:\n" + ex.getMessage());
            }
        });

        HBox input = new HBox(12,
                Forms.field("Branch", cmbBranch, 200),
                Forms.action(btnCalc));
        Label resultLabel = new Label("Result of sp_branch_financials");
        resultLabel.setStyle("-fx-font-size: 11px; -fx-text-fill: #555555;");
        box.getChildren().addAll(input, resultLabel, txtResult);
        return box;
    }

    private void refreshLogs() {
        try {
            List<LogEntry> list = dao.getAllLogs();
            table.getItems().setAll(list);
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
