const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const dns = require("dns");

require("dotenv").config();

// Attempt to resolve DNS issues for MongoDB Atlas
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const authRoutes = require("./routes/authRoutes");
const medicineRoutes = require("./routes/medicineRoutes");
const interactionRoutes = require("./routes/interactionRoutes");
const reminderRoutes = require("./routes/reminderRoutes");

const app = express();

app.use(cors());
app.use(express.json());

// Request logging for debugging
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    if (req.method === 'POST') {
        const body = { ...req.body };
        if (body.password) body.password = '********';
        console.log('Body:', body);
    }
    next();
});

// MongoDB Connection with improved options
const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI, {
            serverSelectionTimeoutMS: 5000, 
        });
        console.log(`✅ MongoDB Connected to: ${mongoose.connection.name}`);
    } catch (err) {
        console.error("❌ MongoDB Connection Error:", err.message);
        console.log("💡 Tip: Check if your IP address is whitelisted in MongoDB Atlas: https://www.mongodb.com/docs/atlas/security-whitelist/");
    }
};

connectDB();

app.use("/api", authRoutes);
app.use("/api", medicineRoutes);
app.use("/api", interactionRoutes);
app.use("/api", reminderRoutes);

app.get("/", (req, res) => {
    res.send("MediCheck AI API is running...");
});

// Global Error Handler to catch 500 errors and provide more info
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        success: false,
        message: "Internal Server Error",
        error: err.message
    });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
});