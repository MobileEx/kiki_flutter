'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');

const { Logging } = require('@google-cloud/logging');
const logging = new Logging({
  projectId: process.env.GCLOUD_PROJECT,
});

const appConfig = require('../../appConfig');
const errHandler = require('../../util/errHandler');

const stripe = appConfig.stripeClient;

//** get vendors data from firestore */
exports.getVendorList = functions.https.onCall( async (data, context) => {

    if (!context.auth) {
        // User is not logged in
        return null;
    }

    const user = await admin.firestore().collection('users').doc(context.auth.uid).get();

    if (!user.data() || user.data().role !== 'admin') {
        return {msg: 'You have no rights'}
    }

    const vendors = await admin.firestore().collection('vendors').get();
    
    let res = {};
    vendors.forEach((doc) => {
        res[doc.id] = doc.data();
    });

    return res
});

//** delete vendor from firestore and stripe api */
exports.deleteVendor = functions.https.onCall( async (data, context) => {

    if (!context.auth) {
        // User is not logged in
        return null;
    }

    const user = await admin.firestore().collection('users').doc(context.auth.uid).get();

    if (!user.data() || user.data().role !== 'admin') {
        return {msg: 'You have no rights'}
    }

    try {
        const { userId } = data;
        const vendor = await admin.firestore().collection('vendors').doc(userId).get();
        
        if (vendor.data()) {
            const deleted = await stripe.accounts.del(vendor.data().account_id);

            await admin.firestore().collection('vendors').doc(userId).delete();

            return {msg: `Ok`, data: deleted}
        }

        return {msg: 'Vendor not found'}
    } catch (err) {
        console.log(err);
        return {msg: err.message}
    }
});