const functions = require('firebase-functions');

const stripeCustomer = require('../../platform/feature/stripePayment/stripeCustomer');
const appEmail     = require('../../platform/feature/email/appEmail');

let mErrors = [];

/**
 * When a user is created, check if:
 * 1. they are a seller
 * 2. the network is within range for a Buyer that is waiting
 * Kiki Hours Sunday: 2 hours putting together these cloud funcs and modularizing code for Seller Create Account and Cancel button
 */
exports.onCreateAuthUser = functions.auth.user().onCreate(async (createdFirebaseAuthUser) => {
    console.log(`ENTER: exports.onCreateAuthUser(), 
                    createdFirebaseAuthUser.email : ${createdFirebaseAuthUser.email}, 
                    createdFirebaseAuthUser.uid : ${createdFirebaseAuthUser.uid}`);

    let promise = new Promise(((resolve, reject) => {
        let timeoutMillis = 2000;
        console.log(`Calling setTimeout(timeoutMillis: ${timeoutMillis}`);

        setTimeout(async () => {

            await AppTrigger.onCreateKikiWifiUser(createdFirebaseAuthUser);

            await AppTrigger.onCreateStripeCustomer(createdFirebaseAuthUser);

            if (mErrors.length > 0) {
                return reject(mErrors);
            }

            return resolve({result: 'success onCreateAuthUser()'});
        }, timeoutMillis);
    }));

    return promise;
});

let AppTrigger = {};

AppTrigger.onCreateKikiWifiUser = async function (createdFirebaseAuthUser)  {

    try {

        await appEmail.sendEmailsForNewUser(createdFirebaseAuthUser);
        console.log('wifiAccess.onCreateKikiWifiUser2() completed');
    }
    catch (err) {

        mErrors.push(err);
        console.log(`appEmail.sendEmailsForNewUser() FAILED, err: ${err}`);
    }

    return null;
};

AppTrigger.onCreateStripeCustomer = async function (createdFirebaseAuthUser)  {

    try {

        await stripeCustomer.createStripeCustomer2(createdFirebaseAuthUser);
        console.log('stripeCustomer.createStripeCustomer2() completed');
    }
    catch (err) {

        mErrors.push(err);
        console.log(`wifiAccess.createStripeCustomer2() FAILED, err: ${err}`);
    }


    return null;
};
