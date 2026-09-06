#!/bin/bash
# =====================================================================
# Database tests for the travel agency project (spec sections 3.1.x).
#
# Loads the dump into a throw-away database (baseisproject_test) inside the
# MariaDB container, runs every check there and drops it at the end. The
# application database (baseisproject) is never touched.
#
# Usage:  tests/db_tests.sh [dump-file]        (default: baseisproject_dump.sql)
# Env:    CONTAINER (default baseis-mariadb), DB_PASSWORD (default john2005)
# =====================================================================
set -u
cd "$(dirname "$0")/.."

CONTAINER=${CONTAINER:-baseis-mariadb}
DB_PASSWORD=${DB_PASSWORD:-john2005}
DUMP=${1:-baseisproject_dump.sql}
TDB=baseisproject_test

PASS=0; FAIL=0; FAILED=()

# run SQL in the test database; tab-separated, no column headers; errors go to stdout
q()  { docker exec "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" -N -B "$TDB" -e "$1" 2>&1; }
# same but with headers (for result-set assertions)
qh() { docker exec "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" -B "$TDB" -e "$1" 2>&1; }

fresh() {
    docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" -e \
        "DROP DATABASE IF EXISTS $TDB; CREATE DATABASE $TDB CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;" \
        || { echo "cannot create $TDB"; exit 1; }
    sed -E 's#/\*!50017 DEFINER=`[^`]+`@`[^`]+`\*/##g; s#DEFINER=`[^`]+`@`[^`]+` ##g' "$DUMP" \
        | docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" "$TDB" \
        || { echo "cannot load $DUMP"; exit 1; }
}

# check "name" "actual" "expected substring"
check() {
    local name=$1 actual=$2 expected=$3
    if [[ "$actual" == *"$expected"* ]]; then
        PASS=$((PASS+1)); printf '  ok   %s\n' "$name"
    else
        FAIL=$((FAIL+1)); FAILED+=("$name")
        printf '  FAIL %s\n       expected to contain: %s\n       got: %s\n' "$name" "$expected" "${actual//$'\n'/ | }"
    fi
}
# check_ge "name" actual expected_min
check_ge() {
    local name=$1 actual=$2 min=$3
    if [[ "$actual" =~ ^[0-9]+$ ]] && (( actual >= min )); then
        PASS=$((PASS+1)); printf '  ok   %s (%s >= %s)\n' "$name" "$actual" "$min"
    else
        FAIL=$((FAIL+1)); FAILED+=("$name"); printf '  FAIL %s: got %s, need >= %s\n' "$name" "$actual" "$min"
    fi
}
section() { echo; echo "== $1"; }

[[ -f "$DUMP" ]] || { echo "dump file not found: $DUMP"; exit 1; }
docker exec "$CONTAINER" true 2>/dev/null || { echo "container $CONTAINER is not running (docker compose up -d)"; exit 1; }

echo "Loading $DUMP into $TDB ..."
fresh

# ---------------------------------------------------------------- 3.1.1 / 3.1.2
section "3.1.1 minimum rows (2-person team = 2 x per-person minimum)"
while read -r table min; do
    check_ge "$table" "$(q "SELECT COUNT(*) FROM $table")" "$min"
done <<'EOF'
worker 26
guide 8
driver 8
languages 8
language_ref 6
manages 6
branch 6
trip 14
admin 10
phones 10
destination 10
travel_to 14
event 20
reservation 24
customer 20
EOF

