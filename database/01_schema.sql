-- ============================================================================
-- Smart Campus Resource & Lab Booking System
-- Database Schema (MySQL) — 13 Normalized Tables
-- Version : 2.0
-- Created : 2026-11-22
-- ============================================================================

CREATE DATABASE IF NOT EXISTS smart_campus_db;
USE smart_campus_db;

-- Drop tables in reverse dependency order for safe re-runs
DROP TABLE IF EXISTS AUDIT_LOG;
DROP TABLE IF EXISTS CANCELLATION;
DROP TABLE IF EXISTS USAGE_LOG;
DROP TABLE IF EXISTS MAINTENANCE;
DROP TABLE IF EXISTS APPROVAL;
DROP TABLE IF EXISTS BOOKING_ITEM;
DROP TABLE IF EXISTS BOOKING;
DROP TABLE IF EXISTS RESOURCE;
DROP TABLE IF EXISTS RESOURCE_TYPE;
DROP TABLE IF EXISTS LOCATION;
DROP TABLE IF EXISTS `USER`;
DROP TABLE IF EXISTS ROLE;
DROP TABLE IF EXISTS DEPARTMENT;

-- ============================================================================
-- 1. DEPARTMENT
-- ============================================================================
CREATE TABLE DEPARTMENT (
    department_id   INT             AUTO_INCREMENT,
    department_name VARCHAR(100)    NOT NULL,
    head_of_dept    VARCHAR(100),
    contact_email   VARCHAR(150),
    phone           VARCHAR(20),
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (department_id),
    UNIQUE  KEY uq_department_name (department_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM department;

-- ============================================================================
-- 2. ROLE  (Business-rule table: booking-hour caps & approval policies)
-- ============================================================================
CREATE TABLE ROLE (
    role_id               INT            AUTO_INCREMENT,
    role_name             VARCHAR(50)    NOT NULL COMMENT 'e.g. student, faculty, lab_assistant, admin',
    max_booking_hours     SMALLINT       NOT NULL DEFAULT 4
                                         COMMENT 'Max hours a user with this role may book per day',
    max_advance_days      SMALLINT       NOT NULL DEFAULT 7
                                         COMMENT 'How many days in advance a booking may be placed',
    requires_approval     BOOLEAN        NOT NULL DEFAULT TRUE
                                         COMMENT 'Whether bookings by this role need an approver',
    concurrent_bookings   SMALLINT       NOT NULL DEFAULT 1
                                         COMMENT 'Max overlapping active bookings allowed',
    description           VARCHAR(255),
    created_at            DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (role_id),
    UNIQUE  KEY uq_role_name (role_name),
    CONSTRAINT chk_max_booking_hours  CHECK (max_booking_hours  > 0),
    CONSTRAINT chk_max_advance_days   CHECK (max_advance_days   > 0),
    CONSTRAINT chk_concurrent         CHECK (concurrent_bookings > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- SELECT * FROM role;

-- Seed the four default roles
INSERT INTO ROLE (role_name, max_booking_hours, max_advance_days, requires_approval, concurrent_bookings, description)
VALUES
    ('student',        2,  7, TRUE,  1, 'Undergraduate / postgraduate student'),
    ('faculty',        8, 30, FALSE, 3, 'Teaching or research faculty'),
    ('lab_assistant',  6, 14, FALSE, 2, 'Lab technician or assistant'),
    ('admin',         24, 90, FALSE, 5, 'System administrator — unrestricted');
SELECT * FROM role;
-- ============================================================================
-- 3. USER
-- ============================================================================
CREATE TABLE `USER` (
    user_id         INT             AUTO_INCREMENT,
    first_name      VARCHAR(50)     NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    email           VARCHAR(150)    NOT NULL,
    password_hash   VARCHAR(255)    NOT NULL,
    phone           VARCHAR(20),
    role_id         INT             NOT NULL,
    department_id   INT,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id),
    UNIQUE  KEY uq_user_email (email),
    CONSTRAINT fk_user_role
        FOREIGN KEY (role_id) REFERENCES ROLE (role_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_user_department
        FOREIGN KEY (department_id) REFERENCES DEPARTMENT (department_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT * FROM user;

-- ============================================================================
-- 4. LOCATION
-- ============================================================================
CREATE TABLE LOCATION (
    location_id     INT             AUTO_INCREMENT,
    building_name   VARCHAR(100)    NOT NULL,
    floor_number    SMALLINT,
    room_number     VARCHAR(20),
    campus          VARCHAR(50)     NOT NULL DEFAULT 'Main Campus',
    capacity        INT             CHECK (capacity >= 0),
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (location_id),
    UNIQUE  KEY uq_location (building_name, floor_number, room_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM location;

-- ============================================================================
-- 5. RESOURCE_TYPE
-- ============================================================================
CREATE TABLE RESOURCE_TYPE (
    resource_type_id INT            AUTO_INCREMENT,
    type_name        VARCHAR(80)    NOT NULL,
    description      TEXT,
    created_at       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (resource_type_id),
    UNIQUE  KEY uq_resource_type_name (type_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM resource_type;

-- ============================================================================
-- 6. RESOURCE
-- ============================================================================
CREATE TABLE RESOURCE (
    resource_id      INT            AUTO_INCREMENT,
    resource_code    VARCHAR(30)    NOT NULL COMMENT 'Human-readable code, e.g. Lab-305',
    resource_name    VARCHAR(120)   NOT NULL,
    resource_type_id INT            NOT NULL,
    location_id      INT,
    capacity         INT            CHECK (capacity >= 0),
    status           ENUM('available', 'occupied', 'under_maintenance', 'retired')
                                    NOT NULL DEFAULT 'available',
    description      TEXT,
    created_at       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (resource_id),
    UNIQUE  KEY uq_resource_code (resource_code),
    CONSTRAINT fk_resource_type
        FOREIGN KEY (resource_type_id) REFERENCES RESOURCE_TYPE (resource_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_resource_location
        FOREIGN KEY (location_id) REFERENCES LOCATION (location_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM resource;

-- ============================================================================
-- 7. BOOKING
-- ============================================================================
CREATE TABLE BOOKING (
    booking_id      INT             AUTO_INCREMENT,
    user_id         INT             NOT NULL,
    booking_date    DATE            NOT NULL,
    start_time      DATETIME        NOT NULL,
    end_time        DATETIME        NOT NULL,
    purpose         VARCHAR(255),
    status          ENUM('pending', 'confirmed', 'cancelled', 'completed', 'rejected')
                                    NOT NULL DEFAULT 'pending',
    total_resources SMALLINT        NOT NULL DEFAULT 1 CHECK (total_resources >= 1),
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (booking_id),
    CONSTRAINT fk_booking_user
        FOREIGN KEY (user_id) REFERENCES `USER` (user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_booking_time
        CHECK (end_time > start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM booking;

-- ============================================================================
-- 8. BOOKING_ITEM  (junction: one booking can reserve multiple resources)
-- ============================================================================
CREATE TABLE BOOKING_ITEM (
    booking_item_id INT             AUTO_INCREMENT,
    booking_id      INT             NOT NULL,
    resource_id     INT             NOT NULL,
    start_time      DATETIME        NOT NULL,
    end_time        DATETIME        NOT NULL,
    quantity        SMALLINT        NOT NULL DEFAULT 1 CHECK (quantity >= 1),
    notes           VARCHAR(255),
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (booking_item_id),
    UNIQUE  KEY uq_booking_resource (booking_id, resource_id),
    CONSTRAINT fk_bi_booking
        FOREIGN KEY (booking_id) REFERENCES BOOKING (booking_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_bi_resource
        FOREIGN KEY (resource_id) REFERENCES RESOURCE (resource_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_item_time
        CHECK (end_time > start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM booking_item;

-- ============================================================================
-- 9. APPROVAL
-- ============================================================================
CREATE TABLE APPROVAL (
    approval_id     INT             AUTO_INCREMENT,
    booking_id      INT             NOT NULL,
    approver_id     INT             NOT NULL,
    decision        ENUM('approved', 'rejected', 'pending')
                                    NOT NULL DEFAULT 'pending',
    remarks         TEXT,
    decided_at      DATETIME,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (approval_id),
    UNIQUE  KEY uq_approval_booking (booking_id),
    CONSTRAINT fk_approval_booking
        FOREIGN KEY (booking_id) REFERENCES BOOKING (booking_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_approval_approver
        FOREIGN KEY (approver_id) REFERENCES `USER` (user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM approval;

-- ============================================================================
-- 10. MAINTENANCE
-- ============================================================================
CREATE TABLE MAINTENANCE (
    maintenance_id  INT             AUTO_INCREMENT,
    resource_id     INT             NOT NULL,
    reported_by     INT,
    assigned_to     INT,
    issue_title     VARCHAR(150)    NOT NULL,
    description     TEXT,
    priority        ENUM('low', 'medium', 'high', 'critical')
                                    NOT NULL DEFAULT 'medium',
    status          ENUM('open', 'in_progress', 'resolved', 'closed')
                                    NOT NULL DEFAULT 'open',
    reported_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at     DATETIME,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (maintenance_id),
    CONSTRAINT fk_maint_resource
        FOREIGN KEY (resource_id) REFERENCES RESOURCE (resource_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_maint_reporter
        FOREIGN KEY (reported_by) REFERENCES `USER` (user_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_maint_assignee
        FOREIGN KEY (assigned_to) REFERENCES `USER` (user_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM maintenance;

-- ============================================================================
-- 11. USAGE_LOG
-- ============================================================================
CREATE TABLE USAGE_LOG (
    log_id          INT             AUTO_INCREMENT,
    booking_id      INT             NOT NULL,
    resource_id     INT             NOT NULL,
    user_id         INT             NOT NULL,
    check_in_time   DATETIME,
    check_out_time  DATETIME,
    actual_usage    TEXT            COMMENT 'Free-text notes on actual usage',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (log_id),
    CONSTRAINT fk_ulog_booking
        FOREIGN KEY (booking_id) REFERENCES BOOKING (booking_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ulog_resource
        FOREIGN KEY (resource_id) REFERENCES RESOURCE (resource_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ulog_user
        FOREIGN KEY (user_id) REFERENCES `USER` (user_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_checkout_after_checkin
        CHECK (check_out_time IS NULL OR check_out_time > check_in_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM usage_log;

-- ============================================================================
-- 12. CANCELLATION
-- ============================================================================
CREATE TABLE CANCELLATION (
    cancellation_id INT             AUTO_INCREMENT,
    booking_id      INT             NOT NULL,
    cancelled_by    INT             NOT NULL,
    reason          TEXT,
    cancelled_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (cancellation_id),
    UNIQUE  KEY uq_cancel_booking (booking_id),
    CONSTRAINT fk_cancel_booking
        FOREIGN KEY (booking_id) REFERENCES BOOKING (booking_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cancel_user
        FOREIGN KEY (cancelled_by) REFERENCES `USER` (user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM cancellation;

-- ============================================================================
-- 13. AUDIT_LOG  (Business-rule table: immutable ledger of booking changes)
-- ============================================================================
CREATE TABLE AUDIT_LOG (
    audit_id        BIGINT          AUTO_INCREMENT,
    booking_id      INT             NOT NULL,
    changed_by      INT             NOT NULL,
    action          ENUM('created', 'updated', 'confirmed', 'cancelled',
                         'rejected', 'completed', 'approval_granted',
                         'approval_denied')
                                    NOT NULL,
    old_status      VARCHAR(30)     COMMENT 'Status before the change',
    new_status      VARCHAR(30)     COMMENT 'Status after the change',
    change_details  JSON            COMMENT 'Structured diff / extra metadata',
    ip_address      VARCHAR(45)     COMMENT 'IPv4 or IPv6 of the actor',
    user_agent      VARCHAR(255)    COMMENT 'Browser / client identifier',
    changed_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (audit_id),
    CONSTRAINT fk_audit_booking
        FOREIGN KEY (booking_id) REFERENCES BOOKING (booking_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_audit_user
        FOREIGN KEY (changed_by) REFERENCES `USER` (user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT * FROM audit_log;


-- ============================================================================
-- Helpful Indexes
-- ============================================================================
CREATE INDEX idx_booking_user        ON BOOKING (user_id);
CREATE INDEX idx_booking_status      ON BOOKING (status);
CREATE INDEX idx_booking_dates       ON BOOKING (start_time, end_time);
CREATE INDEX idx_bi_resource         ON BOOKING_ITEM (resource_id);
CREATE INDEX idx_resource_status     ON RESOURCE (status);
CREATE INDEX idx_maintenance_status  ON MAINTENANCE (status);
CREATE INDEX idx_usage_log_user      ON USAGE_LOG (user_id);
CREATE INDEX idx_audit_booking       ON AUDIT_LOG (booking_id);
CREATE INDEX idx_audit_changed_at    ON AUDIT_LOG (changed_at);
CREATE INDEX idx_audit_action        ON AUDIT_LOG (action);

-- ============================================================================
-- End of Schema
-- ============================================================================
