const nodemailer = require('nodemailer');

let appConfig = require('../appConfig');

let mailTransport = nodemailer.createTransport(appConfig.emailTransportConfig);

/**
 * @param emailObject, Expects structure:
 const mailOptions = {
            from: emailObject.from,
            to: emailObject.to,
            subject: emailObject.subject,
            html: emailObject.html // email content in HTML
        };

 * @return {Promise<any> | PromiseLike<any>}
 */
exports.sendEmail = function (emailObject) {

    console.log('enter KikiEmail.sendEmail()');
    console.log('emailObject: ' + JSON.stringify(emailObject));

    let recipientEmail = emailObject.to;
    return mailTransport.sendMail(emailObject).then(() => {
        console.log('email sent to:', recipientEmail);
        return new Promise(((resolve, reject) => {

            return resolve({
                result : 'email sent to: ' + recipientEmail
            });
        }));
    });
};


// console.log('emailTypeIdx: ' + emailTypeIdx);
// console.log('recipientEmail: ' + recipientEmail);

// let emailObject = kikiEmail.getEmailObject(emailTypeIdx); // 0-2