section "3.1.2 new tables and columns"
check_ge "vehicle rows"       "$(q "SELECT COUNT(*) FROM vehicle")" 10
check_ge "lodging rows"       "$(q "SELECT COUNT(*) FROM lodging")" 10
check_ge "trip_history rows"  "$(q "SELECT COUNT(*) FROM trip_history")" 90000
check_ge "dba_users rows"     "$(q "SELECT COUNT(*) FROM dba_users")" 1
check "travel_to.to_sequence exists" "$(q "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='$TDB' AND table_name='travel_to' AND column_name='to_sequence'")" "1"
check "room_usage.ru_nights exists"  "$(q "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='$TDB' AND table_name='room_usage' AND column_name='ru_nights'")" "1"
check "trip.tr_km exists"            "$(q "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='$TDB' AND table_name='trip' AND column_name='tr_km'")" "1"
check "no zero-night stays in travel_to" "$(q "SELECT COUNT(*) FROM travel_to WHERE DATEDIFF(to_departure, to_arrival) < 1")" "0"
check "stays lie inside the trip dates"  "$(q "SELECT COUNT(*) FROM travel_to tt JOIN trip t ON t.tr_id=tt.to_tr_id WHERE DATE(tt.to_arrival) < DATE(t.tr_departure) OR DATE(tt.to_departure) > DATE(t.tr_return)")" "0"
check "dba_users.dba_start_date NOT NULL" "$(q "SELECT is_nullable FROM information_schema.columns WHERE table_schema='$TDB' AND table_name='dba_users' AND column_name='dba_start_date'")" "NO"
check "log usernames all registered DBAs" "$(q "SELECT COUNT(*) FROM log_actions l LEFT JOIN dba_users d ON d.dba_username=l.log_dba_username WHERE d.dba_username IS NULL")" "0"
check "26 triggers" "$(q "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='$TDB'")" "26"
check "8 routines"  "$(q "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='$TDB'")" "8"
check "reservation prices set" "$(q "SELECT COUNT(*) FROM reservation WHERE res_total_cost IS NULL OR res_total_cost=0")" "0"

section "section 2 business rules hold in the data"
check "to_sequence is tinyint (relational model)" "$(q "SELECT DATA_TYPE FROM information_schema.columns WHERE table_schema='$TDB' AND table_name='travel_to' AND column_name='to_sequence'")" "tinyint"
check "every worker is in exactly one category" "$(q "SELECT COUNT(*) FROM worker w WHERE (SELECT COUNT(*) FROM driver WHERE drv_AT=w.wrk_AT)+(SELECT COUNT(*) FROM guide WHERE gui_AT=w.wrk_AT)+(SELECT COUNT(*) FROM admin WHERE adm_AT=w.wrk_AT) <> 1")" "0"
check "every branch has a phone and an admin manager" "$(q "SELECT COUNT(*) FROM branch b LEFT JOIN admin a ON a.adm_AT=b.br_manager_AT WHERE a.adm_AT IS NULL OR NOT EXISTS (SELECT 1 FROM phones p WHERE p.ph_br_code=b.br_code)")" "0"
check "every trip has at least one event"      "$(q "SELECT COUNT(*) FROM trip t WHERE NOT EXISTS (SELECT 1 FROM event e WHERE e.ev_tr_id=t.tr_id)")" "0"
check "every trip has a minimum participants"  "$(q "SELECT COUNT(*) FROM trip WHERE tr_min_participants IS NULL OR tr_min_participants < 1")" "0"
check "every guide speaks a language"          "$(q "SELECT COUNT(*) FROM guide g WHERE NOT EXISTS (SELECT 1 FROM languages l WHERE l.lng_gui_AT=g.gui_AT)")" "0"
check "drivers' route matches their trips"     "$(q "SELECT COUNT(*) FROM trip t JOIN driver d ON d.drv_AT=t.tr_drv_AT JOIN travel_to x ON x.to_tr_id=t.tr_id JOIN destination ds ON ds.dst_id=x.to_dst_id WHERE ds.dst_rtype <> d.drv_route")" "0"
check "drivers' licence matches their vehicle" "$(q "SELECT COUNT(*) FROM trip t JOIN vehicle v ON v.v_id=t.tr_vehicle_id JOIN driver d ON d.drv_AT=t.tr_drv_AT WHERE v.v_seats>9 AND d.drv_license NOT IN ('C','D')")" "0"
check "vehicle seats match the type"           "$(q "SELECT COUNT(*) FROM vehicle WHERE NOT ((v_type='Bus' AND v_seats>20) OR (v_type='Mini-Bus' AND v_seats BETWEEN 10 AND 20) OR (v_type='Van' AND v_seats BETWEEN 6 AND 9) OR (v_type='Car' AND v_seats<=5))")" "0"
check "type/seat rule is enforced (CHECK)"     "$(q "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats) VALUES (1,'BAD-0001','M','B','Car',30)")" "chk_vehicle_type_seats"
check "stars only for hotels and resorts"      "$(q "SELECT COUNT(*) FROM lodging WHERE (lg_type IN ('Hotel','Resort')) <> (lg_stars IS NOT NULL)")" "0"
check "stars rule is enforced (CHECK)"         "$(q "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_address, lg_city, lg_total_rooms, lg_cost_per_night) VALUES (2,'Bad Hostel','Hostel',3,'a','London',5,10)")" "chk_lodging_stars_type"
check "lodging has full address (postal code)" "$(q "SELECT COUNT(*) FROM lodging WHERE lg_postal_code IS NULL OR lg_address='' OR lg_city=''")" "0"
check "a city can belong to a country (Paris -> France)" "$(q "SELECT p.dst_name FROM destination c JOIN destination p ON p.dst_id=c.dst_location WHERE c.dst_name='Paris'")" "France"
check "lodging in a country destination is rejected" "$(q "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night) SELECT dst_id,'Bad','Hotel','a','b',5,10 FROM destination WHERE dst_name='France'")" "must belong to a city destination"

