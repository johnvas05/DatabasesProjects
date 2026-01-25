package com.travelagency;

public class Accommodation {
    private int id;
    private String name;
    private String type; // Hotel, Hostel, etc.
    private int stars;
    private double rating;
    private boolean active;
    private String address;
    private String phone;
    private String email;
    private int rooms;
    private double pricePerNight;

    public Accommodation(int id, String name, String type, int stars, double rating, boolean active,
            String address, String phone, String email, int rooms, double pricePerNight) {
        this.id = id;
        this.name = name;
        this.type = type;
        this.stars = stars;
        this.rating = rating;
        this.active = active;
        this.address = address;
        this.phone = phone;
        this.email = email;
        this.rooms = rooms;
        this.pricePerNight = pricePerNight;
    }

    // Constructor without ID (for insertion)
    public Accommodation(String name, String type, int stars, double rating, boolean active,
            String address, String phone, String email, int rooms, double pricePerNight) {
        this(0, name, type, stars, rating, active, address, phone, email, rooms, pricePerNight);
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public int getStars() {
        return stars;
    }

    public void setStars(int stars) {
        this.stars = stars;
    }

    public double getRating() {
        return rating;
    }

    public void setRating(double rating) {
        this.rating = rating;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public int getRooms() {
        return rooms;
    }

    public void setRooms(int rooms) {
        this.rooms = rooms;
    }

    public double getPricePerNight() {
        return pricePerNight;
    }

    public void setPricePerNight(double pricePerNight) {
        this.pricePerNight = pricePerNight;
    }
}
