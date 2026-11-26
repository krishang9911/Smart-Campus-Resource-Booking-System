# Analytical Queries, Query Optimization, NoSQL Extension & Full-Stack Integration

**Project:** Smart Campus Resource & Lab Booking System  
**Branch:** `partner-b-analytics-nosql`  
**Contributor:** Partner B  

---

## 1. Realistic Seed Dataset Engineering (`database/02_seed.sql`)

To validate transactional workflows, analytical queries, and query optimizer execution plans against representative campus workloads, a deterministic relational dataset (`250+` records across all 13 normalized tables) is structured with referential integrity across all parent-child relationships:

* **Master & Reference Entities:** Populates system roles (`ROLE`: Student, Faculty, Staff_admin with distinct `max_booking_hours` and `requires_approval` flags), academic departments (`DEPARTMENT`), physical rooms/labs (`LOCATION`, including `Lab-305`), and resource classifications (`RESOURCE_TYPE`).
* **Catalog & User Population:** Seeds campus users (`USER`) across Student, Faculty, and Staff_admin specializations alongside lab/room inventory (`RESOURCE`, including `Lab-305` and specialized equipment).
* **Transactional & Lifecycle Records:** Generates multi-item reservations (`BOOKING` and `BOOKING_ITEM`) spanning `Pending`, `Confirmed`, `Completed`, and `Cancelled` states, paired with corresponding `APPROVAL` decisions, `MAINTENANCE` windows, `USAGE_LOG` check-in/check-out records, `CANCELLATION` entries, and immutable `AUDIT_LOG` transitions.
* **Verification:** Row-count integrity across all 13 relations is verified via `SELECT COUNT(*)` checks (`screenshots/`).

---

## 2. Procedural Logic & Utilization Metrics (`database/04_queries_and_functions.sql`)

### 2.1 Transactional Approval Procedure (`sp_approve_booking`)
`sp_approve_booking` encapsulates administrative booking sign-off inside an atomic transaction (`START TRANSACTION`, `COMMIT`, and `ROLLBACK` via `EXIT HANDLER FOR SQLEXCEPTION`):

1. **State & Existence Validation:** Locks and verifies that the target `booking_id` exists and is currently in `Pending` status.
2. **Conflict & Maintenance Guard:** Before approving, verifies that none of the booking's reserved `BOOKING_ITEM` intervals overlap with existing `Confirmed` or `Completed` bookings (`new_start < existing_end AND new_end > existing_start`) or active `MAINTENANCE` schedules for the same `resource_id`.
3. **Atomic Multi-Table Update:** Updates `BOOKING.booking_status`, inserts/upserts the coordinator's decision into `APPROVAL`, and appends a structured JSON audit trail entry into `AUDIT_LOG`.

### 2.2 Scalar Utilization Function (`fn_resource_utilization`)
`fn_resource_utilization(p_resource_id, p_window_start, p_window_end)` computes the percentage of scheduled utilization for a given resource within an arbitrary time window:

$$\text{Utilization (\%)} = \frac{\sum \text{Booked Minutes within } [T_{\text{start}}, T_{\text{end}}]}{\text{Total Window Minutes } (T_{\text{end}} - T_{\text{start}})} \times 100$$

* Clamps each overlapping `Confirmed` or `Completed` `BOOKING_ITEM` interval to `[p_window_start, p_window_end]` using `GREATEST` and `LEAST` so bookings straddling window boundaries are measured accurately without overcounting.

---

## 3. Complex Analytical Queries & Reporting Layer (`database/04_queries_and_functions.sql`)

| Query # | Analytical Objective | SQL Constructs Used | Business & Operational Insight |
| :--- | :--- | :--- | :--- |
| **Query 1** | **Interval Availability Search** | `NOT EXISTS`, interval overlap predicate, multi-table `JOIN` | Identifies resources free of conflicting active bookings and maintenance during a requested slot. |
| **Query 2** | **Booking Conflict Detection** | Self-join on `BOOKING_ITEM` (`bi1.item_id < bi2.item_id`), `INNER JOIN` | Audits overlapping time intervals across active/confirmed reservations for the same `resource_id`. |
| **Query 3** | **Resource Utilization Ranking** | `DENSE_RANK()`, `RANK()`, `SUM(TIMESTAMPDIFF(...))`, `LEFT JOIN` | Ranks labs and equipment by total confirmed/completed booking hours within each resource category. |
| **Query 4** | **Above-Average Department Usage** | Common Table Expression (`CTE`), scalar subquery comparison (`> AVG(...)`) | Isolates departments whose total resource utilization exceeds the institutional campus average. |
| **Query 5** | **Monthly Utilization Trend** | Multi-stage `CTE`, `DATE_FORMAT`, `LAG() OVER (...)` | Tracks month-over-month booking hours and utilization deltas to highlight seasonal academic peaks. |
| **Query 6** | **Live Availability View** | `CREATE OR REPLACE VIEW v_current_availability` | Exposes real-time resource availability (`Available`, `In Use`, `Under Maintenance`) for dashboards and APIs. |
| **Query 7** | **Requested vs. Approved Set Comparison** | Anti-join (`LEFT JOIN ... WHERE approved.resource_id IS NULL`) | Surfaces resources that were requested in bookings (`Pending`/`Rejected`/`Cancelled`) but never approved. |

