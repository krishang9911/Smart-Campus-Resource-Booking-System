-- Free-tier MySQL deployment compatibility for the Smart Campus app.
--
-- Run this in the provider-assigned database/schema after 01_schema.sql and
-- 02_seed.sql (select that database in your SQL client first). Set the app's
-- DB_NAME to this exact provider-assigned name. It defines the same booking procedures used by app/server.js,
-- but does not create triggers, functions, database roles, or demo calls.
-- The overlap guard is inside sp_create_booking so it remains transactional
-- on managed tiers that prohibit triggers.

DELIMITER //

DROP PROCEDURE IF EXISTS sp_create_booking//

CREATE PROCEDURE sp_create_booking(
    IN p_user_id INT,
    IN p_resource_id INT,
    IN p_booking_date DATE,
    IN p_start_time DATETIME,
    IN p_end_time DATETIME,
    IN p_purpose VARCHAR(255)
)
proc_create_booking: BEGIN
    DECLARE v_resource_status VARCHAR(30) DEFAULT NULL;
    DECLARE v_conflict_count INT DEFAULT 0;
    DECLARE v_booking_id INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_start_time IS NULL
       OR p_end_time IS NULL
       OR p_end_time <= p_start_time THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'End time must be later than start time';
    END IF;

    SELECT status
    INTO v_resource_status
    FROM RESOURCE
    WHERE resource_id = p_resource_id
    FOR UPDATE;

    IF v_resource_status IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Resource does not exist';
    END IF;

    IF v_resource_status <> 'available' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Resource is not available for booking';
    END IF;

    -- The RESOURCE row lock serializes requests for this resource. This check
    -- replaces trg_booking_item_before_insert_overlap on restricted free tiers.
    SELECT COUNT(*)
    INTO v_conflict_count
    FROM BOOKING_ITEM AS bi
    JOIN BOOKING AS b ON b.booking_id = bi.booking_id
    WHERE bi.resource_id = p_resource_id
      AND b.status IN ('pending', 'confirmed')
      AND p_start_time < bi.end_time
      AND p_end_time > bi.start_time;

    IF v_conflict_count > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The resource is already booked for the requested time range';
    END IF;

    INSERT INTO BOOKING (
        user_id, booking_date, start_time, end_time, purpose, status, total_resources
    )
    VALUES (
        p_user_id, p_booking_date, p_start_time, p_end_time, p_purpose, 'pending', 1
    );

    SET v_booking_id = LAST_INSERT_ID();

    INSERT INTO BOOKING_ITEM (
        booking_id, resource_id, start_time, end_time, quantity
    )
    VALUES (
        v_booking_id, p_resource_id, p_start_time, p_end_time, 1
    );

    INSERT INTO AUDIT_LOG (
        booking_id, changed_by, action, old_status, new_status, change_details
    )
    VALUES (
        v_booking_id,
        p_user_id,
        'created',
        NULL,
        'pending',
        JSON_OBJECT(
            'resource_id', p_resource_id,
            'start_time', p_start_time,
            'end_time', p_end_time
        )
    );

    COMMIT;
    SELECT v_booking_id AS booking_id;
END//

DROP PROCEDURE IF EXISTS sp_approve_booking//

