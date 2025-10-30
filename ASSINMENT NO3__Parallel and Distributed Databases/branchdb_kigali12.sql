CREATE DATABASE LINK musanze_linknew1
CONNECT TO branchdb_kigali IDENTIFIED BY "12345"
USING 'XEPDB1';

GRANT SELECT ON organizers TO branchdb_musanze;

GRANT SELECT ON events TO branchdb_musanze;
GRANT SELECT ON venues TO branchdb_musanze;
GRANT SELECT ON staffs TO branchdb_musanze;


GRANT INSERT ON events TO branchdb_musanze;
GRANT INSERT ON venues TO branchdb_musanze;
GRANT INSERT ON staffs TO branchdb_musanze;
GRANT INSERT ON organizers TO branchdb_musanze;

GRANT UPDATE ON events TO branchdb_musanze;
GRANT UPDATE ON venues TO branchdb_musanze;
GRANT UPDATE ON staffs TO branchdb_musanze;
GRANT UPDATE ON organizers TO branchdb_musanze;




UPDATE Event SET status = 'Confirmed' WHERE event_id = '001';

ALTER TABLE events
ADD organizerid VARCHAR2(10);
-- Add registration date to Organizers
ALTER TABLE organizers
ADD registration_date DATE;

-- Add opening date to Venues
ALTER TABLE venues
ADD opening_date DATE;

-- Add assignment date to Staff
ALTER TABLE staffs
ADD assignment_date DATE;

-- Add scheduled date to Events
ALTER TABLE events
ADD event_date DATE;

INSERT INTO events VALUES (301, 'Tech Summit 2025', 'Conference', TO_DATE('2025-11-10', 'YYYY-MM-DD'), 101, 201, TO_DATE('2025-11-10', 'YYYY-MM-DD'));
INSERT INTO events VALUES (302, 'Green Innovation Fair', 'Expo', TO_DATE('2025-12-05', 'YYYY-MM-DD'), 102, 202, TO_DATE('2025-12-05', 'YYYY-MM-DD'));
INSERT INTO events VALUES (303, 'Youth Connect Forum', 'Forum', TO_DATE('2025-10-20', 'YYYY-MM-DD'), 103, 203, TO_DATE('2025-10-20', 'YYYY-MM-DD'));
INSERT INTO events VALUES (304, 'Smart Business Meetup', 'Networking', TO_DATE('2025-09-15', 'YYYY-MM-DD'), 104, 204, TO_DATE('2025-09-15', 'YYYY-MM-DD'));
INSERT INTO events VALUES (305, 'Creative Arts Festival', 'Festival', TO_DATE('2025-08-30', 'YYYY-MM-DD'), 105, 205, TO_DATE('2025-08-30', 'YYYY-MM-DD'));


INSERT INTO staffs VALUES (401, 'Jean Mugisha', 'Security', 301, TO_DATE('2025-11-09', 'YYYY-MM-DD'));
INSERT INTO staffs VALUES (402, 'Alice Uwase', 'Usher', 302, TO_DATE('2025-12-04', 'YYYY-MM-DD'));
INSERT INTO staffs VALUES (403, 'Eric Nshimiyimana', 'Coordinator', 303, TO_DATE('2025-10-19', 'YYYY-MM-DD'));
INSERT INTO staffs VALUES (404, 'Diane Ingabire', 'Reception', 304, TO_DATE('2025-09-14', 'YYYY-MM-DD'));
INSERT INTO staffs VALUES (405, 'Patrick Habimana', 'Logistics', 305, TO_DATE('2025-08-29', 'YYYY-MM-DD'));


INSERT INTO organizers VALUES (201, 'Tech Rwanda Ltd', '0788001122', TO_DATE('2024-01-15', 'YYYY-MM-DD'));
INSERT INTO organizers VALUES (202, 'Green Events Co.', '0788112233', TO_DATE('2023-11-10', 'YYYY-MM-DD'));
INSERT INTO organizers VALUES (203, 'Youth Connect Africa', '0788223344', TO_DATE('2022-06-25', 'YYYY-MM-DD'));
INSERT INTO organizers VALUES (204, 'Smart Biz Group', '0788334455', TO_DATE('2021-09-30', 'YYYY-MM-DD'));
INSERT INTO organizers VALUES (205, 'Creative Minds Ltd', '0788445566', TO_DATE('2020-12-05', 'YYYY-MM-DD'));

INSERT INTO venues VALUES (101, 'Kigali Arena', 'Kigali', 5000, TO_DATE('2020-06-01', 'YYYY-MM-DD'));
INSERT INTO venues VALUES (102, 'Musanze Stadium', 'Musanze', 3000, TO_DATE('2019-04-15', 'YYYY-MM-DD'));
INSERT INTO venues VALUES (103, 'Rubavu Expo Grounds', 'Rubavu', 4000, TO_DATE('2021-08-20', 'YYYY-MM-DD'));
INSERT INTO venues VALUES (104, 'Huye Convention Center', 'Huye', 3500, TO_DATE('2022-01-10', 'YYYY-MM-DD'));
INSERT INTO venues VALUES (105, 'Nyamata Hall', 'Bugesera', 2500, TO_DATE('2023-03-05', 'YYYY-MM-DD'));

