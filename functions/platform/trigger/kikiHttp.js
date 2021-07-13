const functions = require('firebase-functions');

const cors = require('cors')({
    origin : true,
});

const appHtml = require('../content/appHtml');

const userVerification = require('../model/userVerification');

/**
 * Steps:
 * 1. Extract the value for --> let docId = req.query.doc;
 * 2. Use that to query /users
 * 3. Set email verified in auth.User
 * 4. Set /users doc field, verifiedOn:
 * @type {HttpsFunction}
 */
exports.welcomeVerification = functions.https.onRequest((req, res) => {
    console.log(`ENTER: exports.welcomeVerification`);
    // Forbidding PUT requests.
    if (req.method === 'PUT') {
        return res.status(403).send('Invalid request');
    }

    return cors(req, res, async () => {
        let userDocId = req.query.id;

        console.log(`in welcomeVerification(), userDocId: ${userDocId}`);

        let isUserValid = await userVerification.isUserValid(userDocId);

        console.log(`in welcomeVerification(), isUserValid: ${isUserValid}`);

        if (isUserValid !== true) {

            return res.status(400).send(appHtml.VerificationDocMissing);
        }

        let userVerifyPromise = new Promise(((resolve, reject) => {

            return userVerification
                .setUserVerified(userDocId)
                .then(() => {
                    return resolve({
                        result : true
                    });
                })
                .catch(function (error) {
                    console.log('Error updating user:', error);
                    return reject(error);

                });
        }));

        return userVerifyPromise
            .then(() => {
                return res.status(200).send(appHtml.EmailHasBeenVerified);
            })
            .catch(function (error) {

                let errMsg = 'Err: ' + JSON.stringify(error);
                return res.status(500).send(errMsg);
            });
    });
});