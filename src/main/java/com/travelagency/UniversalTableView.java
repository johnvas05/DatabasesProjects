package com.travelagency;

import javafx.beans.property.SimpleObjectProperty;
import javafx.collections.FXCollections;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.stage.Modality;
import javafx.stage.Stage;

import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.*;
import java.util.function.Supplier;

/**
 * Requirement 3.2.1: pick any table of the database, see its rows and insert,
 * update or delete rows.
 *
 * Requirement 3.2.2: the insert/update dialog restricts input wherever the
 * schema allows it. Foreign-key columns are drop-downs filled from the
 * referenced table (e.g. the list of destinations when adding a destination to
 * a trip), ENUM columns are drop-downs of their values, DATE columns use a date
 * picker, DATETIME columns a date picker plus an hour list, BOOLEAN columns a
 * check box and numeric columns only accept digits.
 */
public class UniversalTableView extends VBox {

    private final ComboBox<String> tableSelector;
    private final TableView<Map<String, Object>> dataTable;
    private String currentTable;
    private List<String> primaryKeys = new ArrayList<>();

    /** One editor per column of the dialog. */
    private static class ColumnEditor {
        final Node node;
        final Supplier<String> value;

        ColumnEditor(Node node, Supplier<String> value) {
            this.node = node;
            this.value = value;
        }
    }

    public UniversalTableView() {
        setSpacing(15);
        setPadding(new Insets(20));

        Label title = new Label("Universal Table Manager");
        title.setStyle("-fx-font-size: 24px; -fx-font-weight: bold;");

        HBox selectorBox = new HBox(10);
        selectorBox.setAlignment(Pos.CENTER_LEFT);
        Label selectorLabel = new Label("Select Table:");
        selectorLabel.setStyle("-fx-font-size: 14px;");

        tableSelector = new ComboBox<>();
        tableSelector.setPrefWidth(250);
        tableSelector.setOnAction(e -> loadTable());
        selectorBox.getChildren().addAll(selectorLabel, tableSelector);

        dataTable = new TableView<>();
        VBox.setVgrow(dataTable, Priority.ALWAYS);

        HBox buttonBox = new HBox(10);
        buttonBox.setAlignment(Pos.CENTER);

        Button insertBtn = new Button("Insert Row");
        insertBtn.setStyle("-fx-background-color: #4CAF50; -fx-text-fill: white;");
        insertBtn.setOnAction(e -> showRowDialog(null));

        Button updateBtn = new Button("Update Row");
        updateBtn.setStyle("-fx-background-color: #2196F3; -fx-text-fill: white;");
        updateBtn.setOnAction(e -> {
            Map<String, Object> selected = dataTable.getSelectionModel().getSelectedItem();
            if (selected == null) {
                showWarning("Please select a row to update");
            } else {
                showRowDialog(selected);
            }
        });

        Button deleteBtn = new Button("Delete Row");
        deleteBtn.setStyle("-fx-background-color: #f44336; -fx-text-fill: white;");
        deleteBtn.setOnAction(e -> deleteRow());

        Button refreshBtn = new Button("Refresh");
        refreshBtn.setOnAction(e -> loadTable());

        buttonBox.getChildren().addAll(insertBtn, updateBtn, deleteBtn, refreshBtn);
        getChildren().addAll(title, selectorBox, dataTable, buttonBox);

        loadTableNames();
    }

    private void loadTableNames() {
        try {
            tableSelector.setItems(FXCollections.observableArrayList(UniversalTableManager.getAllTableNames()));
        } catch (SQLException e) {
            showError("Failed to load table names", e);
        }
    }

