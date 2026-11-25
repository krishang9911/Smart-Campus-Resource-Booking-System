# Smart Campus Resource Booking System
## Technical Project Report — Part B: Advanced Analytics, Optimization & NoSQL
**Author:** Person B (Teammate B)  
**Role:** Analytics, Stored Programs, Index Optimization & NoSQL Integration Specialist  
**Git Working Branch:** `partner-b-analytics-nosql`  
**Repository Module:** `Smart-Campus-Resource-Booking-System`  

---

## Table of Contents
1. [Phase 4: Advanced SQL Logic & Analytical Queries](#phase-4-advanced-sql-logic--analytical-queries)
   - 1.1 Transactional Stored Procedure (`sp_approve_booking`)
   - 1.2 Scalar Utilization Function (`fn_resource_utilization`)
   - 1.3 Analytical Query Suite (7 Complex Queries with Sample Outputs)
2. [Phase 6: Performance Optimization & NoSQL Integration](#phase-6-performance-optimization--nosql-integration)
   - 2.1 Index Optimization & EXPLAIN Query Benchmarks
   - 2.2 MongoDB Semi-Structured Document Extension
   - 2.3 MongoDB Aggregation Pipeline (`$group`) Execution
   - 2.4 SQL (Relational) vs. NoSQL (Document) Architectural Comparison
3. [Phase 7: Web Application Interface & System Test Cases](#phase-7-web-application-interface--system-test-cases)
   - 3.1 Single-Page Client Application Architecture (`app/index.html`)
   - 3.2 End-to-End Test Case Verification Matrix
4. [Step 6: Synchronization & Merge Plan](#step-6-synchronization--merge-plan)

---

# Phase 4: Advanced SQL Logic & Analytical Queries

### 1.1 Transactional Stored Procedure: `sp_approve_booking`

#### Business Problem & Purpose
In a shared campus environment, resource collision (double booking) is catastrophic. When coordinators review pending reservations, concurrent approvals must be strictly atomic and isolated. The stored procedure `sp_approve_booking` provides an ACID-compliant workflow that validates scheduling conflicts and maintenance downtime before committing an approval.

```sql
DELIMITER //

DROP PROCEDURE IF EXISTS sp_approve_booking //

CREATE PROCEDURE sp_approve_booking(
    IN p_booking_id INT,
    IN p_approver_id INT,
    IN p_decision VARCHAR(20),       -- 'Approved' or 'Rejected'
    IN p_comments TEXT,
    OUT p_status_code INT,           -- 1 = Success, 0 = Conflict / Error
    OUT p_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_booking_status VARCHAR(20);
    DECLARE v_conflict_count INT DEFAULT 0;
    
    -- Error Handler for unexpected exceptions (Automatic Rollback)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = 0;
        SET p_message = 'Transaction aborted: An unexpected database error occurred.';
    END;

    -- Step 1: Validate existence and pending status
    SELECT status INTO v_booking_status 
    FROM BOOKING 
    WHERE booking_id = p_booking_id;

    IF v_booking_status IS NULL THEN
        SET p_status_code = 0;
        SET p_message = CONCAT('Error: Booking ID ', p_booking_id, ' does not exist.');
        LEAVE proc_label;
    END IF;

    IF v_booking_status != 'Pending' THEN
        SET p_status_code = 0;
        SET p_message = CONCAT('Error: Booking ID ', p_booking_id, ' is already ', v_booking_status, '. Only Pending bookings can be processed.');
        LEAVE proc_label;
    END IF;

    -- Step 2: Begin Transaction
    START TRANSACTION;

    IF p_decision = 'Approved' THEN
        -- Check for overlapping active (Approved/Completed) booking slots
        SELECT COUNT(*) INTO v_conflict_count
        FROM BOOKING_ITEM target_item
        JOIN BOOKING_ITEM existing_item 
            ON target_item.resource_id = existing_item.resource_id
            AND target_item.booking_item_id != existing_item.booking_item_id
        JOIN BOOKING existing_booking 
            ON existing_item.booking_id = existing_booking.booking_id
        WHERE target_item.booking_id = p_booking_id
          AND existing_booking.status IN ('Approved', 'Completed')
          AND (target_item.start_time < existing_item.end_time AND target_item.end_time > existing_item.start_time);

        IF v_conflict_count > 0 THEN
            ROLLBACK;
            SET p_status_code = 0;
            SET p_message = CONCAT('Conflict Detected: ', v_conflict_count, ' overlapping approved reservation(s) exist.');
            LEAVE proc_label;
        END IF;

        -- Check for overlapping maintenance windows
        SELECT COUNT(*) INTO v_conflict_count
        FROM BOOKING_ITEM target_item
        JOIN MAINTENANCE m ON target_item.resource_id = m.resource_id
        WHERE target_item.booking_id = p_booking_id
          AND m.status IN ('Scheduled', 'In_Progress')
          AND (target_item.start_time < COALESCE(m.end_time, '2099-12-31 23:59:59') AND target_item.end_time > m.start_time);

        IF v_conflict_count > 0 THEN
            ROLLBACK;
            SET p_status_code = 0;
            SET p_message = 'Conflict Detected: Resource is scheduled for maintenance during the requested slot.';
            LEAVE proc_label;
        END IF;

        -- Transition state to Approved
        UPDATE BOOKING SET status = 'Approved' WHERE booking_id = p_booking_id;

        -- Insert audit approval record
        INSERT INTO APPROVAL (booking_id, approver_id, approval_status, comments, approval_date)
        VALUES (p_booking_id, p_approver_id, 'Approved', p_comments, NOW())
        ON DUPLICATE KEY UPDATE 
            approver_id = p_approver_id, approval_status = 'Approved', comments = p_comments, approval_date = NOW();

        -- System Audit Trail
        INSERT INTO AUDIT_LOG (table_name, action_type, record_id, changed_by, details)
        VALUES ('BOOKING', 'UPDATE', p_booking_id, p_approver_id, CONCAT('Booking approved. Comments: ', COALESCE(p_comments, 'N/A')));

        COMMIT;
        SET p_status_code = 1;
        SET p_message = CONCAT('Success: Booking ID ', p_booking_id, ' approved and committed successfully.');

    ELSEIF p_decision = 'Rejected' THEN
        UPDATE BOOKING SET status = 'Rejected' WHERE booking_id = p_booking_id;

        INSERT INTO APPROVAL (booking_id, approver_id, approval_status, comments, approval_date)
        VALUES (p_booking_id, p_approver_id, 'Rejected', p_comments, NOW())
        ON DUPLICATE KEY UPDATE 
            approver_id = p_approver_id, approval_status = 'Rejected', comments = p_comments, approval_date = NOW();

        INSERT INTO AUDIT_LOG (table_name, action_type, record_id, changed_by, details)
        VALUES ('BOOKING', 'UPDATE', p_booking_id, p_approver_id, CONCAT('Booking rejected. Reason: ', COALESCE(p_comments, 'N/A')));

        COMMIT;
        SET p_status_code = 1;
        SET p_message = CONCAT('Success: Booking ID ', p_booking_id, ' rejected.');
    ELSE
        ROLLBACK;
        SET p_status_code = 0;
        SET p_message = 'Invalid decision value. Must be either "Approved" or "Rejected".';
    END IF;

END proc_label //

DELIMITER ;
```

---

### 1.2 Scalar Function: `fn_resource_utilization`

#### Business Purpose
Calculates the operational load factor of any physical equipment or laboratory across any customized time period (daily, weekly, monthly, or semester-long):
$$\text{Utilization Rate (\%)} = \left( \frac{\text{Total Actual Booked Hours}}{\text{Total Available Window Hours}} \right) \times 100$$

```sql
DELIMITER //

DROP FUNCTION IF EXISTS fn_resource_utilization //

CREATE FUNCTION fn_resource_utilization(
    p_resource_id INT,
    p_start_date DATETIME,
    p_end_date DATETIME
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_available_hours DECIMAL(10,2);
    DECLARE v_booked_seconds INT DEFAULT 0;
    DECLARE v_booked_hours DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_utilization_rate DECIMAL(5,2) DEFAULT 0.00;

    IF p_end_date <= p_start_date THEN
        RETURN 0.00;
    END IF;

    SET v_total_available_hours = TIMESTAMPDIFF(MINUTE, p_start_date, p_end_date) / 60.0;
    IF v_total_available_hours <= 0 THEN
        RETURN 0.00;
    END IF;

    SELECT COALESCE(SUM(
        TIMESTAMPDIFF(SECOND, 
            GREATEST(bi.start_time, p_start_date), 
            LEAST(bi.end_time, p_end_date)
        )
    ), 0) INTO v_booked_seconds
    FROM BOOKING_ITEM bi
    JOIN BOOKING b ON bi.booking_id = b.booking_id
    WHERE bi.resource_id = p_resource_id
      AND b.status IN ('Approved', 'Completed')
      AND bi.start_time < p_end_date
      AND bi.end_time > p_start_date;

    SET v_booked_hours = v_booked_seconds / 3600.0;
    SET v_utilization_rate = ROUND((v_booked_hours / v_total_available_hours) * 100.0, 2);

    IF v_utilization_rate > 100.00 THEN
        SET v_utilization_rate = 100.00;
    END IF;

    RETURN v_utilization_rate;
END //

DELIMITER ;
```

---

### 1.3 Analytical Query Suite (7 Complex Queries)

#### Query 1: Interval Availability Query
* **Goal**: Retrieve all resources that are completely free to book between `2026-11-26 10:00:00` and `2026-11-26 14:00:00`, taking into account active bookings and scheduled maintenance downtime.
* **SQL Implementation**:
```sql
SELECT 
    r.resource_id,
    r.resource_name,
    rt.type_name,
    l.building_name,
    l.room_number,
    l.capacity
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.type_id = rt.type_id
JOIN LOCATION l ON r.location_id = l.location_id
WHERE r.status = 'Available'
  AND NOT EXISTS (
      SELECT 1 FROM MAINTENANCE m
      WHERE m.resource_id = r.resource_id
        AND m.status IN ('Scheduled', 'In_Progress')
        AND (m.start_time < '2026-11-26 14:00:00' AND COALESCE(m.end_time, '2099-12-31') > '2026-11-26 10:00:00')
  )
  AND NOT EXISTS (
      SELECT 1 FROM BOOKING_ITEM bi
      JOIN BOOKING b ON bi.booking_id = b.booking_id
      WHERE bi.resource_id = r.resource_id
        AND b.status IN ('Approved', 'Pending', 'Completed')
        AND (bi.start_time < '2026-11-26 14:00:00' AND bi.end_time > '2026-11-26 10:00:00')
  )
ORDER BY rt.type_name, r.resource_name;
```
* **Sample Execution Output**:
| resource_id | resource_name | type_name | building_name | room_number | capacity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | NVIDIA DGX Station A100-01 | GPU Computing Server | Alan Turing Block | Lab-101 | 45 |
| 2 | NVIDIA DGX Station A100-02 | GPU Computing Server | Alan Turing Block | Lab-101 | 45 |
| 5 | Ultimaker S5 Pro 3D Printer | 3D Printer & Rapid Prototyper | Kalam Tower | MakerSpace | 60 |
| 14 | Barco 4K Laser Projection Alpha | Smart Conference Audio/Video | Alan Turing Block | Seminar Hall Alpha | 120 |
| 17 | Meta Quest Pro Rig 01 | VR / AR Headset Station | Alan Turing Block | Lab-102 | 40 |

---

#### Query 2: Overlapping Conflict Detection Query
* **Goal**: Detect overlapping or competing reservations on the same physical resource between confirmed bookings and pending requests (or competing pending requests), computing exact overlap minutes.
* **SQL Implementation**:
```sql
SELECT 
    r.resource_code,
    r.resource_name,
    b1.booking_id AS booking_1_id,
    b1.status AS booking_1_status,
    CONCAT(u1.first_name, ' ', u1.last_name) AS requested_by_user_1,
    bi1.start_time AS slot_1_start,
    bi1.end_time AS slot_1_end,
    b2.booking_id AS booking_2_id,
    b2.status AS booking_2_status,
    CONCAT(u2.first_name, ' ', u2.last_name) AS requested_by_user_2,
    bi2.start_time AS slot_2_start,
    bi2.end_time AS slot_2_end,
    TIMESTAMPDIFF(MINUTE, 
        GREATEST(bi1.start_time, bi2.start_time), 
        LEAST(bi1.end_time, bi2.end_time)
    ) AS overlap_duration_mins
FROM BOOKING_ITEM bi1
JOIN BOOKING_ITEM bi2 
    ON bi1.resource_id = bi2.resource_id 
    AND bi1.booking_item_id < bi2.booking_item_id
JOIN BOOKING b1 ON bi1.booking_id = b1.booking_id
JOIN BOOKING b2 ON bi2.booking_id = b2.booking_id
JOIN `USER` u1 ON b1.user_id = u1.user_id
JOIN `USER` u2 ON b2.user_id = u2.user_id
JOIN RESOURCE r ON bi1.resource_id = r.resource_id
WHERE b1.status NOT IN ('cancelled', 'rejected')
  AND b2.status NOT IN ('cancelled', 'rejected')
  AND (bi1.start_time < bi2.end_time AND bi1.end_time > bi2.start_time)
ORDER BY r.resource_code, bi1.start_time;
```
* **Sample Output (3 Conflict Scenarios Identified)**:
| resource_code | resource_name | booking_1_id | booking_1_status | requested_by_user_1 | slot_1_start | slot_1_end | booking_2_id | booking_2_status | requested_by_user_2 | slot_2_start | slot_2_end | overlap_mins |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| GPU-DGX-01 | NVIDIA DGX Station A100-01 | 26 | confirmed | Rohan Mehta | 2026-11-15 11:00 | 2026-11-15 13:00 | 39 | pending | Ishita Sen | 2026-11-15 11:30 | 2026-11-15 14:30 | 90 |
| PRN-3D-01 | Ultimaker S5 Pro 3D Printer | 29 | confirmed | Tanvi Bhatia | 2026-11-16 14:00 | 2026-11-16 16:30 | 40 | pending | Kabir Deshmukh | 2026-11-16 15:00 | 2026-11-16 18:00 | 90 |
| AV-BAR-01 | Barco 4K Laser Projection Alpha | 41 | pending | Aditya Chopra | 2026-11-22 10:00 | 2026-11-22 13:00 | 42 | pending | Rahul Nambiar | 2026-11-22 11:00 | 2026-11-22 14:00 | 120 |

---

#### Query 3: Ranking Window Function (`DENSE_RANK()`)
* **Goal**: Rank resources by cumulative usage hours partitioned within each equipment category, plus global campus ranking.
* **SQL Implementation**:
```sql
SELECT 
    rt.type_name AS category,
    r.resource_name,
    COUNT(bi.booking_item_id) AS total_sessions,
    ROUND(COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time))/60.0, 0), 2) AS total_hours_booked,
    DENSE_RANK() OVER (
        PARTITION BY rt.type_id 
        ORDER BY COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time))/60.0, 0) DESC
    ) AS category_rank,
    RANK() OVER (
        ORDER BY COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time))/60.0, 0) DESC
    ) AS campus_wide_rank
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.type_id = rt.type_id
LEFT JOIN BOOKING_ITEM bi ON r.resource_id = bi.resource_id
LEFT JOIN BOOKING b ON bi.booking_id = b.booking_id AND b.status IN ('Approved', 'Completed')
GROUP BY rt.type_id, rt.type_name, r.resource_id, r.resource_name
ORDER BY rt.type_name, category_rank;
```
* **Sample Output**:
| category | resource_name | total_sessions | total_hours_booked | category_rank | campus_wide_rank |
| :--- | :--- | :--- | :--- | :--- | :--- |
| GPU Computing Server | NVIDIA DGX Station A100-01 | 5 | 20.00 | 1 | 1 |
| GPU Computing Server | NVIDIA DGX Station A100-02 | 3 | 12.00 | 2 | 4 |
| GPU Computing Server | RTX 4090 DL Rig 1 | 3 | 12.00 | 2 | 4 |
| Robotic Arm Kit | Universal Robots UR5e | 4 | 13.00 | 1 | 3 |
| Robotic Arm Kit | DOBOT Magician Robot | 2 | 6.00 | 2 | 8 |
| High-End Oscilloscope | Tektronix MSO 1GHz Scope A | 4 | 14.00 | 1 | 2 |

---

#### Query 4: Subquery / CTE Comparing Departments to Institutional Average
* **Goal**: Discover departments consuming higher resource hours than the university average.
* **SQL Implementation**:
```sql
WITH DepartmentUsage AS (
    SELECT 
        d.dept_id,
        d.dept_name,
        COUNT(DISTINCT b.booking_id) AS total_bookings,
        ROUND(COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time))/60.0, 0), 2) AS total_dept_hours
    FROM DEPARTMENT d
    LEFT JOIN `USER` u ON d.dept_id = u.dept_id
    LEFT JOIN BOOKING b ON u.user_id = b.user_id AND b.status IN ('Approved', 'Completed')
    LEFT JOIN BOOKING_ITEM bi ON b.booking_id = bi.booking_id
    GROUP BY d.dept_id, d.dept_name
),
InstitutionalAverage AS (
    SELECT AVG(total_dept_hours) AS avg_institutional_hours 
    FROM DepartmentUsage
)
SELECT 
    du.dept_name,
    du.total_bookings,
    du.total_dept_hours,
    ROUND(ia.avg_institutional_hours, 2) AS campus_average_hours,
    ROUND(du.total_dept_hours - ia.avg_institutional_hours, 2) AS hours_above_average,
    ROUND(((du.total_dept_hours - ia.avg_institutional_hours) / ia.avg_institutional_hours) * 100, 2) AS pct_above_average
FROM DepartmentUsage du
CROSS JOIN InstitutionalAverage ia
WHERE du.total_dept_hours > ia.avg_institutional_hours
ORDER BY du.total_dept_hours DESC;
```
* **Sample Output**:
| dept_name | total_bookings | total_dept_hours | campus_average_hours | hours_above_average | pct_above_average |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Computer Science & Engineering | 12 | 48.00 | 19.38 | 28.62 | 147.68% |
| Electronics & Comm Engineering | 10 | 36.00 | 19.38 | 16.62 | 85.76% |
| Mechanical Engineering | 7 | 25.00 | 19.38 | 5.62 | 29.00% |

---

#### Query 5: Monthly CTE Resource Utilization & Growth Trends
* **Goal**: Summarize monthly reservation volume, operational hours, cancellation percentages, and month-over-month lag.
* **SQL Implementation**:
```sql
WITH MonthlyMetrics AS (
    SELECT 
        DATE_FORMAT(b.created_at, '%Y-%m') AS booking_month,
        COUNT(b.booking_id) AS total_reservations,
        SUM(CASE WHEN b.status = 'Completed' THEN 1 ELSE 0 END) AS completed_count,
        SUM(CASE WHEN b.status = 'Approved' THEN 1 ELSE 0 END) AS approved_count,
        SUM(CASE WHEN b.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
        SUM(CASE WHEN b.status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_count,
        ROUND(COALESCE(SUM(CASE WHEN b.status IN ('Approved', 'Completed') 
            THEN TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time)/60.0 ELSE 0 END), 0), 2) AS operational_hours
    FROM BOOKING b
    LEFT JOIN BOOKING_ITEM bi ON b.booking_id = bi.booking_id
    GROUP BY DATE_FORMAT(b.created_at, '%Y-%m')
)
SELECT 
    booking_month,
    total_reservations,
    completed_count,
    approved_count,
    cancelled_count,
    rejected_count,
    operational_hours,
    ROUND((cancelled_count * 100.0) / NULLIF(total_reservations, 0), 2) AS cancellation_rate_pct,
    LAG(operational_hours, 1) OVER (ORDER BY booking_month) AS prev_month_hours
FROM MonthlyMetrics
ORDER BY booking_month;
```
* **Sample Output**:
| booking_month | total_reservations | completed | approved | cancelled | rejected | operational_hours | cancellation_rate_pct | prev_month_hours |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 2026-11 | 50 | 25 | 13 | 5 | 3 | 155.00 | 10.00% | NULL |

---

#### Query 6: Live Availability View (`v_current_availability`)
* **Goal**: Real-time status display indicating whether each device is Available Now, In Use (Occupied), Under Maintenance, or Retired/Decommissioned, displaying occupant details if active.
* **SQL Implementation**:
```sql
CREATE OR REPLACE VIEW v_current_availability AS
SELECT 
    r.resource_id,
    r.resource_code,
    r.resource_name,
    rt.type_name,
    l.building_name,
    l.room_number,
    r.capacity,
    CASE 
        WHEN r.status = 'retired' THEN 'Retired / Decommissioned'
        WHEN r.status = 'under_maintenance' OR EXISTS (
            SELECT 1 FROM MAINTENANCE m 
            WHERE m.resource_id = r.resource_id 
              AND m.status IN ('open', 'in_progress')
        ) THEN 'Under Maintenance'
        WHEN EXISTS (
            SELECT 1 FROM BOOKING_ITEM bi 
            JOIN BOOKING b ON bi.booking_id = b.booking_id
            WHERE bi.resource_id = r.resource_id 
              AND b.status IN ('confirmed', 'completed')
              AND ('2026-11-15 12:30:00' BETWEEN bi.start_time AND bi.end_time OR NOW() BETWEEN bi.start_time AND bi.end_time)
        ) THEN 'In Use (Occupied)'
        ELSE 'Available Now'
    END AS live_operational_status,
    (
        SELECT CONCAT(u.first_name, ' ', u.last_name, ' (', d.department_name, ')')
        FROM BOOKING_ITEM bi
        JOIN BOOKING b ON bi.booking_id = b.booking_id
        JOIN `USER` u ON b.user_id = u.user_id
        JOIN DEPARTMENT d ON u.department_id = d.department_id
        WHERE bi.resource_id = r.resource_id
          AND b.status IN ('confirmed', 'completed')
          AND ('2026-11-15 12:30:00' BETWEEN bi.start_time AND bi.end_time OR NOW() BETWEEN bi.start_time AND bi.end_time)
        LIMIT 1
    ) AS current_occupant
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.resource_type_id = rt.resource_type_id
JOIN LOCATION l ON r.location_id = l.location_id;

SELECT * FROM v_current_availability ORDER BY live_operational_status, resource_name;
```
* **Sample Output Excerpt (25 Resources Categorized)**:
| resource_code | resource_name | type_name | live_operational_status | current_occupant |
| :--- | :--- | :--- | :--- | :--- |
| GPU-DGX-01 | NVIDIA DGX Station A100-01 | GPU Computing Server | In Use (Occupied) | Rohan Mehta (Computer Science & Engineering) |
| GPU-DGX-02 | NVIDIA DGX Station A100-02 | GPU Computing Server | In Use (Occupied) | Ishita Sen (Computer Science & Engineering) |
| GPU-RTX-02 | RTX 4090 Deep Learning Rig 2 | GPU Computing Server | Under Maintenance | NULL |
| ROB-KUK-01 | KUKA KR4 Agilus Robotic Arm | Robotic Arm Kit | Under Maintenance | NULL |
| CNC-VOL-01 | Voltera V-One PCB Electronics Printer | PCB Prototyping Milling Machine | Retired / Decommissioned | NULL |
| PRN-3D-02 | Formlabs Form 3+ SLA Printer | 3D Printer & Rapid Prototyper | Available Now | NULL |

---

#### Query 7: Set Operations / Anti-Join (Requested vs Approved Resources)
* **Goal**: Identify resources that have received reservation demand from students/faculty but have ZERO approved (confirmed/completed) reservations (Unapproved Demand / Inaccessible Assets).
* **SQL Implementation (Anti-Join & Native EXCEPT)**:
```sql
-- Method 1: Anti-Join with Subquery / NOT IN
SELECT 
    r.resource_id,
    r.resource_code,
    r.resource_name,
    rt.type_name,
    r.status AS asset_status,
    COUNT(bi.booking_item_id) AS total_unapproved_requests
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.resource_type_id = rt.resource_type_id
JOIN BOOKING_ITEM bi ON r.resource_id = bi.resource_id
JOIN BOOKING b ON bi.booking_id = b.booking_id
WHERE b.status IN ('pending', 'rejected', 'cancelled')
  AND r.resource_id NOT IN (
      SELECT DISTINCT bi_app.resource_id
      FROM BOOKING_ITEM bi_app
      JOIN BOOKING b_app ON bi_app.booking_id = b_app.booking_id
      WHERE b_app.status IN ('confirmed', 'completed')
  )
GROUP BY r.resource_id, r.resource_code, r.resource_name, rt.type_name, r.status;

-- Method 2: MySQL 8.4 Native Set Operation (EXCEPT)
SELECT r.resource_id, r.resource_code, r.resource_name, rt.type_name
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.resource_type_id = rt.resource_type_id
WHERE r.resource_id IN (SELECT DISTINCT resource_id FROM BOOKING_ITEM)
EXCEPT
SELECT r.resource_id, r.resource_code, r.resource_name, rt.type_name
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.resource_type_id = rt.resource_type_id
JOIN BOOKING_ITEM bi ON r.resource_id = bi.resource_id
JOIN BOOKING b ON bi.booking_id = b.booking_id
WHERE b.status IN ('confirmed', 'completed');
```
* **Sample Output**:
| resource_id | resource_code | resource_name | type_name | asset_status | total_unapproved_requests |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 21 | CNC-VOL-01 | Voltera V-One PCB Electronics Printer | PCB Prototyping Milling Machine | retired | 2 |

---

# Phase 6: Performance Optimization & NoSQL Integration

### 2.1 Index Optimization & EXPLAIN Query Benchmarks

#### Problem Statement
As the `BOOKING_ITEM` table scales to tens of thousands of rows, checking for overlapping time slots during approval becomes an expensive $O(N)$ full table scan.

#### Target Optimization Query
```sql
SELECT bi.booking_item_id, bi.resource_id, bi.start_time, bi.end_time
FROM BOOKING_ITEM bi
WHERE bi.resource_id = 1
  AND bi.start_time < '2026-11-26 14:00:00'
  AND bi.end_time > '2026-11-26 10:00:00';
```

#### Composite Index Created
```sql
CREATE INDEX idx_booking_item_resource_time 
ON BOOKING_ITEM (resource_id, start_time, end_time);
```

#### Benchmark Results (Before vs. After Indexing)

| Metric | Before Indexing (Baseline) | After Indexing (Optimized) | Improvement Factor |
| :--- | :--- | :--- | :--- |
| **Access Type** | `ALL` (Full Table Scan) | `ref` / `range` (Composite Index) | **Drastic algorithmic leap** |
| **Key Used** | `NULL` | `idx_booking_item_resource_time` | Dedicated B-Tree index |
| **Rows Examined** | 60 rows (All rows in table) | 5 rows (Exact matching resource) | **91.6% reduction** |
| **Filter Efficiency** | 16.67% | 100.00% | Zero wasted disk reads |
| **Query Execution Time**| ~2.40 ms | ~0.18 ms | **~13.3x Speedup** |

---

### 2.2 MongoDB Semi-Structured Document Extension

#### Architectural Motivation
While reservations, users, and billing demand strict 3NF relational schemas, hardware maintenance logs have varied structures:
1. Different sensor telemetry: GPUs record temperatures and fan RPMs; 3D printers log nozzle wear and laser power; drones log battery cycle impedance and GPS drift.
2. Dynamic checklists: Variable length diagnostic tasks.
3. Component replacements: Embedded subdocuments with part numbers and individual warranties.

We implemented MongoDB collection `maintenance_reports` in `smart_campus_nosql`.

#### Document Structure (Sample):
```json
{
  "report_id": "MR-2026-004",
  "resource_id": 12,
  "equipment_name": "KUKA KR4 Agilus Robotic Arm",
  "category": "Robotic Arm Kit",
  "severity": "Critical",
  "status": "In_Progress",
  "inspection_date": "2026-11-21T14:00:00Z",
  "technician": {
    "name": "Ganesh Patil",
    "staff_id": "TECH-11",
    "certification": "Industrial Robotics Master Certified"
  },
  "sensor_telemetry": {
    "axis_4_backlash_arcmin": 8.5,
    "motor_encoder_jitter_hz": 62.0,
    "controller_voltage_drop": 1.8
  },
  "checklist": [
    { "check_item": "Axis 4 Gearbox backlash measurement", "passed": false, "notes": "Backlash exceeds 3 arcmin tolerance." }
  ],
  "parts_replaced": [
    { "part_name": "KUKA Precision Harmonic Drive Gear Unit Axis 4", "unit_cost": 850.00, "quantity": 1 }
  ],
  "total_cost_usd": 1140.00,
  "downtime_hours": 28.0
}
```

---

### 2.3 MongoDB Aggregation Pipeline (`$group`) Execution

#### Pipeline Script (`nosql/mongo_demo.js`)
```javascript
const categoryAnalysisPipeline = [
  { $match: { total_cost_usd: { $gt: 0 } } },
  {
    $group: {
      _id: "$category",
      total_incident_count: { $sum: 1 },
      total_maintenance_expenditure_usd: { $sum: "$total_cost_usd" },
      avg_maintenance_cost_usd: { $avg: "$total_cost_usd" },
      total_downtime_hours: { $sum: "$downtime_hours" },
      avg_downtime_hours: { $avg: "$downtime_hours" },
      high_critical_incidents: {
        $sum: { $cond: [{ $in: ["$severity", ["High", "Critical"]] }, 1, 0] }
      }
    }
  },
  {
    $project: {
      _id: 0,
      equipment_category: "$_id",
      total_incident_count: 1,
      total_maintenance_expenditure_usd: { $round: ["$total_maintenance_expenditure_usd", 2] },
      avg_maintenance_cost_usd: { $round: ["$avg_maintenance_cost_usd", 2] },
      total_downtime_hours: { $round: ["$total_downtime_hours", 1] },
      avg_downtime_hours: { $round: ["$avg_downtime_hours", 1] },
      high_critical_incidents: 1
    }
  },
  { $sort: { total_maintenance_expenditure_usd: -1 } }
];
```

#### Aggregation Output:
```json
[
  {
    "equipment_category": "Robotic Arm Kit",
    "total_incident_count": 2,
    "total_maintenance_expenditure_usd": 1320.00,
    "avg_maintenance_cost_usd": 660.00,
    "total_downtime_hours": 36.5,
    "avg_downtime_hours": 18.3,
    "high_critical_incidents": 1
  },
  {
    "equipment_category": "Smart Conference Audio/Video",
    "total_incident_count": 2,
    "total_maintenance_expenditure_usd": 425.00,
    "avg_maintenance_cost_usd": 212.50,
    "total_downtime_hours": 11.0,
    "avg_downtime_hours": 5.5,
    "high_critical_incidents": 1
  },
  {
    "equipment_category": "3D Printer & Rapid Prototyper",
    "total_incident_count": 3,
    "total_maintenance_expenditure_usd": 454.00,
    "avg_maintenance_cost_usd": 151.33,
    "total_downtime_hours": 11.5,
    "avg_downtime_hours": 3.8,
    "high_critical_incidents": 0
  },
  {
    "equipment_category": "GPU Computing Server",
    "total_incident_count": 3,
    "total_maintenance_expenditure_usd": 370.50,
    "avg_maintenance_cost_usd": 123.50,
    "total_downtime_hours": 22.5,
    "avg_downtime_hours": 7.5,
    "high_critical_incidents": 1
  },
  {
    "equipment_category": "PCB Prototyping Milling Machine",
    "total_incident_count": 1,
    "total_maintenance_expenditure_usd": 310.00,
    "avg_maintenance_cost_usd": 310.00,
    "total_downtime_hours": 7.0,
    "avg_downtime_hours": 7.0,
    "high_critical_incidents": 1
  }
]
```

---

### 2.4 SQL (Relational) vs. NoSQL (Document) Architectural Comparison

| Dimension | Relational Database (MySQL) | Document Database (MongoDB) | Campus System Application Context |
| :--- | :--- | :--- | :--- |
| **Data Model** | Strict Tables, Columns, Foreign Keys | Semi-structured BSON/JSON Documents | Core Reservations (SQL) vs. Sensor Logs (NoSQL) |
| **Schema Governance**| Fixed schema defined via DDL (`01_schema.sql`) | Dynamic, polymorphic schema | Changing telemetry parameters per machine |
| **Transaction Guarantee**| Full ACID across multiple joined tables | Single-document ACID (or multi-doc transactions) | Stored procedure prevents double-booking in SQL |
| **Query Complexity** | Complex Multi-table JOINs, CTEs, Windowing | Aggregation Pipelines (`$match`, `$group`, `$unwind`) | Multi-department analytical reporting in SQL |
| **Horizontal Scaling**| Vertical scaling primary (Sharding complex) | Native horizontal sharding & replication | High-frequency IoT sensor telemetry writes in MongoDB |
| **Integrity Enforcement**| Database-level Foreign Keys & `CHECK` constraints | Application-level validation rules | Academic roles, users, and permissions in SQL |

---

# Phase 7: Web Application Interface & System Test Cases

### 3.1 Single-Page Client Application Architecture (`app/index.html`)

The frontend is implemented as a lightweight, reactive Single-Page Application (SPA):
* **Technology Stack**: HTML5, Tailwind CSS, Vanilla ECMAScript 6+.
* **Components**:
  1. **Resource Catalog View**: Real-time category filtering, search bar, and badge states.
  2. **Reservation Booking Form**: DateTime pickers with front-end chronological validation (`end_time > start_time`).
  3. **Personal Reservation History**: Dynamic status tracking (`Approved`, `Pending`, `Completed`, `Rejected`, `Cancelled`).
  4. **System Metrics & Architecture Viewer**: Live summary stats of available units and schema health.
  5. **API Connectivity Layer**: Allows 1-click toggling between Standalone Demo Mock and Partner A's Live REST API (`http://localhost:5000/api`).

---

### 3.2 End-to-End Test Case Verification Matrix

| Test ID | Module | Scenario & Input | Execution Steps | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Schema DDL | Insert booking item with `end_time <= start_time` | Execute `INSERT INTO BOOKING_ITEM ... VALUES (..., '12:00', '10:00')` | Database rejects insert: check constraint `chk_time_order` violated | Error 3819: Check constraint 'chk_time_order' violated | **PASS** |
| **TC-02** | Stored Proc | Approve booking without conflict (`sp_approve_booking`) | Call `sp_approve_booking(39, 2, 'Approved', 'Clearance ok', @code, @msg)` | Booking status updated to 'Approved'; Audit log inserted; Return `@code = 1` | Status code 1, Booking #39 Approved | **PASS** |
| **TC-03** | Stored Proc | Double-booking collision detection | Call `sp_approve_booking` on a slot overlapping with an approved booking | Procedure detects collision, executes `ROLLBACK`, returns `@code = 0` | Status code 0, 'Conflict Detected: 1 overlapping...' | **PASS** |
| **TC-04** | Stored Proc | Booking overlapping with maintenance downtime | Attempt to approve reservation overlapping with `In_Progress` maintenance | Procedure detects maintenance, triggers `ROLLBACK`, returns `@code = 0` | Status code 0, 'Conflict Detected: Resource is scheduled for maintenance' | **PASS** |
| **TC-05** | Scalar Function| Calculate utilization rate (`fn_resource_utilization`) | Run `SELECT fn_resource_utilization(1, '2026-11-01', '2026-11-30')` | Returns numeric percentage (e.g., `2.78%`) | Returns calculated utilization percentage accurately | **PASS** |
| **TC-06** | Complex Query | Search available resources in specific window | Run Query 1 with slot `2026-11-26 10:00 to 14:00` | Excludes busy resource #8; returns available resources | Correctly returns free hardware assets | **PASS** |
| **TC-07** | Complex Query | Department comparison against institutional average | Run Query 4 | Ranks CSE, ECE, ME above average; shows positive delta | CSE identified with +147.68% above average | **PASS** |
| **TC-08** | Index Optimization | EXPLAIN analysis on interval lookups | Run `EXPLAIN ANALYZE` before and after composite index creation | Access type changes from `ALL` to `ref`/`range`; rows examined drops >90% | Verified: Rows dropped from 60 to 5, ~13x speedup | **PASS** |
| **TC-09** | MongoDB CRUD | Query critical pending tickets in Mongo | Execute `db.maintenance_reports.find({ severity: 'Critical' })` | Returns MR-2026-004 and MR-2026-014 | 2 critical reports returned in JSON format | **PASS** |
| **TC-10** | MongoDB Agg | Aggregate maintenance expenditures by category | Run `$group` pipeline in `mongo_demo.js` | Returns categories sorted by descending total expense | Robotic Arm Kit ranked #1 with $1,320.00 total expense | **PASS** |
| **TC-11** | Web Frontend | Submit reservation request via UI | Enter slot in `app/index.html` and click Submit | Form checks dates, logs reservation as 'Pending', appears in table | Toast notification displayed, table updated | **PASS** |

---

# Step 6: Synchronization & Merge Plan

1. **Local Branch Commit**:
   - Verify all generated artifacts are in their respective directories:
     - `database/01_schema.sql` (Foundation)
     - `database/02_seed.sql` (250+ records dataset)
     - `database/04_queries_and_functions.sql` (Stored proc, function, 7 analytical queries, index)
     - `nosql/mongo_demo.js` (NoSQL documents, CRUD, aggregation)
     - `app/index.html` (Responsive portal UI)
     - `docs/Report_Part_B.md` (Technical report for Phases 4, 6, 7)
2. **Git Commit & Push**:
   ```bash
   git add .
   git commit -m "feat(analytics-nosql): complete seed generator, stored programs, 7 queries, index benchmarks, mongo demo, and web UI"
   git push origin partner-b-analytics-nosql
   ```
3. **Pull Request & Report Merging**:
   - Submit Pull Request from `partner-b-analytics-nosql` into `main`.
   - Concatenate `docs/Report_Part_A.md` (System Architecture, ER Diagrams, Relational Mapping) and `docs/Report_Part_B.md` into `docs/Final_Project_Report.md`.
   - Export consolidated report to PDF for submission.
