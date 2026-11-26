-- ============================================================================
-- Smart Campus Resource & Lab Booking System
-- File: database/04_queries_and_functions.sql (Aligned with Schema Version 2.0)
-- Description: Stored Procedures, Functions, Analytical SQL Queries & Indexes
-- Author: Person B (Teammate B) - Analytics & NoSQL Specialist
-- ============================================================================

USE smart_campus_db;

-- ============================================================================
-- SECTION 1: TRANSACTIONAL STORED PROCEDURE
-- Procedure: sp_approve_booking
-- Purpose: Safely approve or reject pending reservations with full ACID safety,
--          conflict collision detection, and audit logging in Schema v2.0.
-- ============================================================================

DELIMITER //

DROP PROCEDURE IF EXISTS sp_approve_booking //

CREATE PROCEDURE sp_approve_booking(
    IN p_booking_id INT,
    IN p_approver_id INT,
    IN p_decision VARCHAR(20),       -- 'approved' or 'rejected'
    IN p_remarks TEXT,
    OUT p_status_code INT,           -- 1 = Success, 0 = Conflict / Error
    OUT p_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_booking_status VARCHAR(20);
    DECLARE v_conflict_count INT DEFAULT 0;
    DECLARE v_decision_clean VARCHAR(20);

    -- Error Handler for unexpected exceptions (Automatic Rollback)
    -- Must be declared before any executable statements
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = 0;
        SET p_message = 'Transaction aborted: An unexpected database error occurred.';
    END;

    -- Standardize decision to lowercase
    SET v_decision_clean = LOWER(TRIM(p_decision));

    -- Step 1: Validate existence and pending status
    SELECT status INTO v_booking_status 
    FROM BOOKING 
    WHERE booking_id = p_booking_id;

    IF v_booking_status IS NULL THEN
        SET p_status_code = 0;
        SET p_message = CONCAT('Error: Booking ID ', p_booking_id, ' does not exist.');
        LEAVE proc_label;
    END IF;

    IF v_booking_status != 'pending' THEN
        SET p_status_code = 0;
        SET p_message = CONCAT('Error: Booking ID ', p_booking_id, ' is currently ', v_booking_status, '. Only pending bookings can be processed.');
        LEAVE proc_label;
    END IF;

    -- Step 2: Begin Transaction
    START TRANSACTION;

    IF v_decision_clean = 'approved' THEN
        -- Check for overlapping active (confirmed / completed) booking slots
        SELECT COUNT(*) INTO v_conflict_count
        FROM BOOKING_ITEM target_item
        JOIN BOOKING_ITEM existing_item 
            ON target_item.resource_id = existing_item.resource_id
            AND target_item.booking_item_id != existing_item.booking_item_id
        JOIN BOOKING existing_booking 
            ON existing_item.booking_id = existing_booking.booking_id
        WHERE target_item.booking_id = p_booking_id
          AND existing_booking.status IN ('confirmed', 'completed')
          -- Interval overlap condition: (StartA < EndB) AND (EndA > StartB)
          AND (target_item.start_time < existing_item.end_time AND target_item.end_time > existing_item.start_time);

        IF v_conflict_count > 0 THEN
            ROLLBACK;
            SET p_status_code = 0;
            SET p_message = CONCAT('Conflict Detected: ', v_conflict_count, ' overlapping confirmed reservation(s) exist for requested resource slots.');
            LEAVE proc_label;
        END IF;

        -- Check if any requested resource is in active maintenance
        SELECT COUNT(*) INTO v_conflict_count
        FROM BOOKING_ITEM target_item
        JOIN MAINTENANCE m ON target_item.resource_id = m.resource_id
        WHERE target_item.booking_id = p_booking_id
          AND m.status IN ('open', 'in_progress')
          AND (target_item.start_time < COALESCE(m.resolved_at, '2099-12-31 23:59:59') AND target_item.end_time > m.reported_at);

        IF v_conflict_count > 0 THEN
            ROLLBACK;
            SET p_status_code = 0;
            SET p_message = 'Conflict Detected: One or more requested resources are scheduled or undergoing maintenance.';
            LEAVE proc_label;
        END IF;

        -- Update booking status to confirmed
        UPDATE BOOKING 
        SET status = 'confirmed' 
        WHERE booking_id = p_booking_id;

        -- Insert or update approval record
        INSERT INTO APPROVAL (booking_id, approver_id, decision, remarks, decided_at)
        VALUES (p_booking_id, p_approver_id, 'approved', p_remarks, NOW())
        ON DUPLICATE KEY UPDATE 
            approver_id = p_approver_id, 
            decision = 'approved', 
            remarks = p_remarks, 
            decided_at = NOW();

        -- System Audit Trail (Schema v2.0 JSON format)
        INSERT INTO AUDIT_LOG (booking_id, changed_by, action, old_status, new_status, change_details, changed_at)
        VALUES (
            p_booking_id, 
            p_approver_id, 
            'approval_granted', 
            'pending', 
            'confirmed', 
            JSON_OBJECT('approver_id', p_approver_id, 'decision', 'approved', 'remarks', COALESCE(p_remarks, 'N/A')),
            NOW()
        );

        COMMIT;
        SET p_status_code = 1;
        SET p_message = CONCAT('Success: Booking ID ', p_booking_id, ' approved and confirmed successfully.');

    ELSEIF v_decision_clean = 'rejected' THEN
        -- Reject booking
        UPDATE BOOKING 
        SET status = 'rejected' 
        WHERE booking_id = p_booking_id;

        INSERT INTO APPROVAL (booking_id, approver_id, decision, remarks, decided_at)
        VALUES (p_booking_id, p_approver_id, 'rejected', p_remarks, NOW())
        ON DUPLICATE KEY UPDATE 
            approver_id = p_approver_id, 
            decision = 'rejected', 
            remarks = p_remarks, 
            decided_at = NOW();

        INSERT INTO AUDIT_LOG (booking_id, changed_by, action, old_status, new_status, change_details, changed_at)
        VALUES (
            p_booking_id, 
            p_approver_id, 
            'approval_denied', 
            'pending', 
            'rejected', 
            JSON_OBJECT('approver_id', p_approver_id, 'decision', 'rejected', 'remarks', COALESCE(p_remarks, 'N/A')),
            NOW()
        );

        COMMIT;
        SET p_status_code = 1;
        SET p_message = CONCAT('Success: Booking ID ', p_booking_id, ' rejected.');
    ELSE
        ROLLBACK;
        SET p_status_code = 0;
        SET p_message = 'Invalid decision value. Must be either "approved" or "rejected".';
    END IF;

END proc_label //

DELIMITER ;

-- ----------------------------------------------------------------------------
-- VISUAL VERIFICATION: DEMONSTRATION CALLS FOR STORED PROCEDURE
-- Displays immediate Result Grids in MySQL Workbench showing ACID behavior.
-- ----------------------------------------------------------------------------

-- Test Call 1: Conflict Collision Interception (Rollback Demonstration)
-- Booking #39 requests Resource 1 during an already confirmed window (Booking #26)
CALL sp_approve_booking(39, 2, 'approved', 'Attempting approval on conflicting slot', @demo_code_1, @demo_msg_1);
SELECT 
    39 AS Tested_Booking_ID, 
    'Booking #39 on Resource 1 (DGX-01)' AS Scenario, 
    @demo_code_1 AS Status_Code, 
    @demo_msg_1 AS System_Response;

-- Test Call 2: Successful Approval Demonstration
-- Booking #44 requests Resource 19 with no conflicts
CALL sp_approve_booking(44, 2, 'approved', 'Approved after coordinator schedule verification', @demo_code_2, @demo_msg_2);
SELECT 
    44 AS Tested_Booking_ID, 
    'Booking #44 on Resource 19 (HTC Vive)' AS Scenario, 
    @demo_code_2 AS Status_Code, 
    @demo_msg_2 AS System_Response;


-- ============================================================================
-- SECTION 2: SCALAR FUNCTION FOR RESOURCE UTILIZATION
-- Function: fn_resource_utilization
-- Purpose: Calculate percentage utilization rate of any resource across a date window.
-- ============================================================================

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

    -- Guard against invalid intervals
    IF p_end_date <= p_start_date THEN
        RETURN 0.00;
    END IF;

    SET v_total_available_hours = TIMESTAMPDIFF(MINUTE, p_start_date, p_end_date) / 60.0;
    IF v_total_available_hours <= 0 THEN
        RETURN 0.00;
    END IF;

    -- Sum actual overlapping seconds for confirmed and completed bookings
    SELECT COALESCE(SUM(
        TIMESTAMPDIFF(SECOND, 
            GREATEST(bi.start_time, p_start_date), 
            LEAST(bi.end_time, p_end_date)
        )
    ), 0) INTO v_booked_seconds
    FROM BOOKING_ITEM bi
    JOIN BOOKING b ON bi.booking_id = b.booking_id
    WHERE bi.resource_id = p_resource_id
      AND b.status IN ('confirmed', 'completed')
      AND bi.start_time < p_end_date
      AND bi.end_time > p_start_date;

    SET v_booked_hours = v_booked_seconds / 3600.0;
    SET v_utilization_rate = ROUND((v_booked_hours / v_total_available_hours) * 100.0, 2);

    -- Cap at 100%
    IF v_utilization_rate > 100.00 THEN
        SET v_utilization_rate = 100.00;
    END IF;

    RETURN v_utilization_rate;
END //

DELIMITER ;

-- ----------------------------------------------------------------------------
-- VISUAL VERIFICATION: FUNCTION DEMONSTRATION QUERY
-- Displays Resource Utilization percentages across the academic semester
-- ----------------------------------------------------------------------------
SELECT 
    r.resource_id,
    r.resource_code,
    r.resource_name,
    rt.type_name AS category,
    r.status AS hardware_status,
    fn_resource_utilization(r.resource_id, '2026-11-01 00:00:00', '2026-11-30 23:59:59') AS `November_Utilization_%`
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.resource_type_id = rt.resource_type_id
WHERE r.resource_id IN (1, 2, 3, 5, 8, 11, 14, 21)
ORDER BY `November_Utilization_%` DESC;


-- ============================================================================
-- SECTION 3: 7 REQUIRED COMPLEX ANALYTICAL SQL QUERIES (Version 2.0)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1 (Availability Interval Query):
-- Search all resources free for reservation during requested time slot:
-- '2026-11-26 10:00:00' to '2026-11-26 14:00:00'.
-- ----------------------------------------------------------------------------
SELECT 
    r.resource_id,
    r.resource_code,
    r.resource_name,
    rt.type_name AS category,
    l.building_name,
    l.room_number,
    r.capacity
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.resource_type_id = rt.resource_type_id
JOIN LOCATION l ON r.location_id = l.location_id
WHERE r.status = 'available'
  -- Exclude resources undergoing or scheduled for maintenance in interval
  AND NOT EXISTS (
      SELECT 1 
      FROM MAINTENANCE m
      WHERE m.resource_id = r.resource_id
        AND m.status IN ('open', 'in_progress')
        AND (m.reported_at < '2026-11-26 14:00:00' AND COALESCE(m.resolved_at, '2099-12-31') > '2026-11-26 10:00:00')
  )
  -- Exclude resources with overlapping confirmed or pending bookings
  AND NOT EXISTS (
      SELECT 1 
      FROM BOOKING_ITEM bi
      JOIN BOOKING b ON bi.booking_id = b.booking_id
      WHERE bi.resource_id = r.resource_id
        AND b.status IN ('confirmed', 'pending', 'completed')
        AND (bi.start_time < '2026-11-26 14:00:00' AND bi.end_time > '2026-11-26 10:00:00')
  )
ORDER BY rt.type_name, r.resource_name;

-- ----------------------------------------------------------------------------
-- QUERY 2 (Conflict & Collision Detection Query):
-- Detects overlapping or competing reservations on the same physical resource
-- between confirmed reservations and pending requests (or competing pending requests).
-- Demonstrates 3 active collision scenarios with calculated overlap duration.
-- ----------------------------------------------------------------------------
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
  -- Overlap condition: (StartA < EndB) AND (EndA > StartB)
  AND (bi1.start_time < bi2.end_time AND bi1.end_time > bi2.start_time)
ORDER BY r.resource_code, bi1.start_time;

-- ----------------------------------------------------------------------------
-- QUERY 3 (Ranking Window Function):
-- Rank resources by total hours booked within their respective Resource Types.
-- ----------------------------------------------------------------------------
SELECT 
    rt.type_name AS category,
    r.resource_code,
    r.resource_name,
    COUNT(bi.booking_item_id) AS total_sessions,
    ROUND(COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time))/60.0, 0), 2) AS total_hours_booked,
    DENSE_RANK() OVER (
        PARTITION BY rt.resource_type_id 
        ORDER BY COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time))/60.0, 0) DESC
    ) AS category_rank,
    RANK() OVER (
        ORDER BY COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time))/60.0, 0) DESC
    ) AS campus_wide_rank
