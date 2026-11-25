require('dotenv').config();
require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
const port = Number(process.env.PORT || 3000);

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

app.post('/api/bookings', async (req, res) => {
  const validation = validateBooking(req.body);
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
    const databaseMessage = error.sqlMessage || error.message || '';
    if (/already booked|overlap/i.test(databaseMessage)) {
      return res.status(409).json({ success: false, error: databaseMessage });
    }
    if (error.code === 'ER_SIGNAL_EXCEPTION' || error.errno === 1644) {
      return res.status(400).json({
        success: false,
        error: databaseMessage || 'Booking validation failed.'
      });
    }
    if (error.code === 'ER_NO_REFERENCED_ROW_2' || error.errno === 1452) {
      return res.status(400).json({
        success: false,
        error: 'user_id or resource_id does not identify an existing record.'
      });
    }
    if (error.code === 'ER_DUP_ENTRY' || error.errno === 1062) {
      return res.status(409).json({ success: false, error: 'The booking conflicts with an existing record.' });
    }

    return res.status(500).json({ success: false, error: 'Unable to create booking.' });
  }
});

app.use((error, req, res, next) => {
  if (error instanceof SyntaxError && error.status === 400 && 'body' in error) {
    return res.status(400).json({ success: false, error: 'Request body must contain valid JSON.' });
  }
  return next(error);
});

app.listen(port, () => {
  console.log(`Smart Campus API listening on port ${port}`);
});