---

## 4. Query Optimization & `EXPLAIN ANALYZE` Benchmarking

### 4.1 Bottleneck Identification
Availability and conflict queries filter `BOOKING_ITEM` by `resource_id` and evaluate range predicates on `(start_time, end_time)`. Without a supporting composite index, MySQL falls back to scanning broad row sets on `BOOKING_ITEM` (`type: ALL` or suboptimal single-column index lookup) followed by filter evaluation.

### 4.2 Composite Index Design
```sql
CREATE INDEX idx_booking_item_res_time
ON BOOKING_ITEM (resource_id, start_time, end_time);
```

* **Column Ordering Rationale:** `resource_id` leads as the equality predicate (`=`), narrowing search space directly to a single resource's B+Tree leaf range, followed by `start_time` and `end_time` to accelerate temporal range filtering and enable index-only / index-condition pushdown evaluation.

### 4.3 Benchmark Verification (`screenshots/`)
* **Baseline (`explain_before_index.png`):** Captures `EXPLAIN ANALYZE` execution cost, row estimates, and scan type prior to creating `idx_booking_item_res_time`.
* **Post-Index (`explain_after_index.png`):** Captures `EXPLAIN ANALYZE` after index creation, demonstrating indexed range access (`ref` / `range` on `idx_booking_item_res_time`) and reduced row examination cost.

---

## 5. Polyglot Persistence: MongoDB Maintenance & Inspection Extension (`nosql/mongo_demo.js`)

While structured reservations and ACID conflict enforcement reside in MySQL, unstructured equipment inspection logs, technician notes, sensor readings, and variable checklists are modeled in MongoDB (`smart_campus_nosql.maintenance_reports`):

* **Schema Flexibility Rationale:** Different resource types (e.g., chemistry fume hoods vs. compute clusters vs. AV halls) require heterogeneous inspection fields that would force sparse `NULL` columns or EAV anti-patterns in relational tables.
* **Dataset & Operations (`nosql/mongo_demo.js`):**
  * Inserts `15` rich `maintenance_reports` documents referencing relational `resource_id` / `resource_code` keys (including `Lab-305`) with nested `inspection_checklist`, `parts_replaced`, and `severity` fields.
  * Demonstrates full **CRUD** lifecycle (`insertMany`, `find` with nested filters, `updateOne` with `$push` / `$set`, and `deleteOne`).
  * Executes an **Aggregation Pipeline (`$match` → `$group` → `$sort`)** computing total incident counts, average downtime/repair cost, and unresolved severity counts grouped by `resource_code` and `issue_category`.

---

## 6. Frontend Integration & End-to-End Contract (`app/index.html`)

A lightweight single-page frontend (`app/index.html`) connects end users to Partner A's REST API endpoints without bypassing database-level triggers or stored procedures:

* **Resource Discovery (`GET /api/resources`):** Fetches live resource metadata, location details, and availability status to populate the interactive resource catalog and booking selector.
* **Atomic Reservation Submission (`POST /api/bookings`):** Submits `user_id`, `purpose`, and selected `items` (`resource_id`, `start_time`, `end_time`, `quantity`) as JSON, surfacing clear UI feedback for both successful confirmations and database-enforced conflict/maintenance rejections.

---

## 7. Cross-Partner Merge & Verification Checklist

* [x] **`database/04_queries_and_functions.sql`:** `sp_approve_booking`, `fn_resource_utilization`, Queries 1–7, `v_current_availability`, and `idx_booking_item_res_time` benchmark SQL drafted and verified.
* [ ] **`database/02_seed.sql` & `screenshots/`:** Finalize 250+ row seed dataset (including `Lab-305`), verify `APPROVAL` column naming (`approver_id` vs. `approved_by`) against `database/01_schema.sql`, and commit `EXPLAIN ANALYZE` + `SELECT COUNT(*)` screenshots.
* [ ] **`nosql/mongo_demo.js` & `app/index.html`:** Commit MongoDB demo script and wire `app/index.html` to Partner A's finalized `GET /api/resources` and `POST /api/bookings` JSON contract.
* [ ] **Final Report Merge:** Combine `docs/Report_Part_A.md` and `docs/Report_Part_B.md` into `docs/Final_Project_Report.md` during the final pull request merge to `main`.