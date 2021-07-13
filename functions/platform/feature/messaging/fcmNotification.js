'use strict';

const appConfig = require('../../appConfig');
const objectUtil = require('../../util/objectUtil');

const admin   = require('firebase-admin');
const appData = appConfig.appData;

exports.sendUserMessage = async function (userId, data) {

    console.log(`ENTER: fcmNotification.exports.sendUserMessage() | userId: ${userId}, data: ${data.toString()}`);

    try {
        const userDoc = await appConfig.firestoreDb
                                       .collection(appData.Collctn.deviceFcmToken)
                                       .doc(userId)
                                       .get();

        let userData = userDoc.data();

        console.log(`userData: ${userData}`);

        let userDeviceTokens = userData[appData.Field.deviceFcmTokens];

        console.log(`userData.userDeviceTokens: ${userDeviceTokens}`);

        if (objectUtil.isMissing(userDeviceTokens) === true
         || userDeviceTokens.length === 0) {
            throw new Error('Unexpected error: (objectUtil.isMissing(userDeviceTokens) === true'
                + '|| userDeviceTokens.length === 0) === TRUE :(');
        }

        
        const deviceFcmTokens = [];

        userDeviceTokens.forEach(function (fcmToken, index) {
            console.log('fcmToken: ', fcmToken, ', at idx:', index);
            deviceFcmTokens.push(fcmToken);
        });

        const userTokensMap = {};
        userDeviceTokens.forEach(token => {
            userTokensMap[token] = userDoc.id
        })

        await FcmNotification.send(deviceFcmTokens, data, userTokensMap);
    }
    catch (error) {
        console.log('Error sending message:', error);
    }
};

exports.sendGlobalMessage = async function (data) {

    console.log(`ENTER: fcmNotification.exports.sendGlobalMessage() | data: ${data.toString()}`);

    // Send a message to the device corresponding to the provided
    // registration token.
    try {
        const allDeviceTokensSnapshot = await appConfig.firestoreDb
                                                       .collection(appData.Collctn.deviceFcmToken)
                                                       .get();

        let deviceFcmTokens = [];

        allDeviceTokensSnapshot.forEach(doc => {
            console.log(`deviceFcmTokenSnapshot.forEach: 
                            doc.id: ${doc.id}, 
                            doc.data(): ${JSON.stringify(doc.data())}`);

            let fcmTokens = doc[appData.Field.deviceFcmTokens];

            console.log(`setting fcmToken: ${fcmTokens}`);

            deviceFcmTokens = deviceFcmTokens.concat(fcmTokens);
            // return true; // to exit loop
        });

        if (!deviceFcmTokens.length) return;

        await FcmNotification.send(deviceFcmTokens, data);
    }
    catch (error) {
        console.log('Error sending message:', error);
    }
};

let FcmNotification = {};

FcmNotification.send = async function (deviceFcmTokens, fcmMessageData, userTokensMap) {

    console.log(`ENTER: FcmNotification.send(), deviceFcmTokens: ${deviceFcmTokens}, fcmMessageData: ${fcmMessageData}`);

    const res = await admin.messaging().sendMulticast({tokens : deviceFcmTokens, data : fcmMessageData});

    // Response is an object of the form { responses: [ {success: bool, error: Object }] }
    const successes = res.responses.filter(r => r.success === true).length;
    const failures  = res.responses.filter(r => r.success === false).length;
    console.log(
        'Notifications sent:',
        `${successes} successful, ${failures} failed`
    );

    const tokensToRemove = [];

    res.responses.forEach((r, i) => {
        if (r.success === false) {
            console.log(`${r.error.code} ${r.error.message}`);
            if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
                tokensToRemove.push(deviceFcmTokens[i]);
              } 
        }
    });

    console.log('Tokens to remove', tokensToRemove);
    if (userTokensMap) {
        const removeRequests = []
        tokensToRemove.forEach(token => {
            const userId = userTokensMap[token];
            if (!userId) return;

            removeRequests.push(admin.firestore().collection(appData.Collctn.deviceFcmToken).doc(userId).update({
                tokens: admin.firestore.FieldValue.arrayRemove(token)
            }));
        });

        await Promise.all(removeRequests);

    }
};

// if (user.data()) {
//     ['web', 'android', 'ios'].forEach(key => {
//         if (user.data()[`fcm_token_${key}`]) {
//             tokens.push(user.data()[`fcm_token_${key}`]);
//         }
//     })
// }
