# Screenshots Directory — Person B Deliverables

Save the following screenshots in this folder for the capstone submission:

1. **`01_seed_record_counts.png`**
   - Execute the verification query at the bottom of `database/02_seed.sql` in MySQL Workbench or terminal.
   - Capture the result showing 300+ total records across all 13 tables.

2. **`02_sp_approval_success.png`**
   - Screenshot showing execution of `sp_approve_booking` successfully approving a booking.

3. **`03_sp_approval_conflict_rollback.png`**
   - Screenshot showing conflict detection and rollback when approving an overlapping slot.

4. **`04_fn_resource_utilization.png`**
   - Screenshot showing the output of `SELECT fn_resource_utilization(...)`.

5. **`05_complex_queries_outputs.png`**
   - Screenshots of Query 1 (Availability), Query 3 (Ranking), and Query 4 (CTE above average).

6. **`06_explain_before_index.png`**
   - Screenshot of baseline `EXPLAIN ANALYZE` showing full table scan (`ALL`).

7. **`07_explain_after_index.png`**
   - Screenshot of post-index `EXPLAIN ANALYZE` showing composite index scan (`idx_booking_item_resource_time`).

8. **`08_mongodb_crud_aggregation.png`**
   - Output screenshot of running `mongosh nosql/mongo_demo.js` showing 15 inserted documents, CRUD outputs, and `$group` aggregation summary.

9. **`09_web_app_catalog.png`** & **`10_web_app_booking.png`**
   - Browser screenshots of `app/index.html` showing Resource Catalog and My Reservations tab.