# ---------------------------------------------------------------- 3.1.3.1
section "3.1.3.1 sp_assign_vehicle_to_trip"
out=$(q "CALL sp_assign_vehicle_to_trip(1, 4, 200100)")
check "vehicle in Maintenance is rejected"        "$out" "vehicle is Maintenance"
check "  ...and every check is reported"          "$out" "Vehicle available	FAIL"
check "  ...including the passing ones"           "$out" "Mileage reading	PASS"
check "unknown trip is rejected"                  "$(q "CALL sp_assign_vehicle_to_trip(9999, 1, 1)")" "trip does not exist"
check "unknown vehicle is rejected"               "$(q "CALL sp_assign_vehicle_to_trip(1, 9999, 1)")" "vehicle does not exist"
# capacity: trip 3 has 3 confirmed/paid reservations
check "too few seats is rejected" \
    "$(q "UPDATE vehicle SET v_seats=2 WHERE v_id=10; CALL sp_assign_vehicle_to_trip(3, 10, 10100)")" "2 seats < 3 reservations"
# licence: trip 8's driver AT114 has licence B, vehicle 1 is a 50-seat bus (free in August)
check "licence B on a bus is rejected" \
    "$(q "CALL sp_assign_vehicle_to_trip(8, 1, 150100)")" "driver licence B (C/D needed)"
# overlap: trip 2 (06-05..06-12) vs trip 1 (06-01..06-10) which uses vehicle 1; trip 2's driver has licence C
check "date overlap is rejected" \
    "$(q "CALL sp_assign_vehicle_to_trip(2, 1, 150100)")" "overlaps 1 other trip"
# mileage: reading lower than the recorded odometer
check "lower mileage reading is rejected" \
    "$(q "CALL sp_assign_vehicle_to_trip(14, 9, 1000)")" "mileage 1000 < recorded 90000"
check "rejected assignment changes nothing" \
    "$(q "SELECT v_status, v_mileage FROM vehicle WHERE v_id=9")" "Available	90000"
