-- Inside event_node_a database

DROP TABLE IF EXISTS ticket_a CASCADE; -- For re-running if needed

CREATE TABLE ticket_a (
    ticket_id       INTEGER PRIMARY KEY,
    event_id        INTEGER NOT NULL,
    customer_id     INTEGER NOT NULL,
    ticket_type     VARCHAR(50),
    price           NUMERIC(10, 2),
    status          VARCHAR(20),
    purchase_date   TIMESTAMP
);
--TASK 1 Distributed Schema Design and Fragmentation
CREATE TABLE IF NOT EXISTS organizers (
    organizer_id SERIAL PRIMARY KEY,    -- Unique identifier for each organizer
    organizer_name VARCHAR(255) NOT NULL, -- Name of the organization or individual
    contact_person VARCHAR(100),        -- Main contact person
    contact_email VARCHAR(255) UNIQUE NOT NULL, -- Email for communications
    contact_phone VARCHAR(50)           -- Phone number
);

CREATE TABLE payment (
  payment_id INT PRIMARY KEY,
  ticket_id INT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  payment_date TIMESTAMP NOT NULL,
  method VARCHAR(30) CHECK (method IN ('CASH', 'CARD', 'MOBILE'))
);


--TASK 1 Distributed Schema Design and Fragmentation
CREATE TABLE IF NOT EXISTS organizers (
    organizer_id SERIAL PRIMARY KEY,    -- Unique identifier for each organizer
    organizer_name VARCHAR(255) NOT NULL, -- Name of the organization or individual
    contact_person VARCHAR(100),        -- Main contact person
    contact_email VARCHAR(255) UNIQUE NOT NULL, -- Email for communications
    contact_phone VARCHAR(50)           -- Phone number
);
CREATE TABLE IF NOT EXISTS venues (
    venue_id SERIAL PRIMARY KEY,        -- Unique identifier for each venue
    venue_name VARCHAR(255) NOT NULL,   -- Name of the venue
    location VARCHAR(255) NOT NULL,     -- Physical address or general location
    capacity INT NOT NULL CHECK (capacity > 0), -- Maximum capacity of the venue
    contact_email VARCHAR(255),         -- Venue contact email
    contact_phone VARCHAR(50)           -- Venue contact phone
);

-- Events Table: Core table storing event details.

CREATE TABLE IF NOT EXISTS events (
    event_id SERIAL PRIMARY KEY,        -- Unique identifier for each event
    organizer_id INT NOT NULL,          -- Organizer of the event
    venue_id INT NOT NULL,              -- Venue where the event will be held
    event_name VARCHAR(255) NOT NULL,   -- Name of the event
    event_date TIMESTAMP NOT NULL,      -- Date and time of the event
    duration_hours DECIMAL(5,2) NOT NULL CHECK (duration_hours > 0), -- Duration in hours
    description TEXT,                   -- Detailed description of the event
    status VARCHAR(50) NOT NULL CHECK (status IN ('Scheduled', 'Active', 'Completed', 'Cancelled')), -- Current status
    
    CONSTRAINT fk_event_organizer FOREIGN KEY (organizer_id) REFERENCES organizers(organizer_id),
    CONSTRAINT fk_event_venue FOREIGN KEY (venue_id) REFERENCES venues(venue_id)
);



--Insert data
-- In EventOperations database
INSERT INTO organizers (organizer_name, contact_person, contact_email, contact_phone) VALUES
('Tech Events Inc.', 'Alice Wonderland', 'alice@techevents.com', '+11234567890'),
('Music Festival Co.', 'Bob Thebuilder', 'bob@musicfest.com', '+10987654321'),
('Art & Culture Hub', 'Carla Diaz', 'carla@arthub.com', '+16543210987');


-- In EventOperations database
INSERT INTO venues (venue_name, location, capacity, contact_email, contact_phone) VALUES
('Convention Center', '123 Main St, Cityville', 5000, 'info@convention.com', '+15551234567'),
('Grand Arena', '456 Stadium Rd, Townsville', 15000, 'events@grandarena.com', '+15559876543'),
('City Hall Auditorium', '789 Civic Ave, Metropolis', 800, 'hall@city.com', '+19876543210');

