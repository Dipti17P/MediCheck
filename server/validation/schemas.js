const Joi = require('joi');

const schemas = {
  signup: Joi.object({
    name: Joi.string().min(2).max(50).required(),
    email: Joi.string().email().required(),
    password: Joi.string()
      .min(8)
      .pattern(new RegExp('^(?=.*[a-z])(?=.*[0-9])'))
      .required()
      .messages({
        'string.min': 'Password must be at least 8 characters long',
        'string.pattern.base': 'Password must contain at least one letter and one number'
      })
  }),
  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),
  addMedicine: Joi.object({
    name: Joi.string().required(),
    uses: Joi.string().allow('', null),
    sideEffects: Joi.array().items(Joi.string()).allow(null)
  }),
  checkInteraction: Joi.object({
    medicines: Joi.array().items(Joi.string()).min(2).required()
  }),
  createReminder: Joi.object({
    medicineName: Joi.string().required(),
    time: Joi.string().required(),
    hour: Joi.number().min(0).max(23).required(),
    minute: Joi.number().min(0).max(59).required(),
    frequency: Joi.string().valid('Daily', 'Weekly', 'Monthly', 'daily', 'weekly', 'monthly').default('daily'),
    active: Joi.boolean().default(true)
  }),
  updateProfile: Joi.object({
    allergies: Joi.array().items(Joi.string()).allow(null),
    medicalHistory: Joi.string().allow('', null)
  }),
  updateFcmToken: Joi.object({
    fcmToken: Joi.string().required()
  }),
  refreshToken: Joi.object({
    refreshToken: Joi.string().required()
  })
};

module.exports = schemas;
