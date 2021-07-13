'use strict';

const functions = require('firebase-functions');

const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});

const appConfig     = require('../../appConfig');
const appData       = appConfig.appData;
const firebaseAdmin = appConfig.firebaseAdmin;
const firestoreDb   = appConfig.firestoreDb;

const objectUtil = require('../../util/objectUtil');
const stringUtil = require('../../util/stringUtil');

const kikiEmail   = require('../../content/kikiEmail');
const wifiAccess  = require('../../model/wifiAccess');
const emailEngine = require('../../network/emailEngine');

let firestore = firebaseAdmin.firestore();

let mUserWifiNetworkProfile;

let mLoggedInUid;

exports.resendVerificationEmail = functions.https.onCall(async (data, context) => {

    console.log(`ENTER: exports.resendVerificationEmail`);

    mLoggedInUid = context.auth[appData.Key.uid];

    await SendEmailPromise.sendWelcomeVerifyEmail();

    return null;
});

exports.sendEmailsForNewUser = async function (createdFirebaseAuthUser) {

    mLoggedInUid = createdFirebaseAuthUser.uid;

    await SendEmailPromise.sendWelcomeVerifyEmail();

    await SendEmailPromise.sendBuyerSellerConnectedAlertEmail();

    return null;
};

let SendEmailPromise = {};

SendEmailPromise.sendWelcomeVerifyEmail = async function () {

    console.log(`ENTER: sendWelcomeVerifyEmail, mLoggedInUid: ${mLoggedInUid}`);

    let welcomeVerifyEmailObject = await SendEmailPromise.buildWelcomeVerifyEmail();

    console.log(`welcomeVerifyEmailObject: ${JSON.stringify(welcomeVerifyEmailObject)}`);

    await emailEngine.sendEmail(welcomeVerifyEmailObject);

    return null;
};

SendEmailPromise.buildWelcomeVerifyEmail = async function () {

    console.log(`ENTER: buildWelcomeVerifyEmail, mLoggedInUid: ${mLoggedInUid}`);

    let userDoc = await firestoreDb.collection(appData.Collctn.users)
                                   .doc(mLoggedInUid)
                                   .get();

    let userData = userDoc.data();

    console.log(`userData: ${JSON.stringify(userData)}`);

    let recipientEmail = userData[appData.Field.email];

    let role = userData[appData.Field.role];
    console.log(`role: ${role}`);

    let isBuyer = (role === appData.Role.buyer);
    console.log(`isBuyer: ${isBuyer}`);

    let welcomeEmailIdx = (isBuyer === true)
        ? kikiEmail.EmailTypeIdx.BuyerSignUpWelcome
        : kikiEmail.EmailTypeIdx.SellerSignUpWelcome;

    console.log(`welcomeEmailIdx: ${welcomeEmailIdx}, 
                    recipientEmail: ${recipientEmail}`);

    let emailObject = kikiEmail
        .getAppEmailObject(
            welcomeEmailIdx,
            recipientEmail);

    console.log(`buildWelcomeVerifyEmail gets emailObject: ${JSON.stringify(emailObject)}`);

    let htmlStr = emailObject.html;
    console.log(`htmlStr: ${htmlStr}`);

    htmlStr = stringUtil.replaceAllOccurrences(
        htmlStr,
        appData.Key.urlDocId,
        userDoc.id);

    console.log(`after replaceAllOccurrences(), htmlStr: ${htmlStr}`);

    emailObject.html = htmlStr;

    console.log(`buildWelcomeVerifyEmail returns emailObject: ${JSON.stringify(emailObject)}`);

    return emailObject;
};

/**
 * When a user is created, check if they are a:
 * 1. Seller: check for waiting buyers
 *              - the network is within range for a Buyer that is waiting
 * 2. Buyer: check for existing seller
 *              - a Seller network exists is within range for Buyer
 *
 * Kiki Hours Sunday: 2 hours putting together these cloud funcs and modularizing code for Seller Create Account and Cancel button
 */
// TODO: force a 3000millis delay to give time for collection to be created
SendEmailPromise.sendBuyerSellerConnectedAlertEmail = async function () {

    // createdFirebaseAuthUser is Seller if there is an entry for them in /networks
    const networksRef = firestore.collection(appData.Collctn.networks);

    const pwdProfilesSnapshot = await
        networksRef.where(appData.Field.owner, '==', mLoggedInUid)
                   .get();

    pwdProfilesSnapshot.forEach(doc => {
        console.log(`pwdProfilesSnapshot.forEach: doc.id: ${doc.id}, doc.data(): ${doc.data()}`);

        mUserWifiNetworkProfile = doc.data();

        // return true; // to exit loop
    });

    console.log('mUserWifiNetworkProfile: ' + JSON.stringify(mUserWifiNetworkProfile));

    let isSellerUser = objectUtil.isDefined(mUserWifiNetworkProfile);
    console.log('isSellerUser: ' + isSellerUser);

    if (isSellerUser === true) {
        await SendEmailPromise.checkSellerWifiForWaitingBuyer();
    }
    else {
        // A Buyer can only register when there is an available network
        // On register, that network is assigned to the Buyer
        await SendEmailPromise.notifySeller_wifiActivated();
    }

    return null;
};

