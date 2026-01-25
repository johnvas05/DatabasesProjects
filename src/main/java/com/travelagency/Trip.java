package com.travelagency;

import java.sql.Timestamp;

public class Trip {
    private int id;
    private Timestamp departure;
    private Timestamp returnDate;
    private int maxSeats;
    private double costAdult;
    private double costChild;
    private String status;
    private int minParticipants;
    private int branchCode;
    private int vehicleId; // New field
    // guideId and driverId might be removed or kept depending on schema. Keeping
    // for now but vehicleId is priority.
    private String guideId;
    private String driverId;

    public Trip(int id, Timestamp departure, Timestamp returnDate, int maxSeats, double costAdult,
            double costChild, String status, int minParticipants, int branchCode, int vehicleId, String guideId,
            String driverId) {
        this.id = id;
        this.departure = departure;
        this.returnDate = returnDate;
        this.maxSeats = maxSeats;
        this.costAdult = costAdult;
        this.costChild = costChild;
        this.status = status;
        this.minParticipants = minParticipants;
        this.branchCode = branchCode;
        this.vehicleId = vehicleId;
        this.guideId = guideId;
        this.driverId = driverId;
    }

    public Trip(Timestamp departure, Timestamp returnDate, int maxSeats, double costAdult,
            double costChild, String status, int minParticipants, int branchCode, int vehicleId, String guideId,
            String driverId) {
        this(0, departure, returnDate, maxSeats, costAdult, costChild, status, minParticipants, branchCode, vehicleId,
                guideId,
                driverId);
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public Timestamp getDeparture() {
        return departure;
    }

    public void setDeparture(Timestamp departure) {
        this.departure = departure;
    }

    public Timestamp getReturnDate() {
        return returnDate;
    }

    public void setReturnDate(Timestamp returnDate) {
        this.returnDate = returnDate;
    }

    public int getMaxSeats() {
        return maxSeats;
    }

    public void setMaxSeats(int maxSeats) {
        this.maxSeats = maxSeats;
    }

    public double getCostAdult() {
        return costAdult;
    }

    public void setCostAdult(double costAdult) {
        this.costAdult = costAdult;
    }

    public double getCostChild() {
        return costChild;
    }

    public void setCostChild(double costChild) {
        this.costChild = costChild;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public int getMinParticipants() {
        return minParticipants;
    }

    public void setMinParticipants(int minParticipants) {
        this.minParticipants = minParticipants;
    }

    public int getBranchCode() {
        return branchCode;
    }

    public void setBranchCode(int branchCode) {
        this.branchCode = branchCode;
    }

    public int getVehicleId() {
        return vehicleId;
    }

    public void setVehicleId(int vehicleId) {
        this.vehicleId = vehicleId;
    }

    public String getGuideId() {
        return guideId;
    }

    public void setGuideId(String guideId) {
        this.guideId = guideId;
    }

    public String getDriverId() {
        return driverId;
    }

    public void setDriverId(String driverId) {
        this.driverId = driverId;
    }

    @Override
    public String toString() {
        return "ID " + id + " : " + departure + " (Max " + maxSeats + ")";
    }
}
