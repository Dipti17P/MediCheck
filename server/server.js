const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const dns = require("dns");
const rateLimit = require("express-rate-limit");
const Sentry = require("@sentry/node");
const { nodeProfilingIntegration } = require("@sentry/profiling-node");
const logger = require("./utils/logger");

require("dotenv").config();

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  integrations: [
    nodeProfilingIntegration(),
  ],
  tracesSampleRate: 1.0,
  profilesSampleRate: 1.0,
});

// Attempt to resolve DNS issues for MongoDB Atlas
dns.setServers(["8.8.8.8", "1.1.1.1"]);

const authRoutes = require("./routes/authRoutes");
const medicineRoutes = require("./routes/medicineRoutes");
const interactionRoutes = require("./routes/interactionRoutes");
const reminderRoutes = require("./routes/reminderRoutes");
const userRoutes = require("./routes/userRoutes");
const aiRoutes = require("./routes/aiRoutes");
require("./services/notificationService"); // Start notification cron job

const app = express();

// Global Rate Limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: {
    success: false,
    message: "Too many requests from this IP, please try again after 15 minutes"
  }
});

// Apply rate limiting globally
// app.use(limiter);

app.use(cors());
app.use(express.json());

// Structured Request Logging
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.url}`);
    if (req.method === 'POST') {
        const body = { ...req.body };
        if (body.password) body.password = '********';
        logger.debug('Request Body', { body });
    }
    next();
});

// MongoDB Connection
const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI, {
            serverSelectionTimeoutMS: 5000, 
        });
        logger.info(`✅ MongoDB Connected to: ${mongoose.connection.name}`);
    } catch (err) {
        logger.error("❌ MongoDB Connection Error: %s", err.message);
        logger.info("💡 Tip: Check if your IP address is whitelisted in MongoDB Atlas: https://www.mongodb.com/docs/atlas/security-whitelist/");
    }
};

connectDB();

app.use("/api/auth", authRoutes);
app.use("/api", authRoutes);
app.use("/api", medicineRoutes);
app.use("/api", interactionRoutes);
app.use("/api", reminderRoutes);
app.use("/api", userRoutes);
app.use("/api", aiRoutes);

app.get("/api/health", (req, res) => {
    res.json({
        success: true,
        status: "UP",
        timestamp: new Date().toISOString(),
        db: mongoose.connection.readyState === 1 ? "CONNECTED" : "DISCONNECTED"
    });
});

app.get("/", (req, res) => {
    res.send("MediCheck AI API is running...");
});

// Sentry Error Handler
Sentry.setupExpressErrorHandler(app);

// Global Error Boundary
app.use((err, req, res, next) => {
    logger.error('Unhandled Error: %o', err);
    
    const statusCode = err.statusCode || 500;
    const message = err.message || "Internal Server Error";
    
    res.status(statusCode).json({
        success: false,
        message: message,
        stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    logger.info(`🚀 Server running on http://localhost:${PORT}`);
});