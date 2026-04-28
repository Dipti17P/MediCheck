const admin = require('firebase-admin');
const cron = require('node-cron');
const Reminder = require('../models/Reminder');
const User = require('../models/User');
const logger = require('../utils/logger');

// Initialize firebase-admin
if (!admin.apps.length) {
    try {
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            admin.initializeApp({
                credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT))
            });
            logger.info('Firebase Admin initialized');
        } else {
            logger.warn('FIREBASE_SERVICE_ACCOUNT not found. Push notifications will not be sent.');
        }
    } catch (e) {
        logger.error('Firebase Admin init error: %s', e.message);
    }
}

const sendMedicineReminder = async (fcmToken, medicineName) => {
    if (!admin.apps.length) return;

    const message = {
        notification: {
            title: 'Medicine Reminder',
            body: `It's time to take your ${medicineName}!`,
        },
        android: {
            priority: 'high',
        },
        token: fcmToken,
    };

    try {
        await admin.messaging().send(message);
        logger.info(`Notification sent for ${medicineName}`);
    } catch (error) {
        logger.error('Error sending FCM: %s', error.message);
    }
};

// Cron job to check every minute
cron.schedule('* * * * *', async () => {
    const now = new Date();
    // Note: The logic below uses system time. Ensure server time matches user expectation or handle timezones.
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    logger.debug(`Checking reminders for ${currentHour}:${currentMinute}`);

    try {
        const activeReminders = await Reminder.find({
            hour: currentHour,
            minute: currentMinute
        }).populate('userId');

        for (const reminder of activeReminders) {
            if (reminder.userId && reminder.userId.fcmToken) {
                await sendMedicineReminder(reminder.userId.fcmToken, reminder.medicineName);
            }
        }
    } catch (err) {
        logger.error('Cron job error: %o', err);
    }
});

module.exports = { sendMedicineReminder };