-- Example (adjust event_id and customer_id if needed, and ensure they exist)
INSERT INTO tickets (event_id, customer_id, ticket_type, price, status)
VALUES (1, 1, 'Standard', 150.00, 'Valid'); -- This would create ticket_id = 1 if it's the next SERIAL value
-- In EventOperations database
INSERT INTO events (organizer_id, venue_id, event_name, event_date, duration_hours, description, status) VALUES
(1, 1, 'Annual Tech Conference', '2024-11-15 09:00:00', 8.00, 'A gathering of tech enthusiasts and professionals.', 'Scheduled'),
(2, 2, 'Summer Music Fest', '2025-07-20 14:00:00', 10.00, 'Live music from various artists.', 'Scheduled'),
(1, 1, 'AI & Robotics Summit', '2024-12-01 10:00:00', 6.50, 'Exploring the future of AI and robotics.', 'Scheduled'),
(3, 3, 'Local Art Exhibition', '2024-10-25 18:00:00', 4.00, 'Showcasing local artists and their work.', 'Scheduled');

-- In EventOperations database
INSERT INTO customers (full_name, email, phone_number) VALUES
('Emma Stone', 'emma.s@example.com', '+12223334444'),
('Liam Hemsworth', 'liam.h@example.com', '+13334445555'),
('Olivia Rodrigo', 'olivia.r@example.com', '+14445556666'),
('Noah Centineo', 'noah.c@example.com', '+15556667777');
INSERT INTO customers (customer_id, full_name, email, phone_number)
VALUES (5, 'New Purchase Customer', 'purchase.customer@example.com', '+19998881111');


-- In EventOperations database
INSERT INTO tickets (ticket_id, event_id, customer_id, ticket_type, price, status) VALUES
(1, 1, 1, 'Standard', 150.00, 'Valid'),         -- For Annual Tech Conference
(2, 1, 2, 'VIP', 300.00, 'Valid'),              -- For Annual Tech Conference
(3, 2, 1, 'Early Bird', 75.00, 'Valid'),        -- For Summer Music Fest
(4, 2, 3, 'Standard', 100.00, 'Valid'),         -- For Summer Music Fest
(5, 3, 2, 'Standard', 200.00, 'Valid'),         -- For AI & Robotics Summit
(6, 4, 4, 'General Admission', 25.00, 'Valid'), -- For Local Art Exhibition
(7, 4, 1, 'Student Discount', 15.00, 'Valid');  -- For Local Art Exhibition




-- Add a comment to indicate its purpose
COMMENT ON TABLE ticket_a IS 'Fragment of Ticket data for Node_A (even ticket_id)';

-- Verify table creation
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = CURRENT_SCHEMA AND TABLE_NAME = 'ticket_a';

-- Connect to a superuser-enabled database (e.g., 'postgres')

CREATE EXTENSION IF NOT EXISTS postgres_fdw;


 -- Connect to event_node_a
INSERT INTO ticket_a (ticket_id, event_id, customer_id, ticket_type, price, status, purchase_date) VALUES
(2, 101, 2001, 'VIP', 150.00, 'CONFIRMED', NOW() - INTERVAL '5 days'),
(4, 102, 2002, 'STANDARD', 75.00, 'CONFIRMED', NOW() - INTERVAL '4 days'),
(6, 101, 2003, 'VIP', 150.00, 'PENDING', NOW() - INTERVAL '3 days'),
(8, 103, 2004, 'STANDARD', 80.00, 'CONFIRMED', NOW() - INTERVAL '2 days'),
(10, 102, 2001, 'PREMIUM', 120.00, 'CONFIRMED', NOW() - INTERVAL '1 day');

COMMIT;


-- Verify inserts
SELECT COUNT(*) FROM ticket_a;
SELECT SUM(MOD(ticket_id, 97)) FROM ticket_a; -- Checksum part (we'll use 97 as a prime for good distribution)

\c event_node_a; -- Connect to event_node_a

-- Create Foreign Server Link to event_node_b
DROP SERVER IF EXISTS proj_link CASCADE; -- For re-running
CREATE SERVER proj_link
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'event_node_b'); -- Adjust host/port if needed

-- Create User Mapping (replace 'your_pg_user' with the actual user)
DROP USER MAPPING IF EXISTS FOR CURRENT_USER SERVER proj_link; -- For re-running
CREATE USER MAPPING FOR CURRENT_USER
    SERVER proj_link
    OPTIONS (user 'postgres', password '12345'); -- Replace with your PostgreSQL user/password

