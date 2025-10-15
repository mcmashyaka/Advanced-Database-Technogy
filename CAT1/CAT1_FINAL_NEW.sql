-- ============================================================================
-- EVENT MANAGEMENT SYSTEM - CORRECTED AND EXPLAINED
-- ============================================================================

SET SERVEROUTPUT ON; -- Enable output messages in console

-- ============================================================================
-- STEP 1: DROP EXISTING OBJECTS (Clean Slate)
-- ============================================================================
-- Purpose: Remove old database objects to avoid conflicts
PROMPT Dropping existing objects...

BEGIN
    -- Drop view if it exists
    FOR rec IN (SELECT view_name FROM user_views WHERE view_name = 'VW_ORGANIZERPAYMENTSUMMARY') LOOP
        EXECUTE IMMEDIATE 'DROP VIEW ' || rec.view_name; 
    END LOOP;
END;
/

BEGIN
    -- Drop tables in reverse dependency order (children first, parents last)
    FOR rec IN (SELECT table_name FROM user_tables 
                WHERE table_name IN ('PAYMENT', 'TICKET', 'CUSTOMER', 'EVENT', 'ORGANIZER', 'VENUE')) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

BEGIN
    -- Drop sequences (auto-increment counters)
    FOR rec IN (SELECT sequence_name FROM user_sequences 
                WHERE sequence_name IN ('VENUE_SEQ', 'ORGANIZER_SEQ', 'EVENT_SEQ', 
                                       'CUSTOMER_SEQ', 'TICKET_SEQ', 'PAYMENT_SEQ')) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || rec.sequence_name;
    END LOOP;
END;
/

PROMPT All existing objects dropped successfully.

-- ============================================================================
-- STEP 2: CREATE SEQUENCES (Auto-increment ID generators)
-- ============================================================================
-- Purpose: Create counters that automatically generate unique IDs
PROMPT Creating sequences...

CREATE SEQUENCE VENUE_SEQ START WITH 1 INCREMENT BY 1;      -- Counter for Venue IDs
CREATE SEQUENCE ORGANIZER_SEQ START WITH 1 INCREMENT BY 1;  -- Counter for Organizer IDs
CREATE SEQUENCE EVENT_SEQ START WITH 1 INCREMENT BY 1;      -- Counter for Event IDs
CREATE SEQUENCE CUSTOMER_SEQ START WITH 1 INCREMENT BY 1;   -- Counter for Customer IDs
CREATE SEQUENCE TICKET_SEQ START WITH 1 INCREMENT BY 1;     -- Counter for Ticket IDs
CREATE SEQUENCE PAYMENT_SEQ START WITH 1 INCREMENT BY 1;    -- Counter for Payment IDs

PROMPT Sequences created successfully.

-- ============================================================================
-- STEP 3: CREATE TABLES
-- ============================================================================
-- Purpose: Define database structure with relationships
PROMPT Creating tables...

-- VENUE TABLE: Stores event locations
CREATE TABLE VENUE (
    VenueID NUMBER PRIMARY KEY,              -- Unique venue identifier
    VenueName VARCHAR2(100) NOT NULL,        -- Venue name (required)
    Location VARCHAR2(200),                  -- Physical address
    Capacity NUMBER NOT NULL,                -- Maximum capacity
    AvailableCapacity NUMBER NOT NULL        -- Current available spots
);

-- ORGANIZER TABLE: Stores event organizers
CREATE TABLE ORGANIZER (
    OrganizerID NUMBER PRIMARY KEY,          -- Unique organizer identifier
    FullName VARCHAR2(100) NOT NULL,         -- Organizer's name (required)
    Company VARCHAR2(100),                   -- Company name
    Email VARCHAR2(100) UNIQUE NOT NULL,     -- Email (unique, required)
    Phone VARCHAR2(20)                       -- Phone number
);

