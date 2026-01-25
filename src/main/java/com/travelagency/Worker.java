package com.travelagency;

public class Worker {
    private String AT; // Arithmos Tautotitas (ID Card) - Primary Key
    private String name;
    private String lastName;
    private double salary;
    private int branchCode;

    public Worker(String AT, String name, String lastName, double salary, int branchCode) {
        this.AT = AT;
        this.name = name;
        this.lastName = lastName;
        this.salary = salary;
        this.branchCode = branchCode;
    }

    public String getAT() {
        return AT;
    }

    public void setAT(String AT) {
        this.AT = AT;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public double getSalary() {
        return salary;
    }

    public void setSalary(double salary) {
        this.salary = salary;
    }

    public int getBranchCode() {
        return branchCode;
    }

    public void setBranchCode(int branchCode) {
        this.branchCode = branchCode;
    }
}
