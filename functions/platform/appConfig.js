'use strict';
exports.firebaseAdmin = require('firebase-admin');

exports.firestoreDb = exports.firebaseAdmin.firestore();
exports.firestoreFieldConst = exports.firebaseAdmin.firestore.FieldValue;

let appData = exports.appData = require('./config/appData');

let dateUtil   = exports.dateUtil = require('./util/dateUtil');
let objectUtil = exports.dateUtil = require('./util/objectUtil');

let numberUtil = exports.numberUtil = require('./util/numberUtil');

exports.errHandler = require('./util/errHandler');

// ==================================================
// ====  Email

/**
 * Here we're using Gmail to send
 */
exports.emailTransportConfig = {
    service: 'gmail',
    auth: {
        user: 'support@kiki.nyc',
        pass: 'aaa1bbb2'
    }
};


// ==================================================
// ====  Stripe

const STRIPE_SERVER_KEY = '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';

exports.STRIPE_WEBHOOK_SECRET = 'whsec_qKAAAn1kt6kHEgZcJXvZnMyJ9TQ0yLu8';

exports.STRIPE_PRICE_ID = 'price_1HvnfeKe4BM2E8InQo55Iuww';

//  noinspection JSValidateTypes
exports.stripeClient = require('stripe')(
    STRIPE_SERVER_KEY, {
        apiVersion : '2020-03-02',
    });

// ==================================================
// ====  General Util

exports.log = async function (message) {

    // this should order log chronologically in collection
    let docId = dateUtil.getTodayMDYHM();
    docId += '_' + dateUtil.getNowNumericTimestamp();
    docId += '_' + numberUtil.getFixedLenRandomNumber(3);

    await exports.firestoreDb
                 .collection(appData.Collctn.appLog)
                 .doc(docId)
                 .set({
                     [appData.Field.created] : dateUtil.getNowReadableTimestamp(),
                     [appData.Field.message] : message
                 });

    return true;
};
