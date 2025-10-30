
 Event Booking and Ticketing Platform

This project presents a **distributed PostgreSQL-based Event Booking and Ticketing Platform** designed for scalability, reliability, and fault tolerance. It manages events, ticket sales, customer information, and payments while ensuring strong data integrity, consistency, and high performance across multiple database nodes.

Objectives

- Provide a robust distributed database solution tailored for event booking operations.
- Track ticket sales, monitor revenue, and enforce business rules.
- Prevent overbooking and ensure transactional integrity.
- Demonstrate PostgreSQL’s advanced capabilities in a real-world distributed system.

Architecture Overview

Distributed Data Model: Two PostgreSQL instances — `event_node_a` and `event_node_b`.
  - Tickets are horizontally fragmented by ticket ID parity:
    - Even IDs → `ticket_a` on `event_node_a`
    - Odd IDs → `ticket_b` on `event_node_b`
Supporting Entities: Organizers, venues, events, and customers are structured to support distribution.
Payments: All transactions are recorded on `event_node_b`.
Specialized Tables:
  - `business_limits`: Enforces constraints
  - `hierarchy`: Supports recursive relationships
  - `triple`: Enables semantic inference
  - `ticket_audit`: Provides auditing

Technical Highlights

1.oreign Data Wrappers (FDW): Allow cross-node queries and distributed joins via the unified `ticket_all` view.
2.wo-Phase Commit (2PC): Guarantees atomicity across nodes.
3.Triggers & Constraints: Enforce business logic and prevent invalid transactions.
4.Recursive CTEs: Enable hierarchical roll-ups and semantic inference.
5.Auditing & Reporting: Unified reporting and financial auditing built-in.

 Features

- Seamless ticket management across nodes.
- Unified reporting via `ticket_all` view.
- Automatic enforcement of business rules.
- High concurrency and fault tolerance.
- Foundation for future enhancements:
  - Overbooking prevention
  - Advanced analytics
  - Cloud deployment

 Project Structure

root/ ├── README.md ├── .env.example ├── sql/ │ ├── setup_event_node_a.sql │ └── setup_event_node_b.sql └── docs/ └── setup_guide.md (placeholder)
Code

Requirements

- PostgreSQL 18
- Superuser access
- `psql` client

Setup Instructions

1. Install PostgreSQL 18 and ensure `psql` is available.
2. Run setup scripts in the `sql/` folder to initialize both nodes.
3. Use the `.env.example` to configure environment variables.
4. Query the `ticket_all` view or run sample distributed transactions to verify functionality.

 Author

Authored by **Claire Marie**, Master's Student in Data Science, as part of the **Advanced Database Technology** final exam project.

Let me know if you'd like this formatted into a downloadable Markdown file or need help generating ER diagrams or setup instructions to accompany it.
220020603 ADVANCED DATABASE FINAL EXAM (SectionA&SectionB).pdf
PDF
GIVE THE README FILE
Here’s a complete and professional README.md file that integrates both your project overview and the final exam implementation details. It’s formatted for clarity, reproducibility, and presentation in a GitHub or academic submission context:
md
 Event Booking and Ticketing Platform

A distributed PostgreSQL-based system designed for scalable, fault-tolerant event management. It handles venues, organizers, customers, ticketing, and payments across two database nodes, enforcing business rules and ensuring transactional integrity.



Project Overview

- Architecture: Two PostgreSQL instances — `event_node_a` and `event_node_b`
- Fragmentation Strategy:
  - Horizontal Fragmentation of `ticket` table:
    - Even `ticket_id` → `ticket_a` on `event_node_a`
    - Odd `ticket_id` → `ticket_b` on `event_node_b`
- Cross-node Access: Foreign Data Wrapper (FDW) and `proj_link` server
- Unified View: `ticket_all` created on `event_node_a` via `UNION ALL`
- Business Logic**: Enforced via constraints, triggers, and recursive CTEs
- Recovery**: Two-phase commit (2PC) with rollback handling
---

 ER Diagram (Logical)

--text
Venue(VenueID, VenueName, Location, Capacity, Contact)
Organizer(OrganizerID, FullName, Company, Email, Phone)
Event(EventID, OrganizerID, VenueID, Title, EventDate, Category)
Customer(CustomerID, FullName, Contact, Email, City)
Ticket(TicketID, EventID, CustomerID, SeatNo, Price, Status)
Payment(PaymentID, TicketID, Amount, PaymentDate, Method)
	Relationships:
1	Organizer → Event (1:N)
2	Venue → Event (1:N)
3	Event → Ticket (1:N)
5	Customer → Ticket (1:N)
5	Ticket → Payment (1:1)
 Setup Instructions
1.	Create Databases:
	-event_node_a (local)
	-event_node_b (remote)
2.	Create Fragmented Tables:
-	ticket_a on Node A (even IDs)
-	ticket_b on Node B (odd IDs)
3.	Insert Sample Rows:
-	≤10 rows total across both fragments
4.	Create FDW Link:
sql
CREATE SERVER proj_link FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', port '5432', dbname 'event_node_b');
CREATE USER MAPPING FOR CURRENT_USER SERVER proj_link;
5.	Import Foreign Tables:
sql
IMPORT FOREIGN SCHEMA public LIMIT TO (ticket_b) FROM SERVER proj_link INTO public;
6.	Create Unified View:
sql
CREATE VIEW ticket_all AS
SELECT * FROM ticket_a
UNION ALL
SELECT * FROM ticket_b;
 Verification Queries
•	Row Count & Checksum:
sql
SELECT COUNT(*) FROM ticket_all;
SELECT SUM(MOD(ticket_id, 97)) FROM ticket_all;
•	Cross-node Join Example:
sql
SELECT t.ticket_id, t.event_id, t.customer_id, c.email, t.price, t.status
FROM ticket_a t
JOIN customer c ON t.customer_id = c.customer_id
WHERE t.status = 'CONFIRMED';
 Performance Comparison
Mode	Planning Time	Execution Time	Notes
Serial	1.623 ms	2.353 ms	max_parallel_workers = 0
Parallel	0.266 ms	1.936 ms	Forced parallel aggregation
 Two-Phase Commit Example
sql
DO $$
BEGIN
  INSERT INTO ticket_a (...) VALUES (...);
  INSERT INTO payment@proj_link (...) VALUES (...);
  COMMIT;
END $$;
•	Failure Simulation: Insert invalid method → triggers rollback
•	Recovery: Use ROLLBACK FORCE if needed
 
 Project Structure

root/
├── README.md
├── .env.example
├── sql/
│   ├── setup_event_node_a.sql
│   └── setup_event_node_b.sql
└── docs/
    └── setup_guide.md
 
Marie Claire Mukashyaka Reg: 220020603 University of Rwanda – ACE DS Advanced Database Technology Final Exam Date: 28 October 2025