-- EVENT TABLE: Stores event details
CREATE TABLE EVENT (
    EventID NUMBER PRIMARY KEY,              -- Unique event identifier
    OrganizerID NUMBER NOT NULL,             -- Who organizes the event
    VenueID NUMBER NOT NULL,                 -- Where event takes place
    Title VARCHAR2(200) NOT NULL,            -- Event name (required)
    EventDate DATE NOT NULL,                 -- When event occurs (required)
    Category VARCHAR2(50),                   -- Event type (Music, Tech, etc.)
    FOREIGN KEY (OrganizerID) REFERENCES ORGANIZER(OrganizerID),  -- Link to organizer
    FOREIGN KEY (VenueID) REFERENCES VENUE(VenueID)              -- Link to venue
);

-- CUSTOMER TABLE: Stores customer information
CREATE TABLE CUSTOMER (
    CustomerID NUMBER PRIMARY KEY,           -- Unique customer identifier
    FullName VARCHAR2(100) NOT NULL,         -- Customer name (required)
    Contact VARCHAR2(20),                    -- Phone number
    Email VARCHAR2(100) UNIQUE NOT NULL,     -- Email (unique, required)
    City VARCHAR2(50)                        -- Customer's city
);

-- TICKET TABLE: Stores ticket bookings
CREATE TABLE TICKET (
    TicketID NUMBER PRIMARY KEY,             -- Unique ticket identifier
    EventID NUMBER NOT NULL,                 -- Which event
    CustomerID NUMBER NOT NULL,              -- Who bought it
    SeatNo VARCHAR2(10),                     -- Seat number
    Price NUMBER(10,2) NOT NULL,             -- Ticket price (required)
    Status VARCHAR2(20) DEFAULT 'Booked',    -- Booking status
    FOREIGN KEY (EventID) REFERENCES EVENT(EventID),          -- Link to event
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID)  -- Link to customer
);

-- PAYMENT TABLE: Stores payment transactions
CREATE TABLE PAYMENT (
    PaymentID NUMBER PRIMARY KEY,            -- Unique payment identifier
    TicketID NUMBER NOT NULL,                -- Which ticket was paid for
    Amount NUMBER(10,2) NOT NULL,            -- Payment amount (required)
    PaymentDate DATE DEFAULT SYSDATE,        -- When payment was made (default: now)
    Method VARCHAR2(50),                     -- Payment method (Card, Cash, etc.)
    FOREIGN KEY (TicketID) REFERENCES TICKET(TicketID)  -- Link to ticket
);

PROMPT Tables created successfully.

-- ============================================================================
-- STEP 4: CREATE AUTO-INCREMENT TRIGGERS
-- ============================================================================
-- Purpose: Automatically assign IDs when inserting new records
PROMPT Creating auto-increment triggers...

-- Auto-assign VenueID if not provided
CREATE OR REPLACE TRIGGER TRG_VENUE_ID
BEFORE INSERT ON VENUE
FOR EACH ROW
BEGIN
    IF :NEW.VenueID IS NULL THEN
        :NEW.VenueID := VENUE_SEQ.NEXTVAL;  -- Get next number from sequence
    END IF;
END;
/

-- Auto-assign OrganizerID if not provided
CREATE OR REPLACE TRIGGER TRG_ORGANIZER_ID
BEFORE INSERT ON ORGANIZER
FOR EACH ROW
BEGIN
    IF :NEW.OrganizerID IS NULL THEN
        :NEW.OrganizerID := ORGANIZER_SEQ.NEXTVAL;
    END IF;
END;
/

-- Auto-assign EventID if not provided
CREATE OR REPLACE TRIGGER TRG_EVENT_ID
BEFORE INSERT ON EVENT
FOR EACH ROW
BEGIN
    IF :NEW.EventID IS NULL THEN
        :NEW.EventID := EVENT_SEQ.NEXTVAL;
    END IF;
END;
/

-- Auto-assign CustomerID if not provided
CREATE OR REPLACE TRIGGER TRG_CUSTOMER_ID
BEFORE INSERT ON CUSTOMER
FOR EACH ROW
BEGIN
    IF :NEW.CustomerID IS NULL THEN
        :NEW.CustomerID := CUSTOMER_SEQ.NEXTVAL;
    END IF;
