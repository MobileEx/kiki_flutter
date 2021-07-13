const appConfig = require('../../platform/appConfig');
const appData   = appConfig.appData;

let supportFrom1 = 'Kiki Support <Kiki_Support@gmail.com>';
exports.EmailTypeIdx = {

    BuyerInterestRegistered    : 0,
    BuyerSignUpWelcome         : 1,
    SellerSignUpWelcome        : 2,
    SellerFoundForWaitingBuyer : 3,
    SellerWifiActivated        : 4,
};

exports.getAppEmailObject = function (emailTypeIdx, recipientEmail) {

    console.log(`ENTER getAppEmailObject()`);

    let emailTemplate = EmailTemplates[emailTypeIdx];

    console.log(`emailTemplate: ${JSON.stringify(emailTemplate)}`);

    let emailObject = {
        from    : emailTemplate.from,
        to      : recipientEmail,
        subject : emailTemplate.subject,
        html    : emailTemplate.html // email content in HTML
    };

    console.log(`built emailObject: ${JSON.stringify(emailObject)}`);

    return emailObject;
};

EmailTemplates = [

    // BuyerInterestRegistered
    {
        from    : supportFrom1,
        subject : 'Welcome to Kiki: Interest Registered',
        html    : `<p style='font-size: 16px;'>Thanks for signing up with Kiki!!</p>
        <p style='font-size: 12px;'>We will contact you when there is WiFi nearby.</p>
        <p style='font-size: 12px;'>Best Regards,</p>
        <p style='font-size: 12px;'>-Kiki Support Team</p>
      ` // email content in HTML
    },
    /*
    Logic to add:
      When we create an account and then go to send email, get user doc.id
     */
    // BuyerSignUpWelcome
    {

        from    : supportFrom1,
        subject : 'Welcome to Kiki, Start Enjoying your WiFi',
        html    : `<p style='font-size: 16px;'>Thanks for signing up with Kiki!!</p>
        <p style='font-size: 12px;'>Please verify your email by clicking the link below:</p>
        <a href='${appData.AppUrl.welcomeVerification}'>Verify my Email with Kiki</a>
        <p style='font-size: 12px;'>Login to the app to access your WiFi today</p>
        <p style='font-size: 12px;'>Best Regards,</p>
        <p style='font-size: 12px;'>-Kiki Support Team</p>
      ` // email content in HTML
    },
    // SellerSignUpWelcome
    {

        from    : supportFrom1,
        subject : 'Welcome to the Kiki Network Family',
        html    : `<p style='font-size: 16px;'>Thanks for signing up with Kiki to help others and make a little extra money.</p>
        <p style='font-size: 12px;'>Please verify your email by clicking the link below:</p>
        <a href='${appData.AppUrl.welcomeVerification}'>Verify my Email with Kiki</a>
        <p style='font-size: 12px;'>Login to the app to see if a user is connected</p>
        <p style='font-size: 12px;'>Best Regards,</p>
        <p style='font-size: 12px;'>-Kiki Support Team</p>
      ` // email content in HTML
    },
    // SellerFoundForWaitingBuyer
    {

        from    : supportFrom1,
        subject : 'Kiki Wifi Update: Good News, Wifi Now Available for your Location ',
        html    : `<p style='font-size: 16px;'>You are receiving this message because you registered interest through the Kiki WiFi App.</p>
        <p style='font-size: 12px;'>Open Kiki WiFi, click 'I need Wifi' button, and finish the registration process there.</p>
        <p style='font-size: 12px;'>After you login you will see a button to connect to the wifi.</p>
        <p style='font-size: 12px;'>Let us know if you run into any challenges, our support will reply within 1 business day.</p>
        <p style='font-size: 12px;'>Best Regards,</p>
        <p style='font-size: 12px;'>-Kiki Support Team</p>
      ` // email content in HTML
    },
    // SellerWifiActivated
    {

        from    : supportFrom1,
        subject : 'Congratulations!, Your Kiki Wifi is Now Active',
        html    : `<p style='font-size: 16px;'>A subscriber is now in a 3 day trial with your network.</p>
        <p style='font-size: 12px;'>Let us know how it goes.</p>
        <p style='font-size: 12px;'>Here's a link to cancel their subscription before the 3 days is up:
        <a href='#'>Cancel Subscriber (not working now)</a>
        </p>
        <p style='font-size: 12px;'>Let us know if you run into any challenges, our support will reply within 1 business day.</p>
        <p style='font-size: 12px;'>Best Regards,</p>
        <p style='font-size: 12px;'>-Kiki Support Team</p>
      ` // email content in HTML
    }
];
