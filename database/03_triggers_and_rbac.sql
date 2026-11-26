-- ============================================================================
-- Smart Campus Resource & Lab Booking System
-- Triggers, Stored Procedures, and RBAC
-- ============================================================================

USE smart_campus_db;

DELIMITER //

-- Reject a booking item whose time range overlaps another active booking item
-- for the same resource.
DROP TRIGGER IF EXISTS trg_booking_item_before_insert_overlap//

CREATE TRIGGER trg_booking_item_before_insert_overlap
BEFORE INSERT ON BOOKING_ITEM
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM BOOKING_ITEM AS bi
        JOIN BOOKING AS b ON b.booking_id = bi.booking_id
        WHERE bi.resource_id = NEW.resource_id
          AND b.status IN ('pending', 'confirmed')
          AND NEW.start_time < bi.end_time
          AND NEW.end_time > bi.start_time
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The resource is already booked for the requested time range';
    END IF;
END//

-- Cancelled bookings are recorded and the status transition is audited.
DROP TRIGGER IF EXISTS trg_booking_after_update_cancel//

CREATE TRIGGER trg_booking_after_update_cancel
AFTER UPDATE ON BOOKING
FOR EACH ROW
BEGIN
    IF OLD.status <> 'cancelled'
       AND NEW.status = 'cancelled' THEN
        INSERT INTO CANCELLATION (booking_id, cancelled_by, reason)
        VALUES (NEW.booking_id, NEW.user_id, 'Cancelled by booking status update');

        INSERT INTO AUDIT_LOG (
            booking_id,
            changed_by,
            action,
            old_status,
            new_status,
            change_details
        )
        VALUES (
            NEW.booking_id,
            NEW.user_id,
            'cancelled',
            OLD.status,
            NEW.status,
            JSON_OBJECT(
                'trigger', 'trg_booking_after_update_cancel',
                'old_status', OLD.status,
                'new_status', NEW.status
            )
        );
    END IF;
END//

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
    DECLARE v_resource_id INT DEFAULT NULL;
    DECLARE v_resource_status VARCHAR(30) DEFAULT NULL;
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

    SET v_resource_id = p_resource_id;

    INSERT INTO BOOKING (
        user_id,
        booking_date,
        start_time,
        end_time,
        purpose,
        status,
        total_resources
    )
    VALUES (
        p_user_id,
        p_booking_date,
        p_start_time,
        p_end_time,
        p_purpose,
        'pending',
        1
    );

    SET v_booking_id = LAST_INSERT_ID();

    INSERT INTO BOOKING_ITEM (
        booking_id,
        resource_id,
        start_time,
        end_time,
        quantity
    )
    VALUES (
        v_booking_id,
        v_resource_id,
        p_start_time,
        p_end_time,
        1
    );

    INSERT INTO AUDIT_LOG (
        booking_id,
        changed_by,
        action,
        old_status,
        new_status,
        change_details
    )
    VALUES (
        v_booking_id,
        p_user_id,
        'created',
        NULL,
        'pending',
        JSON_OBJECT(
            'resource_id', v_resource_id,
            'start_time', p_start_time,
            'end_time', p_end_time
        )
    );

    COMMIT;
    SELECT v_booking_id AS booking_id;
END//

DELIMITER ;

-- Database roles
DROP ROLE IF EXISTS student_role;
CREATE ROLE student_role;
DROP ROLE IF EXISTS faculty_role;
CREATE ROLE faculty_role;
DROP ROLE IF EXISTS admin_role;
CREATE ROLE admin_role;

-- Students create bookings only through the transaction-safe procedure.
GRANT SELECT ON smart_campus_db.RESOURCE TO student_role;
GRANT SELECT ON smart_campus_db.BOOKING TO student_role;
GRANT SELECT ON smart_campus_db.BOOKING_ITEM TO student_role;
GRANT SELECT ON smart_campus_db.APPROVAL TO student_role;
GRANT EXECUTE ON PROCEDURE smart_campus_db.sp_create_booking TO student_role;

-- Faculty can book and view operational records, plus participate in approvals.
GRANT SELECT ON smart_campus_db.RESOURCE TO faculty_role;
GRANT SELECT ON smart_campus_db.BOOKING TO faculty_role;
GRANT SELECT ON smart_campus_db.BOOKING_ITEM TO faculty_role;
GRANT SELECT, INSERT, UPDATE ON smart_campus_db.APPROVAL TO faculty_role;
GRANT SELECT, INSERT ON smart_campus_db.CANCELLATION TO faculty_role;
GRANT EXECUTE ON PROCEDURE smart_campus_db.sp_create_booking TO faculty_role;

-- Admin role manages the application database but retains referential integrity
-- and is not granted database/user administration privileges.
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.RESOURCE TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.BOOKING TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.BOOKING_ITEM TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.APPROVAL TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.CANCELLATION TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.MAINTENANCE TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.USAGE_LOG TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.AUDIT_LOG TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.LOCATION TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.RESOURCE_TYPE TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.DEPARTMENT TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.ROLE TO admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_campus_db.`USER` TO admin_role;

-- Preserve the audit trail by revoking the admin role's DELETE privilege.
REVOKE DELETE ON smart_campus_db.AUDIT_LOG FROM admin_role;

-- Transaction Demonstration 3: roll back an optional step to a savepoint.
-- A temporary table keeps this demonstration isolated from application data.
DROP TEMPORARY TABLE IF EXISTS booking_tcl_savepoint_demo;
CREATE TEMPORARY TABLE booking_tcl_savepoint_demo (
    step_name VARCHAR(50) PRIMARY KEY
);

START TRANSACTION;
INSERT INTO booking_tcl_savepoint_demo (step_name) VALUES ('required step');
SAVEPOINT after_required_step;
INSERT INTO booking_tcl_savepoint_demo (step_name) VALUES ('optional step');
ROLLBACK TO SAVEPOINT after_required_step;
COMMIT;

SELECT * FROM booking_tcl_savepoint_demo;
DROP TEMPORARY TABLE booking_tcl_savepoint_demo;
