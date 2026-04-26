const admin = require('firebase-admin');
const cron = require('node-cron');
const Reminder = require('../models/Reminder');
const User = require('../models/User');

// Initialize firebase-admin
if (!admin.apps.length) {
    try {
        // You should have FIREBASE_SERVICE_ACCOUNT env var or a file
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            admin.initializeApp({
                credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT))
            });
            console.log('Firebase Admin initialized');
        } else {
            console.warn('FIREBASE_SERVICE_ACCOUNT not found. Push notifications will not be sent.');
        }
    } catch (e) {
        console.error('Firebase Admin init error:', e.message);
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
        console.log(`Notification sent for ${medicineName}`);
    } catch (error) {
        console.error('Error sending FCM:', error.message);
    }
};

// Cron job to check every minute
cron.schedule('* * * * *', async () => {
    const now = new Date();
    // Offset for local time if needed, assuming UTC for server
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    console.log(`Checking reminders for ${currentHour}:${currentMinute}`);

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
        console.error('Cron job error:', err.message);
    }
});

module.exports = { sendMedicineReminder };