/**
 * Look up the wifi new user is accessing
 * @param user
 * @return {Promise<void>}
 */
SendEmailPromise.notifySeller_wifiActivated = async function () {

    console.log(`ENTER: notifySeller_wifiActivated, mCreatedUserUid: ${mLoggedInUid}`);

    let currentBuyer = await firestore.collection(appData.Collctn.users)
                                      .doc(mLoggedInUid)
                                      .get();

    currentBuyer = currentBuyer.data();

    console.log(`currentBuyer: ${JSON.stringify(currentBuyer)}`);

    let sellerNetworkId = currentBuyer[appData.Field.connected]; // key for buyer networkID

    console.log(`sellerNetworkId: ${sellerNetworkId}`);

    let sellerNetwork = await firestore.collection(appData.Collctn.networks)
                                       .doc(sellerNetworkId)
                                       .get();

    sellerNetwork = sellerNetwork.data();

    console.log(`sellerNetwork: ${JSON.stringify(sellerNetwork)}`);

    let sellerUserId = sellerNetwork[appData.Field.owner];

    let sellerUser = await firestore.collection(appData.Collctn.users)
                                    .doc(sellerUserId)
                                    .get();

    sellerUser = sellerUser.data();

    let sellerEmail = sellerUser[appData.Field.email];
    let emailObject = kikiEmail
        .getAppEmailObject(
            kikiEmail.EmailTypeIdx.SellerWifiActivated,
            sellerEmail);

    await emailEngine.sendEmail(emailObject);

    return null;
};

/**
 * TODO: We will need logic to remove user from mailing-list when a user in the list joins a network
 *
 * We know this seller's Wifi is avialable, because they just joined
 * @return {Promise<void>}
 */
SendEmailPromise.checkSellerWifiForWaitingBuyer = async function () {

    let sellerLatLonArr = mUserWifiNetworkProfile[appData.Field.pos];
    console.log(`sellerLatLonArr: ${sellerLatLonArr}`);

    wifiAccess.setSellerLatLng(sellerLatLonArr);

    let firestoreDbRef = firebaseAdmin.firestore();

    firestoreDbRef = await firestoreDbRef.collection('mailing-list');

    // NEXT: Iterate and check geo code
    return new Promise((resolve, reject) => {

        firestoreDbRef.get()
                      .then(waitingBuyersSnapshot => {

                          SendEmailPromise.processWaitingBuyers(waitingBuyersSnapshot);

                          return resolve(true);
                      })
                      .catch(reason => {

                          console.log('getCollectionMap !! ERR, reason: ' + reason);
                          return reject(reason);
                      });
    });
};


/**
 *  1. send email to any Buyer that's in range - so we loop all the way through
 *  2. When Buyer signs up, we check if they are in the mailing list, and if they are we can remove them
 *
 * @param waitingBuyersSnapshot
 */
SendEmailPromise.processWaitingBuyers = function (waitingBuyersSnapshot) {

    waitingBuyersSnapshot.forEach(waitingBuyerDoc => {
        let waitingBuyerDocData = waitingBuyerDoc.data();

        console.log('waitingBuyerDoc.id: ' + waitingBuyerDoc.id);
        console.log('waitingBuyerDocData: ' + JSON.stringify(waitingBuyerDocData));

        let latLonArr  = waitingBuyerDocData[appData.Field.pos];
        let buyerEmail = waitingBuyerDocData[appData.Field.email];
        console.log('latLonArr: ' + JSON.stringify(latLonArr));

        let isWifiInRangeOfBuyer = wifiAccess.isWifiInRangeOfBuyer(latLonArr);
        console.log('isWifiInRangeOfBuyer: ' + isWifiInRangeOfBuyer);

        let emailObject = kikiEmail
            .getAppEmailObject(
                kikiEmail.EmailTypeIdx.SellerFoundForWaitingBuyer,
                buyerEmail);

        if (isWifiInRangeOfBuyer === true) {
            emailEngine.sendEmail(emailObject);
        }
    });

};
