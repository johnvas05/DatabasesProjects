import com.travelagency.*;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.sql.Date;
import java.util.*;

/**
 * =====================================================================
 * Application / GUI test suite for the travel agency project.
 * =====================================================================
 *
 * Every test calls the same classes the JavaFX screens call, so what is
 * verified here is exactly what happens when the buttons are pressed:
 *
 *   Customers      -> CustomerDAO
 *   Vehicles       -> VehicleDAO         (+ smart filter, bonus 3.2.3 #1)
 *   Lodgings       -> LodgingDAO, DestinationDAO
 *   Trips          -> TripDAO            (+ trip details, bonus 3.2.3 #2)
 *                                        (+ auto-booking, bonus 3.2.3 #3)
 *   Reservations   -> ReservationDAO     (adult/child pricing)
 *   Staff          -> WorkerDAO          (categories, salary trigger)
 *   Admin & Logs   -> AdminDAO           (log table, branch financials)
 *   Universal Mgr  -> UniversalTableManager
 *
 * It runs against a throw-away database; tests/app_tests.sh creates it,
 * points DB_URL at it and drops it afterwards. The application database is
 * never touched. Between sections the suite re-applies queries/Reset.sql,
 * so each section starts from the documented demo state.
 *
 * Usage:  java AppTests <path-to-Reset.sql>
 */
public class AppTests {

    // ---------------------------------------------------------------- harness

    private static int passed = 0;
    private static int failed = 0;
    private static final List<String> failures = new ArrayList<>();
    private static Path resetScript;

    interface Action {
        void run() throws Exception;
    }

    private static void section(String title) {
        System.out.println();
        System.out.println("== " + title);
    }

    private static void ok(String name) {
        passed++;
        System.out.println("  ok   " + name);
    }

    private static void bad(String name, String expected, String actual) {
        failed++;
        failures.add(name);
        System.out.println("  FAIL " + name);
        System.out.println("       expected: " + expected);
        System.out.println("       got:      " + actual);
    }

    /** Asserts a condition that the test itself evaluated. */
    private static void check(String name, boolean condition, String expected, Object actual) {
        if (condition) {
            ok(name);
        } else {
            bad(name, expected, String.valueOf(actual));
        }
    }

    private static void eq(String name, Object actual, Object expected) {
        check(name, Objects.equals(String.valueOf(actual), String.valueOf(expected)),
                String.valueOf(expected), actual);
    }

    private static void contains(String name, String actual, String needle) {
        check(name, actual != null && actual.contains(needle),
                "text containing \"" + needle + "\"", actual);
    }

    /** The GUI shows the SQLException message in an alert; here we assert on it. */
    private static void expectError(String name, String messagePart, Action action) {
        try {
            action.run();
            bad(name, "an error containing \"" + messagePart + "\"", "the call succeeded");
        } catch (Exception e) {
            String message = String.valueOf(e.getMessage());
            check(name, message.contains(messagePart), "error containing \"" + messagePart + "\"", message);
        }
    }

    /** A step that must not fail; a failure is reported instead of aborting the run. */
    private static void run(String name, Action action) {
        try {
            action.run();
            ok(name);
        } catch (Exception e) {
            bad(name, "no error", e.getClass().getSimpleName() + ": " + e.getMessage());
        }
    }

    // ---------------------------------------------------------------- helpers

