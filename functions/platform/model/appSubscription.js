'use strict';

const appConfig   = require('../appConfig');
const appData     = appConfig.appData;
const firestoreDb = appConfig.firestoreDb;

const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});


const errHandler = require('../util/errHandler');
const dateUtil   = require('../util/dateUtil');
const objectUtil = require('../util/objectUtil');

const firestoreFieldConst = appConfig.firestoreFieldConst;

exports.isTrialExpired = async function (userDoc) {

    console.log(`ENTER: onSubscriptionCreated`);
    let expiresReadableTimestamp = userDoc[appData.Field.subscriptionExpires];

    let expiresTimestampDate = dateUtil.getReadableTimestampAsDate(expiresReadableTimestamp);

    let nowDate = new Date();

    let deltaFromNowToExpires = nowDate.getTime() - expiresTimestampDate.getTime();

    let isTrialExpired = (deltaFromNowToExpires < 0);

    return isTrialExpired;
};

/**
 * Attaches a payment method to the Stripe customer,
 * subscribes to a Stripe plan, and saves the plan to Firestore
 */
exports.getAppUserDoc = async function (webhookData) {

    console.log(`ENTER: getAppUserDoc, webhookData: ${JSON.stringify(webhookData)}`);

    let stripeCustomerId = webhookData.customer;
    console.log(`webhookData.customer, stripeCustomerId: ${stripeCustomerId})`);
    console.log(`running lookup /stripeCustomers, .where(stripeCustomerId == ${stripeCustomerId})`);

    const stripeCustomerSnapshot = await firestoreDb.collection(appData.Collctn.stripeCustomers)
                                                    .where('customer_id', '==', stripeCustomerId)
                                                    .limit(1).get();

    console.log(`stripeCustomerSnapshot.docs[0].data(): ${JSON.stringify(stripeCustomerSnapshot.docs[0].data())})`);

    const appUserUid = stripeCustomerSnapshot.docs[0].id;

    if (objectUtil.isMissing(appUserUid) === true) {

        console.log('BAD ERR: (objectUtil.isMissing(appUserUid) === true) ');
        return null;
    }

    console.log(`Looking up user w/ appUserUid: ${appUserUid}`);

    let appUserDoc = await firestoreDb
        .collection(appData.Collctn.users)
        .doc(appUserUid).get();

    console.log(`returns appUserDoc.data(): ${JSON.stringify(appUserDoc)})`);

    return appUserDoc;
};


exports.onSubscriptionCreated = async function (webhookData) {

    console.log(`ENTER: onSubscriptionCreated`);

    let appUserDoc = await exports.getAppUserDoc(webhookData);
    if (objectUtil.isMissing(appUserDoc) === true) {

        console.log('BAD ERR: (objectUtil.isMissing(appUserUid) === true) ');
        return false;
    }

    let appUserUid = appUserDoc.id;

    await firestoreDb
        .collection(appData.Collctn.stripeCustomers)
        .doc(appUserUid)
        .update({
            activePlans : firestoreFieldConst.arrayUnion(webhookData.plan.id),
        });

    return true;
};


exports.updateUserSubscriptionExpires = async function (webhookData) {
    console.log(`ENTER: updateUserSubscriptionExpires`);

    let appUserDoc = await exports.getAppUserDoc(webhookData);

    if (objectUtil.isMissing(appUserDoc) === true) {

        console.log('BAD ERR: (objectUtil.isMissing(appUserUid) === true) ');
        return false;
    }

    console.log(`updateUserSubscriptionExpires gets appUserDoc.data(): ${JSON.stringify(appUserDoc)})`);

    let appUserUid = appUserDoc.id;
    let appUser    = appUserDoc.data();

    let expiresReadableTimestamp = appUser[appData.Field.subscriptionExpires];

    console.log(`subscriptionExpires, expiresReadableTimestamp: ${JSON.stringify(expiresReadableTimestamp)})`);

    if (objectUtil.isMissing(expiresReadableTimestamp) === true) {
        console.log(`calling: dateUtil.getNowReadableTimestamp()`);
        expiresReadableTimestamp = dateUtil.getNowReadableTimestamp();
    }
    else {

        console.log(`calling: dateUtil.getNowReadableTimestamp()`);
        expiresReadableTimestamp = dateUtil.add1MonthToTimestamp(expiresReadableTimestamp);
    }

    console.log(`expiresReadableTimestamp: ${expiresReadableTimestamp}`);

    console.log(`calling: collection(appData.Collctn.users).update`);

    await firestoreDb.collection(appData.Collctn.users)
                     .doc(appUserUid)
                     .update({
                         [appData.Field.subscriptionExpires] : expiresReadableTimestamp
                     });

    console.log(`return true;, AFTER call to: collection(appData.Collctn.users).update`);

    return true;
};

exports.logPaymentFailed = async function (webhookData) {

    console.log(`ENTER: logPaymentFailed`);

    let appUserDoc = await exports.getAppUserDoc(webhookData);
    if (objectUtil.isMissing(appUserDoc) === true) {

        console.log('BAD ERR: (objectUtil.isMissing(appUserUid) === true) ');
        return false;
    }

    let appUserUid = appUserDoc.id;
    await firestoreDb.collection(appData.Collctn.stripeCustomers).doc(appUserUid).update({status : 'PAST_DUE'});

    await firestoreDb.collection(appData.Collctn.stripeFailedPayments)
                     .add({
                         [appData.Field.uid]     : appUserUid,
                         [appData.Field.created] : dateUtil.getNowReadableTimestamp(),
                         [appData.Field.email]   : appUserDoc[appData.Field.email]
                     });

    return true;
};

exports.logSubscriptionDeleted = async function (webhookData) {

    console.log(`ENTER: logSubscriptionDeleted`);

    let appUserDoc = await exports.getAppUserDoc(webhookData);
    if (objectUtil.isMissing(appUserDoc) === true) {

        console.log('BAD ERR: (objectUtil.isMissing(appUserUid) === true) ');
        return false;
    }

    let appUserUid = appUserDoc.id;

    await firestoreDb.collection(appData.Collctn.stripeCustomers).doc(appUserUid)
                     .update({
                         activePlans : firestoreDb.FieldValue.arrayRemove(webhookData.plan.id),
                     });

    await firestoreDb.collection(appData.Collctn.stripeDeletedSubscriptions)
                     .add({
                         [appData.Field.uid]     : appUserUid,
                         [appData.Field.created] : dateUtil.getNowReadableTimestamp(),
                         [appData.Field.email]   : appUserDoc[appData.Field.email]
                     });

    return true;
};

