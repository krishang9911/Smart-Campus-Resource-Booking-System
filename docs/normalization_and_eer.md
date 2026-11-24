# Conceptual EER Design, Business Rules & Normalization Proofs
**Project:** Smart Campus Resource & Lab Booking System  
**Branch:** `partner-a-core-concurrency`  

---

## 1. Domain Business Rules
1. **User Identity & Role Specialization:** Every campus user belongs to one `DEPARTMENT` (`1:N`) and holds one system `ROLE` (`1:N`) defining booking limits (`max_booking_hours`) and whether reservations require administrative sign-off (`requires_approval`). `USER` is modeled using disjoint `(d)` specialization into `Student`, `Faculty`, and `Staff_admin`.
2. **Resource Cataloging & Current Location:** Each `RESOURCE` has a unique `resource_code` (e.g., `Lab-305`), belongs to one `RESOURCE_TYPE` (`1:N`), is owned by one `DEPARTMENT` (`1:N`), and resides at one **current** physical `LOCATION` (`1:N`). Historical room transfers overwrite `location_id`, whereas all repair incidents are retained historically in `MAINTENANCE` (`1:N`).
3. **Multi-Resource Atomic Bookings ($M:N$ Decomposition):** One `USER` creates many `BOOKING` requests (`1:N`). Because a single booking can reserve multiple resources across specific time windows (`start_time`, `end_time`, `quantity`), the $M:N$ relationship between `BOOKING` and `RESOURCE` is resolved through the associative entity `BOOKING_ITEM` (`1:N` from `BOOKING` via `< includes >`, and `1:N` from `RESOURCE` via `< reserves >`).
4. **Conflict & Maintenance Prevention:** No two active (`Pending` or `Confirmed`) `BOOKING_ITEM` rows for the same `resource_id` may overlap in time (`new_start < existing_end AND new_end > existing_start`), nor can a resource be booked while undergoing active `MAINTENANCE`.
5. **Approval Authority:** Only `Staff_admin` coordinators (`1:N` via `< issues >`) may issue an `APPROVAL` decision (`1:1` with `BOOKING` via `< receives >`).
6. **Lifecycle Tracking & Auditability:** Each `BOOKING` has at most one `USAGE_LOG` (`1:1` check-in/check-out record) and at most one `CANCELLATION` record (`1:1`), while every status transition generates an immutable entry in `AUDIT_LOG` (`1:N`).

---

## 2. Conceptual EER Model Summary (`screenshots/01_eer_diagram.png`)
* **Entities & Specialization:** 13 core relational tables plus 3 disjoint `(d)` subtypes (`Student`, `Faculty`, `Staff_admin`) inheriting from the `USER` superclass.
* **Cardinality Ratios:**
  * **`1:1` Relationships (3):** `BOOKING` $\leftrightarrow$ `APPROVAL` (`< receives >`), `BOOKING` $\leftrightarrow$ `USAGE_LOG` (`< recorded_in >`), and `BOOKING` $\leftrightarrow$ `CANCELLATION` (`< results_in >`) — enforced via `UNIQUE` foreign keys on `booking_id`.
  * **`1:N` Relationships (11):** `ROLE` $\rightarrow$ `USER`, `DEPARTMENT` $\rightarrow$ `USER`, `DEPARTMENT` $\rightarrow$ `RESOURCE`, `LOCATION` $\rightarrow$ `RESOURCE`, `RESOURCE_TYPE` $\rightarrow$ `RESOURCE`, `RESOURCE` $\rightarrow$ `MAINTENANCE`, `USER` $\rightarrow$ `BOOKING`, `BOOKING` $\rightarrow$ `BOOKING_ITEM`, `RESOURCE` $\rightarrow$ `BOOKING_ITEM`, `Staff_admin` $\rightarrow$ `APPROVAL`, and `BOOKING` $\rightarrow$ `AUDIT_LOG`.
* **Participation Constraints:**
  * **Total (`===`):** All child/foreign-key sides (`USER` in `< assigned >`/`< belongs_to >`, `RESOURCE` in `< owns >`/`< houses >`/`< categorizes >`, `BOOKING` in `< creates >`, `BOOKING_ITEM` in `< includes >`/`< reserves >`, `MAINTENANCE`, `APPROVAL`, `USAGE_LOG`, `CANCELLATION`, `AUDIT_LOG`) as well as `BOOKING` in `< includes >` (every booking must include at least one reserved item).
  * **Partial (`—`):** All parent/optional sides where zero child records may exist initially (`ROLE`, `DEPARTMENT`, `LOCATION`, `RESOURCE_TYPE`, `RESOURCE`, `USER`, `Staff_admin`, and `BOOKING` with respect to optional approval, cancellation, usage log, or audit entries).

---

## 3. Functional Dependencies (FDs) & Candidate Keys

