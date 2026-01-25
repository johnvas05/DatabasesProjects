package com.travelagency;

import javafx.beans.property.SimpleObjectProperty;
import javafx.collections.FXCollections;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.stage.Modality;
import javafx.stage.Stage;

import java.sql.SQLException;
import java.util.*;

public class UniversalTableView extends VBox {

    private ComboBox<String> tableSelector;
    private TableView<Map<String, Object>> dataTable;
    private Button insertBtn, updateBtn, deleteBtn, refreshBtn;
    private String currentTable;
    private List<String> primaryKeys;

    public UniversalTableView() {
        setSpacing(15);
        setPadding(new Insets(20));

        // Title
        Label title = new Label("Universal Table Manager");
        title.setStyle("-fx-font-size: 24px; -fx-font-weight: bold;");

        // Table selector
        HBox selectorBox = new HBox(10);
        selectorBox.setAlignment(Pos.CENTER_LEFT);
        Label selectorLabel = new Label("Select Table:");
        selectorLabel.setStyle("-fx-font-size: 14px;");

        tableSelector = new ComboBox<>();
        tableSelector.setPrefWidth(250);
        tableSelector.setOnAction(e -> loadTable());

        selectorBox.getChildren().addAll(selectorLabel, tableSelector);

        // Data table
        dataTable = new TableView<>();
        // Remove CONSTRAINED_RESIZE_POLICY to allow horizontal scrolling when needed
        VBox.setVgrow(dataTable, Priority.ALWAYS);

        // Action buttons
        HBox buttonBox = new HBox(10);
        buttonBox.setAlignment(Pos.CENTER);

        insertBtn = new Button("Insert Row");
        insertBtn.setStyle("-fx-background-color: #4CAF50; -fx-text-fill: white;");
        insertBtn.setOnAction(e -> showInsertDialog());

        updateBtn = new Button("Update Row");
        updateBtn.setStyle("-fx-background-color: #2196F3; -fx-text-fill: white;");
        updateBtn.setOnAction(e -> showUpdateDialog());

        deleteBtn = new Button("Delete Row");
        deleteBtn.setStyle("-fx-background-color: #f44336; -fx-text-fill: white;");
        deleteBtn.setOnAction(e -> deleteRow());

        refreshBtn = new Button("Refresh");
        refreshBtn.setOnAction(e -> loadTable());

        buttonBox.getChildren().addAll(insertBtn, updateBtn, deleteBtn, refreshBtn);

        getChildren().addAll(title, selectorBox, dataTable, buttonBox);

        // Load table names
        loadTableNames();
    }

    private void loadTableNames() {
        try {
            List<String> tables = UniversalTableManager.getAllTableNames();
            tableSelector.setItems(FXCollections.observableArrayList(tables));
        } catch (SQLException e) {
            showError("Failed to load table names", e);
        }
    }

    private void loadTable() {
        currentTable = tableSelector.getValue();
        if (currentTable == null || currentTable.isEmpty())
            return;

        try {
            // Get table metadata
            List<UniversalTableManager.ColumnInfo> columns = UniversalTableManager.getTableColumns(currentTable);
            primaryKeys = UniversalTableManager.getPrimaryKeys(currentTable);

            // Clear existing columns
            dataTable.getColumns().clear();

            // Create dynamic columns
            for (UniversalTableManager.ColumnInfo col : columns) {
                TableColumn<Map<String, Object>, Object> column = new TableColumn<>(col.name);

                // Set max width to prevent very wide columns from hiding others
                column.setMaxWidth(300);
                column.setPrefWidth(150);

                column.setCellValueFactory(cellData -> {
                    Object value = cellData.getValue().get(col.name);
                    return new SimpleObjectProperty<>(value);
                });

                column.setCellFactory(tc -> new TableCell<Map<String, Object>, Object>() {
                    @Override
                    protected void updateItem(Object item, boolean empty) {
                        super.updateItem(item, empty);
                        if (empty || item == null) {
                            setText(null);
                        } else {
                            setText(item.toString());
                        }
                    }
                });

                dataTable.getColumns().add(column);
            }

            // Load data
            List<Map<String, Object>> rows = UniversalTableManager.getAllRows(currentTable);
            dataTable.setItems(FXCollections.observableArrayList(rows));

        } catch (SQLException e) {
            showError("Failed to load table data", e);
        }
    }

    private void showInsertDialog() {
        if (currentTable == null) {
            showWarning("Please select a table first");
            return;
        }

        try {
            List<UniversalTableManager.ColumnInfo> columns = UniversalTableManager.getTableColumns(currentTable);

            Stage dialog = new Stage();
            dialog.initModality(Modality.APPLICATION_MODAL);
            dialog.setTitle("Insert Row - " + currentTable);

            GridPane grid = new GridPane();
            grid.setPadding(new Insets(20));
            grid.setHgap(10);
            grid.setVgap(10);

            Map<String, TextField> fieldMap = new LinkedHashMap<>();
            int row = 0;

            for (UniversalTableManager.ColumnInfo col : columns) {
                // Skip auto-increment primary keys
                if (col.autoIncrement && primaryKeys.contains(col.name)) {
                    continue;
                }

                Label label = new Label(col.name + ":");
                TextField field = new TextField();

                if (!col.nullable) {
                    label.setText(col.name + " *:");
                }

                grid.add(label, 0, row);
                grid.add(field, 1, row);
                fieldMap.put(col.name, field);
                row++;
            }

            Button saveBtn = new Button("Insert");
            saveBtn.setStyle("-fx-background-color: #4CAF50; -fx-text-fill: white;");
            saveBtn.setOnAction(e -> {
                try {
                    Map<String, Object> values = new HashMap<>();
                    for (Map.Entry<String, TextField> entry : fieldMap.entrySet()) {
                        String value = entry.getValue().getText().trim();
                        if (!value.isEmpty()) {
                            values.put(entry.getKey(), value);
                        }
                    }

                    UniversalTableManager.executeInsert(currentTable, values);
                    showInfo("Row inserted successfully");
                    loadTable();
                    dialog.close();
                } catch (SQLException ex) {
                    showError("Insert failed", ex);
                }
            });

            Button cancelBtn = new Button("Cancel");
            cancelBtn.setOnAction(e -> dialog.close());

            HBox btnBox = new HBox(10, saveBtn, cancelBtn);
            btnBox.setAlignment(Pos.CENTER);
            grid.add(btnBox, 0, row, 2, 1);

            Scene scene = new Scene(grid);
            dialog.setScene(scene);
            dialog.showAndWait();

        } catch (SQLException e) {
            showError("Failed to open insert dialog", e);
        }
    }

