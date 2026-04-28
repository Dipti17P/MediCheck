const jwt = require("jsonwebtoken");

module.exports = function (req, res, next) {

  let token = req.headers.authorization;

  if (!token) {
    return res.status(401).json({ message: "Access denied. No token provided." });
  }

  // Extract token from 'Bearer <token>'
  if (token.startsWith("Bearer ")) {
    token = token.split(" ")[1];
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = decoded;

    next();

  } catch (error) {

    res.status(401).json({ message: "Invalid token" });

  }
};