# happy path: trip 14 (2027, driver AT113 licence D) with bus 9
out=$(q "CALL sp_assign_vehicle_to_trip(14, 9, 90500)")
check "valid assignment succeeds"                 "$out" "Success: vehicle 9 assigned to trip 14"
check "  ...all checks PASS"                      "$(echo "$out" | grep -c PASS)" "5"
check "  ...only a positive number of seats/reservations reported" "$out" "52 seats for 1 confirmed/paid"
check "  ...vehicle becomes InUse with mileage"   "$(q "SELECT v_status, v_mileage FROM vehicle WHERE v_id=9")" "InUse	90500"
check "  ...trip references the vehicle"          "$(q "SELECT tr_vehicle_id FROM trip WHERE tr_id=14")" "9"
check "  ...vehicle update is logged"             "$(q "SELECT log_details FROM log_actions WHERE log_table_name='vehicle' ORDER BY log_id DESC LIMIT 1")" "status Available -> InUse, mileage 90000 -> 90500"

# ---------------------------------------------------------------- 3.1.3.2
section "3.1.3.2 sp_search_accommodation"
fresh
out=$(qh "CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 2, @id); SELECT @id AS first_id")
check "finds the Paris hotel"                     "$out" "Le Grand Paris"
check "shows available rooms"                     "$out" "100"
check "OUT parameter = first lodging id"          "$(echo "$out" | tail -1)" "1"
check "amenities are listed"                      "$out" "WiFi, Rest/Bar, A/C, Access"
check "existing bookings reduce availability" \
    "$(q "INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count) VALUES (11, 1, '2026-06-03', '2026-06-07', 95); CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 2, @id); SELECT @id")" "5"$'\n'"1"
check "not enough free rooms -> no result, OUT is NULL" \
    "$(q "CALL sp_search_accommodation(1, '2026-06-01', '2026-06-05', 6, @id); SELECT IFNULL(@id, 'NULL')")" "NULL"
check "non-overlapping period is unaffected" \
    "$(q "CALL sp_search_accommodation(1, '2026-06-07', '2026-06-09', 6, @id); SELECT @id")" "1"
check "inactive lodging is excluded" \
    "$(q "UPDATE lodging SET lg_status='Inactive' WHERE lg_id=1; CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @id); SELECT IFNULL(@id,'NULL')")" "NULL"
# ordering: add a cheaper lodging in Paris and check it comes first
out=$(qh "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_stars, lg_rating, lg_address, lg_city, lg_total_rooms, lg_cost_per_night) VALUES (1,'Budget Inn','Hostel',NULL,3.0,'Rue X','Paris',20,30.00),(1,'Mid Hotel','Hotel',3,4.0,'Rue Y','Paris',20,30.00); UPDATE lodging SET lg_status='Active' WHERE lg_id=1; CALL sp_search_accommodation(1, '2026-09-01', '2026-09-03', 1, @id); SELECT @id")
check "ordered by price, then stars, then rating" "$(echo "$out" | grep -E 'Mid Hotel|Budget Inn|Le Grand' | awk -F'\t' '{print $2}' | paste -sd, -)" "Mid Hotel,Budget Inn,Le Grand Paris"

# ---------------------------------------------------------------- 3.1.4.2
section "3.1.4.2 trg_calculate_accommodation_cost"
fresh
out=$(q "INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count) VALUES (11, 3, '2026-10-01', '2026-10-04', 3); SELECT ru_nights, ru_total_cost FROM room_usage WHERE ru_trip_id=11")
check "nights = 3 and cost = 120 x 3 nights x 3 rooms" "$out" "3	1080.00"
check "zero-night booking is rejected" \
    "$(q "INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count) VALUES (11, 3, '2026-10-05', '2026-10-05', 1)")" "check-out must be at least one day after check-in"

