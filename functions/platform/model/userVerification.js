'use strict';
// TODO: 4 hrs Sunday: 10am-12pm, 1pm - 4pm
const appConfig = require('../appConfig');
const appData   = appConfig.appData;
const dateUtil  = require('../util/dateUtil');

const frAdmin     = appConfig.firebaseAdmin;
const firestoreDb = appConfig.firestoreDb;

const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});


const errHandler = require('../util/errHandler');
const objectUtil = require('../util/objectUtil');

exports.isUserValid = async function (userId) {

    console.log(`ENTER: isUserValid(), userId: ${userId}`);

    let userDoc = await firestoreDb.collection(appData.Collctn.users)
                                   .doc(userId)
                                   .get();

    let userData = userDoc.data();
    console.log(`userData: ${userData}`);

    let isUserValid = objectUtil.isDefined(userData);
    console.log(`isUserValid: ${isUserValid}`);

    return isUserValid;
};

/**
 * This is called from a Promise wrapper, so reject will get triggered if there is an error/exception
 * @param userId
 * @return {Promise<void>}
 */
exports.setUserVerified = async function (userId) {

    console.log(`ENTER: setUserVerified(), userId: ${userId}`);

    await frAdmin.auth()
                 .updateUser(userId, {
                     emailVerified : true
                 });

    await firestoreDb.collection(appData.Collctn.users)
                     .doc(userId)
                     .update({
                         [appData.Field.verifiedOn] : dateUtil.getNowReadableTimestamp()
                     });
};

// Here for reference
exports.deleteUser = async function (userId) {

    await frAdmin.auth().deleteUser(userId);

    return null;
};

