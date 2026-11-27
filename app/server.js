const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const { MongoClient } = require('mongodb');

const app = express();
const port = Number(process.env.PORT || 3000);
const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017';
const mongoDbName = process.env.MONGO_DB || 'smart_campus_nosql';

let mongoClient = null;
let maintenanceCollection = null;
const sessions = new Map();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'smart_campus_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'dist')));

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  return `${salt}:${crypto.scryptSync(password, salt, 64).toString('hex')}`;
}

function verifyPassword(password, storedHash) {
  if (typeof storedHash !== 'string') return false;
  const [salt, hash, ...extra] = storedHash.split(':');
  if (salt && hash && !extra.length && /^[a-f0-9]{128}$/i.test(hash)) {
    const expected = Buffer.from(hash, 'hex');
    const actual = crypto.scryptSync(password, salt, expected.length);
    return crypto.timingSafeEqual(actual, expected);
  }
  // Seed rows contain non-verifiable placeholder bcrypt strings; "password" is the demo credential.
  return storedHash.startsWith('$2') && password === 'password';
}

function isAdminRole(roleName) {
  return ['admin', 'staff'].includes(String(roleName || '').trim().toLowerCase());
}

app.post('/api/signup', async (req, res) => {
  const body = req.body;
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return res.status(400).json({ error: 'A JSON object is required.' });
  }
  const firstName = typeof body.first_name === 'string' ? body.first_name.trim() : '';
  const lastName = typeof body.last_name === 'string' ? body.last_name.trim() : '';
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
  const password = typeof body.password === 'string' ? body.password : '';
  const missingFields = [
    !firstName && 'first_name',
    !lastName && 'last_name',
    !email && 'email',
    !password && 'password'
  ].filter(Boolean);
  if (missingFields.length) {
    return res.status(400).json({
      error: `Required fields are missing: ${missingFields.join(', ')}.`,
      missing_fields: missingFields
    });
  }
  if (firstName.length > 50 || lastName.length > 50) return res.status(400).json({ error: 'Names must be 50 characters or fewer.' });
  if (email.length > 150 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ error: 'Enter a valid email address.' });
  }
  if (password.length < 8 || password.length > 128) return res.status(400).json({ error: 'Password must be between 8 and 128 characters.' });
  try {
    const isAdminSignup = email === 'admin@gmail.com'
      || (firstName.toLowerCase() === 'admin' && lastName.toLowerCase() === 'staff');
    const [[existing], [roles]] = await Promise.all([
      pool.execute('SELECT user_id FROM `USER` WHERE email = ? LIMIT 1', [email]),
      isAdminSignup
        ? pool.execute("SELECT role_id, role_name FROM ROLE WHERE LOWER(role_name) IN ('admin', 'staff') ORDER BY FIELD(LOWER(role_name), 'admin', 'staff') LIMIT 1")
        : pool.execute("SELECT role_id, role_name FROM ROLE WHERE LOWER(role_name) = 'student' LIMIT 1")
    ]);
    if (existing.length) return res.status(409).json({ error: 'An account with this email already exists.' });
    if (!roles.length) {
      const requiredRole = isAdminSignup ? 'Admin or Staff' : 'Student';
      console.error(`Unable to register user: ${requiredRole} role is missing from ROLE.`);
      return res.status(500).json({ error: `${requiredRole} role is not configured. Please contact an administrator.` });
    }

    await pool.execute(
      'INSERT INTO `USER` (first_name, last_name, email, password_hash, role_id, department_id, is_active) VALUES (?, ?, ?, ?, ?, NULL, 1)',
      [firstName, lastName, email, hashPassword(password), roles[0].role_id]
    );
    return res.status(201).json({ message: 'User registered successfully' });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'An account with this email already exists.' });
    console.error('Failed to register user:', { code: error.code, sqlMessage: error.sqlMessage });
    return res.status(500).json({ error: 'Unable to register account.' });
  }
});

