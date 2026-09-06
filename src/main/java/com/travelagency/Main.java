package com.travelagency;

import javafx.application.Application;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.Separator;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import java.sql.SQLException;

public class Main extends Application {

    @Override
    public void start(Stage stage) {
        stage.setTitle("Travel Agency Manager 2025");

        // Main Layout
        BorderPane mainLayout = new BorderPane();
        mainLayout.setPadding(new Insets(10));

        // Top: Header
        Label headerLabel = new Label("Travel Agency Management System");
        headerLabel.setStyle("-fx-font-size: 20px; -fx-font-weight: bold;");
        BorderPane.setAlignment(headerLabel, Pos.CENTER);
        mainLayout.setTop(headerLabel);

        // Center: Content Area
        StackPane contentArea = new StackPane();
        contentArea.getChildren().add(new Label("Welcome! Select an option from the menu."));
        mainLayout.setCenter(contentArea);

        // Left: Navigation
        VBox navigation = new VBox(10);
        navigation.setPadding(new Insets(20, 10, 10, 10));
        navigation.setStyle("-fx-border-color: lightgray; -fx-border-width: 0 1 0 0;");
        navigation.setPrefWidth(150);

        Button btnHome = new Button("Home");
        btnHome.setMaxWidth(Double.MAX_VALUE);
        btnHome.setOnAction(e -> {
            contentArea.getChildren().clear();
            contentArea.getChildren().add(new Label("Welcome! Select an option from the menu."));
        });

        Button btnCustomers = new Button("Customers");
        btnCustomers.setMaxWidth(Double.MAX_VALUE);
        btnCustomers.setOnAction(e -> contentArea.getChildren().setAll(new CustomerView().getView()));

        Button btnVehicles = new Button("Vehicles");
        btnVehicles.setMaxWidth(Double.MAX_VALUE);
        btnVehicles.setOnAction(e -> contentArea.getChildren().setAll(new VehicleView().getView()));

        Button btnAccommodations = new Button("Lodgings");
        btnAccommodations.setMaxWidth(Double.MAX_VALUE);
        btnAccommodations.setOnAction(e -> contentArea.getChildren().setAll(new LodgingView().getView()));

        Button btnReservations = new Button("Reservations");
        btnReservations.setMaxWidth(Double.MAX_VALUE);
        btnReservations.setOnAction(e -> contentArea.getChildren().setAll(new ReservationView().getView()));

        Button btnTrips = new Button("Trips");
        btnTrips.setMaxWidth(Double.MAX_VALUE);
        btnTrips.setOnAction(e -> contentArea.getChildren().setAll(new TripView().getView()));

        Button btnStaff = new Button("Staff");
        btnStaff.setMaxWidth(Double.MAX_VALUE);
        btnStaff.setOnAction(e -> contentArea.getChildren().setAll(new WorkerView().getView()));

        Button btnAdmin = new Button("Admin & Logs");
        btnAdmin.setMaxWidth(Double.MAX_VALUE);
        btnAdmin.setOnAction(e -> contentArea.getChildren().setAll(new AdminView().getView()));

        Button btnUniversal = new Button("Universal Manager");
        btnUniversal.setMaxWidth(Double.MAX_VALUE);
        btnUniversal.setOnAction(e -> contentArea.getChildren().setAll(new UniversalTableView()));

        Button btnExit = new Button("Exit");
        btnExit.setMaxWidth(Double.MAX_VALUE);
        btnExit.setOnAction(e -> stage.close());

        navigation.getChildren().addAll(btnHome, btnCustomers, btnVehicles, btnAccommodations, btnTrips,
                btnReservations, btnStaff, btnAdmin, btnUniversal,
                new Separator(), btnExit);
        mainLayout.setLeft(navigation);

        // Bottom: Status Bar
        HBox statusBar = new HBox();
        statusBar.setPadding(new Insets(5));
        statusBar.setStyle("-fx-border-color: lightgray; -fx-border-width: 1 0 0 0;");
        Label statusLabel = new Label("Ready");

        try {
            if (DatabaseConnection.getConnection() != null) {
                statusLabel.setText("Status: Connected as " + DatabaseConnection.describe());
                statusLabel.setStyle("-fx-text-fill: green;");
            }
        } catch (SQLException e) {
            statusLabel.setText("Status: Connection Failed - " + e.getMessage());
            statusLabel.setStyle("-fx-text-fill: red;");
            e.printStackTrace();
        }

        statusBar.getChildren().add(statusLabel);
        mainLayout.setBottom(statusBar);

        // wide enough for the labelled forms of the Trips and Staff screens
        Scene scene = new Scene(mainLayout, 1180, 740);
        stage.setScene(scene);
        stage.setMinWidth(900);
        stage.setMinHeight(600);
        stage.show();
    }
}
