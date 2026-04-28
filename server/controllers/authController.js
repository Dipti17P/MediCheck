const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const logger = require("../utils/logger");

// Helper to generate tokens
const generateTokens = (userId) => {
  const accessToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: "1h" }
  );
  
  const refreshToken = jwt.sign(
    { userId },
    process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET + "_refresh",
    { expiresIn: "30d" }
  );
  
  return { accessToken, refreshToken };
};

// SIGNUP
exports.signup = async (req, res, next) => {
  try {
    const { name, email, password } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      logger.warn(`Signup Failed: User already exists: ${email}`);
      return res.status(400).json({ success: false, message: "User already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = new User({
      name,
      email,
      password: hashedPassword
    });

    const { accessToken, refreshToken } = generateTokens(newUser._id);
    newUser.refreshToken = refreshToken;
    
    await newUser.save();

    logger.info(`User registered successfully: ${email}`);
    res.status(201).json({
      success: true,
      message: "User registered successfully",
      token: accessToken,
      refreshToken: refreshToken
    });

  } catch (error) {
    logger.error('Signup Error: %o', error);
    next(error);
  }
};

// LOGIN
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      logger.warn(`Login Failed: User not found: ${email}`);
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      logger.warn(`Login Failed: Invalid password for: ${email}`);
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }

    const { accessToken, refreshToken } = generateTokens(user._id);
    
    user.refreshToken = refreshToken;
    await user.save();

    logger.info(`Login successful: ${email}`);
    res.json({
      success: true,
      message: "Login successful",
      token: accessToken,
      refreshToken: refreshToken
    });

  } catch (error) {
    logger.error('Login Error: %o', error);
    next(error);
  }
};

// REFRESH TOKEN
exports.refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ success: false, message: "Refresh token is required" });
    }

    const secret = process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET + "_refresh";
    
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, secret);
    } catch (err) {
      return res.status(401).json({ success: false, message: "Invalid or expired refresh token" });
    }

    const user = await User.findById(decoded.userId);
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ success: false, message: "Invalid refresh token" });
    }

    const tokens = generateTokens(user._id);
    user.refreshToken = tokens.refreshToken;
    await user.save();

    res.json({
      success: true,
      token: tokens.accessToken,
      refreshToken: tokens.refreshToken
    });

  } catch (error) {
    logger.error('Refresh Token Error: %o', error);
    next(error);
  }
};

// RESET PASSWORD (UNAUTHENTICATED)
exports.resetPassword = async (req, res, next) => {
  try {
    const { email, currentPassword, newPassword } = req.body;

    if (!email || !currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: "Email, current password, and new password are required" });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: "Incorrect current password" });
    }

    // Hash and save new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    logger.info(`Password reset successfully for: ${email}`);
    res.json({ success: true, message: "Password updated successfully" });
  } catch (error) {
    logger.error('Reset Password Error: %o', error);
    next(error);
  }
};