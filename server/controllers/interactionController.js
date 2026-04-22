const interactions = require("../data/interactions");

exports.checkInteraction = async (req, res) => {

try {

const { medicines } = req.body;

let results = [];

for (let i = 0; i < medicines.length; i++) {

for (let j = i + 1; j < medicines.length; j++) {

const med1 = medicines[i];
const med2 = medicines[j];

const interaction = interactions.find(
(item) =>
(item.med1 === med1 && item.med2 === med2) ||
(item.med1 === med2 && item.med2 === med1)
);

if (interaction) {

results.push(interaction);

}

}

}

if (results.length === 0) {

return res.json({
message: "No interactions detected",
risk: "Low"
});

}

res.json({
message: "Interaction detected",
interactions: results
});

} catch (error) {

res.status(500).json({
error: error.message
});

}

};