app.post('/api/login', async (req, res) => {
  const body = req.body;
  if (!body || typeof body.email !== 'string' || typeof body.password !== 'string' || !body.email.trim() || !body.password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }
  try {
    const email = body.email.trim().toLowerCase();
    const loginSql = `
      SELECT u.user_id, u.first_name, u.last_name, CONCAT_WS(' ', u.first_name, u.last_name) AS full_name,
             u.email, u.password_hash, r.role_name
      FROM \`USER\` AS u JOIN ROLE AS r ON r.role_id = u.role_id
      WHERE u.is_active = TRUE AND u.email = ?
      LIMIT 1
    `;
    let [users] = await pool.execute(loginSql, [email]);

    if (!users.length && email === 'admin@gmail.com' && body.password === '12345678') {
      const [adminRoles] = await pool.execute(
        "SELECT role_id, role_name FROM ROLE WHERE LOWER(role_name) IN ('admin', 'staff') ORDER BY FIELD(LOWER(role_name), 'admin', 'staff') LIMIT 1"
      );
      if (!adminRoles.length) {
        return res.status(500).json({ error: 'Admin role is not configured.' });
      }
      try {
        await pool.execute(
          'INSERT INTO `USER` (first_name, last_name, email, password_hash, role_id, department_id, is_active) VALUES (?, ?, ?, ?, ?, NULL, 1)',
          ['Admin', 'Starks', 'admin@gmail.com', hashPassword('12345678'), adminRoles[0].role_id]
        );
      } catch (insertError) {
        if (insertError.code !== 'ER_DUP_ENTRY') throw insertError;
      }
      [users] = await pool.execute(loginSql, [email]);
    }

    // This one-time promotion is limited to the explicitly requested local demo account.
    // It requires the exact demo credentials and matching Admin Staff/Starks identity, so an
    // existing Student role is corrected without allowing normal users to choose a role.
    if (
      users.length
      && email === 'admin@gmail.com'
      && body.password === '12345678'
      && String(users[0].first_name).trim().toLowerCase() === 'admin'
      && ['staff', 'starks'].includes(String(users[0].last_name).trim().toLowerCase())
      && !isAdminRole(users[0].role_name)
      && verifyPassword(body.password, users[0].password_hash)
    ) {
      const [adminRoles] = await pool.execute(
        "SELECT role_id FROM ROLE WHERE LOWER(role_name) IN ('admin', 'staff') ORDER BY FIELD(LOWER(role_name), 'admin', 'staff') LIMIT 1"
      );
      if (!adminRoles.length) return res.status(500).json({ error: 'Admin role is not configured.' });
      await pool.execute('UPDATE `USER` SET role_id = ? WHERE user_id = ?', [adminRoles[0].role_id, users[0].user_id]);
      [users] = await pool.execute(loginSql, [email]);
    }

    if (!users.length || !verifyPassword(body.password, users[0].password_hash)) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }
    const { password_hash, ...user } = users[0];
    user.is_admin = isAdminRole(user.role_name);
    const token = crypto.randomUUID();
    sessions.set(token, user);
    return res.status(200).json({ token, user });
  } catch (error) {
    console.error('Failed to sign in:', { code: error.code, sqlMessage: error.sqlMessage });
    return res.status(500).json({ error: 'Unable to sign in.' });
  }
});

function authenticate(req, res, next) {
  const match = /^Bearer\s+(.+)$/i.exec(req.get('Authorization') || '');
  const user = match && sessions.get(match[1]);
  if (!user) return res.status(401).json({ error: 'Authentication required.' });
  req.user = user;
  return next();
}

app.post('/api/logout', authenticate, (req, res) => {
  const token = /^Bearer\s+(.+)$/i.exec(req.get('Authorization'))[1];
  sessions.delete(token);
  return res.json({ success: true });
});