# ---------------------------------------------------------------- 3.1.3.3
section "3.1.3.3 sp_book_trip_accommodation"
fresh
out=$(qh "CALL sp_book_trip_accommodation(1)")
check "books one lodging per destination (trip 1: Paris, London)" "$(q "SELECT COUNT(*) FROM room_usage WHERE ru_trip_id=1")" "2"
check "Paris leg: 4 nights, 1 room, 1000.00"      "$out" "Le Grand Paris	Paris	2026-06-01	2026-06-05	4	1	1000.00"
check "London leg: 5 nights, 1 room, 300.00"      "$out" "London Stay	London	2026-06-05	2026-06-10	5	1	300.00"
check "total accommodation cost of the trip"      "$out" "1300.00"
check "rooms = ceil(confirmed/2): trip 3 (3 paid) -> 2 rooms" "$(qh "CALL sp_book_trip_accommodation(3)" | grep -c $'\t2\t')" "2"
check "booking again replaces the previous bookings" "$(q "CALL sp_book_trip_accommodation(1); SELECT COUNT(*) FROM room_usage WHERE ru_trip_id=1")" "2"
check "bookings are logged (room_usage INSERT)"   "$(q "SELECT COUNT(*) FROM log_actions WHERE log_table_name='room_usage' AND log_action_type='INSERT'")" "6"
check "trip without confirmed reservations is rejected" \
    "$(q "UPDATE reservation SET res_status='PENDING' WHERE res_tr_id=12; CALL sp_book_trip_accommodation(12)")" "no confirmed or paid reservations"
check "unknown trip is rejected"                  "$(q "CALL sp_book_trip_accommodation(9999)")" "trip does not exist"
# failure on the second leg: London hostel has no rooms -> Paris booking must be removed too
out=$(q "UPDATE lodging SET lg_total_rooms=0 WHERE lg_id=2; CALL sp_book_trip_accommodation(1)")
check "unbookable destination -> clear error"     "$out" "no lodging in London with 1 free room(s) for 2026-06-05 to 2026-06-10"
check "  ...and all bookings of the trip are cancelled" "$(q "SELECT COUNT(*) FROM room_usage WHERE ru_trip_id=1")" "0"

# ---------------------------------------------------------------- 3.1.4.1
section "3.1.4.1 log triggers (insert/update/delete on 7 tables)"
fresh
before=$(q "SELECT COUNT(*) FROM log_actions")
q "INSERT INTO customer (cust_name, cust_lname, cust_birth_date) VALUES ('Log','Test','1990-01-01'); UPDATE customer SET cust_phone='123' WHERE cust_lname='Test'; DELETE FROM customer WHERE cust_lname='Test';" >/dev/null
q "INSERT INTO destination (dst_name, dst_rtype, dst_language_code) VALUES ('Logville','LOCAL','EN'); UPDATE destination SET dst_descr='x' WHERE dst_name='Logville'; DELETE FROM destination WHERE dst_name='Logville';" >/dev/null
q "INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats) VALUES (1,'LOG-0001','M','B','Car',4); UPDATE vehicle SET v_status='Maintenance' WHERE v_license_plate='LOG-0001'; DELETE FROM vehicle WHERE v_license_plate='LOG-0001';" >/dev/null
q "INSERT INTO lodging (lg_dst_id, lg_name, lg_type, lg_address, lg_city, lg_total_rooms, lg_cost_per_night) VALUES (1,'Log Lodge','Hotel','a','Paris',5,10); UPDATE lodging SET lg_cost_per_night=11 WHERE lg_name='Log Lodge'; DELETE FROM lodging WHERE lg_name='Log Lodge';" >/dev/null
q "INSERT INTO room_usage (ru_trip_id, ru_lodging_id, ru_checkin, ru_checkout, ru_rooms_count) VALUES (11,1,'2026-10-02','2026-10-04',1); UPDATE room_usage SET ru_rooms_count=2 WHERE ru_trip_id=11; DELETE FROM room_usage WHERE ru_trip_id=11;" >/dev/null
q "INSERT INTO reservation (res_tr_id, res_seatnum, res_cust_id, res_status) VALUES (5,9,1,'PENDING'); UPDATE reservation SET res_status='CONFIRMED' WHERE res_tr_id=5 AND res_seatnum=9; DELETE FROM reservation WHERE res_tr_id=5 AND res_seatnum=9;" >/dev/null
q "INSERT INTO trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_br_code) VALUES ('2027-03-01','2027-03-05',10,100,50,'PLANNED',1); UPDATE trip SET tr_status='CANCELLED' WHERE tr_departure='2027-03-01'; DELETE FROM trip WHERE tr_departure='2027-03-01';" >/dev/null
check "21 new log rows (7 tables x 3 actions)" "$(q "SELECT COUNT(*) - $before FROM log_actions")" "21"
for t in customer destination vehicle lodging room_usage reservation trip; do
    check "$t: INSERT, UPDATE and DELETE logged" \
        "$(q "SELECT GROUP_CONCAT(DISTINCT log_action_type ORDER BY log_action_type) FROM log_actions WHERE log_table_name='$t' AND log_id > (SELECT MAX(log_id) - 21 FROM log_actions)")" "INSERT,UPDATE,DELETE"