SELECT * FROM events;
SELECT * FROM customers;

--Distributed Join Script(events and customers fro custmerid)
ALTER TABLE events ADD customerid NUMBER;
-- insert sample customer IDs to match your remote data:

UPDATE events SET customerid = 501 WHERE eventid = 301;
UPDATE events SET customerid = 502 WHERE eventid = 302;
UPDATE events SET customerid = 503 WHERE eventid = 303;
UPDATE events SET customerid = 504 WHERE eventid = 304;
UPDATE events SET customerid = 505 WHERE eventid = 305;

--Distributed Join Query

SELECT 
    e.eventid,
    e.name AS event_name,
    e.type AS event_type,
    e.event_date,
    c.name AS customer_name,
    c.email
FROM 
    events e
JOIN 
    customers@XEPDB1 c ON e.customerid = c.customerid;
    
    
--distributed transaction with atomic commit using PL/SQL and verify it via DBA_2PC_PENDING.
--Step 1: PL/SQL Block for Distributed Insert

BEGIN
  -- Insert into local table
  INSERT INTO events (eventid, name, type, event_date, venueid, organizerid, customerid)
  VALUES (306, 'Digital Health Forum', 'Forum', TO_DATE('01-NOV-25','DD-MON-YY'), 106, 206, 501);

  -- Insert into remote table via DB link
  INSERT INTO customers@XEPDB1(customerid, name, email, registration_date)
  VALUES (506, 'Jean Bosco', 'jean@example.com', TO_DATE('06-OCT-25','DD-MON-YY'));

  -- Single commit
  COMMIT;
END;
SELECT * FROM customers;

--Step 2: Verify Atomicity Using DBA_2PC_PENDING
SELECT LOCAL_TRAN_ID, GLOBAL_TRAN_ID, STATE, MIXED, HOST, COMMIT# 
FROM DBA_2PC_PENDING;


--Distributed Rollback and Recovery
--step1. Prepare the PL/SQL Block
--inserts into both local and remote tables:

BEGIN
  INSERT INTO events (eventid, name, type, event_date, venueid, organizerid, customerid)
  VALUES (307, 'AI Ethics Forum', 'Forum', TO_DATE('02-NOV-25','DD-MON-YY'), 107, 207, 502);

  INSERT INTO customers@XEPDB1 (customerid, name, email, registration_date)
  VALUES (507, 'Claudine Uwase', 'claudine@example.com', TO_DATE('07-OCT-25','DD-MON-YY'));

  COMMIT;
END;
SELECT * FROM events;
BEGIN
  -- Insert into local Events table
  INSERT INTO events (eventid, name, type, event_date, venueid, organizerid, customerid)
  VALUES (308, 'Smart Cities Expo', 'Expo', TO_DATE('12-NOV-25','DD-MON-YY'), 108, 208, 503);

  -- Insert into remote Customers table via DB link
  INSERT INTO customers@XEPDB1 (customerid, name, email, registration_date)
  VALUES (508, 'Kevin Habimana', 'kevin@example.com', TO_DATE('08-OCT-25','DD-MON-YY'));

  -- Commit once
  COMMIT;
END;
SELECT * FROM customers;

BEGIN
  -- Insert into local Events table
  INSERT INTO events (eventid, name, type, event_date, venueid, organizerid, customerid)
  VALUES (309, 'Women in Tech Summit', 'Conference', TO_DATE('18-NOV-25','DD-MON-YY'), 109, 209, 504);

  -- Insert into remote Customers table via DB link
  INSERT INTO customers@XEPDB1 (customerid, name, email, registration_date)
  VALUES (509, 'Aline Ingabire', 'aline@example.com', TO_DATE('09-OCT-25','DD-MON-YY'));

  -- Commit once
  COMMIT;
END;
SELECT LOCAL_TRAN_ID, GLOBAL_TRAN_ID, STATE, MIXED, HOST, COMMIT#
FROM DBA_2PC_PENDING;
  -- Replace with actual LOCAL_TRAN_ID
SELECT LOCAL_TRAN_ID, GLOBAL_TRAN_ID, STATE, MIXED, HOST, COMMIT#
FROM DBA_2PC_PENDING;




SELECT s.sid,
       s.serial#,
       s.username,
       s.machine,
       s.program
FROM v$session s
WHERE s.username IS NOT NULL;

BEGIN
  -- Insert into local Events table
  INSERT INTO events (eventid, name, type, event_date, venueid, organizerid, customerid)
  VALUES (310, 'Green Energy Summit', 'Summit', TO_DATE('20-NOV-25','DD-MON-YY'), 110, 210, 505);

  -- Insert into remote Customers table via DB link
  INSERT INTO customers@XEPDB1 (customerid, name, email, registration_date)
  VALUES (510, 'Eric Nshimiyimana', 'eric@example.com', TO_DATE('10-OCT-25','DD-MON-YY'));

  -- Commit once
  COMMIT;