-- Import Foreign Table definition from remote (Node B)
-- This creates a local representation of ticket_b from event_node_b
DROP FOREIGN TABLE IF EXISTS ticket_b_remote CASCADE; -- For re-running
IMPORT FOREIGN SCHEMA public LIMIT TO (ticket_b)
FROM SERVER proj_link INTO public;

-- Verify Foreign Table (optional)
SELECT foreign_table_name FROM information_schema.foreign_tables WHERE foreign_table_schema = CURRENT_SCHEMA;

 -- Connect to event_node_a

CREATE OR REPLACE VIEW ticket_all AS
SELECT ticket_id, event_id, customer_id, ticket_type, price, status, purchase_date FROM ticket_a
UNION ALL
SELECT ticket_id, event_id, customer_id, ticket_type, price, status, purchase_date FROM ticket_b; -- Use the foreign table
SELECT COUNT(*) FROM ticket_b;


-- Connect to event_node_a

SELECT COUNT(*) AS total_rows_ticket_a,
       SUM(MOD(ticket_id, 97)) AS checksum_ticket_a
FROM ticket_a;


 -- Connect to event_node_a

SELECT COUNT(*) AS total_rows_ticket_a,
       SUM(MOD(ticket_id, 97)) AS checksum_ticket_a
FROM ticket_a;

-- Connect to event_node_a

SELECT COUNT(*) AS total_rows_ticket_b,
       SUM(MOD(ticket_id, 97)) AS checksum_ticket_b
FROM ticket_b; -- Query the foreign table


-- Verify existence of proj_link server
SELECT s.srvname, s.srvoptions FROM pg_foreign_server s WHERE s.srvname = 'proj_link';

 -- Connect to event_node_a

-- Import Foreign Table for Event
DROP FOREIGN TABLE IF EXISTS event_remote CASCADE;
IMPORT FOREIGN SCHEMA public LIMIT TO (event)
FROM SERVER proj_link INTO public;

-- Run remote SELECT
SELECT event_id, name, event_date FROM event  LIMIT 5;

\c event_node_a; -- Connect to event_node_a

-- Import Foreign Table for Customer
\c event_node_a; -- Connect to event_node_a

-- Import Foreign Table for Customer
DROP FOREIGN TABLE IF EXISTS customer_remote CASCADE;
IMPORT FOREIGN SCHEMA public LIMIT TO (customer)
FROM SERVER proj_link INTO public;

-- Run Distributed Join
SELECT
    ta.ticket_id,
    ta.ticket_type,
    ta.price,
    cr.name AS customer_name,
    cr.email AS customer_email
FROM
    ticket_a ta -- Local fragment
JOIN
    customer c ON ta.customer_id = c.customer_id -- Remote customer data
WHERE
    ta.price > 100 -- Selective predicate
    AND c.customer_id IN (2001, 2003, 2005, 2007) -- Selective predicate to control row count
ORDER BY ta.ticket_id
LIMIT 10; -- Ensure we stay within 3-10 rows



    -- Disable parallel query for serial run
SET max_parallel_workers_per_gather = 0;
SET force_parallel_mode = off;

EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT
    ticket_type,
    COUNT(*) AS total_tickets,
    SUM(price) AS total_revenue
FROM
    ticket
GROUP BY
    ticket_type
HAVING
    COUNT(*) >= 1
ORDER BY
    ticket_type;

-- Reset parallel settings
RESET max_parallel_workers_per_gather;
RESET force_parallel_mode;

SELECT * FROM customers; 

-- On event_node_a
ALTER TABLE ticket_a
  ADD CONSTRAINT chk_price_positive CHECK (price > 0),
  ADD CONSTRAINT chk_status_valid CHECK (status IN ('CONFIRMED', 'PENDING', 'CANCELED'));

-- Failing inserts (wrapped in block)
BEGIN;
  INSERT INTO ticket_a VALUES (13, 105, 2010, 'STANDARD', -50.00, 'CONFIRMED', NOW()); -- Negative price
  INSERT INTO payment VALUES (13, -100.00, NOW(), 'CARD'); -- Negative amount
ROLLBACK;

SELECT COUNT(*) FROM ticket_b; -- Should be ≤10

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

DROP SERVER IF EXISTS proj_link CASCADE;

