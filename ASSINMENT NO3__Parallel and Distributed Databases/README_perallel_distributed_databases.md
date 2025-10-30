 Assignment No. 3 — Parallel and Distributed Databases
 Overview
This assignment explores key concepts of Parallel and Distributed Database Systems using Oracle SQL.
It demonstrates schema creation, data fragmentation, distributed transactions, parallel query optimization, and performance comparisons.
Two schemas — BranchDB_MUSANZE and BranchDB_KIGALI — act as distributed database nodes (node_a and node_b).
________________________________________
 System Architecture
 Distributed Node Setup
•	Node A: BranchDB_MUSANZE (North Node)
•	Node B: BranchDB_KIGALI (Central Node)
•	Each node has privileges for schema creation, distributed access, and synonym linking.
CREATE USER BranchDB_MUSANZE IDENTIFIED BY "12345";
CREATE USER BranchDB_KIGALI IDENTIFIED BY "12345";

GRANT CONNECT, RESOURCE, CREATE TABLE, CREATE SYNONYM TO BranchDB_MUSANZE;
GRANT CONNECT, RESOURCE, CREATE TABLE, CREATE SYNONYM TO BranchDB_KIGALI;
________________________________________
Q1 — Distributed Schema and Fragmentation
Entities Created
Each branch schema defines similar but fragmented and replicated tables to demonstrate distributed design:
Table	Fragment Type	Node	Description
Organizer	Replicated	Both	Shared organizer data
Venue	Filtered Replication	Musanze	Venue limited to VenueLocation='Musanze'
Event	Horizontal Fragmentation	Musanze	Events held in Musanze
Customer	Horizontal Fragmentation	Musanze	Customers in City='Musanze'
Ticket	Derived Fragment	Musanze	Joins Event and Customer
Payment	Local	Musanze	Payment records per ticket
Staff	Local	Musanze	Staff assigned to events
Activity	Local	Musanze	Event-specific activity schedule
Example (Venue table):
CREATE TABLE Venue (
  VenueID INT PRIMARY KEY,
  VenueName VARCHAR2(100),
  VenueLocation VARCHAR2(100) CHECK (VenueLocation = 'Musanze')
);
________________________________________
Q2 — Database Link and Distributed Join
Demonstrates creation of database links and distributed joins between schemas.
For example, querying customer names across Musanze (remote) and Kigali (local):
SELECT e.Title, c.FullName
FROM BranchDB_MUSANZE.Event@DBLINK_KIGALI e
JOIN BranchDB_KIGALI.Customer c ON e.EventID = c.CustomerID;
Cross-schema SELECT privileges were granted:
GRANT SELECT ON BranchDB_MUSANZE.Organizer TO BranchDB_KIGALI;
GRANT SELECT ON BranchDB_MUSANZE.Event TO BranchDB_KIGALI;
________________________________________
 Q3 — Parallel vs. Serial Query Execution
A large dataset (Orders table with 100,000+ rows) was used to compare parallel query execution with serial execution.
Run	Execution Type	Time (s)	Observations
Run 1	Parallel	277	Initial overhead due to cold cache and I/O
Run 2	Parallel (Cached)	159	Improved thread utilization
Parallelism reduced elapsed time by distributing work across multiple threads.
________________________________________
 Q4 — Distributed Transaction with Atomic Commit
A PL/SQL block inserts data into both local and remote tables using database links.
Oracle’s Two-Phase Commit Protocol (2PC) ensures atomicity.
Verification:
SELECT * FROM DBA_2PC_PENDING;
 No pending transactions — confirming successful distributed atomic commit.
________________________________________
 Q5 — Distributed Rollback and Recovery
To simulate failure:
1.	Disable remote listener (disconnect Musanze).
2.	Execute distributed PL/SQL insert.
3.	Commit fails — pending transaction recorded.
4.	Resolve with:
ROLLBACK FORCE 'Transaction_ID';
This confirms robust rollback recovery in a distributed environment.
________________________________________
 Q6 — Lock Conflict Demonstration
Two sessions update the same record from different nodes to trigger lock contention.
Observation	Description
Session A	Holds lock (MODE_HELD = Exclusive) for ~6min via DBMS_LOCK.SLEEP
Session B	Waits (MODE_REQUESTED = Exclusive) until A commits
Result	Session A blocks; B succeeds instantly after release
Key diagnostic columns:
LOCK_TYPE, MODE_HELD, MODE_REQUESTED, BLOCKING_OTHERS
________________________________________
 Q7 — Parallel Data Loading / ETL Simulation