END;
SELECT '22.45.1234' FROM DBA_2PC_PENDING;

--Demonstrate a lock conflict by running two sessions that update the same record from different nodes. Query DBA_LOCKS and interpret results.
--Step 1: Setup — Choose a Target Record
-- Sample row to target
SELECT * FROM events WHERE eventid = 310;

--Step 2: Session A — Start Transaction and Lock the Row
-- Session A
BEGIN
  UPDATE events SET name = 'Green Energy Summit - Updated' WHERE eventid = 310;
  -- Do NOT commit yet
END;
--Step 3: Session B — Try to Update the Same Row
-- Session B
BEGIN
  UPDATE events SET name = 'Green Energy Summit - Conflict' WHERE eventid = 310;
  -- This will hang or wait due to lock conflict
END;
--Step 4: Query DBA_LOCKS to Observe the Conflict
SELECT
  l.session_id,
  s.username,
  l.lock_type,
  l.mode_held,
  l.mode_requested,
  l.blocking_others
FROM
  dba_locks l
JOIN
  v$session s ON l.session_id = s.sid
WHERE
  l.lock_type = 'TX';  -- Transaction locks

--Resolve the Conflict

ROLLBACK;


SELECT
  s.sid,
  s.serial#,
  s.username,
  l.lock_type,
  l.mode_held,
  l.mode_requested,
  l.blocking_others
FROM
  dba_locks l
JOIN
  v$session s ON l.session_id = s.sid
WHERE
  l.lock_type IN ('TX', 'TM');

WHERE l.lock_type IS NOT NULL

BEGIN
  UPDATE events SET name = 'Locked by Session A' WHERE eventid = 310;
  DBMS_LOCK.SLEEP(60);  -- Hold lock for 60 seconds
END;
ROLLBACK;
INSERT INTO customers VALUES (5001, 'Jane Doe', 'jane@example.com', SYSDATE);

INSERT INTO tickets VALUES (1001, 310, 5001, 250, SYSDATE);
ALTER TABLE tickets DISABLE CONSTRAINT fk_ticket_customer;
-- Insert test data
ALTER TABLE tickets ENABLE CONSTRAINT fk_ticket_customer;
SELECT COUNT(*) FROM customers WHERE customerid = 5001;


--Parallel Data Aggregation Using PARALLEL DML

BEGIN
  FOR i IN 1..100000 LOOP
    INSERT INTO tickets VALUES (
      i,
      MOD(i, 1000),  -- eventid
      MOD(i, 5000),  -- customerid
      TRUNC(DBMS_RANDOM.VALUE(50, 500)),  -- price
      SYSDATE - DBMS_RANDOM.VALUE(0, 365)
    );
  END LOOP;
  COMMIT;
END;

--Enable Parallel DML
ALTER SESSION ENABLE PARALLEL DML;
ALTER TABLE tickets PARALLEL 4;
--Serial Aggregation Test
SET TIMING ON
CREATE TABLE event_revenue_serial AS
SELECT eventid, SUM(price) AS total_revenue
FROM tickets
GROUP BY eventid;

--Parallel Aggregation Test
SET TIMING ON
CREATE TABLE event_revenue_parallel AS
SELECT /*+ PARALLEL(tickets, 4) */ eventid, SUM(price) AS total_revenue
FROM tickets
GROUP BY eventid;


--Distributed Join Query

SELECT 
    e.eventid,
    e.name AS event_name,
    e.type AS event_type,
    e.event_date,
    c.name AS customer_name,
    c.email
FROM 
    events e
JOIN 
    customers@XEPDB1 c ON e.customerid = c.customerid;


SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'dist_join_plan', 'TYPICAL'));

EXPLAIN PLAN FOR
SELECT 
    e.eventid,
    e.name AS event_name,
    e.type AS event_type,
    e.event_date,
    c.name AS customer_name,
    c.email
FROM 
    events e
JOIN 
    customers@XEPDB1 c ON e.customerid = c.customerid;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());


CREATE INDEX idx_customers_customerid ON customers(customerid);

SELECT * FROM customers;  -- Is it spelled correctly?
SELECT customerid, name FROM customers@XEPDB1 WHERE ROWNUM <= 5;


SELECT 
    e.eventid,
    e.name AS event_name,
    e.event_date,
    c.name AS customer_name,
    p.amount AS payment_amount
FROM 
    events e
JOIN 
    tickets t ON e.eventid = t.eventid
JOIN 
    customers c ON t.customerid = c.customerid
JOIN 
    payments p ON t.ticketid = p.ticketid
WHERE 
    e.event_date BETWEEN SYSDATE AND SYSDATE + 30;
SET AUTOTRACE ON
-- Run query
ALTER TABLE events PARALLEL 4;
ALTER TABLE tickets PARALLEL 4;
-- Run query
-- Use DB links for remote access
SET AUTOTRACE ON
-- Run distributed query