    private void loadTable() {
        currentTable = tableSelector.getValue();
        if (currentTable == null || currentTable.isEmpty()) {
            return;
        }
        try {
            List<UniversalTableManager.ColumnInfo> columns = UniversalTableManager.getTableColumns(currentTable);
            primaryKeys = UniversalTableManager.getPrimaryKeys(currentTable);

            dataTable.getColumns().clear();
            for (UniversalTableManager.ColumnInfo col : columns) {
                TableColumn<Map<String, Object>, Object> column = new TableColumn<>(col.name);
                column.setMaxWidth(300);
                column.setPrefWidth(150);
                column.setCellValueFactory(cellData -> new SimpleObjectProperty<>(cellData.getValue().get(col.name)));
                column.setCellFactory(tc -> new TableCell<Map<String, Object>, Object>() {
                    @Override
                    protected void updateItem(Object item, boolean empty) {
                        super.updateItem(item, empty);
                        setText(empty || item == null ? null : item.toString());
                    }
                });
                dataTable.getColumns().add(column);
            }
            dataTable.setItems(FXCollections.observableArrayList(UniversalTableManager.getAllRows(currentTable)));
        } catch (SQLException e) {
            showError("Failed to load table " + currentTable, e);
        }
    }

    /** Insert (selectedRow == null) or update (selectedRow != null) dialog. */
    private void showRowDialog(Map<String, Object> selectedRow) {
        if (currentTable == null) {
            showWarning("Please select a table first");
            return;
        }
        boolean isUpdate = selectedRow != null;
        try {
            List<UniversalTableManager.ColumnInfo> columns = UniversalTableManager.getTableColumns(currentTable);
            Map<String, String> sqlTypes = UniversalTableManager.getColumnSqlTypes(currentTable);
            Map<String, String[]> foreignKeys = UniversalTableManager.getForeignKeys(currentTable);

            Stage dialog = new Stage();
            dialog.initModality(Modality.APPLICATION_MODAL);
            dialog.setTitle((isUpdate ? "Update Row - " : "Insert Row - ") + currentTable);

            GridPane grid = new GridPane();
            grid.setPadding(new Insets(20));
            grid.setHgap(10);
            grid.setVgap(10);

            Map<String, ColumnEditor> editors = new LinkedHashMap<>();
            int row = 0;
            for (UniversalTableManager.ColumnInfo col : columns) {
                boolean isPk = primaryKeys.contains(col.name);
                if (!isUpdate && col.autoIncrement && isPk) {
                    continue; // generated by the database
                }
                Object current = isUpdate ? selectedRow.get(col.name) : null;
                ColumnEditor editor = createEditor(col, sqlTypes.get(col.name), foreignKeys.get(col.name), current);
                if (isUpdate && isPk) {
                    editor.node.setDisable(true);
                }
                Label label = new Label(col.name + (col.nullable ? ":" : " *:"));
                grid.add(label, 0, row);
                grid.add(editor.node, 1, row);
                Label hint = new Label(hintFor(sqlTypes.get(col.name), foreignKeys.get(col.name)));
                hint.setStyle("-fx-text-fill: gray; -fx-font-size: 11px;");
                grid.add(hint, 2, row);
                editors.put(col.name, editor);
                row++;
            }

            Button saveBtn = new Button(isUpdate ? "Update" : "Insert");
            saveBtn.setStyle("-fx-background-color: " + (isUpdate ? "#2196F3" : "#4CAF50") + "; -fx-text-fill: white;");
            saveBtn.setOnAction(e -> {
                try {
                    Map<String, Object> values = new LinkedHashMap<>();
                    Map<String, Object> where = new LinkedHashMap<>();
                    for (Map.Entry<String, ColumnEditor> entry : editors.entrySet()) {
                        String v = entry.getValue().value.get();
                        boolean isPk = primaryKeys.contains(entry.getKey());
                        if (isUpdate && isPk) {
                            where.put(entry.getKey(), selectedRow.get(entry.getKey()));
                        } else if (v != null && !v.isEmpty()) {
                            values.put(entry.getKey(), v);
                        } else if (isUpdate) {
                            values.put(entry.getKey(), null);
                        }
                    }
                    if (isUpdate) {
                        UniversalTableManager.executeUpdate(currentTable, values, where);
                        showInfo("Row updated successfully");
                    } else {
                        UniversalTableManager.executeInsert(currentTable, values);
                        showInfo("Row inserted successfully");
                    }
                    loadTable();
                    dialog.close();
                } catch (SQLException ex) {
                    showError((isUpdate ? "Update" : "Insert") + " failed", ex);
                }
            });

            Button cancelBtn = new Button("Cancel");
            cancelBtn.setOnAction(e -> dialog.close());

            HBox btnBox = new HBox(10, saveBtn, cancelBtn);
            btnBox.setAlignment(Pos.CENTER);
            grid.add(btnBox, 0, row, 3, 1);

            ScrollPane scroll = new ScrollPane(grid);
            scroll.setFitToWidth(true);
            dialog.setScene(new Scene(scroll, 640, Math.min(80 + row * 42, 700)));
            dialog.showAndWait();
        } catch (SQLException e) {
            showError("Failed to open dialog", e);
        }
    }

