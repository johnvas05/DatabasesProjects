package com.travelagency;

public class Branch {
    private int id;
    private String street;
    private int num;
    private String city;
    private String managerId;

    public Branch(int id, String street, int num, String city, String managerId) {
        this.id = id;
        this.street = street;
        this.num = num;
        this.city = city;
        this.managerId = managerId;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getStreet() {
        return street;
    }

    public void setStreet(String street) {
        this.street = street;
    }

    public int getNum() {
        return num;
    }

    public void setNum(int num) {
        this.num = num;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getManagerId() {
        return managerId;
    }

    public void setManagerId(String managerId) {
        this.managerId = managerId;
    }

    @Override
    public String toString() {
        return city + " (" + street + " " + num + ")";
    }
}
