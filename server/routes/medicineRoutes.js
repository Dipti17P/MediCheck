const express = require("express");
const router = express.Router();
const { addMedicine, getMedicines, findAlternatives } = require("../controllers/medicineController");
const authMiddleware = require("../middleware/authMiddleware");
const validate = require("../middleware/validate");
const schemas = require("../validation/schemas");

router.post("/add-medicine", authMiddleware, validate(schemas.addMedicine), addMedicine);
router.get("/medicines", authMiddleware, getMedicines);
router.post("/find-alternatives", authMiddleware, validate(schemas.findAlternatives), findAlternatives);

module.exports = router;