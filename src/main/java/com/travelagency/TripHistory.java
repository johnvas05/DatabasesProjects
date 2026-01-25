package com.travelagency;

import java.sql.Timestamp;

public class TripHistory {
    private int id;
    private int tripId;
    private Timestamp departure;
    private Timestamp returnDate;
    private int destCount;
    private int participants;
    private double revenue;

    public TripHistory(int id, int tripId, Timestamp departure, Timestamp returnDate, int destCount, int participants,
            double revenue) {
        this.id = id;
        this.tripId = tripId;
        this.departure = departure;
        this.returnDate = returnDate;
        this.destCount = destCount;
        this.participants = participants;
        this.revenue = revenue;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getTripId() {
        return tripId;
    }

    public void setTripId(int tripId) {
        this.tripId = tripId;
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

    public int getDestCount() {
        return destCount;
    }

    public void setDestCount(int destCount) {
        this.destCount = destCount;
    }

    public int getParticipants() {
        return participants;
    }

    public void setParticipants(int participants) {
        this.participants = participants;
    }

    public double getRevenue() {
        return revenue;
    }

    public void setRevenue(double revenue) {
        this.revenue = revenue;
    }
}
