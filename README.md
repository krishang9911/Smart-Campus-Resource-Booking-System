# Smart Campus Resource & Lab Booking System

Project 1 for **ETCCMS304**: a normalized MySQL booking system with transactional
conflict prevention, a Node.js/Express API, a browser dashboard, and an optional
MongoDB maintenance-report extension.

See the [final project report](docs/FINAL_PROJECT_REPORT.md) for the seven-phase
capstone write-up, schema analysis, query explanations, and test evidence.

## Requirements

- MySQL 8.4 (recommended; the SQL uses roles, window functions, checks, and
  `EXCEPT`)
- Node.js 20.19 or newer and npm (or a newer supported release compatible
  with the MongoDB Node.js driver 7)
- MongoDB Community Server and `mongosh` for the NoSQL demo and maintenance
  panel; MongoDB is optional for the MySQL booking features
- PowerShell on Windows, or an equivalent terminal

## 1. Create the MySQL schema and seed data

Run the SQL scripts once, in this order, using MySQL Workbench or a MySQL 8.4
client with privileges to create tables, routines, triggers, and roles:

1. `database/01_schema.sql`
2. `database/02_seed.sql`
3. `database/03_triggers_and_rbac.sql`
4. `database/04_queries_and_functions.sql`

The schema script creates `smart_campus_db`. The seed script inserts the
project's fixed IDs and sample data; run it only against a fresh schema. Its
13 table inserts total **307 seeded rows**. The final script includes example
procedure calls (including an approval example) and before/after
`EXPLAIN ANALYZE` statements, so run it on a development database.

PowerShell alternative from the repository root:

```powershell
Get-Content .\database\01_schema.sql -Raw | mysql -h localhost -u root -p
Get-Content .\database\02_seed.sql -Raw | mysql -h localhost -u root -p
Get-Content .\database\03_triggers_and_rbac.sql -Raw | mysql -h localhost -u root -p
Get-Content .\database\04_queries_and_functions.sql -Raw | mysql -h localhost -u root -p
```

The role statements in `03_triggers_and_rbac.sql` require an account allowed to
create roles and grant/revoke privileges. The scripts do not create MySQL login
accounts or assign roles to accounts; do that separately for a deployment.

## 2. Configure and install the API

Copy the placeholder template, then edit `app/.env` (ignored by Git) with your
local connection settings:

```powershell
Copy-Item .\app\.env.example .\app\.env
```

```dotenv
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_mysql_user
DB_PASSWORD=your_local_mysql_password
DB_NAME=smart_campus_db
MONGO_URI=mongodb://127.0.0.1:27017
MONGO_DB=smart_campus_nosql
PORT=3000
```

Use an application-specific MySQL account with only the permissions the API
needs. Do not commit `app/.env` or put real credentials in a tracked file.

Install dependencies and start the server:

```powershell
Set-Location .\app
npm install
npm start
```

Open [http://localhost:3000](http://localhost:3000). Express serves the
dashboard from `app/index.html` and the API from the same origin. Stop the
server with **Ctrl+C**.

## 3. MongoDB extension

Start MongoDB locally before starting the API if you want to use maintenance
reports and telemetry. When MongoDB is unavailable, the dashboard's booking
and resource features remain usable; maintenance-report endpoints return a
service-unavailable response.

To run the standalone CRUD and aggregation demonstration from the repository
root:

```powershell
mongosh .\nosql\mongo_demo.js
```

**Destructive demo behavior:** the script drops and recreates
`smart_campus_nosql.maintenance_reports` before inserting its 15 example
documents. Do not run it against a collection containing data you need.

## API overview

| Method | Route | Purpose |
| --- | --- | --- |
| `GET` | `/api/resources?search=...` | Search inventory using parameterized SQL |
| `GET` | `/api/bookings` | Return the latest 25 bookings with resource and user labels |
| `POST` | `/api/bookings` | Validate and submit a pending booking through `sp_create_booking` |
| `DELETE` | `/api/bookings/:id` | Cancel a pending/confirmed booking transactionally and release its slot |
| `GET` | `/api/maintenance-reports` | Read MongoDB reports and grouped summaries |
| `POST` | `/api/maintenance-reports` | Validate and add a MongoDB maintenance report |

The sample dashboard has no login/session layer; its user ID field is for
demonstration and must not be treated as authentication in a production
deployment.

## Validation and project files

- Seed row-count query: `database/02_seed.sql`
- Stored procedures, triggers, roles, and savepoint example:
  `database/03_triggers_and_rbac.sql`
- Approval procedure, utilization function, seven analytical queries, view,
  and index benchmark: `database/04_queries_and_functions.sql`
- MongoDB CRUD and aggregation: `nosql/mongo_demo.js`
- Browser app and API: `app/index.html` and `app/server.js`
- Capstone report and evidence: `docs/FINAL_PROJECT_REPORT.md` and `screenshots/`

The report distinguishes requirements and conceptual modeling from what is
currently enforced by the SQL procedures and API.
