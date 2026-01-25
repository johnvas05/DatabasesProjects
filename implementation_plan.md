# Database Project Implementation Plan

This plan outlines the steps to complete the "Laboratory Database Project 2025-2026". The project involves designing and implementing extensions to a travel agency database.

## User Review Required
> [!NOTE]
> **Base Schema**: I will use the provided `projectschema.txt` to initialize the database.

> [!NOTE]
> **Part B (GUI)**: This plan focuses on Part A (SQL Implementation). Part B (Java GUI) will be addressed in a separate phase after Part A is complete and verified.

## Proposed Changes

### 1. Base Schema Setup
Initialize the database with the provided schema.

#### [NEW] [queries/projectschema.sql](file:///c:/Users/thodo/Documents/Project/DatabasesProjects/queries/projectschema.sql)
- Copy contents from `projectschema.txt` to a SQL file for execution.
- Ensure correct execution order (tables with no dependencies first).

### 2. Part A: Schema Extensions
Extend the database to support Vehicles, Accommodations, Trip History, and DBA Logs.

#### [NEW] [queries/schema_extensions.sql](file:///c:/Users/thodo/Documents/Project/DatabasesProjects/queries/schema_extensions.sql)
- **Vehicles** (Req 3.1.2.1):
    - `vehicle`: `veh_license_plate` (or internal ID), `veh_model`, `veh_brand`, `veh_capacity`, `veh_type` (Bus, Mini-Bus, Van, Car).
    - Link `trip` to `vehicle` (if not already handled by a separate assignment table, though the Stored Procedure suggests assignment logic). I will add `tr_veh_plate` to `trip` or distinct assignment table if M:N needed, but 1 vehicle per trip seems implied by "assignment of a vehicle to a specific trip".
- **Accommodations** (Req 3.1.2.2):
    - `accommodation`: `acc_id`, `acc_name`, `acc_type` (Hotel, Hostel, etc.), `acc_stars` (opt), `acc_rating`, `acc_active`, `acc_address`, `acc_phone`, `acc_email`, `acc_rooms`, `acc_price_per_night`.
    - `accommodation_amenities`: Links accommodation to amenities (WiFi, Pool, etc.).
- **Trip History** (Req 3.1.2.3):
    - `trip_history`: `h_tr_id`, `h_departure`, `h_return`, `h_maxseats`, `h_participants`, `h_revenue`.
- **Log Table** (Req 3.1.2.4):
    - `log`: `log_id`, `log_username`, `log_timestamp`, `log_action`, `log_table`.

### 3. Stored Procedures
Implement the required business logic.

#### [NEW] [queries/procedures_part_a.sql](file:///c:/Users/thodo/Documents/Project/DatabasesProjects/queries/procedures_part_a.sql)
- `sp_assign_vehicle_to_trip` (3.1.3.1): Assign vehicle check capacity, license type, availability.
- `sp_search_accommodation` (3.1.3.2): Search by destination, date, rooms needed.
- `sp_reservation_accommodation` (3.1.3.3): Make reservation + trigger update.
- `sp_trip_history` (3.1.3.4): Populate history table.

### 4. Triggers
Implement automated actions.

#### [NEW] [queries/triggers_part_a.sql](file:///c:/Users/thodo/Documents/Project/DatabasesProjects/queries/triggers_part_a.sql)
- `trg_log_dba_actions` (3.1.4.1): Log operations on specific tables.
- `trg_update_reservation_cost` (3.1.4.2): Auto-calc cost/nights when accommodation booked.
- `trg_update_vehicle_mileage` (3.1.4.3): Update mileage on trip completion.

## Verification Plan

### Automated Tests
I will create a SQL script `queries/verify_part_a.sql` to run scenarios:
1.  **Schema Check**: Query `information_schema.tables` to verify all new tables exist.
2.  **Procedure Tests**:
    -   Call `sp_assign_vehicle_to_trip` with valid/invalid data.
    -   Call `sp_search_accommodation` and verify output.
3.  **Trigger Tests**:
    -   Perform an INSERT on `trip` and check `log` table.
    -   Complete a trip (update status) and check vehicle mileage/status.