CREATE SERVER proj_link
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', port '5432', dbname 'event_node_b');

DROP USER MAPPING IF EXISTS FOR CURRENT_USER SERVER proj_link;

CREATE USER MAPPING FOR CURRENT_USER
SERVER proj_link
OPTIONS (user 'postgres', password '12345');


IMPORT FOREIGN SCHEMA public
LIMIT TO (ticket_audit)
FROM SERVER proj_link INTO public;


INSERT INTO ticket_audit (bef_total, aft_total, changed_at, key_col)
VALUES (500.00, 550.00, NOW(), 'INSERT');






--Step 2: Create Trigger Function

CREATE OR REPLACE FUNCTION log_ticket_totals()
RETURNS TRIGGER AS $$
DECLARE
  bef NUMERIC;
  aft NUMERIC;
BEGIN
  SELECT SUM(price) INTO bef FROM ticket_a;
  -- Wait for DML to complete
  PERFORM pg_sleep(0.5);
  SELECT SUM(price) INTO aft FROM ticket_a;
  INSERT INTO ticket_audit VALUES (bef, aft, NOW(), TG_OP);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

--Step 3: Create Trigger
CREATE TRIGGER trg_payment_totals
AFTER INSERT OR UPDATE OR DELETE ON payment
FOR EACH STATEMENT EXECUTE FUNCTION log_ticket_totals();
--Step 4: Run DML

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name ILIKE '%payment%';



-- Mixed DML
INSERT INTO payment VALUES (14, 102, 120.00, NOW(), 'MOBILE');
UPDATE payment SET amount = 130.00 WHERE payment_id = 14;
DELETE FROM payment WHERE payment_id = 14;

SELECT * FROM ticket_audit;
--B8: Recursive Hierarchy Roll-Up

--Step 1: Create Hierarchy Table

CREATE TABLE hier (
  parent_id INT,
  child_id INT
);

INSERT INTO hier VALUES
(1,2), (1,3), (2,4), (2,5), (3,6), (3,7);
--Step 2: Recursive Query

WITH RECURSIVE rollup AS (
  SELECT child_id, parent_id AS root_id, 1 AS depth
  FROM hier WHERE parent_id = 1
  UNION ALL
  SELECT h.child_id, r.root_id, r.depth + 1
  FROM hier h JOIN rollup r ON h.parent_id = r.child_id
)
SELECT * FROM rollup;




WITH RECURSIVE rollup AS (
  SELECT child_id, parent_id AS root_id, 1 AS depth
  FROM hier
  WHERE parent_id = 1

  UNION ALL

  SELECT h.child_id, r.root_id, r.depth + 1
  FROM hier h
  JOIN rollup r ON h.parent_id = r.child_id
)
--Step 3: Join to Ticket
SELECT r.child_id, r.root_id, r.depth, t.price
FROM rollup r
JOIN ticket_a t ON r.child_id = t.ticket_id;









--B9: Mini-Knowledge Base with Transitive Inference
--Step 1: Create TRIPLE Table
CREATE TABLE triple (
  s TEXT,
  p TEXT,
  o TEXT
);

INSERT INTO triple VALUES
('Ticket', 'isA', 'Product'),
('Product', 'isA', 'Item'),
('Item', 'isA', 'Entity'),
('VIP', 'isA', 'Ticket'),
('STANDARD', 'isA', 'Ticket'),
('PREMIUM', 'isA', 'Ticket');
--Step 2: Recursive Inference
WITH RECURSIVE isa_chain AS (
  SELECT s, o FROM triple WHERE p = 'isA'
  UNION
  SELECT t1.s, t2.o
  FROM isa_chain t1 JOIN triple t2 ON t1.o = t2.s AND t2.p = 'isA'
)
SELECT * FROM isa_chain;

--Step 3: Grouping Check

SELECT o AS inferred_type, COUNT(*) AS count
FROM isa_chain
GROUP BY o;

WITH RECURSIVE isa_chain AS (
  SELECT s, o FROM triple WHERE p = 'isA'
  UNION
  SELECT t1.s, t2.o
  FROM isa_chain t1
  JOIN triple t2 ON t1.o = t2.s AND t2.p = 'isA'
)
SELECT o AS inferred_type, COUNT(*) AS count
FROM isa_chain
GROUP BY o;

