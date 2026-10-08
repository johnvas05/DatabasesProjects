USE baseisproject;

-- 3.1.2.4 DBAs. end_date is NULL while the DBA is still in the role.
CREATE TABLE dba_users (
                           dba_username VARCHAR(50) PRIMARY KEY,
                           dba_start_date DATE NOT NULL,
                           dba_end_date DATE
);

-- Log of the DBA actions (filled by the triggers of 3.1.4.1)
CREATE TABLE log_actions (
                             log_id INT AUTO_INCREMENT PRIMARY KEY,
                             log_dba_username VARCHAR(50),
                             log_table_name VARCHAR(50),
                             log_action_type ENUM('INSERT', 'UPDATE', 'DELETE'),
                             log_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                             log_details TEXT,                   -- what changed
                             FOREIGN KEY (log_dba_username) REFERENCES dba_users(dba_username)
);