END;
/

-- Auto-assign TicketID if not provided
CREATE OR REPLACE TRIGGER TRG_TICKET_ID
BEFORE INSERT ON TICKET
FOR EACH ROW
BEGIN
    IF :NEW.TicketID IS NULL THEN
        :NEW.TicketID := TICKET_SEQ.NEXTVAL;
    END IF;
END;
/

-- Auto-assign PaymentID if not provided
CREATE OR REPLACE TRIGGER TRG_PAYMENT_ID
BEFORE INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    IF :NEW.PaymentID IS NULL THEN
        :NEW.PaymentID := PAYMENT_SEQ.NEXTVAL;
    END IF;
END;
/

PROMPT Auto-increment triggers created successfully.

-- ============================================================================
-- STEP 5: ENFORCE CASCADE DELETE
-- ============================================================================
-- Purpose: When an event is deleted, automatically delete its tickets
-- CORRECTED: Use proper constraint name from system catalog
PROMPT Enforcing CASCADE DELETE on Event -> Ticket...

-- First, find and drop the existing foreign key constraint
DECLARE
    v_constraint_name VARCHAR2(30);
BEGIN
    -- Get the actual constraint name
    SELECT constraint_name INTO v_constraint_name
    FROM user_constraints
    WHERE table_name = 'TICKET' 
      AND constraint_type = 'R'
      AND r_constraint_name IN (
          SELECT constraint_name 
          FROM user_constraints 
          WHERE table_name = 'EVENT' 
            AND constraint_type = 'P'
      );
    
    -- Drop the old constraint
    EXECUTE IMMEDIATE 'ALTER TABLE TICKET DROP CONSTRAINT ' || v_constraint_name;
    
    DBMS_OUTPUT.PUT_LINE('Dropped constraint: ' || v_constraint_name);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No existing constraint found to drop.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Multiple constraints found. Dropping all...');
        FOR rec IN (SELECT constraint_name FROM user_constraints
                    WHERE table_name = 'TICKET' AND constraint_type = 'R') LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE TICKET DROP CONSTRAINT ' || rec.constraint_name;
        END LOOP;
END;
/

-- Add new constraint with CASCADE DELETE
ALTER TABLE TICKET ADD CONSTRAINT FK_TICKET_EVENT 
    FOREIGN KEY (EventID) REFERENCES EVENT(EventID) ON DELETE CASCADE;

PROMPT CASCADE DELETE enforced successfully.

-- ============================================================================
-- STEP 6: INSERT SAMPLE DATA
-- ============================================================================
-- Purpose: Add test data to demonstrate system functionality
PROMPT Inserting sample data...

-- Insert 3 Venues
INSERT INTO VENUE (VenueName, Location, Capacity, AvailableCapacity)
VALUES ('Grand Exhibition Hall', 'Downtown', 500, 500);

INSERT INTO VENUE (VenueName, Location, Capacity, AvailableCapacity)
VALUES ('Central Park Arena', 'Uptown', 1000, 1000);

INSERT INTO VENUE (VenueName, Location, Capacity, AvailableCapacity)
VALUES ('Riverside Theatre', 'Riverside', 300, 300);

-- Insert 3 Organizers
INSERT INTO ORGANIZER (FullName, Company, Email, Phone)
VALUES ('Alice Smith', 'Event Masters Inc.', 'alice@eventmasters.com', '555-1111');

INSERT INTO ORGANIZER (FullName, Company, Email, Phone)
VALUES ('Bob Johnson', 'Concert Co.', 'bob@concertco.com', '555-2222');

INSERT INTO ORGANIZER (FullName, Company, Email, Phone)
VALUES ('Charlie Brown', 'Tech Conferences', 'charlie@techconf.com', '555-3333');