--B10: Business Limit Alert (Function + Trigger)
--Step 1: Create Limits Table
CREATE TABLE business_limits (
  rule_key TEXT,
  threshold NUMERIC,
  active CHAR(1) CHECK (active IN ('Y','N'))
);

INSERT INTO business_limits VALUES ('max_payment', 150, 'Y');


--Step 2: Create Function
CREATE OR REPLACE FUNCTION fn_should_alert()
RETURNS INT AS $$
DECLARE
  limit NUMERIC;
BEGIN
  SELECT threshold INTO limit FROM business_limits WHERE rule_key = 'max_payment' AND active = 'Y';
  IF EXISTS (SELECT 1 FROM payment WHERE amount > "limit") THEN
    RETURN 1;
  END IF;
  RETURN 0;
END;
$$ LANGUAGE plpgsql;

--Step 3: Create Trigger
CREATE OR REPLACE FUNCTION enforce_payment_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.amount > (SELECT threshold FROM business_limits WHERE rule_key = 'max_payment' AND active = 'Y') THEN
    RAISE EXCEPTION 'Payment exceeds business limit';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payment_limit
BEFORE INSERT OR UPDATE ON payment
FOR EACH ROW EXECUTE FUNCTION enforce_payment_limit();

--Step 4: Test DML
-- Passing
INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
VALUES (15, 111, 120.00, NOW(), 'CASH');

INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
VALUES (16, 110, 120.00, NOW(), 'CASH');

-- Failing
BEGIN;
  INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
VALUES (17, 111, 120.00, NOW(), 'CASH');

-- This insert respects all constraints
INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
VALUES (101, 201, 120.00, NOW(), 'CARD');
-- Another valid insert
INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
VALUES (102, 202, 80.00, NOW(), 'CASH');
--3. Failing Insert #1 (invalid method)
BEGIN;
  INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
  VALUES (103, 203, 90.00, NOW(), 'CHEQUE');  -- 'CHEQUE' not allowed by CHECK constraint


BEGIN;
  INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
  VALUES (103, 203, 90.00, NOW(), 'CHEQUE');  -- 'CHEQUE' not allowed by CHECK constraint
ROLLBACK;

BEGIN;
  INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
  VALUES (104, 204, -50.00, NOW(), 'MOBILE');  -- Negative amount violates business logic
ROLLBACK;

-- Insert a 3-level hierarchy with 7 rows
INSERT INTO hier VALUES
(1, 2),  -- root → level 1
(1, 3),
(2, 4),  -- level 2
(2, 5),
(3, 6),
(3, 7),
(4, 8);  -- level 3



SELECT * FROM hier;

WITH RECURSIVE rollup AS (
  SELECT child_id, parent_id AS root_id, 1 AS depth
  FROM hier
  WHERE parent_id = 1

  UNION ALL

  SELECT h.child_id, r.root_id, r.depth + 1
  FROM hier h
  JOIN rollup r ON h.parent_id = r.child_id
)
SELECT * FROM rollup;

WITH RECURSIVE rollup AS (
  SELECT child_id, parent_id AS root_id, 1 AS depth
  FROM hier
  WHERE parent_id = 1

  UNION ALL

  SELECT h.child_id, r.root_id, r.depth + 1
  FROM hier h
  JOIN rollup r ON h.parent_id = r.child_id
)
SELECT r.root_id, r.child_id, r.depth, t.price
FROM rollup r
JOIN ticket_a t ON r.child_id = t.ticket_id
ORDER BY r.depth, r.child_id
LIMIT 10;

--Aggregate rollup totals per root

WITH RECURSIVE rollup AS (
  SELECT child_id, parent_id AS root_id, 1 AS depth
  FROM hier
  WHERE parent_id = 1

  UNION ALL

  SELECT h.child_id, r.root_id, r.depth + 1
  FROM hier h
  JOIN rollup r ON h.parent_id = r.child_id
)
SELECT r.root_id, SUM(t.price) AS total_price
FROM rollup r
JOIN ticket_a t ON r.child_id = t.ticket_id
GROUP BY r.root_id;


