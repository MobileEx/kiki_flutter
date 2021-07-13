'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
// admin.initializeApp();
const { Logging } = require('@google-cloud/logging');
const logging = new Logging({
    projectId: process.env.GCLOUD_PROJECT,
});

const appConfig = require('../../appConfig');
const appData   = appConfig.appData;

const errHandler = require('../../util/errHandler');

const stripe = appConfig.stripeClient;

/**
 * Firestore Trigger: functions.auth.user().onCreate(..)
 *
 * When a user is created, create a Stripe customer object for them.
 * We use this top level document to store all Stripe related data for the user
 *
 * @see https://stripe.com/docs/payments/save-and-reuse#web-create-customer
 */
exports.createStripeCustomer = functions.auth.user().onCreate(async (user) => {
    // console.log('ENTER: createStripeCustomer');
    // const customer = await stripe.customers.create({ email: user.email });
    // const intent = await stripe.setupIntents.create({
    //     customer: customer.id,
    // });
    // await admin.firestore().collection(appConfig.Collctn.stripeCustomers).doc(user.uid).set({
    //     customer_id: customer.id,
    //     setup_secret: intent.client_secret,
    // });
    // return;
});

exports.createStripeCustomer2 = async function (user) {
    console.log('ENTER: createStripeCustomer');
    const customer = await stripe.customers.create({ email: user.email });
    const intent = await stripe.setupIntents.create({
        customer: customer.id,
    });
    await admin.firestore().collection(appData.Collctn.stripeCustomers).doc(user.uid).set({
        customer_id: customer.id,
        setup_secret: intent.client_secret,
    });
    return;
};

/**
 * Firestore Trigger: functions.auth.user().onDelete(..)
 *
 * When a user deletes their account, clean up after them
 */
exports.cleanupUser = functions.auth.user().onDelete(async (user) => {
    console.log('ENTER: cleanupUser.onDelete(..)');
    const dbRef = admin.firestore().collection(appData.Collctn.stripeCustomers);
    const customer = (await dbRef.doc(user.uid).get()).data();
    await stripe.customers.del(customer.customer_id);
    // Delete the customers payments & payment methods in firestore.
    const snapshot = await dbRef
        .doc(user.uid)
        .collection('payment_methods')
        .get();
    snapshot.forEach((snap) => snap.ref.delete());
    await dbRef.doc(user.uid).delete();
    return;
});