-- Insert 5 Events
INSERT INTO EVENT (OrganizerID, VenueID, Title, EventDate, Category)
VALUES (1, 1, 'Annual Tech Summit', TO_DATE('2023-11-15', 'YYYY-MM-DD'), 'Technology');

INSERT INTO EVENT (OrganizerID, VenueID, Title, EventDate, Category)
VALUES (2, 2, 'Summer Music Festival', TO_DATE('2024-07-20', 'YYYY-MM-DD'), 'Music');

INSERT INTO EVENT (OrganizerID, VenueID, Title, EventDate, Category)
VALUES (1, 1, 'Marketing Masterclass', TO_DATE('2023-12-01', 'YYYY-MM-DD'), 'Business');

INSERT INTO EVENT (OrganizerID, VenueID, Title, EventDate, Category)
VALUES (3, 3, 'Open Air Cinema Night', TO_DATE('2024-08-05', 'YYYY-MM-DD'), 'Entertainment');

INSERT INTO EVENT (OrganizerID, VenueID, Title, EventDate, Category)
VALUES (2, 2, 'Charity Gala Dinner', TO_DATE('2024-01-25', 'YYYY-MM-DD'), 'Charity');

-- Insert 10 Customers
INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('John Doe', '111-222-3333', 'john.doe@example.com', 'CityA');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('Jane Smith', '444-555-6666', 'jane.smith@example.com', 'CityB');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('Peter Jones', '777-888-9999', 'peter.jones@example.com', 'CityA');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('Mary Brown', '222-333-4444', 'mary.brown@example.com', 'CityC');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('David Lee', '555-666-7777', 'david.lee@example.com', 'CityB');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('Emily White', '888-999-0000', 'emily.white@example.com', 'CityA');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('Michael Green', '123-456-7890', 'michael.green@example.com', 'CityC');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('Sarah Black', '987-654-3210', 'sarah.black@example.com', 'CityB');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('Robert Blue', '321-654-9870', 'robert.blue@example.com', 'CityA');

INSERT INTO CUSTOMER (FullName, Contact, Email, City)
VALUES ('Laura Red', '654-987-3210', 'laura.red@example.com', 'CityC');

COMMIT;

PROMPT Sample data inserted successfully.

-- ============================================================================
-- STEP 7: CREATE CAPACITY MANAGEMENT TRIGGERS
-- ============================================================================
-- Purpose: Automatically manage venue capacity when tickets are booked
PROMPT Creating capacity management triggers...

-- Check if venue has space BEFORE booking ticket
CREATE OR REPLACE TRIGGER TRG_BEFORETICKETINSERT_CHECKCAPACITY
BEFORE INSERT ON TICKET
FOR EACH ROW
DECLARE
    v_available_capacity NUMBER;
BEGIN
    -- Get current available capacity for the event's venue
    SELECT V.AvailableCapacity INTO v_available_capacity
    FROM VENUE V
    JOIN EVENT E ON V.VenueID = E.VenueID
    WHERE E.EventID = :NEW.EventID;
    
    -- Reject ticket if no space available
    IF v_available_capacity <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cannot book ticket. Venue is full for this event.');
    END IF;
END;
/

-- Decrease available capacity AFTER ticket is booked
CREATE OR REPLACE TRIGGER TRG_AFTERTICKETINSERT_UPDATECAPACITY
AFTER INSERT ON TICKET
FOR EACH ROW
DECLARE
    v_venue_id NUMBER;
BEGIN
    -- Find which venue hosts this event
    SELECT VenueID INTO v_venue_id
    FROM EVENT
    WHERE EventID = :NEW.EventID;
    
    -- Reduce available capacity by 1
    UPDATE VENUE
    SET AvailableCapacity = AvailableCapacity - 1
    WHERE VenueID = v_venue_id;
END;
/

PROMPT Capacity management triggers created successfully.

-- ============================================================================
-- STEP 8: INSERT TICKETS AND PAYMENTS
-- ============================================================================
-- Purpose: Add ticket bookings and payment records
PROMPT Inserting tickets and payments...