CREATE PROCEDURE sp_approve_booking(
    IN p_booking_id INT,
    IN p_approver_id INT,
    IN p_decision VARCHAR(20),
    IN p_remarks TEXT,
    OUT p_status_code INT,
    OUT p_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_booking_status VARCHAR(20);
    DECLARE v_conflict_count INT DEFAULT 0;
    DECLARE v_decision_clean VARCHAR(20);
    DECLARE v_resource_id INT;
    DECLARE v_locked_resource_id INT DEFAULT NULL;
    DECLARE v_done BOOLEAN DEFAULT FALSE;
    DECLARE resource_cursor CURSOR FOR
        SELECT resource_id
        FROM BOOKING_ITEM
        WHERE booking_id = p_booking_id
        ORDER BY resource_id;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_code = 0;
        SET p_message = 'Transaction aborted: An unexpected database error occurred.';
    END;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET v_decision_clean = LOWER(TRIM(p_decision));
    START TRANSACTION;

    SELECT status INTO v_booking_status
    FROM BOOKING
    WHERE booking_id = p_booking_id
    FOR UPDATE;

    IF v_booking_status IS NULL THEN
        ROLLBACK;
        SET p_status_code = 0;
        SET p_message = CONCAT('Error: Booking ID ', p_booking_id, ' does not exist.');
        LEAVE proc_label;
    END IF;

    SET v_done = FALSE;
    OPEN resource_cursor;
    resource_lock_loop: LOOP
        FETCH resource_cursor INTO v_resource_id;
        IF v_done THEN
            LEAVE resource_lock_loop;
        END IF;

        SET v_locked_resource_id = NULL;
        SET v_done = FALSE;
        SELECT resource_id INTO v_locked_resource_id
        FROM RESOURCE
        WHERE resource_id = v_resource_id
        FOR UPDATE;

        IF v_done THEN
            CLOSE resource_cursor;
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Booking references a resource that does not exist';
        END IF;
    END LOOP;
    CLOSE resource_cursor;

    IF v_booking_status <> 'pending' THEN
        ROLLBACK;
        SET p_status_code = 0;
        SET p_message = CONCAT(
            'Error: Booking ID ', p_booking_id, ' is currently ', v_booking_status,
            '. Only pending bookings can be processed.'
        );
        LEAVE proc_label;
    END IF;

    IF v_decision_clean = 'approved' THEN
        SELECT COUNT(*) INTO v_conflict_count
        FROM BOOKING_ITEM AS target_item
        JOIN BOOKING_ITEM AS existing_item
          ON target_item.resource_id = existing_item.resource_id
         AND target_item.booking_item_id <> existing_item.booking_item_id
        JOIN BOOKING AS existing_booking
          ON existing_item.booking_id = existing_booking.booking_id
        WHERE target_item.booking_id = p_booking_id
          AND existing_booking.status IN ('confirmed', 'completed')
          AND target_item.start_time < existing_item.end_time
          AND target_item.end_time > existing_item.start_time;

        IF v_conflict_count > 0 THEN
            ROLLBACK;
            SET p_status_code = 0;
            SET p_message = CONCAT(
                'Conflict Detected: ', v_conflict_count,
                ' overlapping confirmed reservation(s) exist for requested resource slots.'
            );
            LEAVE proc_label;
        END IF;

        SELECT COUNT(*) INTO v_conflict_count
        FROM BOOKING_ITEM AS target_item
        JOIN MAINTENANCE AS m ON target_item.resource_id = m.resource_id
        WHERE target_item.booking_id = p_booking_id
          AND m.status IN ('open', 'in_progress')
          AND target_item.start_time < COALESCE(m.resolved_at, '2099-12-31 23:59:59')
          AND target_item.end_time > m.reported_at;

        IF v_conflict_count > 0 THEN
            ROLLBACK;
            SET p_status_code = 0;
            SET p_message = 'Conflict Detected: One or more requested resources are scheduled or undergoing maintenance.';
            LEAVE proc_label;
        END IF;

        UPDATE BOOKING SET status = 'confirmed' WHERE booking_id = p_booking_id;

        INSERT INTO APPROVAL (booking_id, approver_id, decision, remarks, decided_at)
        VALUES (p_booking_id, p_approver_id, 'approved', p_remarks, NOW())
        ON DUPLICATE KEY UPDATE
            approver_id = p_approver_id,
            decision = 'approved',
            remarks = p_remarks,
            decided_at = NOW();

        INSERT INTO AUDIT_LOG (
            booking_id, changed_by, action, old_status, new_status, change_details, changed_at
        )
        VALUES (
            p_booking_id, p_approver_id, 'approval_granted', 'pending', 'confirmed',
            JSON_OBJECT(
                'approver_id', p_approver_id,
                'decision', 'approved',
                'remarks', COALESCE(p_remarks, 'N/A')
            ),
            NOW()
        );

        COMMIT;
        SET p_status_code = 1;
        SET p_message = CONCAT('Success: Booking ID ', p_booking_id, ' approved and confirmed successfully.');

    ELSEIF v_decision_clean = 'rejected' THEN
        UPDATE BOOKING SET status = 'rejected' WHERE booking_id = p_booking_id;

        INSERT INTO APPROVAL (booking_id, approver_id, decision, remarks, decided_at)
        VALUES (p_booking_id, p_approver_id, 'rejected', p_remarks, NOW())
        ON DUPLICATE KEY UPDATE
            approver_id = p_approver_id,
            decision = 'rejected',
            remarks = p_remarks,
            decided_at = NOW();

        INSERT INTO AUDIT_LOG (
            booking_id, changed_by, action, old_status, new_status, change_details, changed_at
        )
        VALUES (
            p_booking_id, p_approver_id, 'approval_denied', 'pending', 'rejected',
            JSON_OBJECT(
                'approver_id', p_approver_id,
                'decision', 'rejected',
                'remarks', COALESCE(p_remarks, 'N/A')
            ),
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
END//

DELIMITER ;