    private void showUpdateDialog() {
        Map<String, Object> selectedRow = dataTable.getSelectionModel().getSelectedItem();
        if (selectedRow == null) {
            showWarning("Please select a row to update");
            return;
        }

        try {
            List<UniversalTableManager.ColumnInfo> columns = UniversalTableManager.getTableColumns(currentTable);

            Stage dialog = new Stage();
            dialog.initModality(Modality.APPLICATION_MODAL);
            dialog.setTitle("Update Row - " + currentTable);

            GridPane grid = new GridPane();
            grid.setPadding(new Insets(20));
            grid.setHgap(10);
            grid.setVgap(10);

            Map<String, TextField> fieldMap = new LinkedHashMap<>();
            int row = 0;

            for (UniversalTableManager.ColumnInfo col : columns) {
                Label label = new Label(col.name + ":");
                TextField field = new TextField();

                // Pre-fill with current value
                Object currentValue = selectedRow.get(col.name);
                if (currentValue != null) {
                    field.setText(currentValue.toString());
                }

                // Disable primary key fields
                if (primaryKeys.contains(col.name)) {
                    field.setDisable(true);
                }

                grid.add(label, 0, row);
                grid.add(field, 1, row);
                fieldMap.put(col.name, field);
                row++;
            }

            Button saveBtn = new Button("Update");
            saveBtn.setStyle("-fx-background-color: #2196F3; -fx-text-fill: white;");
            saveBtn.setOnAction(e -> {
                try {
                    Map<String, Object> values = new HashMap<>();
                    Map<String, Object> whereClause = new HashMap<>();

                    for (Map.Entry<String, TextField> entry : fieldMap.entrySet()) {
                        String colName = entry.getKey();
                        String value = entry.getValue().getText().trim();

                        if (primaryKeys.contains(colName)) {
                            whereClause.put(colName, value);
                        } else if (!value.isEmpty()) {
                            values.put(colName, value);
                        }
                    }

                    UniversalTableManager.executeUpdate(currentTable, values, whereClause);
                    showInfo("Row updated successfully");
                    loadTable();
                    dialog.close();
                } catch (SQLException ex) {
                    showError("Update failed", ex);
                }
            });

            Button cancelBtn = new Button("Cancel");
            cancelBtn.setOnAction(e -> dialog.close());

            HBox btnBox = new HBox(10, saveBtn, cancelBtn);
            btnBox.setAlignment(Pos.CENTER);
            grid.add(btnBox, 0, row, 2, 1);

            Scene scene = new Scene(grid);
            dialog.setScene(scene);
            dialog.showAndWait();

        } catch (SQLException e) {
            showError("Failed to open update dialog", e);
        }
    }

    private void deleteRow() {
        Map<String, Object> selectedRow = dataTable.getSelectionModel().getSelectedItem();
        if (selectedRow == null) {
            showWarning("Please select a row to delete");
            return;
        }

        Alert confirm = new Alert(Alert.AlertType.CONFIRMATION);
        confirm.setTitle("Confirm Delete");
        confirm.setHeaderText("Delete this row?");
        confirm.setContentText("This action cannot be undone.");

        confirm.showAndWait().ifPresent(response -> {
            if (response == ButtonType.OK) {
                try {
                    Map<String, Object> whereClause = new HashMap<>();
                    for (String pk : primaryKeys) {
                        whereClause.put(pk, selectedRow.get(pk));
                    }

                    UniversalTableManager.executeDelete(currentTable, whereClause);
                    showInfo("Row deleted successfully");
                    loadTable();
                } catch (SQLException e) {
                    // Check if it's a foreign key constraint error
                    if (e.getMessage().contains("foreign key constraint") ||
                            e.getMessage().contains("Cannot delete or update a parent row")) {

                        Alert fkError = new Alert(Alert.AlertType.ERROR);
                        fkError.setTitle("Cannot Delete - Foreign Key Constraint");
                        fkError.setHeaderText("This row is referenced by other tables");
                        fkError.setContentText("You must first delete any child records that reference this row.\n\n" +
                                "Database Error: " + e.getMessage());
                        fkError.showAndWait();
                    } else {
                        showError("Delete failed", e);
                    }
                }
            }
        });
    }

    private void showError(String message, Exception e) {
        Alert alert = new Alert(Alert.AlertType.ERROR);
        alert.setTitle("Error");
        alert.setHeaderText(message);
        alert.setContentText(e.getMessage());
        alert.showAndWait();
    }

    private void showWarning(String message) {
        Alert alert = new Alert(Alert.AlertType.WARNING);
        alert.setTitle("Warning");
        alert.setHeaderText(message);
        alert.showAndWait();
    }

    private void showInfo(String message) {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.setTitle("Success");
        alert.setHeaderText(message);
        alert.showAndWait();
    }
}
