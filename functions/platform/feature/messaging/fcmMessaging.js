'use strict';

const functions = require('firebase-functions');

const appConfig = require('../../appConfig');
const appData   = appConfig.appData;
const dateUtil  = require('../../util/dateUtil');

const admin           = require('firebase-admin');
const fcmNotification = require('./fcmNotification')

const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});

//** save FCM token for specific user */
exports.storeFcmToken = functions.https.onCall(async (data, context) => {

    if (!context.auth) {
        // User is not logged in
        return null;
    }
    console.log(`ENTER: storeFcmToken(), data: ${data.toString()}`);

    const {
              deviceType,
              fcmToken
          } = data;

    console.log(`for data, deviceType: ${deviceType}, fcmToken: ${fcmToken} `);

    //** possible device types are: web, android, ios */
    await admin.firestore()
               .collection(appData.Collctn.deviceFcmToken)
               .doc(context.auth.uid)
               .set({
                       [appData.Field.created]    : dateUtil.getNowReadableTimestamp(),
                       [appData.Field.deviceType] : deviceType,
                       [appData.Field.deviceFcmTokens]: admin.firestore.FieldValue.arrayUnion(fcmToken)
                   },
                   {merge : true});

    return {msg : 'OK'}

});

// exports.sendUserFcmMessage = functions.https.onCall(async (data, context) => {

//     console.log(`ENTER: exports.sendUserFcmMessage() | data: ${data.toString()}`);

//     if (!context.auth) {
//         console.log(`(!context.auth) == true, so returning null`);
//         // User is not logged in
//         return null;
//     }

//     const {
//               message
//           } = data;

//     console.log(`got message: ${message}`);

//     await fcmNotification.sendUserMessage(context.auth.uid,
//         {title : 'Kiki Notification', body : message})

//     return {msg : 'sendUserFcmMessage OK'}

// });

// .doc(context.auth.uid)
// [`fcm_token_${deviceType}`] : fcmToken

// For client-to-CloudFunc access
//** send FCM message for logged in user. Just for test */
// exports.sendGlobalFcmMessage = functions.https.onCall(async (data, context) => {

//     console.log(`ENTER: exports.sendGlobalFcmMessage() | data: ${data.toString()}`);

//     const {
//               message
//           } = data;

//     console.log(`got message: ${message}`);

//     await fcmNotification.sendGlobalMessage({title : 'Kiki Notification', body : message})

//     return {msg : 'sendGlobalFcmMessage OK'}

// });


/*
let FirstHourNtfcnMsg = {
    title   : 'Welcome to Kiki!',
    message : 'This is a test ntfcn for firstHourNtfcnUserIds'
};

exports.sendPushNtfcnMessage = async function (firstHourNtfcnUserIds) {

    console.log(`ENTER sendPushNtfcnMessage(), 
                firstHourNtfcnUserIds: ${JSON.stringify(firstHourNtfcnUserIds)}`);

    const sendRequests = [];
    firstHourNtfcnUserIds.forEach(function (ntfcnUserId) {
        console.log(ntfcnUserId);
        sendRequests
            .push(sendFCMNotification(ntfcnUserId, {
                title : FirstHourNtfcnMsg.title,
                body  : FirstHourNtfcnMsg.message
            }));
    });

    await Promise.all(sendRequests);

    //!** update message status in DB *!/
    const batch = admin.firestore().batch();
    firstHourNtfcnUserIds.forEach(function (ntfcnUserId) {
        console.log(ntfcnUserId);
        const messageRef = firestoreDb.collection(appData.Collctn.user).doc(ntfcnUserId);
        batch.update(messageRef, {[appData.MessagesSent.firstHourNtfcn] : true});
    });

    await batch.commit();
    return null;
};

// read scheduled messages from the DB and send every 5 minutes
exports.sendScheduledMessages = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
    const now      = Date.now();
    const messages = await admin.firestore().collection('scheduledMessages')
                                .where('sendWhen', '<=', now)
                                .where('status', '==', 'pending')
                                .get();

    //** send messages  * /
    const sendRequests = [];
    messages.forEach(snap => {
        const snapData = snap.data();
        sendRequests.push(sendFCMNotification(snapData.forUserId, {title : snapData.title, body : snapData.message}));
    });

    await Promise.all(sendRequests);

    //** update message status in DB * /
    const batch = admin.firestore().batch();
    messages.forEach(snap => {
        const messageRef = admin.firestore().collection('scheduledMessages').doc(snap.id);
        batch.update(messageRef, {'status' : 'sent'});

        //** if need to delete, use  * /
        // batch.delete(messageRef);
    });

    await batch.commit();
    return null;
});
*/