done
check "username stored without host" "$(q "SELECT DISTINCT log_dba_username FROM log_actions WHERE log_id > (SELECT MAX(log_id) - 21 FROM log_actions)")" "root"
check "timestamp is recorded"        "$(q "SELECT COUNT(*) FROM log_actions WHERE log_timestamp IS NULL")" "0"
check "unregistered DBA cannot change data (FK to dba_users)" \
    "$(q "DELETE FROM dba_users WHERE dba_username='root'; INSERT INTO customer (cust_name) VALUES ('x')")" "foreign key constraint fails"

# ---------------------------------------------------------------- 3.1.4.3
section "3.1.4.3 trg_complete_trip_vehicle_update"
fresh
out=$(q "UPDATE vehicle SET v_status='InUse' WHERE v_id=1; UPDATE trip SET tr_status='COMPLETED', tr_km=350 WHERE tr_id=1; SELECT v_status, v_mileage FROM vehicle WHERE v_id=1")
check "completed trip: vehicle Available and km added (150000 + 350)" "$out" "Available	150350"
check "trip update logged with km"   "$(q "SELECT log_details FROM log_actions WHERE log_table_name='trip' ORDER BY log_id DESC LIMIT 1")" "status PLANNED -> COMPLETED, vehicle 1 -> 1, km 0 -> 350"
check "other status changes leave the vehicle alone" \
    "$(q "UPDATE vehicle SET v_status='InUse' WHERE v_id=2; UPDATE trip SET tr_status='ACTIVE' WHERE tr_id=2; SELECT v_status, v_mileage FROM vehicle WHERE v_id=2")" "InUse	80000"