app.get('/api/resources', async (req, res) => {
  const search = typeof req.query.search === 'string' ? req.query.search.trim() : '';
  const filters = [];
  const values = [];

  if (search) {
    const term = `%${search}%`;
    filters.push(`(
      r.resource_name LIKE ?
      OR r.resource_code LIKE ?
      OR r.description LIKE ?
      OR rt.type_name LIKE ?
      OR l.building_name LIKE ?
      OR l.room_number LIKE ?
    )`);
    values.push(term, term, term, term, term, term);
  }

  const whereClause = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
  const sql = `
    SELECT
      r.resource_id,
      r.resource_code,
      r.resource_name,
      r.resource_type_id,
      rt.type_name AS resource_type,
      r.location_id,
      l.building_name,
      l.floor_number,
      l.room_number,
      l.campus,
      r.capacity,
      r.status,
      r.description
    FROM RESOURCE AS r
    JOIN RESOURCE_TYPE AS rt ON rt.resource_type_id = r.resource_type_id
    LEFT JOIN LOCATION AS l ON l.location_id = r.location_id
    ${whereClause}
    ORDER BY r.resource_name, r.resource_id
  `;

  try {
    const [resources] = await pool.execute(sql, values);
    res.json(resources);
  } catch (error) {
    console.error('Failed to fetch resources:', {
      code: error.code,
      sqlMessage: error.sqlMessage
    });
    res.status(500).json({ success: false, error: 'Unable to fetch resources.' });
  }
});

app.get('/api/bookings', authenticate, async (req, res) => {
  const isAdmin = req.user.is_admin === true;
  const sql = `
    SELECT
      b.booking_id,
      b.user_id,
      CONCAT(u.first_name, ' ', u.last_name) AS booked_by,
      u.email AS user_email,
      bi.resource_id,
      r.resource_name,
      r.resource_code,
      DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date,
      DATE_FORMAT(b.start_time, '%Y-%m-%d %H:%i:%s') AS start_time,
      DATE_FORMAT(b.end_time, '%Y-%m-%d %H:%i:%s') AS end_time,
      b.purpose,
      b.status,
      CONCAT(u.first_name, ' ', u.last_name) AS full_name
    FROM BOOKING AS b
    JOIN \`USER\` AS u ON u.user_id = b.user_id
    LEFT JOIN BOOKING_ITEM AS bi ON bi.booking_id = b.booking_id
    LEFT JOIN RESOURCE AS r ON r.resource_id = bi.resource_id
    ${isAdmin ? '' : 'WHERE b.user_id = ?'}
    ORDER BY CASE WHEN LOWER(b.status) = 'pending' THEN 0 ELSE 1 END, b.booking_id DESC
  `;

  try {
    const [bookings] = await pool.query(sql, isAdmin ? [] : [req.user.user_id]);
    res.json(bookings);
  } catch (error) {
    console.error('Failed to fetch bookings:', {
      code: error.code,
      sqlMessage: error.sqlMessage
    });
    res.status(500).json({ error: 'Unable to fetch bookings.' });
  }
});

app.patch('/api/bookings/:id/decision', authenticate, async (req, res) => {
  if (req.user.is_admin !== true) {
    return res.status(403).json({ error: 'Only Admin Staff can approve or reject bookings.' });
  }

  const bookingId = Number(req.params.id);
  if (!Number.isSafeInteger(bookingId) || bookingId <= 0) {
    return res.status(400).json({ error: 'Booking ID must be a positive integer.' });
  }
  const decision = typeof req.body?.decision === 'string' ? req.body.decision.trim().toLowerCase() : '';
  if (!['approved', 'rejected'].includes(decision)) {
    return res.status(400).json({ error: "decision must be 'approved' or 'rejected'." });
  }
  const remarks = req.body?.remarks == null ? null : req.body.remarks;
  if (remarks !== null && typeof remarks !== 'string') {
    return res.status(400).json({ error: 'remarks must be a string or null.' });
  }

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.query(
      'CALL sp_approve_booking(?, ?, ?, ?, @approval_status_code, @approval_message)',
      [bookingId, req.user.user_id, decision, remarks]
    );
    const [[result]] = await connection.query(
      'SELECT @approval_status_code AS status_code, @approval_message AS message'
    );
    if (Number(result.status_code) !== 1) {
      const message = result.message || 'Unable to process booking decision.';
      if (/does not exist/i.test(message)) return res.status(404).json({ error: message });
      return res.status(409).json({ error: message });
    }
    return res.status(200).json({
      message: decision === 'approved' ? 'Booking approved successfully' : 'Booking rejected',
      booking_id: bookingId,
      status: decision === 'approved' ? 'confirmed' : 'rejected'
    });
  } catch (error) {
    console.error('Failed to process booking decision:', { code: error.code, sqlMessage: error.sqlMessage });
    return res.status(500).json({ error: error.sqlMessage || 'Unable to process booking decision.' });
  } finally {
    if (connection) connection.release();
  }
});

function isValidDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }

  const [year, month, day] = value.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year
    && date.getUTCMonth() === month - 1
    && date.getUTCDate() === day;
}

function normalizeDateTime(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const match = /^(\d{4}-\d{2}-\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?$/.exec(value);
  if (!match || !isValidDate(match[1])) {
    return null;
  }

  const hour = Number(match[2]);
  const minute = Number(match[3]);
  const second = match[4] === undefined ? 0 : Number(match[4]);
  if (hour > 23 || minute > 59 || second > 59) {
    return null;
  }

  return {
    value: `${match[1]} ${match[2]}:${match[3]}:${String(second).padStart(2, '0')}`,
    date: match[1]
  };
}

function validateBooking(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'A JSON object is required.' };
  }

  if (!Number.isSafeInteger(body.user_id) || body.user_id <= 0) {
    return { error: 'user_id must be a positive integer.' };
  }
  if (!Number.isSafeInteger(body.resource_id) || body.resource_id <= 0) {
    return { error: 'resource_id must be a positive integer.' };
  }

  const start = normalizeDateTime(body.start_time);
  const end = normalizeDateTime(body.end_time);
  if (!start || !end) {
    return { error: 'start_time and end_time must be valid DATETIME values.' };
  }

  const bookingDate = body.booking_date === undefined ? start.date : body.booking_date;
  if (!isValidDate(bookingDate)) {
    return { error: 'booking_date must be a valid YYYY-MM-DD date.' };
  }
  if (end.value <= start.value) {
    return { error: 'end_time must be later than start_time.' };
  }

  if (body.purpose !== undefined && body.purpose !== null && typeof body.purpose !== 'string') {
    return { error: 'purpose must be a string or null.' };
  }
  if (typeof body.purpose === 'string' && body.purpose.length > 255) {
    return { error: 'purpose must be no longer than 255 characters.' };
  }

  return {
    values: [
      body.user_id,
      body.resource_id,
      bookingDate,
      start.value,
      end.value,
      body.purpose === undefined ? null : body.purpose
    ]
  };
}

function getProcedureResultSets(result) {
  return Array.isArray(result) ? result[0] : null;
}

app.post('/api/bookings', authenticate, async (req, res) => {
  const startTime = req.body && req.body.start_time;
  const endTime = req.body && req.body.end_time;
  const startDate = new Date(startTime);
  const endDate = new Date(endTime);
  if (
    !normalizeDateTime(startTime)
    || !normalizeDateTime(endTime)
    || !Number.isFinite(startDate.getTime())
    || !Number.isFinite(endDate.getTime())
    || startDate >= endDate
  ) {
    return res.status(400).json({ error: 'End time must be strictly after start time.' });
  }

  const bookingBody = { ...req.body, user_id: req.user.user_id };
  const validation = validateBooking(bookingBody);
  if (validation.error) {
    return res.status(400).json({ success: false, error: validation.error });
  }

  try {
    const [result] = await pool.query(
      'CALL sp_create_booking(?, ?, ?, ?, ?, ?)',
      validation.values
    );
    const resultSets = getProcedureResultSets(result);
    const bookingId = Array.isArray(resultSets) ? resultSets[0]?.booking_id : undefined;

    if (bookingId === undefined) {
      console.error('Booking procedure completed without returning a booking_id.');
      return res.status(500).json({ success: false, error: 'Unable to create booking.' });
    }

    const { user_id, resource_id, start_time, end_time } = bookingBody;
    const booking_id = bookingId;
    console.log('Booking request submitted successfully:', { booking_id, user_id, resource_id, start_time, end_time });

    return res.status(201).json({
      success: true,
      booking_id: bookingId,
      message: 'Booking created successfully.'
    });

  } catch (error) {
    console.error('Failed to create booking:', {
      code: error.code,
      sqlMessage: error.sqlMessage
    });
    if (error.code === 'ER_SIGNAL_EXCEPTION') {
      return res.status(409).json({ error: error.sqlMessage });
    }
    if (error.code === 'ER_CHECK_CONSTRAINT_VIOLATED') {
      return res.status(400).json({
        error: 'Invalid booking input: end time must be after start time and quantity must be at least 1.'
      });
    }
    if (error.code === 'ER_NO_REFERENCED_ROW_2') {
      return res.status(400).json({ error: 'Selected User ID or Resource ID does not exist.' });
    }
    return res.status(500).json({ error: error.sqlMessage || 'Unable to create booking.' });
  }
});

