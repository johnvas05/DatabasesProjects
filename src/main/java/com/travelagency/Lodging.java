package com.travelagency;

public class Lodging {
    private int id;
    private int destinationId; // lg_dst_id
    private String name;
    private String type;
    private int stars;
    private double rating;
    private String status; // lg_status (Active/Inactive)
    private String address;
    private String city;
    private String postalCode;
    private String phone;
    private String email;
    private int totalRooms; // lg_total_rooms
    private double pricePerNight;

    public Lodging(int id, int destinationId, String name, String type, int stars, double rating, String status,
            String address, String city, String postalCode, String phone, String email, int totalRooms,
            double pricePerNight) {
        this.id = id;
        this.destinationId = destinationId;
        this.name = name;
        this.type = type;
        this.stars = stars;
        this.rating = rating;
        this.status = status;
        this.address = address;
        this.city = city;
        this.postalCode = postalCode;
        this.phone = phone;
        this.email = email;
        this.totalRooms = totalRooms;
        this.pricePerNight = pricePerNight;
    }

    // Constructor without ID (for insertion)
    public Lodging(int destinationId, String name, String type, int stars, double rating, String status,
            String address, String city, String postalCode, String phone, String email, int totalRooms,
            double pricePerNight) {
        this(0, destinationId, name, type, stars, rating, status, address, city, postalCode, phone, email, totalRooms,
                pricePerNight);
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getDestinationId() {
        return destinationId;
    }

    public void setDestinationId(int destinationId) {
        this.destinationId = destinationId;
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

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getPostalCode() {
        return postalCode;
    }

    public void setPostalCode(String postalCode) {
        this.postalCode = postalCode;
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

    public int getTotalRooms() {
        return totalRooms;
    }

    public void setTotalRooms(int totalRooms) {
        this.totalRooms = totalRooms;
    }

    public double getPricePerNight() {
        return pricePerNight;
    }

    public void setPricePerNight(double pricePerNight) {
        this.pricePerNight = pricePerNight;
    }
}
