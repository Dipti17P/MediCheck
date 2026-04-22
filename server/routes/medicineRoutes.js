const express = require("express");
const router = express.Router();

const { addMedicine, getMedicines } = require("../controllers/medicineController");

const authMiddleware = require("../middleware/authMiddleware");

router.post("/add-medicine", authMiddleware, addMedicine);

router.get("/medicines", authMiddleware, getMedicines);

module.exports = router;