| Table | Candidate Key(s) | Non-Trivial Functional Dependencies |
| :--- | :--- | :--- |
| **`ROLE`** | `role_id`, `role_name` | `role_id -> {role_name, max_booking_hours, requires_approval}`<br>`role_name -> {role_id, max_booking_hours, requires_approval}` |
| **`DEPARTMENT`** | `dept_id`, `dept_name` | `dept_id -> {dept_name, building_code}`<br>`dept_name -> {dept_id, building_code}` |
| **`USER`** | `user_id`, `email` | `user_id -> {full_name, email, phone, role_id, dept_id}`<br>`email -> {user_id, full_name, phone, role_id, dept_id}` |
| **`LOCATION`** | `location_id`, `(building_name, floor_no, room_no)` | `location_id -> {building_name, floor_no, room_no}`<br>`(building_name, floor_no, room_no) -> location_id` |
| **`RESOURCE_TYPE`** | `type_id`, `type_name` | `type_id -> {type_name, category}`<br>`type_name -> {type_id, category}` |
| **`RESOURCE`** | `resource_id`, `resource_code` | `resource_id -> {resource_code, resource_name, capacity, status, dept_id, location_id, type_id}`<br>`resource_code -> {resource_id, resource_name, capacity, status, dept_id, location_id, type_id}` |
| **`MAINTENANCE`** | `maintenance_id` | `maintenance_id -> {resource_id, issue_description, start_date, end_date, repair_status}` |
| **`BOOKING`** | `booking_id` | `booking_id -> {user_id, purpose, booking_status, created_at}` |
| **`BOOKING_ITEM`** | `item_id` | `item_id -> {booking_id, resource_id, start_time, end_time, quantity}` |
| **`APPROVAL`** | `approval_id`, `booking_id` | `approval_id -> {booking_id, approver_id, decision, remarks, decided_at}`<br>`booking_id -> {approval_id, approver_id, decision, remarks, decided_at}` |
| **`CANCELLATION`** | `cancellation_id`, `booking_id` | `cancellation_id -> {booking_id, cancelled_by, reason, cancelled_at}`<br>`booking_id -> {cancellation_id, cancelled_by, reason, cancelled_at}` |
| **`USAGE_LOG`** | `usage_id`, `booking_id` | `usage_id -> {booking_id, check_in_time, check_out_time, remarks}`<br>`booking_id -> {usage_id, check_in_time, check_out_time, remarks}` |
| **`AUDIT_LOG`** | `log_id` | `log_id -> {booking_id, action_type, old_status, new_status, changed_by, changed_at}` |

---

## 4. Normalization Analysis (1NF $\rightarrow$ 3NF / BCNF)

### First Normal Form (1NF)
* Every attribute across all 13 relations contains atomic, single-valued data with no repeating groups or comma-separated lists.
* Multi-resource bookings are decomposed into individual atomic line-item tuples inside `BOOKING_ITEM`, and every table defines an explicit Primary Key.

### Second Normal Form (2NF)
* Every relation is already in 1NF and uses a single-attribute surrogate Primary Key (`role_id`, `user_id`, `resource_id`, `booking_id`, `item_id`, etc.).
* Because no relation relies on a composite primary key, partial functional dependencies on a proper subset of a primary key cannot occur.

### Third Normal Form (3NF) & Boyce-Codd Normal Form (BCNF)
A relation $R$ is in **3NF** if for every non-trivial functional dependency $X \rightarrow A$, either $X$ is a superkey or $A$ is a prime attribute, and in **BCNF** if every determinant $X$ is a superkey.

1. **Decomposition of `ROLE` from `USER` (Eliminating Transitive Dependency):**
   * *Anomaly Before Decomposition:* Storing `role_name`, `max_booking_hours`, and `requires_approval` inside `USER` creates the transitive dependency `user_id -> role_id -> {role_name, max_booking_hours, requires_approval}`, causing update anomalies when a role's booking limit changes and insertion anomalies before any user holds that role.
   * *Normalized Resolution:* Separated into `ROLE(role_id, role_name, max_booking_hours, requires_approval)` and `USER(..., role_id)`. Both determinants (`role_id`, `role_name`) are candidate keys in `ROLE`, satisfying **3NF and BCNF**.
2. **Decomposition of `LOCATION` and `RESOURCE_TYPE` from `RESOURCE`:**
   * *Anomaly Before Decomposition:* Keeping `building_name`, `floor_no`, `room_no`, and `category` inside `RESOURCE` introduces transitive chains `resource_id -> location_id -> {building_name, floor_no, room_no}` and `resource_id -> type_id -> {type_name, category}`.
   * *Normalized Resolution:* Extracted into `LOCATION` and `RESOURCE_TYPE`. Every determinant in both relations is a candidate key (**BCNF**).
3. **Decomposition of `AUDIT_LOG` from `BOOKING`:**
   * *Anomaly Before Decomposition:* Storing status-transition logs inside `BOOKING` either overwrites prior audit states or introduces repeating/multi-valued attributes.
   * *Normalized Resolution:* Isolated into `AUDIT_LOG(log_id, booking_id, action_type, old_status, new_status, changed_by, changed_at)` where `log_id` is the sole determinant (**BCNF**).
4. **1:1 Lifecycle Relations (`APPROVAL`, `CANCELLATION`, `USAGE_LOG`):**
   * Separated from `BOOKING` so conditional lifecycle events (which only exist once a booking is approved, cancelled, or checked into) avoid `NULL`-heavy tuples and transitive dependencies on `approver_id` or `cancelled_by` inside `BOOKING`. Every determinant (`approval_id`, `booking_id`, `cancellation_id`, `usage_id`) is a candidate key, placing all 13 tables in **3NF and BCNF**.