    /** One value straight from the database, for assertions on what the DAO wrote. */
    private static String sql(String query) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {
            return rs.next() ? rs.getString(1) : null;
        }
    }

    /** One named column of the first row, for assertions on EXPLAIN output. */
    private static String sqlColumn(String query, String column) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {
            return rs.next() ? rs.getString(column) : null;
        }
    }

    private static void exec(String statement) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement()) {
            stmt.execute(statement);
        }
    }

    /**
     * Re-applies queries/Reset.sql, so the next section starts from the demo
     * state. The script holds no stored routines, so splitting it on the lines
     * that end a statement is enough.
     */
    private static void resetDatabase() throws SQLException, IOException {
        List<String> statements = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        for (String line : Files.readAllLines(resetScript, StandardCharsets.UTF_8)) {
            String trimmed = line.trim();
            if (trimmed.isEmpty() || trimmed.startsWith("--") || trimmed.toUpperCase().startsWith("USE ")) {
                continue;
            }
            current.append(line).append('\n');
            if (trimmed.endsWith(";")) {
                statements.add(current.toString());
                current.setLength(0);
            }
        }
        try (Connection conn = DatabaseConnection.getConnection();
                Statement stmt = conn.createStatement()) {
            for (String statement : statements) {
                stmt.execute(statement);
            }
        }
    }

    // ---------------------------------------------------------------- sections

    /** Main.java status bar: connect, show the account, register it as a DBA. */
    private static void testStartup() throws Exception {
        section("Startup (Main: status bar and DBA registration)");

        run("the application connects to the database",
                () -> {
                    if (DatabaseConnection.getConnection() == null) {
                        throw new SQLException("no connection");
                    }
                });
        contains("status bar shows the account and the URL", DatabaseConnection.describe(), "@ jdbc:mysql://");

        // the log triggers reject changes by an account that is not a DBA, so the
        // GUI registers the connecting account on connect
        eq("connecting account is registered in dba_users",
                sql("SELECT COUNT(*) FROM dba_users WHERE dba_username = SUBSTRING_INDEX(USER(), '@', 1)"), 1);

        exec("DELETE FROM dba_users WHERE dba_username = SUBSTRING_INDEX(USER(), '@', 1)");
        DatabaseConnection.closeConnection();
        DatabaseConnection.getConnection(); // reconnect: registerDba runs again
        eq("account is registered again after a reconnect",
                sql("SELECT COUNT(*) FROM dba_users WHERE dba_username = SUBSTRING_INDEX(USER(), '@', 1)"), 1);
    }

    /** Customers screen. */
    private static void testCustomers() throws Exception {
        section("Customers screen (CustomerDAO)");
        CustomerDAO dao = new CustomerDAO();

        List<Customer> all = dao.getAllCustomers();
        eq("the table lists the 20 seeded customers", all.size(), 20);
        check("the list is sorted by last name, then first name",
                isSortedByName(all), "sorted by last name", firstNames(all));
        check("every row carries the fields the columns show",
                all.get(0).getFirstName() != null && all.get(0).getLastName() != null
                        && all.get(0).getBirthDate() != null,
                "name, last name and birth date are read", all.get(0).getFirstName());

        // "Add Customer"
        dao.addCustomer(new Customer("Test", "Passenger", "test.passenger@mail.com",
                "2100000000", "Test Street 1", Date.valueOf("1995-05-05")));
        eq("Add Customer inserts the row", sql(
                "SELECT COUNT(*) FROM customer WHERE cust_lname = 'Passenger'"), 1);
        eq("the new customer appears in the refreshed table",
                dao.getAllCustomers().size(), 21);
        eq("the insert is written to the audit log (3.1.4.1)", sql(
                "SELECT log_action_type FROM log_actions WHERE log_table_name = 'customer' ORDER BY log_id DESC LIMIT 1"),
                "INSERT");

        int id = Integer.parseInt(sql("SELECT cust_id FROM customer WHERE cust_lname = 'Passenger'"));
        dao.deleteCustomer(id);
        eq("Delete removes the customer",
                sql("SELECT COUNT(*) FROM customer WHERE cust_lname = 'Passenger'"), 0);
        eq("the delete is written to the audit log", sql(
                "SELECT log_action_type FROM log_actions WHERE log_table_name = 'customer' ORDER BY log_id DESC LIMIT 1"),
                "DELETE");

        // the birth date decides the price of a reservation (adult / child)
        eq("15 adults and 5 children are available for the pricing demo",
                sql("SELECT CONCAT(SUM(TIMESTAMPDIFF(YEAR, cust_birth_date, CURDATE()) >= 18), '/',"
                        + " SUM(TIMESTAMPDIFF(YEAR, cust_birth_date, CURDATE()) < 18)) FROM customer"),
                "15/5");

        expectError("a customer of a booked reservation cannot be deleted (foreign key)",
                "foreign key constraint fails", () -> dao.deleteCustomer(1));
    }

    /** Vehicles screen, including the smart filter of bonus 3.2.3. */
    private static void testVehicles() throws Exception {
        section("Vehicles screen (VehicleDAO)");
        VehicleDAO dao = new VehicleDAO();

        eq("the table lists the 10 seeded vehicles", dao.getAllVehicles().size(), 10);

        dao.addVehicle(new Vehicle("TST-9001", "Sprinter", "Mercedes", "Van", 8, "Available", 1000, 1));
        eq("Add Vehicle inserts the row", sql(
                "SELECT v_seats FROM vehicle WHERE v_license_plate = 'TST-9001'"), 8);
        int id = Integer.parseInt(sql("SELECT v_id FROM vehicle WHERE v_license_plate = 'TST-9001'"));

        dao.updateVehicle(new Vehicle(id, "TST-9001", "Sprinter", "Mercedes", "Van", 8, "Maintenance", 2500, 1));
        eq("Update changes status and mileage",
                sql("SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = " + id), "Maintenance/2500");
        contains("the update is written to the audit log with the old and new value", sql(
                "SELECT log_details FROM log_actions WHERE log_table_name = 'vehicle' ORDER BY log_id DESC LIMIT 1"),
                "status Available -> Maintenance, mileage 1000 -> 2500");

        dao.deleteVehicle(id);
        eq("Delete Selected removes the vehicle",
                sql("SELECT COUNT(*) FROM vehicle WHERE v_license_plate = 'TST-9001'"), 0);

        // section 2: the number of seats must match the type (CHECK constraint)
        expectError("a Car with 30 seats is refused (type/seats rule)", "chk_vehicle_type_seats",
                () -> dao.addVehicle(new Vehicle("TST-9002", "X", "Y", "Car", 30, "Available", 0, 1)));
        expectError("a vehicle of an unknown branch is refused (foreign key)", "foreign key constraint fails",
                () -> dao.addVehicle(new Vehicle("TST-9003", "X", "Y", "Car", 4, "Available", 0, 999)));

        // Bonus 3.2.3 #1: the vehicle drop-down of the Trips screen
        section("Bonus 1: smart vehicle selection (VehicleDAO.getAvailableVehicles)");
        List<Vehicle> big = dao.getAvailableVehicles(40);
        eq("40+ seats: the three big buses are offered", big.size(), 3);
        check("only vehicles that are Available are offered",
                big.stream().allMatch(v -> "Available".equals(v.getStatus())),
                "every vehicle Available", statuses(big));
        check("the bus in Maintenance is not offered",
                big.stream().noneMatch(v -> v.getId() == 4), "vehicle 4 absent", ids(big));
        check("every offered vehicle has enough seats",
                big.stream().allMatch(v -> v.getSeats() >= 40), "all seats >= 40", seats(big));
        check("the smallest suitable vehicle comes first",
                big.get(0).getSeats() <= big.get(big.size() - 1).getSeats(), "ascending by seats", seats(big));

        eq("5 seats: every available vehicle is offered", dao.getAvailableVehicles(5).size(), 9);
        eq("999 seats: nothing is offered (the form says so)", dao.getAvailableVehicles(999).size(), 0);

        exec("UPDATE vehicle SET v_status = 'Maintenance' WHERE v_id = 1");
        check("a vehicle sent to maintenance disappears from the drop-down",
                dao.getAvailableVehicles(40).stream().noneMatch(v -> v.getId() == 1),
                "vehicle 1 absent", ids(dao.getAvailableVehicles(40)));
        exec("UPDATE vehicle SET v_status = 'Available' WHERE v_id = 1");
    }

    /** Lodgings screen. */
    private static void testLodgings() throws Exception {
        section("Lodgings screen (LodgingDAO, DestinationDAO)");
        LodgingDAO dao = new LodgingDAO();
        DestinationDAO destinations = new DestinationDAO();

        List<Lodging> all = dao.getAllLodgings();
        eq("the table lists the 10 seeded lodgings", all.size(), 10);
        Lodging paris = all.stream().filter(l -> l.getName().equals("Le Grand Paris")).findFirst().orElseThrow();
        eq("the columns show the stars of a hotel", paris.getStars(), 5);
        eq("the columns show the price per night", paris.getPricePerNight(), 250.0);
        Lodging hostel = all.stream().filter(l -> l.getName().equals("London Stay")).findFirst().orElseThrow();
        eq("a lodging without stars is read as 0, not as an error", hostel.getStars(), 0);

        // the destination drop-down of the form offers cities only (3.1.2.2)
        List<Destination> cities = destinations.getCityDestinations();
        eq("the destination list offers the 10 cities", cities.size(), 10);
        check("the country France is not offered as a lodging destination",
                cities.stream().noneMatch(d -> d.getName().equals("France")),
                "France absent", cities.stream().map(Destination::getName).toList());
        eq("the full destination list still has all 11 rows", destinations.getAllDestinations().size(), 11);

        dao.addLodging(new Lodging(1, "Test Hotel", "Hotel", 4, 0.0, "Active",
                "Test Street 2", "Paris", "75002", "3310000099", "test@hotel.fr", 12, 99.50));
        eq("Add Lodging inserts the row",
                sql("SELECT lg_total_rooms FROM lodging WHERE lg_name = 'Test Hotel'"), 12);
        int id = Integer.parseInt(sql("SELECT lg_id FROM lodging WHERE lg_name = 'Test Hotel'"));
        dao.deleteLodging(id);
        eq("Delete Selected removes the lodging",
                sql("SELECT COUNT(*) FROM lodging WHERE lg_name = 'Test Hotel'"), 0);

        // section 2 rules, enforced by the database and mirrored by the form
        expectError("a hostel with stars is refused (stars only for hotels/resorts)", "chk_lodging_stars_type",
                () -> dao.addLodging(new Lodging(2, "Bad Hostel", "Hostel", 3, 0.0, "Active",
                        "a", "London", "NW1", "44", "x@y.uk", 5, 10.0)));
        // the rule is "stars only for hotels and resorts", not "hotels must have
        // stars": a hotel that has not been rated yet is accepted
        run("a hotel whose stars are not known yet is accepted",
                () -> {
                    dao.addLodging(new Lodging(2, "Unrated Hotel", "Hotel", 0, 0.0, "Active",
                            "a", "London", "NW1", "44", "x@y.uk", 5, 10.0));
                    if (!"1".equals(sql("SELECT COUNT(*) FROM lodging WHERE lg_name = 'Unrated Hotel'"))) {
                        throw new SQLException("the lodging was not stored");
                    }
                    exec("DELETE FROM lodging WHERE lg_name = 'Unrated Hotel'");
                });
        expectError("a lodging in a country is refused (trigger)", "must belong to a city destination",
                () -> dao.addLodging(new Lodging(11, "Bad France", "Hotel", 3, 0.0, "Active",
                        "a", "Paris", "75001", "33", "x@y.fr", 5, 10.0)));
    }

    /** Trips screen: the table, adding a trip and assigning a vehicle (3.1.3.1). */
    private static void testTrips() throws Exception {
        section("Trips screen (TripDAO)");
        TripDAO dao = new TripDAO();

        List<Trip> trips = dao.getAllTrips();
        eq("the table lists the 14 seeded trips", trips.size(), 14);
        eq("the newest trip is on top (ordered by departure, descending)", trips.get(0).getId(), 14);
        Trip first = trips.stream().filter(t -> t.getId() == 1).findFirst().orElseThrow();
        eq("the columns show the adult price", first.getCostAdult(), 500.0);
        eq("the columns show the status", first.getStatus(), "PLANNED");

        // the form offers the drivers and guides of the database (3.2.2)
        WorkerDAO workers = new WorkerDAO();
        List<String> drivers = workers.getDriverOptions();
        eq("the driver drop-down offers the 8 drivers", drivers.size(), 8);
        contains("a driver is shown with the licence that decides the vehicle",
                drivers.get(0), "(licence D,");
        eq("the id behind the chosen driver is used",
                UniversalTableManager.optionKey(drivers.get(0)).length(), 5);
        List<String> guides = workers.getGuideOptions();
        eq("the guide drop-down offers the 8 guides", guides.size(), 8);
        contains("a guide is shown with the languages they speak", guides.get(0), "(");

        // "Add Trip": the form inserts the trip with its driver, then assigns the
        // vehicle through the procedure
        String driverAT = UniversalTableManager.optionKey(
                drivers.stream().filter(d -> d.contains("licence D")).findFirst().orElseThrow());
        int id = dao.addTrip(new Trip(Timestamp.valueOf("2027-05-01 08:00:00"),
                Timestamp.valueOf("2027-05-06 20:00:00"), 40, 450.0, 225.0, "PLANNED", 10, 1, 0,
                "AT119", driverAT));
        check("Add Trip returns the id of the new trip", id > 14, "an id above 14", id);
        eq("the trip is stored without a vehicle until the procedure runs",
                sql("SELECT IFNULL(tr_vehicle_id, 'NULL') FROM trip WHERE tr_id = " + id), "NULL");
        eq("the chosen driver and guide are stored with the trip",
                sql("SELECT CONCAT(tr_drv_AT, '/', tr_gui_AT) FROM trip WHERE tr_id = " + id),
                driverAT + "/AT119");
        eq("the new trip is in the refreshed table", dao.getAllTrips().size(), 15);

        // this is what the button does next: a 50-seat bus needs a C/D licence,
        // which the chosen driver has
        contains("the vehicle chosen in the form is assigned to the new trip",
                dao.assignVehicle(id, 1, 150000), "Success");
        eq("  ...and the trip now shows the vehicle",
                sql("SELECT tr_vehicle_id FROM trip WHERE tr_id = " + id), 1);
        exec("UPDATE trip SET tr_vehicle_id = NULL WHERE tr_id = " + id);
        exec("DELETE FROM trip WHERE tr_id = " + id);
        exec("UPDATE vehicle SET v_status = 'Available', v_mileage = 150000 WHERE v_id = 1");

        section("3.1.3.1 assigning a vehicle (TripDAO.assignVehicle)");
        // the five checks of the procedure, each one refused on its own
        expectError("a vehicle in maintenance is refused", "vehicle is Maintenance",
                () -> dao.assignVehicle(1, 4, 200100));
        expectError("an unknown trip is refused", "trip does not exist",
                () -> dao.assignVehicle(9999, 1, 1));
        expectError("an unknown vehicle is refused", "vehicle does not exist",
                () -> dao.assignVehicle(1, 9999, 1));
        expectError("a vehicle with too few seats is refused", "2 seats < 3 reservations",
                () -> {
                    exec("UPDATE vehicle SET v_seats = 2 WHERE v_id = 10");
                    dao.assignVehicle(3, 10, 10100);
                });
        expectError("a driver with licence B is refused on a bus", "driver licence B (C/D needed)",
                () -> dao.assignVehicle(8, 1, 150100));
        expectError("a vehicle already used on overlapping dates is refused", "overlaps 1 other trip",
                () -> dao.assignVehicle(2, 1, 150100));
        expectError("a mileage below the recorded one is refused", "mileage 1000 < recorded 90000",
                () -> dao.assignVehicle(14, 9, 1000));
        expectError("when two checks fail, the alert names both", "vehicle is Maintenance; mileage 1 < recorded 200000",
                () -> dao.assignVehicle(1, 4, 1));
        eq("a refused assignment changes nothing",
                sql("SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 4"), "Maintenance/200000");

        // the assignment that passes every check: trip 14 (driver AT113, licence D)
        // and the free 52-seat bus 9
        String report = dao.assignVehicle(14, 9, 90500);
        contains("the report of the checks is shown in the alert", report, "PASS");
        eq("all five checks pass", report.split("PASS", -1).length - 1, 5);
        contains("the seat check names the number of reservations", report, "52 seats for 1 confirmed/paid");
        eq("the vehicle is now in use, with the new mileage",
                sql("SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9"), "InUse/90500");
        eq("the trip points at the vehicle", sql("SELECT tr_vehicle_id FROM trip WHERE tr_id = 14"), 9);
        eq("the change of the vehicle is written to the audit log", sql(
                "SELECT log_details FROM log_actions WHERE log_table_name = 'vehicle' ORDER BY log_id DESC LIMIT 1")
                .contains("status Available -> InUse, mileage 90000 -> 90500"), true);

        // 3.1.4.3: completing the trip frees the vehicle and adds the kilometres
        exec("UPDATE trip SET tr_status = 'COMPLETED', tr_km = 350 WHERE tr_id = 14");
        eq("completing the trip frees the vehicle and adds its kilometres (3.1.4.3)",
                sql("SELECT CONCAT(v_status, '/', v_mileage) FROM vehicle WHERE v_id = 9"), "Available/90850");
    }

    /** Bonus 3.2.3 #2: the Trip Details window. */
    private static void testTripDetails() throws Exception {
        section("Bonus 2: Show Trip Details (TripDAO.getDriverInfo / getGuideInfo / getAccommodations)");
        TripDAO dao = new TripDAO();
        Trip trip = dao.getAllTrips().stream().filter(t -> t.getId() == 1).findFirst().orElseThrow();

        TripDAO.StaffInfo driver = dao.getDriverInfo(trip.getDriverId());
        check("the driver of the trip is found", driver != null, "a driver", null);
        eq("the driver's name is shown", driver.name + " " + driver.lastName, "Takis Volanis");
        eq("the driver's licence is shown", driver.licence, "D");
        eq("the driver's experience is shown", driver.experience, 10);

        TripDAO.StaffInfo guide = dao.getGuideInfo(trip.getGuideId());
        check("the guide of the trip is found", guide != null, "a guide", null);
        eq("the guide's name is shown", guide.name + " " + guide.lastName, "Zoi Laskari");
        // the languages come from the languages table, named through language_ref
        eq("the languages the guide speaks are shown", guide.languages, "French");

        exec("INSERT INTO languages (lng_gui_AT, lng_language_code) VALUES ('AT119', 'EN')");
        eq("a guide who speaks two languages shows both",
                dao.getGuideInfo("AT119").languages, "English, French");
        exec("DELETE FROM languages WHERE lng_gui_AT = 'AT119' AND lng_language_code = 'EN'");

        check("a trip without a driver shows 'Not assigned' instead of failing",
                dao.getDriverInfo(null) == null, "null", dao.getDriverInfo(null));
        check("an unknown guide gives no row", dao.getGuideInfo("AT999") == null, "null", dao.getGuideInfo("AT999"));

        eq("a trip with no bookings yet shows an empty list", dao.getAccommodations(1).size(), 0);

        ReservationDAO reservations = new ReservationDAO();
        eq("the passenger table of the window lists the reservations of the trip",
                reservations.getReservationsByTripId(1).size(), 3);
        contains("the passengers are shown by name",
                reservations.getReservationsByTripId(1).get(0).getCustomerName(), "C1 Lname1");
    }

    /** Bonus 3.2.3 #3: auto-booking hotels for a whole trip. */
    private static void testAutoBooking() throws Exception {
        section("Bonus 3: Auto-Book Accommodations (TripDAO.autoBookAccommodations, 3.1.3.3)");
        TripDAO dao = new TripDAO();

        String result = dao.autoBookAccommodations(1);
        contains("the confirmation names the number of bookings", result, "booked 2 accommodation(s)");
        eq("one lodging is booked per destination of the trip",
                sql("SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1"), 2);

        List<TripDAO.AccommodationInfo> booked = dao.getAccommodations(1);
        eq("the Paris leg is booked first", booked.get(0).lodgingName, "Le Grand Paris");
        eq("with the dates of the stay", booked.get(0).checkIn + " to " + booked.get(0).checkOut,
                "2026-06-01 to 2026-06-05");
        eq("the cost is 4 nights x 250 for one room", booked.get(0).cost, 1000.0);
        eq("the London leg follows", booked.get(1).lodgingName, "London Stay");
        eq("its cost is 5 nights x 60", booked.get(1).cost, 300.0);
        eq("the nights are stored by the trigger (3.1.4.2)",
                sql("SELECT ru_nights FROM room_usage WHERE ru_trip_id = 1 ORDER BY ru_checkin LIMIT 1"), 4);

        // one room per two confirmed passengers: trip 3 has 3 paid reservations
        dao.autoBookAccommodations(3);
        eq("rooms = ceil(passengers / 2): 3 passengers need 2 rooms",
                sql("SELECT DISTINCT ru_rooms_count FROM room_usage WHERE ru_trip_id = 3"), 2);

        eq("booking again replaces the previous bookings, it does not add to them",
                dao.autoBookAccommodations(1).contains("2 accommodation(s)"), true);
        eq("  ...so the trip still has exactly two bookings",
                sql("SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1"), 2);

        expectError("an unknown trip is refused", "trip does not exist",
                () -> dao.autoBookAccommodations(9999));
        expectError("a trip without confirmed reservations is refused", "no confirmed or paid reservations",
                () -> {
                    exec("UPDATE reservation SET res_status = 'PENDING' WHERE res_tr_id = 12");
                    dao.autoBookAccommodations(12);
                });
        expectError("a destination with no free room is reported by name",
                "no lodging in London with 1 free room(s)",
                () -> {
                    exec("UPDATE lodging SET lg_total_rooms = 0 WHERE lg_id = 2");
                    dao.autoBookAccommodations(1);
                });
        eq("  ...and the whole booking is rolled back, not left half done",
                sql("SELECT COUNT(*) FROM room_usage WHERE ru_trip_id = 1"), 0);
    }

    /** Reservations screen, including the adult/child pricing procedure. */
    private static void testReservations() throws Exception {
        section("Reservations screen (ReservationDAO)");
        ReservationDAO dao = new ReservationDAO();

        List<Reservation> all = dao.getAllReservations();
        eq("the table lists the 24 seeded reservations", all.size(), 24);
        check("each row shows the customer's name, not the id",
                all.stream().allMatch(r -> r.getCustomerName() != null && r.getCustomerName().contains(" ")),
                "customer names", all.get(0).getCustomerName());
        contains("each row shows the trip and its departure", all.get(0).getTripInfo(), "Trip ID:");

        eq("the details window of trip 1 shows its 3 reservations",
                dao.getReservationsByTripId(1).size(), 3);
        eq("the seats of a trip are listed in order",
                dao.getReservationsByTripId(1).get(0).getSeatNum(), 1);
        eq("a trip without reservations gives an empty list", dao.getReservationsByTripId(9999).size(), 0);

        // the free-seat drop-down of the form: max seats minus the taken ones
        Set<Integer> taken = new HashSet<>();
        for (Reservation r : dao.getReservationsByTripId(1)) {
            taken.add(r.getSeatNum());
        }
        List<Integer> free = new ArrayList<>();
        for (int seat = 1; seat <= 50; seat++) {
            if (!taken.contains(seat)) {
                free.add(seat);
            }
        }
        eq("the form offers the 47 free seats of trip 1", free.size(), 47);
        check("seats 1 to 3 are taken and are not offered",
                !free.contains(1) && !free.contains(2) && !free.contains(3), "1, 2, 3 absent", free.subList(0, 3));
        eq("the first free seat offered is 4", free.get(0), 4);

        // "Book Reservation": the cost comes from sp_calculate_reservation_cost
        dao.addReservation(new Reservation(1, 10, 1, "PENDING", 0));
        eq("an adult is charged the adult price of the trip (500)",
                sql("SELECT res_total_cost FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 10"), "500.00");

        dao.addReservation(new Reservation(1, 11, 20, "PENDING", 0));
        eq("a child is charged the child price of the trip (300)",
                sql("SELECT res_total_cost FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 11"), "300.00");

        eq("both new bookings are in the refreshed table", dao.getAllReservations().size(), 26);
        eq("the booking is written to the audit log", sql(
                "SELECT COUNT(*) FROM log_actions WHERE log_table_name = 'reservation' AND log_action_type = 'INSERT'"),
                2);

        expectError("the same seat cannot be booked twice", "Duplicate entry",
                () -> dao.addReservation(new Reservation(1, 10, 2, "PENDING", 0)));
        expectError("a booking on an unknown trip is refused", "foreign key constraint fails",
                () -> dao.addReservation(new Reservation(9999, 1, 1, "PENDING", 0)));
        expectError("a booking for an unknown customer is refused", "foreign key constraint fails",
                () -> dao.addReservation(new Reservation(1, 12, 9999, "PENDING", 0)));
    }

    /** Staff screen: the three worker categories and the salary trigger. */
    private static void testStaff() throws Exception {
        section("Staff screen (WorkerDAO)");
        WorkerDAO dao = new WorkerDAO();

        eq("the table lists the 26 seeded workers", dao.getAllWorkers().size(), 26);
        eq("the language drop-down offers the 6 languages", dao.getLanguageCodes().size(), 6);
        contains("a language is shown as code and name", dao.getLanguageCodes().get(0), " | ");

        // every worker belongs to exactly one category (section 2.3)
        dao.addWorker(new Worker("AT901", "Test", "Driver", 1200, 1), "t.driver@ag.gr",
                "DRIVER", "C", "LOCAL", 7);
        eq("Add Worker (DRIVER) writes the worker row",
                sql("SELECT wrk_lname FROM worker WHERE wrk_AT = 'AT901'"), "Driver");
        eq("  ...and the driver row with licence, route and experience",
                sql("SELECT CONCAT(drv_license, '/', drv_route, '/', drv_experience) FROM driver WHERE drv_AT = 'AT901'"),
                "C/LOCAL/7");

        dao.addWorker(new Worker("AT902", "Test", "Guide", 1100, 1), "t.guide@ag.gr",
                "GUIDE", "Test CV", "EN", null);
        eq("Add Worker (GUIDE) writes the guide row",
                sql("SELECT gui_cv FROM guide WHERE gui_AT = 'AT902'"), "Test CV");
        eq("  ...and the language the guide speaks",
                sql("SELECT lng_language_code FROM languages WHERE lng_gui_AT = 'AT902'"), "EN");

        dao.addWorker(new Worker("AT903", "Test", "Admin", 1300, 1), "t.admin@ag.gr",
                "ADMIN", "LOGISTICS", "BSc", null);
        eq("Add Worker (ADMIN) writes the admin row",
                sql("SELECT CONCAT(adm_type, '/', adm_diploma) FROM admin WHERE adm_AT = 'AT903'"), "LOGISTICS/BSc");

        eq("the three new workers are in the refreshed table", dao.getAllWorkers().size(), 29);
        eq("every worker is in exactly one category",
                sql("SELECT COUNT(*) FROM worker w WHERE (SELECT COUNT(*) FROM driver WHERE drv_AT = w.wrk_AT)"
                        + " + (SELECT COUNT(*) FROM guide WHERE gui_AT = w.wrk_AT)"
                        + " + (SELECT COUNT(*) FROM admin WHERE adm_AT = w.wrk_AT) <> 1"),
                0);

        // the category row and the worker row are written in one transaction
        expectError("an unknown category is refused", "Unknown worker category",
                () -> dao.addWorker(new Worker("AT904", "Bad", "Category", 1000, 1), "b@ag.gr",
                        "PILOT", null, null, null));
        eq("  ...and no half-created worker is left behind (rollback)",
                sql("SELECT COUNT(*) FROM worker WHERE wrk_AT = 'AT904'"), 0);

        expectError("a guide with an unknown language is refused", "foreign key constraint fails",
                () -> dao.addWorker(new Worker("AT905", "Bad", "Language", 1000, 1), "b@ag.gr",
                        "GUIDE", "CV", "ZZ", null));
        eq("  ...and the worker and guide rows are rolled back too",
                sql("SELECT COUNT(*) FROM worker WHERE wrk_AT = 'AT905'"), 0);

        expectError("a duplicate worker id is refused", "Duplicate entry",
                () -> dao.addWorker(new Worker("AT101", "Dup", "Worker", 1000, 1), "d@ag.gr",
                        "ADMIN", "LOGISTICS", "BSc", null));

        // "Update Salary": the trigger allows a raise only in a profitable branch
        // and only up to 2%
        section("Staff screen: salary trigger (trg_worker_salary_increase)");
        exec("UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1"); // lowering is always allowed
        eq("lowering a salary is always allowed",
                sql("SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'"), "100.00");

        dao.updateSalary("AT101", 101);
        eq("a raise of 1% in a profitable branch is accepted",
                sql("SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'"), "101.00");

        expectError("a raise above 2% is refused by the trigger", "exceeds 2% limit",
                () -> dao.updateSalary("AT101", 110));
        eq("  ...and the salary is unchanged",
                sql("SELECT wrk_salary FROM worker WHERE wrk_AT = 'AT101'"), "101.00");

        expectError("a raise in a branch that makes no profit is refused", "branch is not profitable",
                () -> {
                    exec("UPDATE reservation SET res_total_cost = 0");
                    dao.updateSalary("AT101", 102);
                });
    }

    /** Admin & Logs screen. */
    private static void testAdmin() throws Exception {
        section("Admin & Logs screen (AdminDAO)");
        AdminDAO dao = new AdminDAO();

        eq("after a reset the log is empty, so the demo starts clean",
                dao.getAllLogs().size(), 0);

        // produce a few actions, the way the other screens do
        new CustomerDAO().addCustomer(new Customer("Log", "Check", "log.check@mail.com",
                "2100000001", "Street 3", Date.valueOf("1990-01-01")));
        exec("UPDATE customer SET cust_phone = '2100000002' WHERE cust_lname = 'Check'");
        exec("DELETE FROM customer WHERE cust_lname = 'Check'");

        List<LogEntry> logs = dao.getAllLogs();
        eq("the three actions are logged", logs.size(), 3);
        eq("the newest action is on top", logs.get(0).getAction(), "DELETE");
        eq("the table that changed is recorded", logs.get(0).getTableName(), "customer");
        eq("the DBA account that made the change is recorded", logs.get(0).getUsername(),
                sql("SELECT SUBSTRING_INDEX(USER(), '@', 1)"));
        check("the time of the change is recorded", logs.get(0).getTimestamp() != null,
                "a timestamp", logs.get(0).getTimestamp());

        // the view shows the 100 most recent entries
        exec("INSERT INTO destination (dst_name, dst_rtype, dst_language_code) "
                + "SELECT CONCAT('LogCity', seq), 'LOCAL', 'EN' FROM seq_1_to_120");
        check("the table shows at most the 100 newest entries", dao.getAllLogs().size() == 100,
                "100", dao.getAllLogs().size());
        exec("DELETE FROM destination WHERE dst_name LIKE 'LogCity%'");

        section("Admin & Logs screen: branch financials (sp_branch_financials)");
        String financials = dao.getBranchFinancials(1);
        contains("the procedure reports the revenue of the branch", financials, "Revenue:");
        contains("  ...the expenses", financials, "Expenses:");
        contains("  ...and the profit ratio", financials, "Profit Ratio:");
        contains("the branch that was asked for is named", financials, "Branch Code: 1");
        contains("an unknown branch is reported, not crashed", dao.getBranchFinancials(999), "not found");
    }

    /** Universal Manager screen: schema-driven CRUD on every table (3.2.2). */
    private static void testUniversalManager() throws Exception {
        section("Universal Manager screen (UniversalTableManager)");

        List<String> tables = UniversalTableManager.getAllTableNames();
        eq("every table of the database is offered", tables.size(), 21);
        check("the list is sorted and free of duplicates",
                new TreeSet<>(tables).size() == tables.size(), "no duplicates", tables.size());
        check("the tables of the report are there",
                tables.containsAll(List.of("trip", "reservation", "vehicle", "lodging", "room_usage",
                        "trip_history", "log_actions", "dba_users")),
                "all project tables", tables);

        List<UniversalTableManager.ColumnInfo> columns = UniversalTableManager.getTableColumns("vehicle");
        eq("the columns of the chosen table are read", columns.size(), 9);
        check("the generated key is recognised, so the form does not ask for it",
                columns.stream().anyMatch(c -> c.name.equals("v_id") && c.autoIncrement),
                "v_id auto increment", columns.get(0).name);
        check("columns that may stay empty are recognised",
                columns.stream().anyMatch(c -> c.nullable), "a nullable column", "none");

        // a seat of a trip can be booked once: the key is (trip, seat)
        eq("a composite primary key is read completely, in the order of the key",
                UniversalTableManager.getPrimaryKeys("reservation"), List.of("res_tr_id", "res_seatnum"));
        eq("a single primary key is read", UniversalTableManager.getPrimaryKeys("trip"), List.of("tr_id"));

        eq("the rows of the chosen table are shown", UniversalTableManager.getAllRows("branch").size(), 6);
        Map<String, Object> row = UniversalTableManager.getAllRows("branch").get(0);
        check("every column of the row is available to the table view",
                row.containsKey("br_code") && row.containsKey("br_city"), "br_code and br_city", row.keySet());

        // foreign keys become drop-downs of the referenced rows (3.2.2)
        Map<String, String[]> foreignKeys = UniversalTableManager.getForeignKeys("travel_to");
        check("the foreign keys of the table are found",
                foreignKeys.containsKey("to_dst_id") && foreignKeys.containsKey("to_tr_id"),
                "to_dst_id and to_tr_id", foreignKeys.keySet());
        eq("a foreign key knows the table it points at", foreignKeys.get("to_dst_id")[0], "destination");
        eq("  ...and the column", foreignKeys.get("to_dst_id")[1], "dst_id");

        List<String> options = UniversalTableManager.getReferenceOptions("destination", "dst_id");
        eq("the drop-down offers every referenced row", options.size(), 11);
        contains("each option shows the key and a readable description", options.get(0), "1 | Paris");
        eq("the key is taken from the chosen option", UniversalTableManager.optionKey("1 | Paris ABROAD"), "1");
        eq("an option without a description still gives its key", UniversalTableManager.optionKey("7"), "7");
        check("no option is passed as null", UniversalTableManager.optionKey(null) == null, "null", "not null");

        // ENUM and date columns get the right editor
        Map<String, String> types = UniversalTableManager.getColumnSqlTypes("vehicle");
        contains("an ENUM column offers its values as a list", types.get("v_type"), "enum(");
        contains("  ...including the status column", types.get("v_status"), "enum(");
        contains("a date column gets a date picker", UniversalTableManager.getColumnSqlTypes("trip").get("tr_departure"),
                "datetime");

        // insert / update / delete through the generic dialog
        Map<String, Object> values = new LinkedHashMap<>();
        values.put("v_br_code", 1);
        values.put("v_license_plate", "UNI-0001");
        values.put("v_model", "Universal");
        values.put("v_brand", "Test");
        values.put("v_type", "Car");
        values.put("v_seats", 4);
        UniversalTableManager.executeInsert("vehicle", values);
        eq("Insert adds the row", sql("SELECT v_model FROM vehicle WHERE v_license_plate = 'UNI-0001'"), "Universal");

        String id = sql("SELECT v_id FROM vehicle WHERE v_license_plate = 'UNI-0001'");
        UniversalTableManager.executeUpdate("vehicle", Map.of("v_seats", 5, "v_status", "Maintenance"),
                Map.of("v_id", Integer.parseInt(id)));
        eq("Update changes only the chosen row",
                sql("SELECT CONCAT(v_seats, '/', v_status) FROM vehicle WHERE v_id = " + id), "5/Maintenance");
        eq("  ...and leaves the other rows alone",
                sql("SELECT COUNT(*) FROM vehicle WHERE v_status = 'Maintenance'"), 2);

        UniversalTableManager.executeDelete("vehicle", Map.of("v_id", Integer.parseInt(id)));
        eq("Delete removes the row", sql("SELECT COUNT(*) FROM vehicle WHERE v_license_plate = 'UNI-0001'"), 0);

        // a composite key is used completely, so only one row is touched
        UniversalTableManager.executeUpdate("reservation", Map.of("res_status", "PAID"),
                Map.of("res_tr_id", 1, "res_seatnum", 1));
        eq("a row with a composite key is updated by both key columns",
                sql("SELECT res_status FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 1"), "PAID");
        eq("  ...and the other seats of the trip are untouched",
                sql("SELECT res_status FROM reservation WHERE res_tr_id = 1 AND res_seatnum = 2"), "CONFIRMED");

        expectError("the rules of the database still apply in the generic dialog", "chk_vehicle_type_seats",
                () -> UniversalTableManager.executeInsert("vehicle", Map.of("v_br_code", 1,
                        "v_license_plate", "UNI-0002", "v_model", "M", "v_brand", "B",
                        "v_type", "Car", "v_seats", 40)));
    }

    /** The history reports of 3.1.3.4, reachable from the Universal Manager. */
    private static void testHistory() throws Exception {
        section("Trip history (3.1.2.3 / 3.1.3.4)");

        eq("the 90 000 generated trips are in the database", sql("SELECT COUNT(*) FROM trip_history"), 90000);
        check("the revenue report returns a number",
                Double.parseDouble(sql("CALL sp_history_revenue('2021-01-01', '2021-12-31')")) > 0,
                "a positive revenue", sql("CALL sp_history_revenue('2021-01-01', '2021-12-31')"));
        eq("the revenue report uses its covering index (3.1.3.4)",
                sqlColumn("EXPLAIN SELECT SUM(th_revenue) FROM trip_history "
                        + "WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31'", "key"),
                "idx_hist_dep_rev");
        eq("the destination report uses its covering index (3.1.3.4)",
                sqlColumn("EXPLAIN SELECT th_departure FROM trip_history WHERE th_dest_count = 3", "key"),
                "idx_hist_dc_dep");
        check("the destination report returns rows",
                Integer.parseInt(sql("SELECT COUNT(*) FROM trip_history WHERE th_dest_count = 3")) > 1000,
                "more than 1000 trips with 3 destinations",
                sql("SELECT COUNT(*) FROM trip_history WHERE th_dest_count = 3"));
        eq("the reset keeps the history (regenerating it takes minutes)",
                sql("SELECT COUNT(*) FROM trip_history"), 90000);
    }

    // ---------------------------------------------------------------- small helpers

    private static boolean isSortedByName(List<Customer> customers) {
        for (int i = 1; i < customers.size(); i++) {
            String previous = customers.get(i - 1).getLastName() + " " + customers.get(i - 1).getFirstName();
            String current = customers.get(i).getLastName() + " " + customers.get(i).getFirstName();
            if (previous.compareToIgnoreCase(current) > 0) {
                return false;
            }
        }
        return true;
    }

    private static List<String> firstNames(List<Customer> customers) {
        return customers.stream().map(c -> c.getLastName() + " " + c.getFirstName()).limit(5).toList();
    }

    private static List<Integer> ids(List<Vehicle> vehicles) {
        return vehicles.stream().map(Vehicle::getId).toList();
    }

    private static List<Integer> seats(List<Vehicle> vehicles) {
        return vehicles.stream().map(Vehicle::getSeats).toList();
    }

    private static List<String> statuses(List<Vehicle> vehicles) {
        return vehicles.stream().map(Vehicle::getStatus).toList();
    }

    // ---------------------------------------------------------------- main

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.err.println("usage: java AppTests <path-to-Reset.sql>");
            System.exit(2);
        }
        resetScript = Path.of(args[0]);
        if (!Files.exists(resetScript)) {
            System.err.println("reset script not found: " + resetScript);
            System.exit(2);
        }

        System.out.println("Application tests against " + DatabaseConnection.describe());

        // Each section starts from the demo state, so the tests are independent
        // and can be read (and shown) in any order.
        Map<String, Action> sections = new LinkedHashMap<>();
        sections.put("startup", AppTests::testStartup);
        sections.put("customers", AppTests::testCustomers);
        sections.put("vehicles", AppTests::testVehicles);
        sections.put("lodgings", AppTests::testLodgings);
        sections.put("trips", AppTests::testTrips);
        sections.put("trip details", AppTests::testTripDetails);
        sections.put("auto-booking", AppTests::testAutoBooking);
        sections.put("reservations", AppTests::testReservations);
        sections.put("staff", AppTests::testStaff);
        sections.put("admin", AppTests::testAdmin);
        sections.put("universal manager", AppTests::testUniversalManager);
        sections.put("history", AppTests::testHistory);

        for (Map.Entry<String, Action> entry : sections.entrySet()) {
            resetDatabase();
            try {
                entry.getValue().run();
            } catch (Exception e) {
                failed++;
                failures.add(entry.getKey() + " (section aborted)");
                System.out.println("  FAIL section \"" + entry.getKey() + "\" stopped: "
                        + e.getClass().getSimpleName() + ": " + e.getMessage());
                e.printStackTrace(System.out);
            }
        }

        resetDatabase();
        DatabaseConnection.closeConnection();

        System.out.println();
        System.out.println("Passed: " + passed + "   Failed: " + failed);
        for (String failure : failures) {
            System.out.println("  - " + failure);
        }
        System.exit(failed == 0 ? 0 : 1);
    }
}
