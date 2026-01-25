package com.travelagency;

import java.sql.Timestamp;

public class LogEntry {
    private int id;
    private String username;
    private Timestamp timestamp;
    private String action;
    private String tableName;

    public LogEntry(int id, String username, Timestamp timestamp, String action, String tableName) {
        this.id = id;
        this.username = username;
        this.timestamp = timestamp;
        this.action = action;
        this.tableName = tableName;
    }

    public int getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public Timestamp getTimestamp() {
        return timestamp;
    }

    public String getAction() {
        return action;
    }

    public String getTableName() {
        return tableName;
    }
}
