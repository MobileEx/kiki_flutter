'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
// admin.initializeApp();
const { Logging } = require('@google-cloud/logging');
const logging = new Logging({
  projectId: process.env.GCLOUD_PROJECT,
});

const appConfig = require('../../appConfig');
const errHandler = require('../../util/errHandler');

const stripe = appConfig.stripeClient;

//** onboard new vendor */
exports.onboardVendor = functions.https.onCall( async (data, context) => {
    const { userId } = data;
    if (!context.auth) {
        // User is not logged in
        return null;
    }

    let account;
    const vendor = await admin.firestore().collection('vendors').doc(userId).get();
    if (!vendor.data()) {
        account = await stripe.accounts.create({
            type: 'express',
        });
        await admin.firestore().collection('vendors').doc(userId)
                   .set({account_id: account.id}, {merge: true});

        const accountLinks = await stripe.accountLinks.create({
            account: account.id,
            refresh_url: 'https://example.com/reauth',
            return_url: 'https://wifi-share-c1423.web.app/return',
            type: 'account_onboarding',
        });

        return accountLinks;

    } else {
        account = await stripe.accounts.retrieve(vendor.data().account_id);

        await admin.firestore().collection('vendors').doc(userId)
                   .set({details_submitted: account.details_submitted}, {merge: true});

        if (!account.details_submitted) {
            // user didn't complete onboarding, create new onboarding link to let him finish
            const accountLinks = await stripe.accountLinks.create({
                account: account.id,
                refresh_url: 'https://example.com/reauth',
                return_url: 'https://wifi-share-c1423.web.app/return',
                type: 'account_onboarding',
            });

            return accountLinks;
        }
    }

    // vendor already exists in stripe
    return {msg: 'Vendor already completed onboarding process'};

});


//** get vendor data from stripe api */
exports.getVendor = functions.https.onCall( async (data, context) => {
    const { userId } = data;
    if (!context.auth) {
        // User is not logged in
        return null;
    }

    const vendor = await admin.firestore().collection('vendors').doc(userId).get();
    if (vendor.data()) {
        const account = await stripe.accounts.retrieve(vendor.data().account_id);

        await admin.firestore().collection('vendors').doc(userId)
                   .set(account, {merge: true});

        return account
    }

    return {msg: 'Vendor not found'}
});
//
// /**
//  * Business logic for specific webhook event types
//  */
// const webhookHandlers = {
//     'customer.subscription.deleted': async (data) => {
//         const customer = await stripe.customers.retrieve( data.customer );
//         const user = await db.collection(appConfig.Collctn.stripeCustomers).where('customer_id', '==', customer.id).limit(1).get();
//         const userId = user.docs[0].id;
//
//         await db.collection(appConfig.Collctn.stripeCustomers).doc(userId)
//                 .update({
//                     activePlans: admin.firestore.FieldValue.arrayRemove(data.plan.id),
//                 });
//     },
//     'customer.subscription.created': async (data) => {
//         const customer = await stripe.customers.retrieve( data.customer );
//         const user = await db.collection(appConfig.Collctn.stripeCustomers).where('customer_id', '==', customer.id).limit(1).get();
//         const userId = user.docs[0].id;
//
//         await db.collection(appConfig.Collctn.stripeCustomers).doc(userId)
//                 .update({
//                     activePlans: admin.firestore.FieldValue.arrayUnion(data.plan.id),
//                 });
//     },
//     'invoice.payment_succeeded': async (data) => {
//         await makeVendorPayouts(data.amount_paid);
//     },
//     'invoice.payment_failed': async (data) => {
//
//         const customer = await stripe.customers.retrieve( data.customer);
//         const user = await db.collection(appConfig.Collctn.stripeCustomers).where('customer_id', '==', customer.id).limit(1).get();
//         const userId = user.docs[0].id;
//         await db.collection(appConfig.Collctn.stripeCustomers).doc(userId).update({ status: 'PAST_DUE' });
//
//     }
// }
//
// /**
//  * Validate the stripe webhook secret, then call the handler for the event type
//  *
//  * webhook Actions:
//  * A) On invoice.payment_succeeded
//  * 1. Update user expires date
//  * 2. Log the payment in /stripePayments
//  * 3. Do the vendor payout right away
//  *
//  * B) On invoice.payment_failed
//  * (Do nothing, let the user expires date arrive)
//  * 1. Can have a collection /stripeLog/<userId>
//  *
//  */
// const STRIPE_WEBHOOK_SECRET = 'whsec_rhVlcE7JotM6LgqvB22IWR5vfhdrtz7K';
// exports.handleStripeWebhook = functions.https.onRequest(async(req, res) => {
//     const sig = req.headers['stripe-signature'];
//     const event = stripe.webhooks.constructEvent(req['rawBody'], sig, appConfig.STRIPE_WEBHOOK_SECRET);
//
//     try {
//         await webhookHandlers[event.type](event.data.object);
//         res.send({received: true});
//     } catch (err) {
//         console.error(err)
//         res.status(400).send(`Webhook Error: ${err.message}`);
//     }
// });
//
// const VENDOR_FEE = 0.150; // 15%
// async function makeVendorPayouts(amount_paid) {
//     const vendors = await db.collection('vendors').get();
//
//     const payoutRequests = [];
//     vendors.forEach(snapshot => {
//         // pay each vendor specified amount
//         const request = stripe.transfers.create({
//             amount: amount_paid * VENDOR_FEE,
//             currency: "usd",
//             destination: snapshot.data().account_id,
//         });
//
//         payoutRequests.push(request);
//     })
//
//     return Promise.all(payoutRequests);
// }