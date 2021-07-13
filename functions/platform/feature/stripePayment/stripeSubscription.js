'use strict';

const functions   = require('firebase-functions');
const appConfig   = require('../../appConfig');
const firestoreDb = appConfig.firestoreDb;
const appData     = appConfig.appData;
const errHandler  = appConfig.errHandler;
const stripe      = appConfig.stripeClient;
const priceId      = appConfig.STRIPE_PRICE_ID;

const firestoreFieldConst = appConfig.firestoreFieldConst;

const {Logging} = require('@google-cloud/logging');
const logging   = new Logging({
    projectId : process.env.GCLOUD_PROJECT,
});


/**
 * Attaches a payment method to the Stripe customer,
 * subscribes to a Stripe plan, and saves the plan to Firestore
 */

exports.createSubscription = functions.https.onCall(async (data, context) => {
    console.log('ENTER: createSubscription');
    console.log(`data: ${JSON.stringify(data)}`);

    const {
              userId,
              payment_method
          } = data;

    if (!context.auth) {
        // User is not logged in
        return null;
    }

    console.log(`look up for userId: ${userId}, in /${appData.Collctn.stripeCustomers}`);

    const customer = await firestoreDb
                                .collection(appData.Collctn.stripeCustomers)
                                .doc(userId)
                                .get();

    console.log(`stripe customer.data(): ${JSON.stringify(customer.data())}`);

    // Attach the  payment method to the customer
    await stripe.paymentMethods.attach(payment_method, {customer : customer.data().customer_id});

    // Set it as the default payment method
    await stripe.customers.update(customer.data().customer_id, {
        invoice_settings : {default_payment_method : payment_method},
    });

    const subscription = await stripe.subscriptions.create({
        customer : customer.data().customer_id,
        items    : [{price: priceId}],
        expand   : ['latest_invoice.payment_intent'],
    });


    const invoice        = subscription.latest_invoice;
    const payment_intent = invoice.payment_intent;

    let activePlanList = firestoreFieldConst.arrayUnion(plan);
    console.log(`after Adding subscription.plan.id: ${subscription.plan.id}, setting activePlanList: ${JSON.stringify(activePlanList)}`);

    // Update the user's status
    if (payment_intent.status === 'succeeded') {
        await firestoreDb.collection(appData.Collctn.stripeCustomers)
                         .doc(userId)
                         .set(
                             {
                                 stripeCustomerId : customer.data().customer_id,
                                 activePlans      : activePlanList,
                             },
                             {merge : true}
                         );
    }

    return subscription;
});

/**
 * Cancels an active subscription, syncs the data in Firestore
 */

exports.cancelSubscription = functions.https.onCall(async (data, context) => {
    const {
              userId,
              subscriptionId
          } = data;

    if (!context.auth) {
        // User is not logged in
        // also need to check that user is cancelling his own subscription
        return null;
    }

    // const customer =  await admin.firestore().collection(appConfig.Collctn.stripeCustomers).doc(userId).get();
    // if (customer.metadata.firebaseUID !== userId) {
    //   throw Error('Firebase UID does not match Stripe Customer');
    // }
    const subscription = await stripe.subscriptions.del(subscriptionId);

    // Cancel at end of period
    // const subscription = stripe.subscriptions.update(subscriptionId, { cancel_at_period_end: true });

    let activePlanList = firestoreFieldConst.arrayRemove(subscription.plan.id);
    console.log(`after removing subscription.plan.id: ${subscription.plan.id}, setting activePlanList: ${JSON.stringify(activePlanList)}`);

    if (subscription.status === 'canceled') {
        await firestoreDb.collection(appData.Collctn.stripeCustomers)
                         .doc(userId)
                         .update({
                             activePlans : activePlanList,
                         });
    }

    return subscription;
});

/**
 * Returns all the subscriptions linked to a Firebase userID in Stripe
 */

exports.listSubscriptions = functions.https.onCall(async (data, context) => {
    const {userId} = data;
    if (!context.auth) {
        // User is not logged in
        return null;
    }
    const customer      = await firestoreDb.collection(appData.Collctn.stripeCustomers).doc(userId).get();
    const subscriptions = await stripe.subscriptions.list({
        customer : customer.data().customer_id,
    });

    return subscriptions;
});