app.delete('/api/bookings/:id', authenticate, async (req, res) => {
  const bookingId = Number(req.params.id);
  if (!Number.isSafeInteger(bookingId) || bookingId <= 0) {
    return res.status(400).json({ error: 'Booking ID must be a positive integer.' });
  }

  let connection;
  let transactionStarted = false;
  try {
    connection = await pool.getConnection();
    await connection.query('START TRANSACTION');
    transactionStarted = true;

    const [bookings] = await connection.execute(
      'SELECT booking_id, user_id, status FROM BOOKING WHERE booking_id = ? FOR UPDATE',
      [bookingId]
    );
    if (!bookings.length) {
      await connection.query('ROLLBACK');
      transactionStarted = false;
      return res.status(404).json({ error: 'Booking not found.' });
    }

    const canCancelAny = req.user.is_admin === true || String(req.user.role_name || '').toLowerCase() === 'coordinator';
    if (!canCancelAny && Number(bookings[0].user_id) !== Number(req.user.user_id)) {
      await connection.query('ROLLBACK');
      transactionStarted = false;
      return res.status(403).json({ error: 'Forbidden: you can only cancel your own bookings.' });
    }

    if (!['pending', 'confirmed'].includes(bookings[0].status)) {
      await connection.query('ROLLBACK');
      transactionStarted = false;
      return res.status(409).json({ error: 'Only pending or approved bookings can be cancelled.' });
    }

    await connection.execute(
      "UPDATE BOOKING SET status = 'cancelled' WHERE booking_id = ?",
      [bookingId]
    );
    await connection.query('COMMIT');
    transactionStarted = false;

    console.log('Booking cancelled successfully:', { booking_id: bookingId });
    return res.status(200).json({
      success: true,
      booking_id: bookingId,
      message: 'Booking cancelled and slot released.'
    });
  } catch (error) {
    if (connection && transactionStarted) {
      try {
        await connection.query('ROLLBACK');
      } catch (rollbackError) {
        console.error('Failed to roll back booking cancellation:', {
          code: rollbackError.code,
          sqlMessage: rollbackError.sqlMessage
        });
      }
    }
    console.error('Failed to cancel booking:', {
      code: error.code,
      sqlMessage: error.sqlMessage
    });
    return res.status(500).json({ error: error.sqlMessage || 'Unable to cancel booking.' });
  } finally {
    if (connection) connection.release();
  }
});

app.use((error, req, res, next) => {
  if (error instanceof SyntaxError && error.status === 400 && 'body' in error) {
    return res.status(400).json({ success: false, error: 'Request body must contain valid JSON.' });
  }
  return next(error);
});

const FALLBACK_MAINTENANCE_SEED = [
  {
    report_id: 'MR-2026-001',
    resource_id: 1,
    resource_code: 'GPU-DGX-01',
    equipment_name: 'NVIDIA DGX Station A100-01',
    resource_name: 'NVIDIA DGX Station A100-01',
    category: 'GPU Computing Server',
    issue_summary: 'Routine liquid cooling and PCIe link inspection',
    severity: 'Low',
    status: 'Completed',
    inspection_date: new Date('2026-11-15T13:00:00Z'),
    technician: { name: 'Ramesh Yadav', staff_id: 'TECH-09' },
    sensor_telemetry: { peak_gpu_temp_celsius: 72.4, fan_rpm: 3800, power_draw_watts: 420 },
    checklist: [
      { check_item: 'Liquid coolant transparency and level', passed: true, notes: 'Coolant level topped up.' },
      { check_item: 'PCIe 4.0 bus link integrity check', passed: true, notes: 'All 8 links at Gen4 x16.' }
    ],
    total_cost_usd: 125.0,
    downtime_hours: 6.0
  }
];

