# How to Run the Travel Agency GUI

## Quick Start

### 1. Configure Database Connection

Edit this file: `src/main/java/com/travelagency/DatabaseConnection.java`

```java
private static final String URL = "jdbc:mysql://localhost:3306/baseis project";
private static final String USER = "root";        // Your MySQL username
private static final String PASSWORD = "yourpass"; // Your MySQL password
```

### 2. Launch the Application

**Run this file:** `src/main/java/com/travelagency/Launcher.java`

**In Eclipse:**
- Right-click `Launcher.java` → Run As → Java Application

**From Command Line:**
```bash
java -cp ".;src/main/java;lib/*" com.travelagency.Launcher
```

That's it! The GUI window will open.

---

## Main Features

- **Home** - Dashboard
- **Customers** - Manage customers
- **Vehicles** - Manage vehicles
- **Lodging** - Manage hotels
- **Trips** - ⭐ Main feature (includes all bonus features)
- **Reservations** - Manage bookings
- **Staff** - Manage employees

### Bonus Features (3.2.3) - All in "Trips" section:
1. **Smart Vehicle Selection** - Dropdown filters by capacity (real-time)
2. **Trip Details** - Click "Show Trip Details" button
3. **Auto-Book Hotels** - Click "Auto-Book Accommodations 🏨" button

---

## Prerequisites

- Java JDK 17+
- MySQL Server running
- Database `baseis project` created and populated

**Need database setup?** See `queries/Query.sql` for schema and `queries/Insertions.sql` for sample data.
