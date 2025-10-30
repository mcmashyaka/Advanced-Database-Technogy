SELECT table_name FROM all_tables WHERE table_name LIKE '%EVENT%';
-- Ticket table
CREATE TABLE tickets (
    ticketid NUMBER PRIMARY KEY,
    eventid NUMBER,
    customerid NUMBER,
    price NUMBER,
    purchase_date DATE,

    -- Foreign key constraints (optional but recommended)
    CONSTRAINT fk_ticket_event FOREIGN KEY (eventid) REFERENCES events(eventid),
    CONSTRAINT fk_ticket_customer FOREIGN KEY (customerid) REFERENCES customers(customerid)
);

-- Payment table
CREATE TABLE payment (
    PaymentID NUMBER PRIMARY KEY,
    TicketID NUMBER,
    Amount NUMBER,
    Method VARCHAR2(50)
);
-- Add registration date to Customer table
ALTER TABLE customers
ADD registration_date DATE;

-- Add purchase date to Ticket table
ALTER TABLE tickets
ADD purchase_date DATE;

-- Add payment date to Payment table
ALTER TABLE payment
ADD payment_date DATE;

-- Add scheduled date to Activity table
ALTER TABLE activities
ADD activity_date DATE;



GRANT SELECT ON tickets TO branchdb_kigali;
GRANT SELECT ON payment TO branchdb_kigali;
GRANT SELECT ON customers TO branchdb_kigali;
GRANT SELECT ON activities TO branchdb_kigali;

GRANT INSERT ON tickets TO branchdb_kigali;
GRANT INSERT ON tickets TO branchdb_kigali;
GRANT INSERT ON customers TO branchdb_kigali;
GRANT INSERT ON payment TO branchdb_kigali;
GRANT INSERT ON activities TO branchdb_kigali;


GRANT UPDATE ON tickets TO branchdb_kigali;
GRANT UPDATE ON customers TO branchdb_kigali;
GRANT UPDATE ON payment TO branchdb_kigali;
GRANT UPDATE ON activities TO branchdb_kigali;






INSERT INTO customers VALUES (501, 'Alice Niyonsaba', 'alice@example.com', TO_DATE('2025-10-01', 'YYYY-MM-DD'));
INSERT INTO customers VALUES (502, 'Eric Nkurunziza', 'eric@example.com', TO_DATE('2025-10-02', 'YYYY-MM-DD'));
INSERT INTO customers VALUES (503, 'Diane Uwimana', 'diane@example.com', TO_DATE('2025-10-03', 'YYYY-MM-DD'));
INSERT INTO customers VALUES (504, 'Patrick Mugisha', 'patrick@example.com', TO_DATE('2025-10-04', 'YYYY-MM-DD'));
INSERT INTO customers VALUES (505, 'Sandrine Ishimwe', 'sandrine@example.com', TO_DATE('2025-10-05', 'YYYY-MM-DD'));

INSERT INTO tickets VALUES (601, 301, 501, 15000, TO_DATE('2025-10-25', 'YYYY-MM-DD'));
INSERT INTO tickets VALUES (602, 302, 502, 12000, TO_DATE('2025-10-26', 'YYYY-MM-DD'));
INSERT INTO tickets VALUES (603, 303, 503, 10000, TO_DATE('2025-10-27', 'YYYY-MM-DD'));
INSERT INTO tickets VALUES (604, 304, 504, 13000, TO_DATE('2025-10-28', 'YYYY-MM-DD'));
INSERT INTO tickets VALUES (605, 305, 505, 11000, TO_DATE('2025-10-29', 'YYYY-MM-DD'));


INSERT INTO payment VALUES (701, 601, 15000, 'Mobile Money', TO_DATE('2025-10-26', 'YYYY-MM-DD'));
INSERT INTO payment VALUES (702, 602, 12000, 'Credit Card', TO_DATE('2025-10-27', 'YYYY-MM-DD'));
INSERT INTO payment VALUES (703, 603, 10000, 'Cash', TO_DATE('2025-10-28', 'YYYY-MM-DD'));
INSERT INTO payment VALUES (704, 604, 13000, 'Mobile Money', TO_DATE('2025-10-29', 'YYYY-MM-DD'));
INSERT INTO payment VALUES (705, 605, 11000, 'Bank Transfer', TO_DATE('2025-10-30', 'YYYY-MM-DD'));

INSERT INTO activities VALUES (801, 301, 'Opening Ceremony', '09:00–10:00', TO_DATE('2025-11-10', 'YYYY-MM-DD'));
INSERT INTO activities VALUES (802, 302, 'Green Tech Showcase', '10:30–12:00', TO_DATE('2025-12-05', 'YYYY-MM-DD'));
INSERT INTO activities VALUES (803, 303, 'Youth Panel Discussion', '13:00–14:30', TO_DATE('2025-10-20', 'YYYY-MM-DD'));
INSERT INTO activities VALUES (804, 304, 'Startup Pitching', '15:00–16:30', TO_DATE('2025-09-15', 'YYYY-MM-DD'));
INSERT INTO activities VALUES (805, 305, 'Art Exhibition', '17:00–18:30', TO_DATE('2025-08-30', 'YYYY-MM-DD'));

SELECT * FROM customers;


--Parallel vs Serial Query Execution
-- Create and populate a large Orders table
CREATE TABLE orders (
    orderid NUMBER,
    customerid NUMBER,
    order_date DATE,
    amount NUMBER
);

-- Insert sample data (e.g., 100,000 rows)
BEGIN
  FOR i IN 1..100000 LOOP
    INSERT INTO Orders VALUES (
      i,
      MOD(i, 500) + 501, -- match customer IDs
      SYSDATE - MOD(i, 365),
      ROUND(DBMS_RANDOM.VALUE(100, 1000), 2)
    );
  END LOOP;
  COMMIT;
END;

--Enable Parallelism on the Table
-- Enable parallelism at the table level
ALTER TABLE Orders PARALLEL 8;

-- Serial execution (no hint)
SET TIMING ON;
EXPLAIN PLAN FOR
SELECT customerid, SUM(amount)
FROM orders
GROUP BY customerid;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

--Run Parallel Query
-- Parallel execution using hint
SET TIMING ON;
EXPLAIN PLAN FOR
SELECT /*+ PARALLEL(orders, 8) */ customerid, SUM(amount)
FROM orders
GROUP BY customerid;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT * FROM USER_ROLE_PRIVS;

ROLLBACK FORCE 'your_local_transaction_id';

BEGIN
  UPDATE events SET name = 'Locked by Session B' WHERE eventid = 310;
END;

ROLLBACK;

CREATE INDEX idx_events_customerid ON events(customerid);
-- On remote DB:
EXPLAIN PLAN FOR
SELECT ...
FROM events e
JOIN customers@XEPDB1 c ON e.customerid = c.customerid
WHERE c.city = 'Kigali';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());