    /** Builds the editor that fits the column: FK list, enum list, date, boolean, number or text. */
    private ColumnEditor createEditor(UniversalTableManager.ColumnInfo col, String sqlType, String[] fk,
            Object current) throws SQLException {
        String type = sqlType == null ? "" : sqlType.toLowerCase();
        String currentText = current == null ? "" : current.toString();

        // 1. Foreign key: choose an existing row of the referenced table
        if (fk != null) {
            ComboBox<String> combo = new ComboBox<>();
            combo.setPrefWidth(320);
            if (col.nullable) {
                combo.getItems().add("");
            }
            combo.getItems().addAll(UniversalTableManager.getReferenceOptions(fk[0], fk[1]));
            combo.setPromptText("Select " + fk[0]);
            for (String option : combo.getItems()) {
                if (!option.isEmpty() && UniversalTableManager.optionKey(option).equals(currentText)) {
                    combo.setValue(option);
                }
            }
            return new ColumnEditor(combo, () -> UniversalTableManager.optionKey(combo.getValue()));
        }

        // 2. ENUM: choose one of the allowed values
        if (type.startsWith("enum(")) {
            ComboBox<String> combo = new ComboBox<>();
            combo.setPrefWidth(320);
            if (col.nullable) {
                combo.getItems().add("");
            }
            for (String v : type.substring(5, type.length() - 1).split(",")) {
                combo.getItems().add(v.trim().replaceAll("^'|'$", "").toUpperCase(Locale.ROOT).equals(v.trim().replaceAll("^'|'$", ""))
                        ? v.trim().replaceAll("^'|'$", "")
                        : originalCase(sqlType, v.trim().replaceAll("^'|'$", "")));
            }
            combo.setValue(currentText);
            return new ColumnEditor(combo, combo::getValue);
        }

        // 3. Boolean flags (tinyint(1))
        if (type.startsWith("tinyint(1)") || type.equals("bit(1)") || type.equals("boolean")) {
            CheckBox box = new CheckBox();
            box.setSelected("1".equals(currentText) || "true".equalsIgnoreCase(currentText));
            return new ColumnEditor(box, () -> box.isSelected() ? "1" : "0");
        }

        // 4. Dates
        if (col.type == Types.DATE) {
            DatePicker picker = new DatePicker();
            if (!currentText.isEmpty()) {
                picker.setValue(LocalDate.parse(currentText.substring(0, 10)));
            }
            return new ColumnEditor(picker, () -> picker.getValue() == null ? "" : picker.getValue().toString());
        }
        if (col.type == Types.TIMESTAMP || type.startsWith("datetime")) {
            DatePicker picker = new DatePicker();
            ComboBox<String> hour = new ComboBox<>();
            for (int h = 0; h < 24; h++) {
                hour.getItems().add(String.format("%02d:00", h));
            }
            hour.setValue("12:00");
            if (!currentText.isEmpty()) {
                picker.setValue(LocalDate.parse(currentText.substring(0, 10)));
                if (currentText.length() >= 16) {
                    hour.setValue(currentText.substring(11, 13) + ":00");
                }
            }
            HBox box = new HBox(5, picker, hour);
            return new ColumnEditor(box, () -> picker.getValue() == null ? ""
                    : picker.getValue() + " " + hour.getValue() + ":00");
        }

        // 5. Numbers: digits only (and a decimal point for decimals)
        TextField field = new TextField(currentText);
        field.setPrefWidth(320);
        boolean integer = col.type == Types.INTEGER || col.type == Types.SMALLINT || col.type == Types.TINYINT
                || col.type == Types.BIGINT;
        boolean decimal = col.type == Types.DECIMAL || col.type == Types.NUMERIC || col.type == Types.DOUBLE
                || col.type == Types.FLOAT || col.type == Types.REAL;
        if (integer || decimal) {
            String pattern = decimal ? "-?\\d*(\\.\\d*)?" : "-?\\d*";
            field.setTextFormatter(new TextFormatter<>(change -> change.getControlNewText().matches(pattern) ? change : null));
            field.setPromptText(decimal ? "number, e.g. 120.50" : "whole number");
        } else if (type.startsWith("varchar(") || type.startsWith("char(")) {
            int max = Integer.parseInt(type.replaceAll("\\D", ""));
            field.setTextFormatter(new TextFormatter<>(change -> change.getControlNewText().length() <= max ? change : null));
            field.setPromptText("max " + max + " characters");
        }
        return new ColumnEditor(field, field::getText);
    }