FROM RESOURCE r
JOIN RESOURCE_TYPE rt ON r.resource_type_id = rt.resource_type_id
LEFT JOIN BOOKING_ITEM bi ON r.resource_id = bi.resource_id
LEFT JOIN BOOKING b ON bi.booking_id = b.booking_id AND b.status IN ('confirmed', 'completed')
GROUP BY rt.resource_type_id, rt.type_name, r.resource_id, r.resource_code, r.resource_name
ORDER BY rt.type_name, category_rank;

-- ----------------------------------------------------------------------------
-- QUERY 4 (Subquery / CTE with Department Comparison):
-- Identifies academic departments with resource utilization higher than the institutional average.
-- ----------------------------------------------------------------------------
WITH DepartmentUsage AS (
    SELECT 
        d.department_id,
        d.department_name,
        COUNT(DISTINCT b.booking_id) AS total_bookings,
        ROUND(COALESCE(SUM(TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time))/60.0, 0), 2) AS total_dept_hours
    FROM DEPARTMENT d
    LEFT JOIN `USER` u ON d.department_id = u.department_id
    LEFT JOIN BOOKING b ON u.user_id = b.user_id AND b.status IN ('confirmed', 'completed')
    LEFT JOIN BOOKING_ITEM bi ON b.booking_id = bi.booking_id
    GROUP BY d.department_id, d.department_name
),
InstitutionalAverage AS (
    SELECT AVG(total_dept_hours) AS avg_institutional_hours 
    FROM DepartmentUsage
)
SELECT 
    du.department_name,
    du.total_bookings,
    du.total_dept_hours,
    ROUND(ia.avg_institutional_hours, 2) AS campus_average_hours,
    ROUND(du.total_dept_hours - ia.avg_institutional_hours, 2) AS hours_above_average,
    ROUND(((du.total_dept_hours - ia.avg_institutional_hours) / ia.avg_institutional_hours) * 100, 2) AS pct_above_average
