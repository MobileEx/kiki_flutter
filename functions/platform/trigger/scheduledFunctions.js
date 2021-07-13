const functions = require('firebase-functions');

const appConfig   = require('../appConfig');
const dateUtil    = require('../util/dateUtil');
const appData     = appConfig.appData;
const firestoreDb = appConfig.firestoreDb;

const appSubscription = require('../model/appSubscription');
const fcmMessaging = require('../feature/messaging/fcmMessaging');

let mErrors         = [];
let mHourlyCheckLog = '';

/**
 1. scheduled check::
 Notification to both sides during three day period, checking in, telling them to reach out of they have issues etc    Daily routine to check sign up dates

 2. scheduled check::
 Notification to seller, after say 2.5 days; saying "let us know if this has not worked. If we don't hear from you, we'll assume you are ok with it and will ask the buyer if they want to commit and pay $XX for the next 30 days    Daily routine to check sign up dates

 3. scheduled check::
 Check who's trial has expired, set to false
 */
let currTime        = dateUtil.getNowReadableTimestampPST();
exports.hourlyCheck = functions.pubsub.schedule('every 60 minutes').onRun(async (context) => {

    mHourlyCheckLog += (`ENTER ***hourlyCheck(), currTime: ${currTime}`);

    let promise = new Promise((async (resolve, reject) => {

        mHourlyCheckLog += (`ENTER promise for ***hourlyCheck(), currTime: ${currTime}`);

        await ScheduledFuncPromise.setExpiredUserTrials();

        await ScheduledFuncPromise.alertBuyerAndSellerTrialIsStarting();

        await ScheduledFuncPromise.sendFirstHourNtfcns();

        if (mErrors.length > 0) {
            return reject(mErrors);
        }

        return resolve({result : 'success onCreateAuthUser()'});
    }));

    await appConfig.log(mHourlyCheckLog);

    return promise;
});

let ScheduledFuncPromise = {};

exports.sendFirstHourNtfcns = functions.https.onCall(async (data, context) => {

    await ScheduledFuncPromise.sendFirstHourNtfcns();

    return true;
});


ScheduledFuncPromise.sendFirstHourNtfcns = async function () {

    console.log(`ENTER sendFirstHourNtfcns(), currTime: ${currTime}`);

    try {
        // TBD: for .where clause
        const usersSnapShot = firestoreDb.collection(appData.Collctn.users)
                                    // .where(appData.MessagesSent.firstHourNtfcn, '!=', null)
                                    .get();

        const firstHourNtfcnUserIds = [];
        usersSnapShot.forEach(doc => {
            let uid = doc.id;
            let userData = doc.data();

            console.log(`sendFirstHourNtfcns.forEach: uid: ${uid}, userData: ${userData}`);

            let messagesSent = userData[appData.Field.messagesSent];

            console.log(`messagesSent: ${JSON.stringify(messagesSent)}`);
            if (messagesSent === null) {
                console.log('Adding user to ntfcn list');
                firstHourNtfcnUserIds.push(uid);
            }
            else {
                console.log('NOT Adding user to ntfcn list');
            }

        });

        // FIXME
        // await fcmMessaging.sendPushNtfcnMessage(firstHourNtfcnUserIds);
    }
    catch (err) {

        mErrors.push(err);
        console.log(`ScheduledFuncPromise.setExpiredUserTrials() FAILED, err: ${err}`);
    }

    return null;
};


/**
 * TODO: This happens internally, update trial field to false
 * @return {Promise<void>}
 *
 * 1. Query all users where trial == true
 * 2. Go through the list for ones that have expired
 * 3. For expired, set trial = false
 */
ScheduledFuncPromise.setExpiredUserTrials = async function () {

    try {
        // so this should run before the next try/catch block
        await ScheduledFuncPromise._setExpiredUserTrials();
        mHourlyCheckLog += 'ScheduledFuncPromise.setExpiredUserTrials() completed';
    }
    catch (err) {

        mErrors.push(err);
        console.log(`ScheduledFuncPromise.setExpiredUserTrials() FAILED, err: ${err}`);
    }

    return null;
};

ScheduledFuncPromise._setExpiredUserTrials = async function () {

    await appConfig.log(`ENTER check for setExpiredUserTrials(), currTime: ${currTime}`);

    const usersRef = firestoreDb.collection(appData.Collctn.users);

    const activeTrialUsersSnapshot = await
        usersRef.where(appData.Field.trial, '==', true)
                .get();

    // TODO: Combine multiple cases when looping through this where:
    // 1. ExpiredTrials
    // 2. Valid trials where welcome email was never sent
    // 3. Valid trials where welcome email was sent, now only 1 day remains, and Trial ending email was not sent

    activeTrialUsersSnapshot.forEach(doc => {
        console.log(`activeTrialsSnapshot.forEach: doc.id: ${doc.id}, doc.data(): ${doc.data()}`);

        let activeTrialUserDoc = doc.data();

        let isTrialExpired = appSubscription.isTrialExpired(activeTrialUserDoc);

        if (isTrialExpired) {

            firestoreDb.collection(appData.Collctn.users)
                       .doc(doc.id)
                       .update({
                           [appData.Field.trial] : false,
                       });
        }
    });

    return null;
};

/**
 * Notification to both sides during three day period, checking in, telling them to reach out of they have issues etc    Daily routine to check sign up dates
 *
 * TODO:
 *  1. set a flag for each email sent
 *      - in /users/<doc>/emailsSent['Trial Starting', 'Trial Ending',
 * @return {Promise<void>}
 */
ScheduledFuncPromise.alertBuyerAndSellerTrialIsStarting = async function () {

    try {
        // We will assume since previous try/catch block ran first, trial values are current
        // await FIXME:.alertBuyerAndSellerTrialIsStarting();
        mHourlyCheckLog += ('ScheduledFuncPromise.alertBuyerAndSellerTrialIsStarting() completed');
    }
    catch (err) {

        mErrors.push(err);
        console.log(`ScheduledFuncPromise.alertBuyerAndSellerTrialIsStarting() FAILED, err: ${err}`);
    }

    return null;
};

/**
 * Notification to both sides during three day period, checking in, telling them to reach out of they have issues etc
 * Daily routine to check sign-up dates
 *
 * Email to Seller: How's it going
 * Email to Buyer: You have 1 day left, then will need to sign up
 * @return {Promise<void>}
 */
ScheduledFuncPromise.alertBuyerAndSellerTrialIsEnding = async function () {

};