async function getMaintenanceCollection() {
  if (maintenanceCollection) {
    return maintenanceCollection;
  }

  try {
    if (!mongoClient) {
      mongoClient = new MongoClient(mongoUri, { serverSelectionTimeoutMS: 2500 });
    }
    await mongoClient.connect();
    const db = mongoClient.db(mongoDbName);
    await db.command({ ping: 1 });
    const collection = db.collection('maintenance_reports');

    const existingCount = await collection.countDocuments();
    if (existingCount === 0) {
      await collection.insertMany(FALLBACK_MAINTENANCE_SEED);
      console.log('Auto-seeded initial document(s) into MongoDB maintenance_reports.');
    }

    maintenanceCollection = collection;
    return maintenanceCollection;
  } catch (error) {
    console.warn('MongoDB unavailable (graceful fallback active):', error.message);
    if (mongoClient) {
      try {
        await mongoClient.close();
      } catch (_) {}
    }
    mongoClient = null;
    maintenanceCollection = null;
    return null;
  }
}

function normalizeSeverity(value) {
  if (typeof value !== 'string') return null;
  const map = { low: 'Low', medium: 'Medium', high: 'High', critical: 'Critical' };
  return map[value.trim().toLowerCase()] || null;
}

app.get('/api/maintenance-reports', async (req, res) => {
  const col = await getMaintenanceCollection();
  if (!col) {
    return res.status(503).json({
      success: false,
      mongo_connected: false,
      error: 'MongoDB service is currently unavailable.',
      reports: [],
      breakdown: { by_severity: [], by_status: [], by_severity_and_status: [] }
    });
  }

  try {
    const [reports, facetResult] = await Promise.all([
      col.find({}).sort({ created_at: -1, inspection_date: -1, _id: -1 }).toArray(),
      col.aggregate([
        {
          $facet: {
            by_severity: [
              {
                $group: {
                  _id: { $ifNull: ['$severity', 'Unspecified'] },
                  count: { $sum: 1 },
                  total_cost_usd: { $sum: { $ifNull: ['$total_cost_usd', 0] } }
                }
              },
              {
                $project: {
                  _id: 0,
                  severity: '$_id',
                  count: 1,
                  total_cost_usd: { $round: ['$total_cost_usd', 2] }
                }
              },
              { $sort: { count: -1, severity: 1 } }
            ],
            by_status: [
              {
                $group: {
                  _id: { $ifNull: ['$status', 'Unspecified'] },
                  count: { $sum: 1 },
                  total_cost_usd: { $sum: { $ifNull: ['$total_cost_usd', 0] } }
                }
              },
              {
                $project: {
                  _id: 0,
                  status: '$_id',
                  count: 1,
                  total_cost_usd: { $round: ['$total_cost_usd', 2] }
                }
              },
              { $sort: { count: -1, status: 1 } }
            ],
            by_severity_and_status: [
              {
                $group: {
                  _id: {
                    severity: { $ifNull: ['$severity', 'Unspecified'] },
                    status: { $ifNull: ['$status', 'Unspecified'] }
                  },
                  count: { $sum: 1 }
                }
              },
              {
                $project: {
                  _id: 0,
                  severity: '$_id.severity',
                  status: '$_id.status',
                  count: 1
                }
              },
              { $sort: { count: -1, severity: 1, status: 1 } }
            ]
          }
        }
      ]).toArray()
    ]);

    const breakdown = facetResult[0] || {
      by_severity: [],
      by_status: [],
      by_severity_and_status: []
    };

    return res.json({
      success: true,
      mongo_connected: true,
      total: reports.length,
      reports,
      breakdown
    });
  } catch (error) {
    console.error('Failed to fetch maintenance reports from MongoDB:', error.message);
    maintenanceCollection = null;
    return res.status(500).json({ success: false, error: 'Unable to fetch maintenance reports.' });
  }
});

