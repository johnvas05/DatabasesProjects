USE baseisproject;

-- 4a. Create the DBA table (Admins who manage the DB)
CREATE TABLE dba_users (
                           dba_username VARCHAR(50) PRIMARY KEY,
                           dba_start_date DATE NOT NULL,       -- Start date (Required) [cite: 173]
                           dba_end_date DATE                   -- End date (Optional) [cite: 174]
);

-- 4b. Create the Log table
-- Tracks INSERT, UPDATE, DELETE on key tables [cite: 216]
CREATE TABLE log_actions (
                             log_id INT AUTO_INCREMENT PRIMARY KEY,
                             log_dba_username VARCHAR(50),       -- Who did it [cite: 216]
                             log_table_name VARCHAR(50),         -- Which table [cite: 216]
                             log_action_type ENUM('INSERT', 'UPDATE', 'DELETE'), -- What action [cite: 216]
                             log_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,   -- When [cite: 216]
                             log_details TEXT,                   -- Optional: store what changed
                             FOREIGN KEY (log_dba_username) REFERENCES dba_users(dba_username)
);