SELECT * FROM ticket_a;
WITH RECURSIVE rollup AS (
  SELECT child_id, parent_id AS root_id, 1 AS depth
  FROM hier
  WHERE parent_id = 1

  UNION ALL

  SELECT h.child_id, r.root_id, r.depth + 1
  FROM hier h
  JOIN rollup r ON h.parent_id = r.child_id
)
SELECT r.child_id, r.root_id, r.depth, t.ticket_type, t.price
FROM rollup r
JOIN ticket_a t ON r.child_id = t.ticket_id
ORDER BY r.depth, r.child_id
LIMIT 10;

IMPORT FOREIGN SCHEMA public
LIMIT TO (customer)
FROM SERVER proj_link INTO public;

SELECT
  t.ticket_id,
  t.event_id,
  t.customer_id,
  c.email,
  t.price,
  t.status
FROM ticket_a t
JOIN customer c ON t.customer_id = c.customer_id
WHERE t.status = 'CONFIRMED'
LIMIT 10;



DO $$
DECLARE
  success_local BOOLEAN := FALSE;
  success_remote BOOLEAN := FALSE;
BEGIN
  RAISE NOTICE '--- Starting Distributed Insert ---';

  -- Phase 1: Insert into local ticket_a
  BEGIN
    INSERT INTO ticket_a (ticket_id, event_id, customer_id, ticket_type, price, status, purchase_date)
    VALUES (99, 101, 2009, 'STANDARD', 95.00, 'CONFIRMED', NOW());
    success_local := TRUE;
    RAISE NOTICE 'Local insert successful.';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Local insert failed: %', SQLERRM;
  END;

  -- Phase 2: Insert into remote payment via FDW
  BEGIN
    INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
    VALUES (99, 99, 95.00, NOW(), 'CARD');
    success_remote := TRUE;
    RAISE NOTICE 'Remote insert successful.';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Remote insert failed: %', SQLERRM;
  END;

  -- Final commit if both succeeded
  IF success_local AND success_remote THEN
    COMMIT;
    RAISE NOTICE 'Distributed transaction committed.';
  ELSE
    ROLLBACK;
    RAISE NOTICE 'Transaction rolled back due to failure.';
  END IF;
END;
$$ LANGUAGE plpgsql;






DO $$
DECLARE
  success_local BOOLEAN := FALSE;
  success_remote BOOLEAN := FALSE;
BEGIN
  RAISE NOTICE '--- Starting Distributed Insert with Failure ---';

  -- Phase 1: Local insert (valid)
  BEGIN
    INSERT INTO ticket_a (ticket_id, event_id, customer_id, ticket_type, price, status, purchase_date)
    VALUES (98, 103, 2012, 'STANDARD', 85.00, 'CONFIRMED', NOW());
    success_local := TRUE;
    RAISE NOTICE 'Local insert successful.';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Local insert failed: %', SQLERRM;
  END;

  -- Phase 2: Remote insert (intentional failure: invalid method)
  BEGIN
    INSERT INTO payment (payment_id, ticket_id, amount, payment_date, method)
    VALUES (98, 98, 85.00, NOW(), 'BITCOIN');  -- 'BITCOIN' violates CHECK constraint
    success_remote := TRUE;
    RAISE NOTICE 'Remote insert successful.';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Remote insert failed: %', SQLERRM;
  END;

  -- Final decision
  IF success_local AND success_remote THEN
    COMMIT;
    RAISE NOTICE 'Distributed transaction committed.';
  ELSE
    ROLLBACK;
    RAISE NOTICE 'Transaction rolled back due to failure.';
  END IF;
END;
$$ LANGUAGE plpgsql;



SELECT * FROM pg_prepared_xacts;


BEGIN;

-- Insert a row (example)
INSERT INTO ticket_a (ticket_id, event_id, customer_id, ticket_type, price, status, purchase_date)
VALUES (98, 103, 2013, 'STANDARD', 90.00, 'CONFIRMED', NOW());

-- Prepare the transaction
PREPARE TRANSACTION 'txn_test_97';

-- To commit
COMMIT PREPARED 'txn_test_97';

-- Or to rollback


COMMIT ;

SELECT * FROM pg_prepared_xacts;

IMPORT FOREIGN SCHEMA public
LIMIT TO (ticket_b)
FROM SERVER proj_link INTO public;



CREATE VIEW ticket_all AS
SELECT * FROM ticket_a
UNION ALL
SELECT * FROM ticket_b;  -- via FDW if remote


SELECT * FROM ticket_a
UNION ALL
SELECT * FROM ticket_b;  -- now accessible via FDW




