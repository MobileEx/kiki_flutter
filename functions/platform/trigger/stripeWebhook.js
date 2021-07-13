'use strict';

const appConfig   = require('../appConfig');
const appData     = appConfig.appData;
const firestoreDb = appConfig.firestoreDb;

const functions = require('firebase-functions');
const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});

const appSubscription = require('../model/appSubscription');

const stripe = appConfig.stripeClient;

/**
 * Validate the stripe webhook secret, then call the handler for the event type
 *
 *
 */
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {

    console.log(`ENTER: exports.handleStripeWebhook`);

    const sig   = req.headers['stripe-signature'];
    const event = stripe.webhooks.constructEvent(req['rawBody'], sig, appConfig.STRIPE_WEBHOOK_SECRET);

    try {
        await webhookHandlers[event.type](event.data.object);
        res.send({received : true});
    }
    catch (err) {

        console.log(`Exception, err: ${err}`);
        console.error(err)
        res.status(400).send(`Webhook Error: ${err.message}`);
    }
});


/**
 * Business logic for specific webhook event types
 *
 * webhook Actions:
 * A) On invoice.payment_succeeded
 * 1. Update user expires date
 *      - Get user by stripeCustomerId lookup in /stripeCustomers
 *      - Doc.id will have the app userId
 * 2. Log the payment in /stripePayments
 * 3. Do the vendor payout right away
 *
 * B) On invoice.payment_failed
 * (Do nothing, let the user expires date arrive)
 * 1. Can have a collection /stripeLog/<userId>

 */
const webhookHandlers = {
    'invoice.payment_succeeded' : async (webhookData) => {

        console.log(`ENTER: 'invoice.payment_succeeded'`);

        try {
            // 1) update Buyer subscriptionExpires
            await appSubscription.updateUserSubscriptionExpires(webhookData);

            // 2)pay Seller
            await makeVendorPayouts(webhookData.amount_paid);
        }
        catch (err) {

            console.log(`invoice.payment_succeeded() - Exception, err: ${err}`);
        }
    },

    'invoice.payment_failed' : async (webhookData) => {

        console.log(`ENTER: 'invoice.payment_failed'`);

        await appSubscription.logPaymentFailed(webhookData);
    },

    'customer.subscription.created' : async (webhookData) => {

        console.log(`ENTER: 'customer.subscription.created'`);

        await appSubscription.onSubscriptionCreated(webhookData);
    },
    'customer.subscription.deleted' : async (webhookData) => {

        console.log(`ENTER: 'customer.subscription.deleted'`);

        await appSubscription.logSubscriptionDeleted(webhookData);
    },
}

const VENDOR_FEE = 0.90; // 15%
/**
 * TODO:
 *  1. Connect incoming payment from Buyer, with corresponding Seller to see which Seller to payout
 *      - Need to add Error Handling for when Vendor has not completed onBoard process
 *  2. Getting this error::
 *  handleStripeWebhook - invoice.payment_succeeded()
 *  - Exception, err: Error: Your destination account needs to have
 *      at least one of the following capabilities enabled: transfers, legacy_payments
 * BE AWARE: USD Dollar amount is represented in cents
 * From Stripe Docs:
 * "amount - positive integer or zero
 Amount intended to be collected by this payment.  A positive integer representing how much to charge
 in the smallest currency unit (e.g., 100 cents to charge $1.00 or 100 to charge ¥100,
 a zero-decimal currency). The minimum amount is $0.50 US or equivalent in charge currency.The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99)."
 * @param amountPaid
 * @return {Promise<unknown[]>}
 */
async function makeVendorPayouts(amountPaid) {

    console.log(`ENTER: makeVendorPayouts, amountPaid: ${amountPaid}`);

    const vendors = await firestoreDb.collection(appData.Collctn.vendors)
                                     .get();

    console.log(`vendors query completed`);

    const payoutRequests = [];
    vendors.forEach(snapshot => {
        let vendorPayout = amountPaid * VENDOR_FEE;

        vendorPayout = Math.round(vendorPayout);

        let accountId = snapshot.data().account_id;
        console.log(`vendorPayout in USD Cents: ${vendorPayout}`);

        let payoutJson = {
            amount      : vendorPayout,
            currency    : 'usd',
            destination : accountId
        };

        console.log(`calling stripe.transfers.create(), 
                        payoutJson: ${JSON.stringify(payoutJson)}`);

        // TODO: just one vendor, the Seller for the Buyer
        // pay each vendor specified amount
        const request = stripe.transfers.create(payoutJson);

        payoutRequests.push(request);
    })

    return Promise.all(payoutRequests);
}