import AbstractView from "./AbstractView.js";

// Uncomment next line to force logout on refresh when screen hangs on "Loadding"
// firebase.auth().signOut();

export default class extends AbstractView {
    constructor(params) {
        super(params);
        this.setTitle("Dashboard");
    }

    setupListeners() {
        /** start firebase logic */

        // const firebaseProject = 'frbase-demo2';
        // const STRIPE_PUBLISHABLE_KEY = 'pk_test_HfpZGsxEimfoYTnkb0m762bo';
        
        // const firebaseProject = 'guest-bookly';
        // const STRIPE_PUBLISHABLE_KEY = 'pk_test_51HgHy3IDB6jDa4Tip85B76s2CvWeK1xOhp2RpGsgGkdArZoIGTIXSPR9k3j7Ljuw2xixbJxT5EpPwcvXIRUxsAVB00oj0vUXAw';

        const firebaseProject = 'wifi-share-c1423';
        const STRIPE_PUBLISHABLE_KEY = 'pk_test_51HgC0eKe4BM2E8Ini22asgHj76JCDaUmNuIlEs4IUDjWKMCO3qhegaSNjKget0HKNiSlaJdcNRm1n8G8dXXlfcHT00iU4H0ect';

        console.log('firebaseProject: ' + firebaseProject);
        console.log('STRIPE_PUBLISHABLE_KEY: ' + STRIPE_PUBLISHABLE_KEY);

        let currentUser = {};
        let customerData = {};

        /**
         * Firebase auth configuration
         */
        if (!window.firebaseUI) window.firebaseUI = new firebaseui.auth.AuthUI(firebase.auth());
        const firebaseUiConfig = {
        callbacks: {
            signInSuccessWithAuthResult: function (authResult, redirectUrl) {
            // User successfully signed in.
            // Return type determines whether we continue the redirect automatically
            // or whether we leave that to developer to handle.
            return true;
            },
            uiShown: () => {
            document.getElementById('loader').style.display = 'none';
            },
        },
        signInFlow: 'popup',
        signInSuccessUrl: '/',
        signInOptions: [
            // firebase.auth.GoogleAuthProvider.PROVIDER_ID,
            firebase.auth.EmailAuthProvider.PROVIDER_ID,
        ],
        credentialHelper: window.firebaseui.auth.CredentialHelper.NONE,
        // Your terms of service url.
        tosUrl: 'https://example.com/terms',
        // Your privacy policy url.
        privacyPolicyUrl: 'https://example.com/privacy',
        };
        firebase.auth().onAuthStateChanged((firebaseUser) => {
        
        setViewNav(firebaseUser);

        this.setUserInfo();


        if (firebaseUser) {
            currentUser = firebaseUser;
            firebase
            .firestore()
            .collection('stripeCustomers')
            .doc(currentUser.uid)
            .onSnapshot((snapshot) => {
                if (snapshot.data()) {
                customerData = snapshot.data();
                startDataListeners();
                document.getElementById('loader').style.display = 'none';
                document.getElementById('content').style.display = 'block';
                } else {
                console.warn(
                    `No Stripe customer found in Firestore for user: ${currentUser.uid}`
                );
                }
            });
        } else {
            document.getElementById('content').style.display = 'none';
            window.firebaseUI.start('#firebaseui-auth-container', firebaseUiConfig);
        }
        });

        /**
         * Set up Stripe Elements
         */
        const stripe = Stripe(STRIPE_PUBLISHABLE_KEY);
        const elements = stripe.elements();
        // const cardElement = elements.create('card');
        // cardElement.mount('#card-element');
        // cardElement.on('change', ({ error }) => {
        // const displayError = document.getElementById('error-message');
        // if (error) {
        //     displayError.textContent = error.message;
        // } else {
        //     displayError.textContent = '';
        // }
        // });

        /**
        * Set up Firestore data listeners
        */
        function startDataListeners() {
        /**
        * Get all payment methods for the logged in customer
        */
        firebase
            .firestore()
            .collection('stripeCustomers')
            .doc(currentUser.uid)
            .collection('payment_methods')
            .onSnapshot((snapshot) => {
            // if (snapshot.empty) {
            //     document.querySelector('#add-new-card').open = true;
            // }
            snapshot.forEach(function (doc) {
                const paymentMethod = doc.data();
                if (!paymentMethod.card) {
                return;
                }

                const optionId = `card-${doc.id}`;
                let optionElement = document.getElementById(optionId);

                // Add a new option if one doesn't exist yet.
                if (!optionElement) {
                optionElement = document.createElement('option');
                optionElement.id = optionId;
                // document
                //     .querySelector('select[name=payment-method]')
                //     .appendChild(optionElement);
                }

                optionElement.value = paymentMethod.id;
                optionElement.text = `${paymentMethod.card.brand} •••• ${paymentMethod.card.last4} | Expires ${paymentMethod.card.exp_month}/${paymentMethod.card.exp_year}`;
            });
            });

        /**
        * Get all payments for the logged in customer
        */
        firebase
            .firestore()
            .collection('stripeCustomers')
            .doc(currentUser.uid)
            .collection('payments')
            .onSnapshot((snapshot) => {
            snapshot.forEach((doc) => {
                const payment = doc.data();

                let liElement = document.getElementById(`payment-${doc.id}`);
                if (!liElement) {
                liElement = document.createElement('li');
                liElement.id = `payment-${doc.id}`;
                }

                let content = '';
                if (
                payment.status === 'new' ||
                payment.status === 'requires_confirmation'
                ) {
                content = `Creating Payment for ${formatAmount(
                    payment.amount,
                    payment.currency
                )}`;
                } else if (payment.status === 'succeeded') {
                const card = payment.charges.data[0].payment_method_details.card;
                content = `✅ Payment for ${formatAmount(
                    payment.amount,
                    payment.currency
                )} on ${card.brand} card •••• ${card.last4}.`;
                } else if (payment.status === 'requires_action') {
                content = `🚨 Payment for ${formatAmount(
                    payment.amount,
                    payment.currency
                )} ${payment.status}`;
                handleCardAction(payment, doc.id);
                } else {
                content = `⚠️ Payment for ${formatAmount(
                    payment.amount,
                    payment.currency
                )} ${payment.status}`;
                }
                liElement.innerText = content;
                // document.querySelector('#payments-list').appendChild(liElement);
            });
            });
        }

        /**
        * Event listeners
        */

        // Signout button
        document
        .getElementById('signout')
        .addEventListener('click', () => firebase.auth().signOut());

        // Add new card form
        // document
        // .querySelector('#payment-method-form')
        // .addEventListener('submit', async (event) => {
        //     event.preventDefault();
        //     if (!event.target.reportValidity()) {
        //     return;
        //     }
        //     document
        //     .querySelectorAll('button')
        //     .forEach((button) => (button.disabled = true));

        //     const form = new FormData(event.target);
        //     const cardholderName = form.get('name');

        //     const { setupIntent, error } = await stripe.confirmCardSetup(
        //     customerData.setup_secret,
        //     {
        //         payment_method: {
        //         card: cardElement,
        //         billing_details: {
        //             name: cardholderName,
        //         },
        //         },
        //     }
        //     );

        //     if (error) {
        //     document.querySelector('#error-message').textContent = error.message;
        //     document
        //         .querySelectorAll('button')
        //         .forEach((button) => (button.disabled = false));
        //     return;
        //     }

        //     await firebase
        //     .firestore()
        //     .collection('stripeCustomers')
        //     .doc(currentUser.uid)
        //     .collection('payment_methods')
        //     .add({ id: setupIntent.payment_method });

        //     document.querySelector('#add-new-card').open = false;
        //     document
        //     .querySelectorAll('button')
        //     .forEach((button) => (button.disabled = false));
        // });

        // // Create payment form
        // document
        // .querySelector('#payment-form')
        // .addEventListener('submit', async (event) => {
        //     event.preventDefault();
        //     document
        //     .querySelectorAll('button')
        //     .forEach((button) => (button.disabled = true));

        //     const form = new FormData(event.target);
        //     const amount = Number(form.get('amount'));
        //     const currency = form.get('currency');
        //     const data = {
        //     payment_method: form.get('payment-method'),
        //     currency,
        //     amount: formatAmountForStripe(amount, currency),
        //     status: 'new',
        //     };

        //     await firebase
        //     .firestore()
        //     .collection('stripeCustomers')
        //     .doc(currentUser.uid)
        //     .collection('payments')
        //     .add(data);

        //     document
        //     .querySelectorAll('button')
        //     .forEach((button) => (button.disabled = false));
        // });

        /**
        * Helper functions
        */

        // Format amount for diplay in the UI
        function formatAmount(amount, currency) {
        amount = zeroDecimalCurrency(amount, currency)
            ? amount
            : (amount / 100).toFixed(2);
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency,
        }).format(amount);
        }

        // Format amount for Stripe
        function formatAmountForStripe(amount, currency) {
        return zeroDecimalCurrency(amount, currency)
            ? amount
            : Math.round(amount * 100);
        }

        // Check if we have a zero decimal currency
        // https://stripe.com/docs/currencies#zero-decimal
        function zeroDecimalCurrency(amount, currency) {
        let numberFormat = new Intl.NumberFormat(['en-US'], {
            style: 'currency',
            currency: currency,
            currencyDisplay: 'symbol',
        });
        const parts = numberFormat.formatToParts(amount);
        let zeroDecimalCurrency = true;
        for (let part of parts) {
            if (part.type === 'decimal') {
            zeroDecimalCurrency = false;
            }
        }
        return zeroDecimalCurrency;
        }

        // Handle card actions like 3D Secure
        async function handleCardAction(payment, docId) {
        const { error, paymentIntent } = await stripe.handleCardAction(
            payment.client_secret
        );
        if (error) {
            alert(error.message);
            payment = error.payment_intent;
        } else if (paymentIntent) {
            payment = paymentIntent;
        }

        await firebase
            .firestore()
            .collection('stripeCustomers')
            .doc(currentUser.uid)
            .collection('payments')
            .doc(docId)
            .set(payment, { merge: true });
        }
    }

    async getHtml() {
        return `
        <section id="firebaseui-auth-container"></section>
        <div id="loader">Loading &hellip;</div>
        <section id="content" style="display: none;">
          <button type="button" id="signout">
            Sign out
          </button>
        </section>
        `;
    }
}

