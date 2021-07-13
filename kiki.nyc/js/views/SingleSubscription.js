import AbstractView from './AbstractView.js';

export default class extends AbstractView {
    constructor(params) {
        super(params);
        this.setTitle('Single Subscription');
    }

    plan = null

    setupListeners() {

        /** start firebase logic */
        let currentUser  = {};
        let customerData = {};

        /**
         * Firebase auth configuration
         */
        if (!window.firebaseUI) window.firebaseUI = new firebaseui.auth.AuthUI(firebase.auth());
        const firebaseUiConfig = {
            callbacks        : {
                signInSuccessWithAuthResult : function (authResult, redirectUrl) {
                    // User successfully signed in.
                    // Return type determines whether we continue the redirect automatically
                    // or whether we leave that to developer to handle.
                    return true;
                },
                uiShown                     : () => {
                    document.getElementById('loader').style.display = 'none';
                },
            },
            signInFlow       : 'popup',
            signInSuccessUrl : '/',
            signInOptions    : [
                // firebase.auth.GoogleAuthProvider.PROVIDER_ID,
                firebase.auth.EmailAuthProvider.PROVIDER_ID,
            ],
            credentialHelper : window.firebaseui.auth.CredentialHelper.NONE,
            // Your terms of service url.
            tosUrl           : 'https://example.com/terms',
            // Your privacy policy url.
            privacyPolicyUrl : 'https://example.com/privacy',
        };
        firebase.auth().onAuthStateChanged((firebaseUser) => {
            setViewNav(firebaseUser);


            if (firebaseUser) {
                currentUser = firebaseUser;
                firebase
                    .firestore()
                    .collection('stripeCustomers')
                    .doc(currentUser.uid)
                    .onSnapshot((snapshot) => {
                        if (snapshot.data()) {
                            customerData = snapshot.data();

                            console.log(`customerData: ${JSON.stringify(customerData)}`);

                            document.getElementById('loader').style.display  = 'none';
                            document.getElementById('content').style.display = 'block';
                        }
                        else {
                            console.warn(
                                `No Stripe customer found in Firestore for user: ${currentUser.uid}`
                            );
                        }
                    });

            }
            else {
                document.getElementById('content').style.display = 'none';
                window.firebaseUI.start('#firebaseui-auth-container', firebaseUiConfig);
            }
        });

        /**
         * Set up Stripe Elements
         */
        const stripe      = Stripe(this.STRIPE_PUBLISHABLE_KEY);
        const elements    = stripe.elements();
        // Create an instance of the card Element.
        const cardElement = elements.create('card');
        // Add an instance of the card Element into the `card-element` <div>.
        cardElement.mount('#card-element');
        // Handle real-time validation errors from the card Element.
        cardElement.on('change', ({error}) => {
            const displayError = document.getElementById('error-message');
            if (error) {
                displayError.textContent = error.message;
            }
            else {
                displayError.textContent = '';
            }
        });

        /**
         * Event listeners
         */

        // Signout button
        document
            .getElementById('signout')
            .addEventListener('click', () => firebase.auth().signOut());

        // Add new card form
        document
            .querySelector('#payment-method-form')
            .addEventListener('submit', async (event) => {
                event.preventDefault();
                if (!event.target.reportValidity()) {
                    return;
                }
                document
                    .querySelectorAll('button')
                    .forEach((button) => (button.disabled = true));

                console.log(`Submitting cardElement: ${JSON.stringify(cardElement)}`);

                const {setupIntent, error} = await stripe.confirmCardSetup(
                    customerData.setup_secret,
                    {
                        payment_method : {
                            card : cardElement,
                            // billing_details: {
                            //     name: cardholderName,
                            // },
                        },
                    }
                );

                console.log(setupIntent);

                let currentUser = firebase.auth().currentUser;

                const createSubscription = firebase.functions().httpsCallable('createSubscription');
                const result             = await createSubscription({
                    userId         : currentUser.uid,
                    plan           : this.SUBSCRIPTION_PRICE_ID,
                    payment_method : setupIntent.payment_method
                });

                console.log(result);

                document
                    .querySelectorAll('button')
                    .forEach((button) => (button.disabled = false));
            });

    }

    async getHtml() {
        return `
            <h2>Single Subscription View</h2>
            <section id="firebaseui-auth-container"></section>
            <div id="loader">Loading &hellip;</div>
            <section id="content" style="display: block;">
                <button type="button" id="signout">
                    Sign out
                </button>
            <h3>Monthly subscription:</h3>

            <button
                id="price_1Hgw2UE2RRjMXL4yLHSXVF3D"
                class="monthly_button"
            >
                Monthly $12.00/month
            </button>
 
            <div id="add-new-card">
                <p style='padding: 10px; '>
                    Test Card: <code>4242424242424242</code>
                </p>
                <div id="error-message"></div>
                <form id="payment-method-form" >
                    <div class="form-row" style='border: 1px solid gray; padding: 10px; border-radius: 5px; max-width: 500px; '>
                        <label for="card-element">
                            Credit or debit card
                        </label>
                        <br/>
                        <br/>
                        <div id="card-element">
                        <!-- A Stripe Element will be inserted here. -->
                        </div>
                
                        <!-- Used to display form errors. -->
                        <div id="card-errors" role="alert"></div>
                    </div>
                    <br />
                    <div>
                    <input type="checkbox" id="terms" />
                    <label for="terms">Accept monthly terms</label>
                    </div>

                    <br />
                    <button>Pay now</button>
                </form>
            </div>

        </section>
        `;
    }
}