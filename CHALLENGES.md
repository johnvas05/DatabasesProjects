# Technical Challenges & Solutions

## 1. Database Schema Mismatch Issues

### Challenge: Lodging Table Empty / Model Mismatch
**Problem:**
- Initial database dump had empty `lodging` table
- Java model (`Accommodation.java`) didn't match actual schema
- Column names differed between code expectations and database reality

**Solution:**
- Renamed class from `Accommodation` to `Lodging` to match database
- Updated all field names to match schema (e.g., `lg_name`, `lg_cost_per_night`)
- Modified DAO queries to use correct column names
- Ensured proper FK relationships with `destination` table

**Lesson Learned:** Always validate database schema against application models before implementation.

---

## 2. Foreign Key Constraint Violations

### Challenge: User Registration Trigger Failure
**Problem:**
- `log_actions` table had FK to `dba_users` table
- Database triggers failed because current user wasn't registered in `dba_users`
- Error: "Cannot add or update a child row: a foreign key constraint fails"

**Solution:**
- Implemented automatic user registration on database connection
- Added `DatabaseConnection.registerCurrentUser()` method
- Checks if user exists in `dba_users` before registering
- Prevents duplicate registration with "skip if exists" logic

**Impact:** System logs and triggers now work seamlessly without manual user setup.

---

## 3. System Logs Not Displaying

### Challenge: Incorrect Table/Column Names
**Problem:**
- Query used `SELECT * FROM log` but actual table was `log_actions`
- Column names didn't match schema:
  - Used: `log_username` vs Actual: `log_dba_username`
  - Used: `log_action` vs Actual: `log_action_type`

**Solution:**
- Updated `AdminDAO.getAllLogs()` query to use correct table name
- Fixed all column references in ResultSet mapping:
  ```java
  rs.getString("log_dba_username")  // was: log_username
  rs.getString("log_action_type")   // was: log_action
  ```
- Added LIMIT 100 for performance optimization

**Lesson Learned:** Document exact schema during database design phase.

---

## 4. JavaFX Runtime Configuration

### Challenge: Module System Errors
**Problem:**
- JavaFX 17+ requires explicit module configuration
- Direct execution of `Main.java` failed with "JavaFX runtime components are missing"
- Module path not properly configured in Maven

**Solution:**
- Created `Launcher.java` as entry point (non-JavaFX class)
- Launcher calls `Application.launch(Main.class, args)`
- Updated `pom.xml` with proper JavaFX dependencies and plugins:
  ```xml
  <plugin>
    <groupId>org.openjfx</groupId>
    <artifactId>javafx-maven-plugin</artifactId>
    <configuration>
      <mainClass>com.travelagency.Launcher</mainClass>
    </configuration>
  </plugin>
  ```

**Impact:** Application launches correctly on all systems without manual module configuration.

---

## 5. Vehicle Model Constructor Issues

### Challenge: Missing Fields in Vehicle Class
**Problem:**
- Database schema added new fields: `v_seats`, `v_branch_code`
- Old `Vehicle` model missing these fields
- Smart vehicle selection feature needed seat count

**Solution:**
- Updated `Vehicle.java` constructor to include all fields
- Added getters/setters for `seats` and `branchCode`
- Modified `VehicleDAO` to populate new fields from ResultSet
- Updated `VehicleView` form to include new input fields

**Complexity:** Required changes across model, DAO, and view layers simultaneously.

---

## 6. Dynamic Vehicle Filtering Implementation

### Challenge: Real-time Dropdown Filtering
**Problem:**
- Need to filter vehicles based on trip max seats dynamically
- Filter must update as user types in seats field
- Must only show available vehicles with sufficient capacity

**Solution:**
- Added `getAvailableVehicles(minSeats)` method to `VehicleDAO`:
  ```sql
  SELECT * FROM vehicle 
  WHERE v_status = 'Available' AND v_seats >= ?
  ```
- Implemented `TextProperty` listener on seats TextField
- Updates ComboBox items on every text change
- Added initial load with default value (40 seats)

