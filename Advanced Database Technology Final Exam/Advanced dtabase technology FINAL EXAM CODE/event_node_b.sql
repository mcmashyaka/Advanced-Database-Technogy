
CREATE TABLE IF NOT EXISTS organizers (
    organizer_id SERIAL PRIMARY KEY,    -- Unique identifier for each organizer
    organizer_name VARCHAR(255) NOT NULL, -- Name of the organization or individual
    contact_person VARCHAR(100),        -- Main contact person
    contact_email VARCHAR(255) UNIQUE NOT NULL, -- Email for communications


    contact_phone VARCHAR(50));           -- Phone number

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

--Customers Table: Stores customer details for ticket purchases.
CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,     -- Unique identifier for each customer
    full_name VARCHAR(100) NOT NULL,    -- Customer's full name
    email VARCHAR(255) UNIQUE NOT NULL, -- Customer's email
    phone_number VARCHAR(50)            -- Customer's phone number
);

INSERT INTO organizers (organizer_name, contact_person, contact_email, contact_phone) VALUES
('Tech Events Inc.', 'Alice Wonderland', 'alice@techevents.com', '+11234567890'),
('Music Festival Co.', 'Bob Thebuilder', 'bob@musicfest.com', '+10987654321'),
('Art & Culture Hub', 'Carla Diaz', 'carla@arthub.com', '+16543210987');


-- In EventOperations database
INSERT INTO venues (venue_name, location, capacity, contact_email, contact_phone) VALUES
('Convention Center', '123 Main St, Cityville', 5000, 'info@convention.com', '+15551234567'),
('Grand Arena', '456 Stadium Rd, Townsville', 15000, 'events@grandarena.com', '+15559876543'),
('City Hall Auditorium', '789 Civic Ave, Metropolis', 800, 'hall@city.com', '+19876543210');


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








-- Inside event_node_b database

DROP TABLE IF EXISTS ticket_b CASCADE; -- For re-running if needed

CREATE TABLE ticket_b (
    ticket_id       INTEGER PRIMARY KEY,
    event_id        INTEGER NOT NULL,
    customer_id     INTEGER NOT NULL,
    ticket_type     VARCHAR(50),
    price           NUMERIC(10, 2),
    status          VARCHAR(20),
    purchase_date   TIMESTAMP
);

-- Add a comment to indicate its purpose
COMMENT ON TABLE ticket_b IS 'Fragment of Ticket data for Node_B (odd ticket_id)';

-- Verify table creation
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = CURRENT_SCHEMA AND TABLE_NAME = 'ticket_b';


 -- Connect to event_node_b

INSERT INTO ticket_b (ticket_id, event_id, customer_id, ticket_type, price, status, purchase_date) VALUES
(1, 101, 2005, 'STANDARD', 100.00, 'CONFIRMED', NOW() - INTERVAL '6 days'),
(3, 102, 2006, 'VIP', 200.00, 'PENDING', NOW() - INTERVAL '5 days'),
(5, 103, 2005, 'STANDARD', 90.00, 'CONFIRMED', NOW() - INTERVAL '4 days'),
(7, 101, 2007, 'PREMIUM', 180.00, 'CONFIRMED', NOW() - INTERVAL '3 days'),
(9, 103, 2008, 'STANDARD', 85.00, 'PENDING', NOW() - INTERVAL '2 days');

COMMIT;
-- Import Foreign Table definition from remote (Node B)
-- This creates a local representation of ticket_b from event_node_b



-- Verify inserts
SELECT COUNT(*) FROM ticket_b;
SELECT SUM(MOD(ticket_id, 97)) FROM ticket_b; -- Checksum

SELECT * FROM customers;

\c event_node_b; -- Connect to event_node_b

DROP TABLE IF EXISTS event CASCADE;
CREATE TABLE event (
    event_id INTEGER PRIMARY KEY,
    name VARCHAR(100),
    event_date DATE
);