# ---------------------------------------------------------------- 3.1.3.4
section "3.1.3.4 history procedures and indexes"
fresh
check "revenue procedure returns a sum" "$(q "CALL sp_history_revenue('2021-01-01','2021-12-31')" | grep -cE '^[0-9]+(\.[0-9]+)?$')" "1"
check_ge "destinations procedure returns rows" "$(q "CALL sp_history_destinations(3)" | wc -l | tr -d ' ')" 1000
check "revenue query uses covering index"      "$(q "EXPLAIN SELECT SUM(th_revenue) FROM trip_history WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31'")" "idx_hist_dep_rev"
check "destinations query uses covering index" "$(q "EXPLAIN SELECT th_departure FROM trip_history WHERE th_dest_count = 3")" "idx_hist_dc_dep"
timing=$(qh "SET profiling=1;
SELECT SUM(th_revenue) FROM trip_history IGNORE INDEX (idx_hist_dep_rev) WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
SELECT SUM(th_revenue) FROM trip_history WHERE th_departure BETWEEN '2021-01-01' AND '2021-12-31';
SELECT COUNT(*) FROM (SELECT th_departure FROM trip_history IGNORE INDEX (idx_hist_dc_dep) WHERE th_dest_count = 3) x;
SELECT COUNT(*) FROM (SELECT th_departure FROM trip_history WHERE th_dest_count = 3) x;
SHOW PROFILES;" | grep -E '^[0-9]+\s' | awk -F'\t' '{printf "       query %s: %.4fs  %s\n", $1, $2, ($1%2==1?"(without index)":"(with index)")}')
echo "  timing (SHOW PROFILES):"; echo "$timing"

# ---------------------------------------------------------------- reservation price
section "sp_calculate_reservation_cost (adult/child price)"
fresh
check "adult pays the adult price (trip 1: 500)" \
    "$(q "INSERT INTO reservation (res_tr_id,res_seatnum,res_cust_id,res_status,res_total_cost) VALUES (1,9,1,'PENDING',0); CALL sp_calculate_reservation_cost(1,9,1); SELECT res_total_cost FROM reservation WHERE res_tr_id=1 AND res_seatnum=9")" "500.00"
check "child pays the child price (trip 1: 300)" \
    "$(q "INSERT INTO reservation (res_tr_id,res_seatnum,res_cust_id,res_status,res_total_cost) VALUES (1,10,20,'PENDING',0); CALL sp_calculate_reservation_cost(1,10,20); SELECT res_total_cost FROM reservation WHERE res_tr_id=1 AND res_seatnum=10")" "300.00"

# ---------------------------------------------------------------- salary trigger
section "trg_worker_salary_increase / sp_branch_financials"
fresh
# make branch 1 profitable: lowering salaries is always allowed (branch 1 revenue > 5 x 100)
q "UPDATE worker SET wrk_salary = 100 WHERE wrk_br_code = 1" >/dev/null
worker=$(q "SELECT wrk_AT FROM worker WHERE wrk_br_code = 1 LIMIT 1")
check "sp_branch_financials reports a positive profit ratio" "$(q "CALL sp_branch_financials(1, @r, @e, @p); SELECT @p > 0")" "1"
check "raise of 1% in a profitable branch is allowed" "$(q "UPDATE worker SET wrk_salary = wrk_salary * 1.01 WHERE wrk_AT='$worker'; SELECT 'updated'")" "updated"
check "raise above 2% is rejected"                    "$(q "UPDATE worker SET wrk_salary = wrk_salary * 1.05 WHERE wrk_AT='$worker'")" "exceeds 2% limit"
check "raise in a loss-making branch is rejected" \
    "$(q "UPDATE reservation SET res_total_cost=0; UPDATE worker SET wrk_salary = wrk_salary * 1.01 WHERE wrk_AT='$worker'")" "branch is not profitable"
check "unknown branch -> NULL financials" "$(q "CALL sp_branch_financials(999, @r, @e, @p); SELECT IFNULL(@r,'NULL'), IFNULL(@p,'NULL')")" "NULL	NULL"

# ---------------------------------------------------------------- seed script
section "queries/Insertions.sql loads on the schema (report seed data)"
fresh
# the seed script truncates and re-inserts; the 90 000-row generator is skipped here for speed
seed_out=$(sed -e "s/^USE baseisproject;/USE $TDB;/" -e "/^CALL sp_generate_dummy_history/d" queries/Insertions.sql \
    | docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" "$TDB" 2>&1)
check "seed script runs without errors" "$([[ "$seed_out" == *ERROR* ]] && echo "$seed_out" || echo clean)" "clean"
while read -r table min; do
    check_ge "seed: $table" "$(q "SELECT COUNT(*) FROM $table")" "$min"
done <<'EOS'
worker 26
guide 8
driver 8
languages 8
language_ref 6
manages 6
branch 6
trip 14
admin 10
phones 10
destination 10
travel_to 14
event 20
reservation 24
customer 20
vehicle 10
lodging 10
EOS
check "seed: drivers' route matches their trips" "$(q "SELECT COUNT(*) FROM trip t JOIN driver d ON d.drv_AT=t.tr_drv_AT JOIN travel_to x ON x.to_tr_id=t.tr_id JOIN destination ds ON ds.dst_id=x.to_dst_id WHERE ds.dst_rtype <> d.drv_route")" "0"
check "seed: every trip has an event"           "$(q "SELECT COUNT(*) FROM trip t WHERE NOT EXISTS (SELECT 1 FROM event e WHERE e.ev_tr_id=t.tr_id)")" "0"
check "seed: stays have nights"                 "$(q "SELECT COUNT(*) FROM travel_to WHERE DATEDIFF(to_departure, to_arrival) < 1")" "0"
check "seed: Paris belongs to France"           "$(q "SELECT p.dst_name FROM destination c JOIN destination p ON p.dst_id=c.dst_location WHERE c.dst_name='Paris'")" "France"
check "seed: auto-booking works on seed data"   "$(qh "CALL sp_book_trip_accommodation(1)")" "1300.00"

# ---------------------------------------------------------------- reset script
section "queries/Reset.sql restores the demo state"
fresh
# make a mess first: book hotels, take a vehicle, add rows, change salaries
q "CALL sp_assign_vehicle_to_trip(14, 9, 90500);
   CALL sp_book_trip_accommodation(1);
   INSERT INTO customer (cust_name, cust_lname, cust_birth_date) VALUES ('Demo','Row','1990-01-01');
   INSERT INTO vehicle (v_br_code, v_license_plate, v_model, v_brand, v_type, v_seats) VALUES (1,'DEMO-001','M','B','Car',4);
   UPDATE worker SET wrk_salary = 1 WHERE wrk_br_code = 1;
   UPDATE trip SET tr_status = 'CANCELLED' WHERE tr_id = 5;
   DELETE FROM reservation WHERE res_tr_id = 1;" >/dev/null
reset_out=$(sed "s/^USE baseisproject;/USE $TDB;/" queries/Reset.sql \
    | docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" "$TDB" 2>&1)
check "the reset runs without errors" "$([[ "$reset_out" == *ERROR* ]] && echo "$reset_out" || echo clean)" "clean"
check "rows added during the demo are gone"      "$(q "SELECT COUNT(*) FROM customer")" "20"
check "  ...vehicles too"                        "$(q "SELECT COUNT(*) FROM vehicle")" "10"
check "deleted rows are back"                    "$(q "SELECT COUNT(*) FROM reservation")" "24"
check "the vehicle taken by a trip is free again" "$(q "SELECT CONCAT(v_status,'/',v_mileage) FROM vehicle WHERE v_id=9")" "Available/90000"
check "a changed trip status is restored"        "$(q "SELECT tr_status FROM trip WHERE tr_id=5")" "PLANNED"
check "changed salaries are restored"            "$(q "SELECT wrk_salary FROM worker WHERE wrk_AT='AT101'")" "1500.00"
check "hotel bookings are cleared"               "$(q "SELECT COUNT(*) FROM room_usage")" "0"
check "the audit log starts empty for the demo"  "$(q "SELECT COUNT(*) FROM log_actions")" "0"
check "every reservation has a price again"      "$(q "SELECT COUNT(*) FROM reservation WHERE res_total_cost IS NULL OR res_total_cost = 0")" "0"
check "  ...adults pay the adult price"          "$(q "SELECT res_total_cost FROM reservation WHERE res_tr_id=1 AND res_seatnum=1")" "500.00"
check "  ...children pay the child price"        "$(q "SELECT res_total_cost FROM reservation WHERE res_tr_id=12 AND res_seatnum=1")" "150.00"
check "ids start from 1 again (trip 1..14)"      "$(q "SELECT CONCAT(MIN(tr_id),'..',MAX(tr_id)) FROM trip")" "1..14"
check_ge "the 90 000 history rows are kept"      "$(q "SELECT COUNT(*) FROM trip_history")" 90000
check "the reset can be run twice in a row" \
    "$(sed "s/^USE baseisproject;/USE $TDB;/" queries/Reset.sql \
        | docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" "$TDB" 2>&1 \
        | grep -c ERROR)" "0"
check "  ...and still holds the seed data"       "$(q "SELECT COUNT(*) FROM customer")" "20"

# ---------------------------------------------------------------- done
docker exec -i "$CONTAINER" mariadb -uroot -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS $TDB;"
echo
echo "Passed: $PASS   Failed: $FAIL"
if (( FAIL > 0 )); then printf '  - %s\n' "${FAILED[@]}"; exit 1; fi