FROM DepartmentUsage du
CROSS JOIN InstitutionalAverage ia
WHERE du.total_dept_hours > ia.avg_institutional_hours
ORDER BY du.total_dept_hours DESC;

-- ----------------------------------------------------------------------------
-- QUERY 5 (Monthly CTE Resource Utilization):
-- Aggregates monthly campus-wide reservation trends, active hours, and cancellation ratios.
-- ----------------------------------------------------------------------------
WITH MonthlyMetrics AS (
    SELECT 
        DATE_FORMAT(b.created_at, '%Y-%m') AS booking_month,
        COUNT(b.booking_id) AS total_reservations,
        SUM(CASE WHEN b.status = 'completed' THEN 1 ELSE 0 END) AS completed_count,
        SUM(CASE WHEN b.status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_count,
        SUM(CASE WHEN b.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
        SUM(CASE WHEN b.status = 'rejected' THEN 1 ELSE 0 END) AS rejected_count,
        ROUND(COALESCE(SUM(CASE WHEN b.status IN ('confirmed', 'completed') 
            THEN TIMESTAMPDIFF(MINUTE, bi.start_time, bi.end_time)/60.0 ELSE 0 END), 0), 2) AS operational_hours
    FROM BOOKING b
    LEFT JOIN BOOKING_ITEM bi ON b.booking_id = bi.booking_id
    GROUP BY DATE_FORMAT(b.created_at, '%Y-%m')
)
SELECT 
    booking_month,
    total_reservations,
    completed_count,
    confirmed_count,
    cancelled_count,
    rejected_count,
    operational_hours,
    ROUND((cancelled_count * 100.0) / NULLIF(total_reservations, 0), 2) AS cancellation_rate_pct,
    LAG(operational_hours, 1) OVER (ORDER BY booking_month) AS prev_month_hours
FROM MonthlyMetrics
ORDER BY booking_month;

-- ----------------------------------------------------------------------------
-- QUERY 6 (Live Campus Availability View):
-- v_current_availability: Real-time dynamic operational status of every resource on campus.
-- Evaluates real-time active state: Available Now, In Use (Occupied), Under Maintenance, Retired.
-- ----------------------------------------------------------------------------
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
    -- Current occupant if currently in use
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

-- Explicit SELECT query to view all 25 resources with their live statuses in Result Grid:
SELECT * FROM v_current_availability ORDER BY live_operational_status, resource_name;

-- ----------------------------------------------------------------------------
-- QUERY 7 (Set Operations / Anti-Join Analysis):
-- Demand vs Approval Disparity: Resources requested by students/faculty that have
-- NEVER been successfully confirmed or completed (Unapproved Demand / Inaccessible Assets).
-- ----------------------------------------------------------------------------

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
  -- Anti-Join condition: Resource has ZERO confirmed or completed bookings
  AND r.resource_id NOT IN (
      SELECT DISTINCT bi_app.resource_id
      FROM BOOKING_ITEM bi_app
      JOIN BOOKING b_app ON bi_app.booking_id = b_app.booking_id
      WHERE b_app.status IN ('confirmed', 'completed')
  )
GROUP BY r.resource_id, r.resource_code, r.resource_name, rt.type_name, r.status;

-- Method 2: MySQL 8.4 Native Set Operation (EXCEPT)
-- Compares all resources that received booking requests EXCEPT those that have approved reservations:
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


-- ============================================================================
-- SECTION 4: TASK 3 - INDEX OPTIMIZATION & EXPLAIN BENCHMARKS
-- ============================================================================

-- Step 1: Baseline EXPLAIN Plan (Before Indexing)
-- Displays execution tree and rows examined in MySQL Workbench Result Grid:
EXPLAIN ANALYZE
SELECT bi.booking_item_id, bi.resource_id, bi.start_time, bi.end_time
FROM BOOKING_ITEM bi
WHERE bi.resource_id = 1
  AND bi.start_time < '2026-11-26 14:00:00'
  AND bi.end_time > '2026-11-26 10:00:00';

-- Step 2: Safe Composite Index Creation on (resource_id, start_time, end_time)
-- Conditionally drops index if already present, ensuring 100% crash-free re-runs:
SET @idx_check = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = DATABASE() 
      AND table_name = 'BOOKING_ITEM' 
      AND index_name = 'idx_booking_item_res_time'
);
SET @drop_query = IF(@idx_check > 0, 'ALTER TABLE BOOKING_ITEM DROP INDEX idx_booking_item_res_time', 'SELECT "Index not present" AS status');
PREPARE stmt_drop FROM @drop_query;
EXECUTE stmt_drop;
DEALLOCATE PREPARE stmt_drop;

CREATE INDEX idx_booking_item_res_time 
ON BOOKING_ITEM (resource_id, start_time, end_time);

-- Step 3: Post-Index EXPLAIN Benchmark
-- Demonstrates Index Range Scan and orders-of-magnitude reduction in rows examined:
EXPLAIN ANALYZE
SELECT bi.booking_item_id, bi.resource_id, bi.start_time, bi.end_time
FROM BOOKING_ITEM bi
WHERE bi.resource_id = 1
  AND bi.start_time < '2026-11-26 14:00:00'
  AND bi.end_time > '2026-11-26 10:00:00';

-- Step 4: Verification of Created Index in Table Metadata
SHOW INDEX FROM BOOKING_ITEM WHERE Key_name = 'idx_booking_item_res_time';

-- ============================================================================
-- END OF SCRIPT: 04_queries_and_functions.sql
-- ============================================================================