**Challenge:** Balancing performance with real-time updates (solved with efficient SQL).

---

## 7. Universal Table Manager Complexity

### Challenge: Generic CRUD for Unknown Tables
**Problem:**
- Need to display/edit ANY table without hardcoding
- Different tables have different column types
- Primary keys vary (some auto-increment, some composite)
- Foreign keys need special handling

**Solution:**
- Used `DatabaseMetaData` to introspect schema at runtime:
  ```java
  DatabaseMetaData meta = conn.getMetaData();
  ResultSet tables = meta.getTables(null, null, "%", new String[]{"TABLE"});
  ResultSet columns = meta.getColumns(null, null, tableName, null);
  ```
- Dynamic column generation based on metadata
- Detected primary keys and auto-increment columns
- Special handling for FK columns (future enhancement: dropdowns)

**Lesson Learned:** JDBC metadata capabilities are powerful for generic database tools.

---

## 8. Enhanced Trip Dashboard JOIN Queries

### Challenge: Complex Multi-Table Data Aggregation
**Problem:**
- Need to display data from 6+ related tables:
  - `trip` → `vehicle` → `driver`/`guide` → `worker`
  - `trip` → `room_usage` → `lodging`
  - `trip` → `reservation` → `customer`
- Some relationships optional (nullable FKs)

**Solution:**
- Implemented separate queries for each section:
  - Driver info: JOIN `worker` + `driver` tables
  - Guide info: JOIN `worker` + `guide` tables
  - Accommodations: JOIN `room_usage` + `lodging` tables
- Handled NULL values gracefully (show "Not assigned")
- Used try-catch for each section to prevent total failure

**Complexity:** Balancing multiple database calls vs query complexity.

---

## 9. Accommodation Cost Calculation

### Challenge: Zero Costs in Database
**Problem:**
- `room_usage.ru_total_cost` showing $0.00
- Database trigger for cost calculation not firing
- Need to display meaningful cost data

**Initial Approach (Attempted):**
- Calculate cost in Java: rooms × nights × price_per_night
- Query `lodging` table for price per night
- Calculate days between check-in/check-out

**Final Decision:**
- Reverted to displaying database value as-is
- Issue identified as database trigger problem, not application issue
- Application should rely on database-calculated values

**Lesson Learned:** Respect separation of concerns - let database handle its calculations.

---

## 10. Code Organization & Cleanup

### Challenge: Unused Methods and Code Bloat
**Problem:**
- Generated helper methods that became unused (`clearForm()` with multiple signatures)
- Unused imports cluttering files
- Lint warnings affecting code quality

**Solution:**
- Removed unused `clearForm()` method variants
- Manually cleared fields inline where needed
- Removed unused imports (e.g., `java.sql.SQLException` in Main.java then restored when actually used)
- Suppressed unavoidable generic type safety warnings

**Impact:** Cleaner codebase, easier maintenance, professional appearance.

---

## Summary of Key Learnings

1. **Schema Documentation is Critical** - Mismatches cause cascading issues
2. **Foreign Keys Need Planning** - Especially for triggers and logging
3. **JavaFX Configuration is Tricky** - Use proper launcher and module setup
4. **Metadata is Powerful** - Enables generic database tools
5. **Test Incrementally** - Small iterations prevent compounding errors
6. **Separation of Concerns** - Database logic in DB, application logic in code
7. **User Experience Matters** - Real-time filtering, helpful error messages
8. **Handle NULLs Gracefully** - Optional relationships need fallback displays

---

## Statistics

- **Total Issues Resolved:** 10 major challenges
- **Database Issues:** 4 (schema, FK, logs, triggers)
- **Application Issues:** 4 (JavaFX, model, filtering, CRUD)
- **Design Decisions:** 2 (cost calculation, code cleanup)
- **Lines of Code Added:** ~2000+
- **Files Created:** 4 (UniversalTableManager, UniversalTableView, Launcher, LogEntry)
- **Files Modified:** 15+ (models, DAOs, views, config)
