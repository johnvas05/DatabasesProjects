package com.travelagency;

public class Reservation {
    private int tr_id;
    private int seatNum;
    private int cust_id;
    private String status;
    private double totalCost;

    // Additional fields for Display purposes (Joined data)
    private String customerName; // from Customer
    private String tripInfo; // from Trip

    public Reservation(int tr_id, int seatNum, int cust_id, String status, double totalCost) {
        this.tr_id = tr_id;
        this.seatNum = seatNum;
        this.cust_id = cust_id;
        this.status = status;
        this.totalCost = totalCost;
    }

    // Extended constructor for TableView display
    public Reservation(int tr_id, int seatNum, int cust_id, String status, double totalCost, String customerName,
            String tripInfo) {
        this(tr_id, seatNum, cust_id, status, totalCost);
        this.customerName = customerName;
        this.tripInfo = tripInfo;
    }

    public int getTr_id() {
        return tr_id;
    }

    public void setTr_id(int tr_id) {
        this.tr_id = tr_id;
    }

    public int getSeatNum() {
        return seatNum;
    }

    public void setSeatNum(int seatNum) {
        this.seatNum = seatNum;
    }

    public int getCust_id() {
        return cust_id;
    }

    public void setCust_id(int cust_id) {
        this.cust_id = cust_id;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public double getTotalCost() {
        return totalCost;
    }

    public void setTotalCost(double totalCost) {
        this.totalCost = totalCost;
    }

    public String getCustomerName() {
        return customerName;
    }

    public String getTripInfo() {
        return tripInfo;
    }
}