app.post('/api/maintenance-reports', async (req, res) => {
  const body = req.body;
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return res.status(400).json({ success: false, error: 'A JSON object is required.' });
  }

  const resourceId = Number(body.resource_id);
  if (!Number.isSafeInteger(resourceId) || resourceId <= 0) {
    return res.status(400).json({ success: false, error: 'resource_id must be a positive integer.' });
  }

  const resourceName = typeof body.resource_name === 'string' && body.resource_name.trim()
    ? body.resource_name.trim()
    : (typeof body.equipment_name === 'string' && body.equipment_name.trim() ? body.equipment_name.trim() : '');
  if (!resourceName) {
    return res.status(400).json({ success: false, error: 'resource_name is required.' });
  }

  const issueSummary = typeof body.issue_summary === 'string' ? body.issue_summary.trim() : '';
  if (!issueSummary) {
    return res.status(400).json({ success: false, error: 'issue_summary is required.' });
  }

  const severity = normalizeSeverity(body.severity);
  if (!severity) {
    return res.status(400).json({ success: false, error: 'severity must be one of Low, Medium, High, or Critical.' });
  }

  let technician;
  if (typeof body.technician === 'string' && body.technician.trim()) {
    technician = { name: body.technician.trim() };
  } else if (body.technician && typeof body.technician === 'object' && !Array.isArray(body.technician) && typeof body.technician.name === 'string' && body.technician.name.trim()) {
    technician = { ...body.technician, name: body.technician.name.trim() };
  } else {
    return res.status(400).json({ success: false, error: 'technician (name string or object with name) is required.' });
  }

  const telemetry = (body.telemetry && typeof body.telemetry === 'object' && !Array.isArray(body.telemetry))
    ? body.telemetry
    : ((body.sensor_telemetry && typeof body.sensor_telemetry === 'object' && !Array.isArray(body.sensor_telemetry))
        ? body.sensor_telemetry
        : {});

  const checklist = Array.isArray(body.checklist) ? body.checklist : [];
  if (body.checklist !== undefined && !Array.isArray(body.checklist)) {
    return res.status(400).json({ success: false, error: 'checklist must be an array.' });
  }

  const col = await getMaintenanceCollection();
  if (!col) {
    return res.status(503).json({
      success: false,
      mongo_connected: false,
      error: 'MongoDB service is currently unavailable.'
    });
  }

  const now = new Date();
  const doc = {
    report_id: typeof body.report_id === 'string' && body.report_id.trim()
      ? body.report_id.trim()
      : `MR-${now.getUTCFullYear()}-${Date.now()}`,
    resource_id: resourceId,
    ...(typeof body.resource_code === 'string' && body.resource_code.trim()
      ? { resource_code: body.resource_code.trim() }
      : {}),
    resource_name: resourceName,
    equipment_name: resourceName,
    ...(typeof body.category === 'string' && body.category.trim()
      ? { category: body.category.trim() }
      : {}),
    issue_summary: issueSummary,
    severity,
    status: typeof body.status === 'string' && body.status.trim() ? body.status.trim() : 'Open',
    inspection_date: now,
    created_at: now,
    technician,
    telemetry,
    sensor_telemetry: telemetry,
    checklist,
    ...(Array.isArray(body.parts_replaced) ? { parts_replaced: body.parts_replaced } : {}),
    total_cost_usd: Number.isFinite(Number(body.total_cost_usd)) ? Number(body.total_cost_usd) : 0,
    downtime_hours: Number.isFinite(Number(body.downtime_hours)) ? Number(body.downtime_hours) : 0
  };

  try {
    const result = await col.insertOne(doc);
    console.log('Maintenance report logged in MongoDB:', { report_id: doc.report_id, resource_id: doc.resource_id, severity: doc.severity });
    return res.status(201).json({
      success: true,
      insertedId: result.insertedId,
      report_id: doc.report_id,
      report: doc
    });
  } catch (error) {
    console.error('Failed to insert maintenance report into MongoDB:', error.message);
    maintenanceCollection = null;
    return res.status(500).json({ success: false, error: 'Unable to save maintenance report.' });
  }
});

app.listen(port, async () => {
  console.log(`Smart Campus API listening on port ${port}`);
  console.log(`Open the app: http://localhost:${port}`);
  const col = await getMaintenanceCollection();
  if (col) {
    console.log(`Connected to MongoDB (${mongoDbName}.maintenance_reports)`);
  }
});