/*
<div>
            <h2>Payment Methods</h2>
            <details id="add-new-card">
              <summary>Add new</summary>
              <p>
                Use any of the
                <a href="https://stripe.com/docs/testing#international-cards"
                  >Stripe test cards</a
                >
                for this demo!
              </p>
              <form id="payment-method-form">
                <label>
                  Cardholder name
                  <input type="text" name="name" required />
                </label>
                <fieldset>
                  <div id="card-element"></div>
                </fieldset>
                <div id="error-message" role="alert"></div>
                <button>Save Card</button>
              </form>
            </details>
            <hr />
            <form id="payment-form">
              <div>
                <label>
                  Card:
                  <select name="payment-method" required></select>
                </label>
              </div>
              <div>
                <label>
                  Amount:
                  <input
                    name="amount"
                    type="number"
                    min="1"
                    max="99999999"
                    value="100"
                    required
                  />
                </label>
                <label>
                  Currency:
                  <select name="currency">
                    <option value="usd">USD</option>
                    <option value="eur">EUR</option>
                    <option value="gbp">GBP</option>
                    <option value="jpy">JPY</option>
                  </select>
                </label>
              </div>
              <button>Charge selected card</button>
            </form>
          </div>
          <div>
            <h2>Payments</h2>
            <ul id="payments-list"></ul>
          </div>
 */