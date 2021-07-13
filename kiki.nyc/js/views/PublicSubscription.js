import AbstractView from './AbstractView.js';

export default class extends AbstractView {
    constructor(params) {
        super(params);
        this.setTitle('Single Subscription');
    }

    plan = null

    setupListeners() {
        /** start firebase logic */
        const STRIPE_PUBLISHABLE_KEY = 'pk_test_HfpZGsxEimfoYTnkb0m762bo';
        let currentUser              = {};
        let customerData             = {};

        /**
         * Set up Stripe Elements
         */
        const stripe      = Stripe(STRIPE_PUBLISHABLE_KEY);
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
                const PRICE_ID = 'price_1Hgw2UE2RRjMXL4yLHSXVF3D';

                let currentUserId = 'abc123';

                const createSubscription = firebase.functions().httpsCallable('createSubscription');
                const result             = await createSubscription({
                    userId         : currentUserId,
                    plan           : PRICE_ID,
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
            <section id="content" style="display: block;">
            <p style='font-size: 28px; font-weight: bold;  '>Monthly Subscription</p>

            <button
                id="price_1Hgw2UE2RRjMXL4yLHSXVF3D"
                class="monthly_button"
            >
                Monthly $12.00/month
            </button>
 
            <div id="add-new-card">
                    <!--
                        <p style='padding: 10px; '>
                        Test Card: <code>4242424242424242</code>
                        </p>
                    -->
                <div id="error-message"></div>
                <form id="payment-method-form" >
                    <div class="form-row" style='border: 1px solid gray; 
                    padding: 10px; border-radius: 5px; max-width: 420px; '>
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