-- Insert 9 Tickets (capacity triggers will fire automatically)
INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (1, 1, 'A1', 50, 'Confirmed');

INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (1, 2, 'A2', 50, 'Confirmed');

INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (1, 3, 'A3', 50, 'Confirmed');

INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (2, 4, 'B10', 75, 'Confirmed');

INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (2, 5, 'B11', 75, 'Confirmed');

INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (3, 6, 'C1', 120, 'Confirmed');

INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (4, 7, 'G5', 25, 'Confirmed');

INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (4, 8, 'G6', 25, 'Confirmed');

INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
VALUES (4, 9, 'G7', 25, 'Booked');

-- Insert 8 Payments (Ticket 9 has no payment yet)
INSERT INTO PAYMENT (TicketID, Amount, PaymentDate, Method)
VALUES (1, 50, SYSDATE, 'Credit Card');

INSERT INTO PAYMENT (TicketID, Amount, PaymentDate, Method)
VALUES (2, 50, SYSDATE, 'Credit Card');

INSERT INTO PAYMENT (TicketID, Amount, PaymentDate, Method)
VALUES (3, 50, SYSDATE, 'Credit Card');

INSERT INTO PAYMENT (TicketID, Amount, PaymentDate, Method)
VALUES (4, 75, SYSDATE, 'PayPal');

INSERT INTO PAYMENT (TicketID, Amount, PaymentDate, Method)
VALUES (5, 75, SYSDATE, 'Credit Card');

INSERT INTO PAYMENT (TicketID, Amount, PaymentDate, Method)
VALUES (6, 120, SYSDATE, 'Debit Card');

INSERT INTO PAYMENT (TicketID, Amount, PaymentDate, Method)
VALUES (7, 25, SYSDATE, 'Cash');

INSERT INTO PAYMENT (TicketID, Amount, PaymentDate, Method)
VALUES (8, 25, SYSDATE, 'PayPal');

COMMIT;

PROMPT Tickets and payments inserted successfully.

-- ============================================================================
-- TASK 4: REPORT - TICKETS SOLD PER EVENT WITH REVENUE
-- ============================================================================
-- Purpose: Show how many tickets sold and total revenue for each event
PROMPT ========================================
PROMPT Task 4: Tickets Sold Per Event Report
PROMPT ========================================

SELECT
    E.Title AS EventTitle,
    COUNT(T.TicketID) AS TicketsSold,           -- Count tickets per event
    NVL(SUM(P.Amount), 0) AS TotalRevenue       -- Sum payments (0 if none)
FROM
    Event E
LEFT JOIN Ticket T ON E.EventID = T.EventID    -- Include events with no tickets
LEFT JOIN Payment P ON T.TicketID = P.TicketID -- Include tickets with no payment
GROUP BY
    E.Title                                      -- Group by event name
ORDER BY
    EventTitle;

-- ============================================================================
-- TASK 6: REPORT - MOST ATTENDED EVENT PER CATEGORY
-- ============================================================================
-- Purpose: Find the #1 most popular event in each category
PROMPT ========================================
PROMPT Task 6: Top Event Per Category Report
PROMPT ========================================

SELECT
    Category,
    EventTitle,
    NumberOfTicketsSold
FROM (
    SELECT
        E.Category,
        E.Title AS EventTitle,
        COUNT(T.TicketID) AS NumberOfTicketsSold,
        ROW_NUMBER() OVER (
            PARTITION BY E.Category                -- Separate ranking per category
            ORDER BY COUNT(T.TicketID) DESC        -- Highest ticket count = rank 1
        ) as rn
    FROM
        Event E
    LEFT JOIN Ticket T ON E.EventID = T.EventID
    WHERE
        T.Status IN ('Booked', 'Confirmed')        -- Only count valid tickets
    GROUP BY
        E.Category, E.Title
)
WHERE
    rn = 1                                         -- Keep only rank 1 per category
