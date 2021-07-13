console.log('ENTER: Cloud Funcs index.js');

const admin = require('firebase-admin');
admin.initializeApp();

const eventTriggers      = require('./platform/trigger/eventTriggers');
const kikiHttp           = require('./platform/trigger/kikiHttp');
const scheduledFunctions = require('./platform/trigger/scheduledFunctions');
const stripeWebhook      = require('./platform/trigger/stripeWebhook');

const userAdmin            = require('./platform/feature/admin/userAdmin');
const appEmail            = require('./platform/feature/email/appEmail');
const userSignUp          = require('./platform/feature/signUp/userSignUp');
const stripeCustomer      = require('./platform/feature/stripePayment/stripeCustomer');
const stripeSubscription  = require('./platform/feature/stripePayment/stripeSubscription');
const stripeSellerPayment = require('./platform/feature/stripePayment/stripeWifiSellerPayment');
const stripeVendorAdmin   = require('./platform/feature/stripePayment/stripeVendorAdmin');

const fcmMessaging = require('./platform/feature/messaging/fcmMessaging');

// ==================================================
// ====  Trigger functions
exports.onCreateAuthUser    = eventTriggers.onCreateAuthUser;
exports.hourlyCheck         = scheduledFunctions.hourlyCheck;
exports.handleStripeWebhook = stripeWebhook.handleStripeWebhook;

// The name `welcomeVerification` is what user will see in url
exports.welcomeVerification = kikiHttp.welcomeVerification;

//  ... TEST ONLY
exports.sendFirstHourNtfcns = scheduledFunctions.sendFirstHourNtfcns;

// ==================================================
// ====  OnCall functions
exports.sendHttpRequest1   = userAdmin.sendHttpRequest1;
exports.deleteSeanUsers   = userAdmin.deleteSeanUsers;

exports.registerBuyerInterest   = userSignUp.registerBuyerInterest;
exports.resendVerificationEmail = appEmail.resendVerificationEmail;

// TODO: refactor to eventTriggers, as was done for createStripeCustomer
exports.cleanupUser = stripeCustomer.cleanupUser;

exports.createSubscription = stripeSubscription.createSubscription;
exports.cancelSubscription = stripeSubscription.cancelSubscription;
exports.listSubscriptions  = stripeSubscription.listSubscriptions;

exports.getVendor     = stripeSellerPayment.getVendor;
exports.onboardVendor = stripeSellerPayment.onboardVendor;

exports.getVendorList = stripeVendorAdmin.getVendorList;
exports.deleteVendor  = stripeVendorAdmin.deleteVendor;

exports.storeFcmToken = fcmMessaging.storeFcmToken;
// exports.sendScheduledMessages = fcmMessaging.sendScheduledMessages;

//** for testing purposes. No need to send messages from frontend in production */
exports.sendUserFcmMessage = fcmMessaging.sendUserFcmMessage;
exports.sendGlobalFcmMessage = fcmMessaging.sendGlobalFcmMessage;

/*
// const functions = require('firebase-functions');
// exports.onCreateKikiWifiUser = wifiAccess.onCreateKikiWifiUser;
// exports.createStripeCustomer = stripeCustomer.createStripeCustomer;


Subscribe UI/UX:
1. User access Kiki and trial has expired
2. User is taken to Subscribe view
    - Check user['subscriptionExpires']
        -- IF EXISTS: "Subscription Expired, Please Resubscribe"
        -- ELSE: "Please Subscribe"
    - Once we process success result from createSubscription
        -- Take user to success screen, payment made
        -- In cloud funcs, Stripe webhook should come in and update 'subscriptionExpires' +1 month
        -- Reload the user in the client for new 'subscriptionExpires' date

======================

TASKS 11/4
- TEST Setup Mailing List with 2 Buyers first, then add Seller
- See about Stripe plugin for Flutter, but we have web UI work around as well

DONE: Notification to interested buyer
when a seller within range signs up	onCreate, check: if seller, if seller already assigned
- Run a check on Seller Create
user.onCreate()

DEBUG:  Notification to seller
that buyer is now using their network for trial period	on Buyer subscribe
user.onCreate()

======

* Firestore Trigger: functions.firestore.document([path]).onCreate(..)

[11/3/2020 1:42:04 PM] Gene Kasrel: In the new setup for Single Subscription, do we still add a payment method .. do we still use and/or need this function:

exports.addPaymentMethodDetails(..) ?
exports.createStripePayment another one we are not using for Single Subscrptn?
exports.confirmStripePayment(..)

================
=== Contact Buyer when there's a nearby seller
Setup an onCreate listener for collection: network
1. Query all Buyers that do not have a Seller yet
2.  Run the distance algorithm
3. First user that is in range, send them an email and stop search


================
=== Scheduled routine - can run every 2 hours so that is the maximum time that will elapse
before a scheduled reminder goes out.  This may have impact of $0.10 payments to GCP

1. Query all users with create time less than 48 hours and [ $isFollowUpEmailSent_forRegister == false ]

2. If Seller : Hows it going with the current Buyer?

3. If Buyer : You have 1 day left on your trial

4. Set isFollowUpEmailSent_forRegister=true
*/