'use strict';

const functions     = require('firebase-functions');
const appConfig     = require('../../appConfig');
const firebaseAdmin = appConfig.firebaseAdmin;
const firestoreDb   = appConfig.firestoreDb;
const appData       = appConfig.appData;

const https = require('https')

const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});


/**
 * Attaches a payment method to the Stripe customer,
 * subscribes to a Stripe plan, and saves the plan to Firestore
 */

exports.deleteSeanUsers = functions.https.onCall(async (data, context) => {
    console.log('ENTER: deleteCurrentUser');

    try {

        await deleteUsersForEmail('seaninnigeria@gmail.com');
        await deleteUsersForEmail('sean@kiki.nyc');
        // await deleteUsersForEmail('sjcgo1a@gmail.com');
        // await deleteUsersForEmail('geneb.contact2@gmail.com');

        return 'Done';
    }
    catch (error) {
        console.log('Error sending message:', error);
        return 'Done';
    }

});

/**
 * Cancels an active subscription, syncs the data in Firestore
 */

async function deleteUsersForEmail(emailAddress) {
    console.log(`ENTER: deleteCurrentUser, emailAddress: ${emailAddress}`);

    let userEmailDocs = await firestoreDb.collection(appData.Collctn.users)
                                         .where(appData.Field.email, '==', emailAddress)
                                         .get();

    userEmailDocs.forEach(doc => {

        return new Promise((async (resolve, reject) => {

            let uid = doc.id;
            console.log(`userEmailDocs.forEach to delete, uid: ${uid}`);

            await firestoreDb.collection(appData.Collctn.users).doc(uid).delete();

            await firebaseAdmin
                .auth()
                .deleteUser(uid)
                .then(() => {
                    console.log(`Successfully deleted user from Auth, uid: ${uid}`);
                    return 'Done';
                })
                .catch((error) => {
                    console.log(`Error deleting user, uid: ${uid}, error: ${error}`);
                });

            return resolve(`delete done for, uid: ${uid}`);
        }));


    });

}


exports.sendHttpRequest1 = functions.https.onCall(async (data, context) => {

    // port: 443,
    // path: '/todos',
    const options = {
        hostname : 'https://www.boredapi.com/api/activity',
        // method: 'POST',
        // method: 'GET',
        // headers: {
        //     'Content-Type': 'application/json',
        //     'Content-Length': emailRequestBody.length,
        //     'Api_Key': '7c05b7613c724447925cd012d6c5a372'
        // }
    };

    const req = https.request(options, res => {
        console.log(`res: ${JSON.stringify(res)}`)
        console.log(`statusCode: ${res.statusCode}`)

        // res.on('emailRequestBody', d => {
        //     process.stdout.write(d);
        // })
    });

    req.on('error', error => {
        console.error(error);
    });

    req.write(emailRequestBody);
    req.end();

    return true;
});