ORDER BY
    Category;

-- ============================================================================
-- TASK 7: CREATE VIEW - ORGANIZER PAYMENT SUMMARY
-- ============================================================================
-- Purpose: Create reusable view showing total revenue per organizer
PROMPT ========================================
PROMPT Task 7: Creating Organizer Revenue View
PROMPT ========================================

CREATE OR REPLACE VIEW vw_OrganizerPaymentSummary AS
SELECT
    O.FullName AS OrganizerName,
    O.Company AS OrganizerCompany,
    NVL(SUM(P.Amount), 0) AS TotalRevenueGenerated  -- Sum all payments for organizer
FROM
    ORGANIZER O
LEFT JOIN EVENT E ON O.OrganizerID = E.OrganizerID       -- Get organizer's events
LEFT JOIN TICKET T ON E.EventID = T.EventID              -- Get tickets for those events
LEFT JOIN PAYMENT P ON T.TicketID = P.TicketID           -- Get payments for those tickets
GROUP BY
    O.FullName, O.Company
ORDER BY
    TotalRevenueGenerated DESC;                          -- Highest earners first

-- Query the view to show results
SELECT * FROM vw_OrganizerPaymentSummary;

PROMPT View created and queried successfully.

-- ============================================================================
-- VERIFICATION: DISPLAY ALL TABLE DATA
-- ============================================================================
-- Purpose: Show all current data for verification
PROMPT ========================================
PROMPT Verification: All Table Data
PROMPT ========================================

PROMPT --- VENUES ---
SELECT * FROM Venue;

PROMPT --- ORGANIZERS ---
SELECT * FROM Organizer;

PROMPT --- EVENTS ---
SELECT * FROM Event;

PROMPT --- CUSTOMERS ---
SELECT * FROM Customer;

PROMPT --- TICKETS ---
SELECT * FROM Ticket;

PROMPT --- PAYMENTS ---
SELECT * FROM Payment;

-- ============================================================================
-- VERIFICATION: VENUE CAPACITY STATUS
-- ============================================================================
-- Purpose: Check how capacity was affected by ticket bookings
PROMPT ========================================
PROMPT Verification: Venue Capacity Status
PROMPT ========================================

SELECT 
    VenueName, 
    Capacity, 
    AvailableCapacity,
    (Capacity - AvailableCapacity) AS TicketsBooked
FROM Venue
ORDER BY VenueName;

-- ============================================================================
-- TASK 8: TEST CAPACITY LIMIT ENFORCEMENT
-- ============================================================================
-- Purpose: Demonstrate that system prevents overbooking
PROMPT ========================================
PROMPT Task 8: Testing Capacity Limit Trigger
PROMPT ========================================

BEGIN
    -- Reduce Venue 1 capacity to 1 for testing
    UPDATE VENUE 
    SET AvailableCapacity = 1 
    WHERE VenueID = 1;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Test Setup: Venue 1 capacity set to 1');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    
    -- Attempt 1: Book ticket (should succeed - 1 spot available)
    BEGIN
        INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
        VALUES (1, 4, 'A4', 50, 'Confirmed');
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✓ SUCCESS: Ticket A4 booked (1 spot filled)');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✗ UNEXPECTED ERROR: ' || SQLERRM);
            ROLLBACK;
    END;
    
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    
    -- Attempt 2: Book another ticket (should fail - no spots left)
    BEGIN
        INSERT INTO TICKET (EventID, CustomerID, SeatNo, Price, Status)
        VALUES (1, 5, 'A5', 50, 'Confirmed');
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✗ FAILURE: Ticket A5 booked (TRIGGER FAILED!)');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✓ SUCCESS: Booking blocked - ' || SQLERRM);
            ROLLBACK;
    END;
    
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
END;
/

-- Show final capacity status
PROMPT Final Venue 1 Capacity Status:
SELECT VenueName, Capacity, AvailableCapacity
FROM Venue
WHERE VenueID = 1;


PROMPT Script Completed Successfully!




