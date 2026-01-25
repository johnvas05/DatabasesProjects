package com.travelagency;

public class Vehicle {
    private int id;
    private String licensePlate;
    private String model;
    private String brand;
    private String type; // Bus, Mini-Bus, Van, Car
    private int seats;
    private String status;
    private int mileage;
    private int branchCode;

    public Vehicle(int id, String licensePlate, String model, String brand,
            String type, int seats, String status, int mileage, int branchCode) {
        this.id = id;
        this.licensePlate = licensePlate;
        this.model = model;
        this.brand = brand;
        this.type = type;
        this.seats = seats;
        this.status = status;
        this.mileage = mileage;
        this.branchCode = branchCode;
    }

    public Vehicle(String licensePlate, String model, String brand, String type,
            int seats, String status, int mileage, int branchCode) {
        this(0, licensePlate, model, brand, type, seats, status, mileage, branchCode);
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getLicensePlate() {
        return licensePlate;
    }

    public void setLicensePlate(String licensePlate) {
        this.licensePlate = licensePlate;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public String getBrand() {
        return brand;
    }

    public void setBrand(String brand) {
        this.brand = brand;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public int getMileage() {
        return mileage;
    }

    public void setMileage(int mileage) {
        this.mileage = mileage;
    }

    public int getSeats() {
        return seats;
    }

    public void setSeats(int seats) {
        this.seats = seats;
    }

    public int getBranchCode() {
        return branchCode;
    }

    public void setBranchCode(int branchCode) {
        this.branchCode = branchCode;
    }

    @Override
    public String toString() {
        return brand + " " + model + " (" + licensePlate + ")";
    }
}