Demonstrated parallel DML aggregation on the Ticket table.
Mode	Execution Time	Gain
Serial	Base time	—
Parallel	0.006s faster	Small gain due to dataset size
Used PARALLEL DML to aggregate ticket revenue per event.
________________________________________
 Q8 — Three-Tier Client–Server Architecture
Tier	Function	Example Technologies
Presentation	User interface	HTML, CSS, JS, Oracle APEX, JavaFX
Application	Business logic & validation	PL/SQL, Java EE, Spring Boot, Node.js
Database	Data storage & transaction control	Oracle 18c+, DB Links
________________________________________
 Q9 — Distributed Query Optimization
Used EXPLAIN PLAN and DBMS_XPLAN.DISPLAY to analyze distributed join execution.
Oracle’s optimizer reduces remote data transfer via predicate pushdown and join filtering.
________________________________________
 Q10 — Centralized vs Parallel vs Distributed Query Comparison
Compared three query modes using AUTOTRACE:
Mode	Performance	Scalability	I/O Cost
Centralized	Moderate	Limited	Low
Parallel	Best	High	Optimized
Distributed	Slowest	Moderate	High (network overhead)
Half-Page Summary
Parallel queries achieved the best efficiency and scalability, while distributed queries suffered from network latency and data movement cost.
Careful design — including predicate filters and indexing — is essential to optimize distributed systems.
________________________________________
 Conclusion
This assignment demonstrates the complete lifecycle of distributed database management:
•	Multi-node schema creation with fragmentation and replication
•	Database link-based data sharing
•	Two-phase commit for distributed atomicity
•	Lock handling, recovery, and parallel DML
•	Query optimization for scalability and efficiency
The system models a real-world distributed Event Management System connecting Musanze and Kigali database nodes.

 Entity Relationship Diagram (ERD)
Based ERD Representation
ORGANIZER (OrganizerID PK)
    ├──< EVENT (EventID PK, OrganizerID FK, VenueID FK)
    │       ├──< TICKET (TicketID PK, EventID FK, CustomerID FK)
    │       │       └──< PAYMENT (PaymentID PK, TicketID FK)
    │       ├──< STAFF (StaffID PK, EventID FK)
    │       └──< ACTIVITY (ActivityID PK, EventID FK)
    │
    └──< VENUE (VenueID PK)
CUSTOMER (CustomerID PK)
Relationship Summary
Relationship	Type	Description
ORGANIZER → EVENT	1:N	One organizer manages many events
VENUE → EVENT	1:N	Each venue hosts multiple events
EVENT → TICKET	1:N	Events can issue multiple tickets
CUSTOMER → TICKET	1:N	Customers can buy multiple tickets
TICKET → PAYMENT	1:1 or 1:N	One or multiple payments per ticket
EVENT → STAFF / ACTIVITY	1:N	Staff and activities tied to each event
________________________________________
 Distributed System Architecture Diagram
Text-Based Layout
                  ┌───────────────────────────┐
                  │   CLIENT APPLICATIONS     │
                  │ (Web, Desktop, Mobile UI) │
                  └────────────┬──────────────┘
                               │
                               ▼
                 ┌──────────────────────────────┐
                 │  APPLICATION SERVER / API    │
                 │  (PL/SQL, Java, Node.js)     │
                 └────────────┬─────────────────┘
                               │
        ┌──────────────────────┼────────────────────────┐
        ▼                      ▼                        ▼
┌─────────────────┐   ┌─────────────────┐      ┌─────────────────┐
│ BRANCHDB_KIGALI │   │ BRANCHDB_MUSANZE│      │  REMOTE CLIENT  │
│  (Central Node) │   │  (North Node)   │      │   (Read Access) │
│  - Customer     │   │  - Event        │      │ - Reporting App │
│  - Organizer    │   │  - Venue        │      │ - API Gateway   │
│  - Synonyms     │   │  - Ticket       │      └─────────────────┘
│  - DB Link to A │<──>│  - Payment     │
└─────────────────┘   └─────────────────┘
         ▲
         │ Distributed Query / 2PC / Parallel DML
         ▼
    Data Integrity & Synchronization

