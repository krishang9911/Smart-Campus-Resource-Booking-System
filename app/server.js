
import express from "express";
import mysql from "mysql2/promise";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// MySQL Database Connection
const db = mysql.createPool({
    host: process.env.DB_HOST || "localhost",
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "smart_campus_db",
    waitForConnections: true,
    connectionLimit: 10
});

// Test API
app.get("/", (req, res) => {
    res.send("Smart Campus API is running!");
});

// Test Database Connection
app.get("/api/test-db", async (req, res) => {
    try {
        const connection = await db.getConnection();
        connection.release();

        res.json({
            success: true,
            message: "MySQL connected successfully!"
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// GET: Fetch all resources
app.get("/api/resources", async (req, res) => {
    try {
        const { status, type_id } = req.query;

        let sql = `
            SELECT *
            FROM RESOURCE
            WHERE 1 = 1
        `;

        const values = [];

        if (status) {
            sql += " AND status = ?";
            values.push(status);
        }

        if (type_id) {
            sql += " AND resource_type_id = ?";
            values.push(type_id);
        }

        const [resources] = await db.query(sql, values);

        res.json({
            success: true,
            data: resources
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// POST: Create a new booking
app.post("/api/bookings", async (req, res) => {
    const {
        user_id,
        title,
        purpose,
        resource_id,
        start_time,
        end_time
    } = req.body;

    if (
        !user_id ||
        !title ||
        !purpose ||
        !resource_id ||
        !start_time ||
        !end_time
    ) {
        return res.status(400).json({
            success: false,
            error: "Please provide all required booking details."
        });
    }

    let connection;

    try {
        connection = await db.getConnection();

        await connection.beginTransaction();

        // Insert booking record
        const [bookingResult] = await connection.query(
            `INSERT INTO BOOKING
            (user_id, title, purpose, booking_date)
            VALUES (?, ?, ?, CURDATE())`,
            [user_id, title, purpose]
        );

        const bookingId = bookingResult.insertId;

        // Insert booking item
        await connection.query(
            `INSERT INTO BOOKING_ITEM
            (booking_id, resource_id, start_time, end_time)
            VALUES (?, ?, ?, ?)`,
            [bookingId, resource_id, start_time, end_time]
        );

        await connection.commit();

        res.status(201).json({
            success: true,
            message: "Booking created successfully!",
            booking_id: bookingId
        });

    } catch (error) {
        if (connection) {
            await connection.rollback();
        }

        res.status(500).json({
            success: false,
            error: error.message
        });

    } finally {
        if (connection) {
            connection.release();
        }
    }
});

// Server Start
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});