INSERT INTO event (event_id, name, event_date) VALUES
(101, 'Concert Night', '2024-10-10'),
(102, 'Art Exhibition', '2024-11-15'),
(103, 'Tech Conference', '2024-12-01');
COMMIT;

DROP TABLE IF EXISTS customer CASCADE;
CREATE TABLE customer (
    customer_id INTEGER PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

INSERT INTO customer (customer_id, name, email) VALUES
(2001, 'Alice Smith', 'alice@example.com'),
(2002, 'Bob Johnson', 'bob@example.com'),
(2003, 'Charlie Brown', 'charlie@example.com'),
(2004, 'Diana Prince', 'diana@example.com'),
(2005, 'Eve Adams', 'eve@example.com'),
(2006, 'Frank White', 'frank@example.com'),
(2007, 'Grace Kelly', 'grace@example.com'),
(2008, 'Heidi Turner', 'heidi@example.com');

SELECT * FROM customer;

\c event_node_b; -- Connect to event_node_b

DROP TABLE IF EXISTS payments CASCADE;
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    ticket_id INTEGER NOT NULL,
    amount NUMERIC(10, 2),
    method VARCHAR(50),
    payment_date TIMESTAMP
);
COMMIT;

-- Prepare the transaction on node B
PREPARE TRANSACTION pg_prepared_xacts;

SELECT * FROM pg_prepared_xacts;
 -- Connect to event_node_b

RAISE NOTICE '--- A4.3: Query and Force Resolution of In-Doubt Transaction ---';

-- Query pg_prepared_xacts (equivalent of DBA_2PC_PENDING)
SELECT * FROM pg_prepared_xacts;


-- Output should show 'ticket_payment_tx_remote_fail'

-- Decide to COMMIT PREPARED or ROLLBACK PREPARED.
-- Since the local transaction committed, we should ideally COMMIT the remote one to maintain consistency.
-- If the local failed, we'd ROLLBACK.
COMMIT PREPARED 'ticket_payment_tx_remote_fail'; -- Issue the force commit

RAISE NOTICE 'Transaction ''ticket_payment_tx_remote_fail'' was forcefully committed.';

-- Re-verify pg_prepared_xacts (should be empty now)
SELECT gid, prepared_at, owner, database FROM pg_prepared_xacts;

-- Check data consistency
SELECT * FROM payments WHERE ticket_id = 2; -- Should now show the inserted row

BEGIN;
UPDATE ticket_b SET status = 'Processing' WHERE ticket_id = 1;

SELECT * FROM payments;

ALTER TABLE payments
  ADD CONSTRAINT chk_amount_positive CHECK (amount > 0),
  ADD CONSTRAINT chk_method_valid CHECK (method IN ('CASH', 'CARD', 'MOBILE'));
SELECT COUNT(*) FROM payments;



CREATE TABLE ticket_audit (
  bef_total NUMERIC,
  aft_total NUMERIC,
  changed_at TIMESTAMP,
  key_col TEXT
);
INSERT INTO ticket_audit (bef_total, aft_total, changed_at, key_col)
VALUES (450.00, 500.00, NOW(), 'INSERT');
INSERT INTO ticket_audit VALUES
(500.00, 550.00, NOW(), 'UPDATE'),
(550.00, 530.00, NOW(), 'DELETE');



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

-Step 3: Create Trigger
CREATE TRIGGER trg_payment_totals
AFTER INSERT OR UPDATE OR DELETE ON payments
FOR EACH STATEMENT EXECUTE FUNCTION log_ticket_totals();
--Step 4: Run DML

-- Mixed DML
INSERT INTO payments (payment_id, ticket_id, amount, payment_date, method)
VALUES (17, 5, 200.00, NOW(), 'CARD');

UPDATE payments SET amount = 130.00 WHERE payment_id = 14;
DELETE FROM payments WHERE payment_id = 14;

SELECT * FROM ticket_b;