    /** Enum values are case-sensitive on display; recover the original case from the SQL type. */
    private static String originalCase(String sqlType, String lowered) {
        for (String v : sqlType.substring(5, sqlType.length() - 1).split(",")) {
            String clean = v.trim().replaceAll("^'|'$", "");
            if (clean.equalsIgnoreCase(lowered)) {
                return clean;
            }
        }
        return lowered;
    }

    private static String hintFor(String sqlType, String[] fk) {
        if (fk != null) {
            return "from " + fk[0] + "." + fk[1];
        }
        return sqlType == null ? "" : sqlType;
    }

    private void deleteRow() {
        Map<String, Object> selectedRow = dataTable.getSelectionModel().getSelectedItem();
        if (selectedRow == null) {
            showWarning("Please select a row to delete");
            return;
        }
        if (primaryKeys.isEmpty()) {
            showWarning("Table " + currentTable + " has no primary key; delete it with SQL.");
            return;
        }
        Alert confirm = new Alert(Alert.AlertType.CONFIRMATION);
        confirm.setTitle("Confirm Delete");
        confirm.setHeaderText("Delete this row from " + currentTable + "?");
        confirm.setContentText(selectedRow.toString());
        confirm.showAndWait().ifPresent(response -> {
            if (response == ButtonType.OK) {
                try {
                    Map<String, Object> where = new LinkedHashMap<>();
                    for (String pk : primaryKeys) {
                        where.put(pk, selectedRow.get(pk));
                    }
                    UniversalTableManager.executeDelete(currentTable, where);
                    showInfo("Row deleted successfully");
                    loadTable();
                } catch (SQLException e) {
                    if (e.getMessage() != null && e.getMessage().toLowerCase().contains("foreign key")) {
                        Alert fkError = new Alert(Alert.AlertType.ERROR);
                        fkError.setTitle("Delete blocked");
                        fkError.setHeaderText("Other rows reference this row");
                        fkError.setContentText("Delete or change the rows that reference it first.\n\n" + e.getMessage());
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
        alert.setHeaderText(null);
        alert.setContentText(message);
        alert.showAndWait();
    }

    private void showInfo(String message) {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.setTitle("Success");
        alert.setHeaderText(null);
        alert.setContentText(message);
        alert.showAndWait();
    }
}
