'use strict';

const functions = require('firebase-functions');

const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});

const appConfig     = require('../../appConfig');
const appData       = appConfig.appData;
const firebaseAdmin = appConfig.firebaseAdmin;
const firestoreDb = appConfig.firestoreDb;

const kikiEmail = require('../../content/kikiEmail');

const emailEngine = require('../../network/emailEngine');


// This is nec. for Buyer Interested email, where they are waiting for next email for Wifi
/**
 *
 * @data - exact JSON we need for firestoreDb .add()
 * @type {HttpsFunction}
 */
exports.registerBuyerInterest = functions.https.onCall(async (data, context) => {

    console.log('enter kikiEmail.exports.sendWelcomeEmail, data: ' + JSON.stringify(data));

    let recipientEmail = data[appData.Field.email];

    console.log('recipientEmail: ' + recipientEmail);

    let emailObject = kikiEmail
        .getAppEmailObject(
            kikiEmail.EmailTypeIdx.BuyerInterestRegistered, 
            recipientEmail);
    
    await emailEngine.sendEmail(emailObject);

    await firestoreDb.collection(appData.Collctn.mailingList)
                     .add(data);

    return null;
});

/*
    Position _pos = await Geolocator.getCurrentPosition();
    await FirebaseFirestore.instance.collection(Collctn.MAILING_LIST).add({
        "email": recipientEmail,
        "pos": [
            _pos.latitude,
            _pos.longitude,
        ],
    });
*/
