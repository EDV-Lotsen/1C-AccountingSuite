
////////////////////////////////////////////////////////////////////////////////
// Stripe API: Server Web Requestor Interface
//------------------------------------------------------------------------------
// Available on:
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

// Stripe: Account
//------------------------------------------------------------------------------
// This is an object representing your Stripe account.
// You can retrieve it to see properties on the account like its current e-mail
// address or if the account is enabled yet to make live charges.
//------------------------------------------------------------------------------
#Region Stripe_Account

// Retrieves the details of the account, based on the API key
// that was used to make the request.
//
// Parameters:
//  AccountData              - FixedArray - Key data used for authorization,
//                           - Undefined  - Use default authorization data.
//
// Returns:
//  ResultDescription - Structure with following parameters:
//   Result                  - Structure  - Account object with the following keys and values:
//    object                 - String     - "account" - verifies type of returned object.
//    id                     - String     - Account ID in Stripe system.
//    charge_enabled         - Boolean    - Flag enabling operating in live mode.
//    country                - String     - The country of the account.
//    currencies_supported   - Array      - Codes of supported currencies.
//    default_currency       - String     - The currency this account has chosen to use as the default.
//    details_submitted      - Boolean    - Account details are submitted to Stripe.
//    transfer_enabled       - Boolean    - Whether or not Stripe will send automatic transfers for this account.
//                                          This is only false when Stripe is waiting for additional information
//                                          from the account holder.
//    email                  - String     - E-mail of person responsible for the account.
//    statement_descriptor   - String     - Provider ID displayed on client statements.
//    - or                   - Undefined  - If failed.
//   Description             - String     - Error description if function failed.
//
Function RetrieveAccount(AccountData = Undefined) Export
	Method = "Get"; Object = "Account"; RequestObj = "account";
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = GetStripeApiEndpoint() + GetStripeApiResourcePath(Object);
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	ExternalParameters  = New Structure("AuthorizationKey",
	                      ?(AccountData <> Undefined, AccountData, ApiStripeSettingsOverridable.GetStripeAPIAuthorizationKey()));
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler, ExternalParameters);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection        = ConnectionStructure.Result;
	
	// Open connection and request Stripe API.
	RequestStructure  = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,,,, ExternalHandler, ExternalParameters);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Handle the execution result and return the object structure.
	Return GetRequestResult(RequestStructure, RequestObj);
	
EndFunction

#EndRegion

// Stripe: Tokens
//------------------------------------------------------------------------------
// Often you want to be able to charge credit cards or send payments to bank
// accounts without having to hold sensitive card information on your own servers.
// Stripe.js makes this easy in the browser, but you can use the same technique
// in other environments with our token API.
// Tokens can be created with your publishable API key, which can safely
// be embedded in downloadable applications like iPhone and Android apps.
// You can then use a token anywhere in our API that a card or bank account
// is accepted. Note that tokens are not meant to be stored or used more than once.
//------------------------------------------------------------------------------
#Region Stripe_Tokens

// Creates a single use token that wraps the details of a credit card.
// This token can be used in place of a credit card dictionary with any API method.
// These tokens can only be used once: by creating a new charge object,
// or attaching them to a customer.
//
// Parameters:
//  TokenData          - Structure - The data used for creating the customer token (2 options),
//                                   either customer or card is required, but not both:
//   card              - Structure - The card details this token will represent.
//    number           - String    - The card number, as a string without any separators.
//    exp_month        - Number    - Two digit number representing the card's expiration month.
//    exp_year         - Number    - Two or four digit number representing the card's expiration year.
//    cvc              - Number    - (optional, highly recommended) Card security code.
//    name             - String    - (optional) Cardholder's full name.
//                                   Optional billing address:
//    address_line1    - String    - (optional).
//    address_line2    - String    - (optional).
//    address_city     - String    - (optional).
//    address_zip      - String    - (optional).
//    address_state    - String    - (optional).
//    address_country  - String    - (optional).
//   - or:
//   customer          - String    - ID of StripeConnect customer to be registered for current account.
//
// Returns:
//  ResultDescription  - Structure with following parameters:
//   Result            - Structure - The Token object with the following keys and values:
//    object           - String    - "token" - verifies type of returned object.
//    id               - String    - Token ID in Stripe system.
//    livemode         - Boolean   - Account mode in which token was created.
//    created          - Datetime  - Timestamp of created token record.
//    type             - String    - "card". Type of the token.
//    used             - Boolean   - False. Whether or not this token has already been used.
//                                   Tokens can be used only once.
//    card             - Structure - The Card obect with the following keys and values:
//     object          - String    - "card" - verifies type of returned object.
//     id              - String    - Card ID in Stripe system.
//     exp_month       - Number    - Number representing the card's expiration month.
//     exp_year        - Number    - Number representing the card's expiration year.
//     fingerprint     - String    - Uniquely identifies this particular card number.
//                                   It is possible to use this attribute to check whether two
//                                   customers who’ve signed up are using the same card number.
//     last4           - String    - Last 4 digits of card number.
//     type            - String      Card brand. Can be "Visa", "American Express", "MasterCard",
//                                   "Discover", "JCB", "Diners Club", or "Unknown".
//                                   Billing address (if defined when creating the card):
//     address_city    - String
//                     - Undefined
//     address_country - String
//                     - Undefined
//     address_line1   - String
//                     - Undefined
//     address_line1_check - String- (optional, if address_line1 was provided)
//                                   "pass", "fail", or "unchecked". Result of address check.
//                     - Undefined - The address was not provided, check was not performed.
//     address_line2   - String
//                     - Undefined
//     address_state   - String
//                     - Undefined
//     address_zip     - String
//                     - Undefined
//     address_zip_check - String  - (optional, if address_zip was provided)
//                                   "pass", "fail", or "unchecked". Result of address zip check.
//                     - Undefined - The address zip was not provided, check was not performed.
//     country         - String    - Two-letter ISO code representing the country of the card
//                                   (as accurately as Stripe can determine it).
//                                   This could be used to get a sense of the international
//                                   breakdown of cards you’ve collected.
//                     - Undefined
//     customer        - String    - Customer (owner) ID in Stripe system.
//     cvc_check       - String    - (optional, if cvc was provided)
//                                   "pass", "fail" or "unchecked". Result of card cvc check.
//                     - Undefined - The cvc code was not provided, check was not performed.
//     name            - String    - Cardholder name.
//                     - Undefined
//   - or              - Undefined - If failed.
//   Description       - String    - Error description if function failed.
//   AdditionalData    - Structure - If failed, contains source data, returned by the Stripe server.
//    Code             - Number    - Server result code (if available).
//    Result           - Structure - If server returned object which wasn't expected.
//                     - String    - If server returned string what we didn't expect at all.
//   - or              - Undefined - If succeeded.
//
Function CreateTokenCard(TokenData) Export
	Method = "Post"; Object = "Tokens"; RequestObj = "token";
	
	// Define and fill input data for Stripe API method.
	If TokenData.Property("card") Then
		// Fill card properties.
		InputParameters    = New Structure("card", New Structure("number, exp_month, exp_year, cvc, name, address_line1, address_line2, address_city, address_zip, address_state, address_country"));
		FillPropertyValues(InputParameters.card, TokenData.card);
		
	ElsIf TokenData.Property("customer") Then
		// Fill customer property.
		InputParameters    = New Structure("customer");
		FillPropertyValues(InputParameters, TokenData.customer);
		
	Else // The input parameters are not specified.
		Return ResultDescription(Undefined, NStr("en = 'Stripe API: Input parameters are not properly defined.'"));
	EndIf;
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = GetStripeApiEndpoint() + GetStripeApiResourcePath(Object);
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection         = ConnectionStructure.Result;
	
	// Convert sending data for POST request.
	InputData          = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	// Open connection and request Stripe API.
	RequestStructure   = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,, InputData,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Handle the execution result and return the object structure.
	Return GetRequestResult(RequestStructure, RequestObj);
	
EndFunction

// Creates a single use token that wraps the details of a bank account.
// This token can be used in place of a bank account dictionary with any API method.
// These tokens can only be used once: by attaching them to a recipient.
//
// Parameters:
//  TokenData          - Structure - The data used for creating the recipient token:
//   bank_account      - Structure - The bank account to attach to the recipient.
//    country          - String    - The country the bank account is in.
//                                   Currently, Stripe supports US only.
//    routing_number   - String    - The routing number for the bank account in string form.
//                                   This should be the ACH routing number,
//                                   not the wire routing number.
//    account_number   - String    - The account number for the bank account in string form.
//                                   Must be a checking account.
//
// Returns:
//  ResultDescription  - Structure with following parameters:
//   Result            - Structure - The Token object with the following keys and values:
//    object           - String    - "token" - verifies type of returned object.
//    id               - String    - Token ID in Stripe system.
//    livemode         - Boolean   - Account mode in which token was created.
//    created          - Datetime  - Timestamp of created token record.
//    type             - String    - "bank_account". Type of the token.
//    used             - Boolean   - False. Whether or not this token has already been used.
//                                   Tokens can be used only once.
//    bank_account     - Structure - The Bank account obect with the following keys and values:
//     object          - String    - "bank_account" - verifies type of returned object.
//     bank_name       - String    - Name of the bank associated with the routing number, e.g. WELLS FARGO.
//     country         - String    - Two-letter ISO code representing the country the bank account is located in.
//     last4           - String    - Last 4 digits of bank account number.
//     fingerprint     - String    - Uniquely identifies this particular bank account.
//                                   It is possible to use this attribute to check
//                                   whether two bank accounts are the same.
//                     - Undefined - If bank is not registered within Stripe system.
//     validated       - Boolean   - Whether or not the bank account exists.
//                                   If false, there isn’t enough information to know
//                                   (e.g. for smaller credit unions), or the validation is not being run.
//                     - Undefined - If bank is not registered within Stripe system.
//   - or              - Undefined - If failed.
//   Description       - String    - Error description if function failed.
//   AdditionalData    - Structure - If failed, contains source data, returned by the Stripe server.
//    Code             - Number    - Server result code (if available).
//    Result           - Structure - If server returned object which wasn't expected.
//                     - String    - If server returned string what we didn't expect at all.
//   - or              - Undefined - If succeeded.
//
Function CreateTokenBankAccount(TokenData) Export
	Method = "Post"; Object = "Tokens"; RequestObj = "token";
	
	// Define and fill input data for Stripe API method.
	If TokenData.Property("bank_account") Then
		// Fill bank account properties.
		InputParameters    = New Structure("bank_account", New Structure("country, routing_number, account_number"));
		FillPropertyValues(InputParameters.bank_account, TokenData.bank_account);
		
	Else // The input parameters are not specified.
		Return ResultDescription(Undefined, NStr("en = 'Stripe API: Input parameters are not properly defined.'"));
	EndIf;
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = GetStripeApiEndpoint() + GetStripeApiResourcePath(Object);
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection         = ConnectionStructure.Result;
	
	// Convert sending data for POST request.
	InputData          = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	// Open connection and request Stripe API.
	RequestStructure   = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,, InputData,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Handle the execution result and return the object structure.
	Return GetRequestResult(RequestStructure, RequestObj);
	
EndFunction

// Retrieves the token with the given ID.
//
// Parameters:
//  TokenData          - String    - ID of existing token in Stripe system.
//
// Returns:
//  ResultDescription  - Structure with following parameters:
//   Result            - Structure - The Token object with the following keys and values:
//    object           - String    - "token" - verifies type of returned object.
//    id               - String    - Token ID in Stripe system.
//    livemode         - Boolean   - Account mode in which token was created.
//    created          - Datetime  - Timestamp of created token.
//    type             - String    - "card" or "bank_account". Type of the token.
//    used             - Boolean   - Whether or not this token has already been used.
//                                   Tokens can be used only once.
//    card             - Structure - (optional) The Card obect with the following keys and values:
//     object          - String    - "card" - verifies type of returned object.
//     id              - String    - Card ID in Stripe system.
//     exp_month       - Number    - Number representing the card's expiration month.
//     exp_year        - Number    - Number representing the card's expiration year.
//     fingerprint     - String    - Uniquely identifies this particular card number.
//                                   It is possible to use this attribute to check whether two
//                                   customers who’ve signed up are using the same card number.
//     last4           - String    - Last 4 digits of card number.
//     type            - String      Card brand. Can be "Visa", "American Express", "MasterCard",
//                                   "Discover", "JCB", "Diners Club", or "Unknown".
//                                   Billing address (if defined when creating the card):
//     address_city    - String
//                     - Undefined
//     address_country - String
//                     - Undefined
//     address_line1   - String
//                     - Undefined
//     address_line1_check - String- (optional, if address_line1 was provided)
//                                   "pass", "fail", or "unchecked". Result of address check.
//                     - Undefined - The address was not provided, check was not performed.
//     address_line2   - String
//                     - Undefined
//     address_state   - String
//                     - Undefined
//     address_zip     - String
//                     - Undefined
//     address_zip_check - String  - (optional, if address_zip was provided)
//                                   "pass", "fail", or "unchecked". Result of address zip check.
//                     - Undefined - The address zip was not provided, check was not performed.
//     country         - String    - Two-letter ISO code representing the country of the card
//                                   (as accurately as Stripe can determine it).
//                                   This could be used to get a sense of the international
//                                   breakdown of cards you’ve collected.
//                     - Undefined
//     customer        - String    - Customer (owner) ID in Stripe system.
//     cvc_check       - String    - (optional, if cvc was provided)
//                                   "pass", "fail" or "unchecked". Result of card cvc check.
//                     - Undefined - The cvc code was not provided, check was not performed.
//     name            - String    - Cardholder name.
//                     - Undefined
//    bank_account     - Structure - (optional) The Bank account obect with the following keys and values:
//     object          - String    - "bank_account" - verifies type of returned object.
//     bank_name       - String    - Name of the bank associated with the routing number, e.g. WELLS FARGO.
//     country         - String    - Two-letter ISO code representing the country the bank account is located in.
//     last4           - String    - Last 4 digits of bank account number.
//     fingerprint     - String    - Uniquely identifies this particular bank account.
//                                   It is possible to use this attribute to check
//                                   whether two bank accounts are the same.
//                     - Undefined - If bank is not registered within Stripe system.
//     validated       - Boolean   - Whether or not the bank account exists.
//                                   If false, there isn’t enough information to know
//                                   (e.g. for smaller credit unions), or the validation is not being run.
//                     - Undefined - If bank is not registered within Stripe system.
//   - or              - Undefined - If failed.
//   Description       - String    - Error description if function failed.
//   AdditionalData    - Structure - If failed, contains source data, returned by the Stripe server.
//    Code             - Number    - Server result code (if available).
//    Result           - Structure - If server returned object which wasn't expected.
//                     - String    - If server returned string what we didn't expect at all.
//   - or              - Undefined - If succeeded.
//
Function RetrieveToken(TokenData) Export
	Method = "Get"; Object = "Token"; RequestObj = "token";
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = StrReplace(GetStripeApiEndpoint() + GetStripeApiResourcePath(Object), "{TOKEN_ID}", TrimAll(TokenData));
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection         = ConnectionStructure.Result;
	
	// Open connection and request Stripe API.
	RequestStructure   = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,,,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Handle the execution result and return the object structure.
	Return GetRequestResult(RequestStructure, RequestObj);
	
EndFunction

#EndRegion

// Stripe: Customers
//------------------------------------------------------------------------------
// Customer objects allow you to perform recurring charges and track multiple
// charges that are associated with the same customer. The API allows you
// to create, delete, and update your customers. You can retrieve individual
// customers as well as a list of all your customers.
//------------------------------------------------------------------------------
#Region Stripe_Customers

// Creates a new customer object.
//
// Parameters:
//  CustomerData       - Structure - The data used for creating the customer (2 options),
//                                   either customer token or customer card is required.
//   account_balance   - Number    - (optional) An integer amount in cents that is the starting account
//                                   balance for your customer. A negative amount represents a credit that
//                                   will be used before attempting any charges to the customer's card;
//                                   a positive amount will be added to the next invoice.
//   card              - String    - (optional) A card token to attach to the customer.
//   -or               - Structure - (optionsl) The active customer card details.
//    number           - String    - The card number, as a string without any separators.
//    exp_month        - Number    - Two digit number representing the card's expiration month.
//    exp_year         - Number    - Two or four digit number representing the card's expiration year.
//    cvc              - Number    - (optional, highly recommended) Card security code.
//    name             - String    - (optional) Cardholder's full name.
//                                   Optional billing address:
//    address_line1    - String    - (optional).
//    address_line2    - String    - (optional).
//    address_city     - String    - (optional).
//    address_zip      - String    - (optional).
//    address_state    - String    - (optional).
//    address_country  - String    - (optional).
//   coupon            - String    - (optional) If you provide a coupon code, the customer will have
//                                   a discount applied on all recurring charges.
//                                   Charges you create through the API will not have the discount.
//                                   You can manage your coupons in the coupon section of your account.
//   description       - String    - (optional) An arbitrary string which you can attach to a customer object.
//                                   It is displayed alongside the customer in the web interface.
//   email             - String    - (optional) The customer's email address. It is displayed alongside
//                                   the customer in the web interface and can be useful for searching
//                                   and tracking.
//   plan              - String    - (optional) The identifier of the plan to subscribe the customer to.
//                                   If provided, the returned customer object has a 'subscription'
//                                   attribute describing the state of the customer's subscription.
//   quantity          - Number    - (optional) The quantity you'd like to apply to the subscription
//                                   you're creating. For example, if your plan is $10/user/month,
//                                   and your customer has 5 users, you could pass 5 as the quantity
//                                   to have the customer charged $50 (5 x $10) monthly. 
//   trial_end         - Datetime  - (optional) UTC integer timestamp representing the end of the trial
//                                   period the customer will get before being charged for the first time.
//                                   If set, trial_end will override the default trial period of the plan
//                                   the customer is being subscribed to.
//   -or               - String    - (optional) The special value 'now' can be provided to end
//                                   the customer's trial immediately.
//
// Returns:
//  ResultDescription  - Structure with following parameters:
//   Result            - Structure - The Customer object with the following keys and values:
//    object           - String    - "customer" - verifies type of returned object.
//    id               - String    - Customer ID in Stripe system.
//    livemode         - Boolean   - Account mode in which customer was created.
//    cards            - Structure - List of customer cards.
//     object          - String    - "list" - verifies type of returned object.
//     count           - Number    - The total number of items available.
//     data            - Array     - Array of "card" objects (see Stripe: Cards).
//     url             - String    - URL of cards for listing access.
//    created          - Datetime  - Timestamp of created customer record.
//    account_balance  - Number    - Current balance, if any, being stored on the customer’s account.
//                                   If negative, the customer has credit to apply to the next invoice.
//                                   If positive, the customer has an amount owed that will be added to
//                                   the next invoice. The balance does not refer to any unpaid invoices;
//                                   it solely takes into account amounts that have yet to be successfully
//                                   applied to any invoice.
//                                   This balance is only taken into account for recurring charges.
//    default_card     - String    - (optional) ID of default card for the customer.
//                     - Undefined - If default card is not specified.
//    delinquent       - Boolean   - Whether or not the latest charge for the customer’s latest
//                                   invoice has failed.
//    description      - String    - An arbitrary string displayed alongside the customer
//                                   in the web interface.
//    discount         - Structure - (optional) Structure describing the current discount
//                                   active on the customer, if there is one:
//     object          - String    - "discount" - verifies type of returned object.
//     coupon          - Structure - Structure describing the coupon, basing on the discount
//                                   is applied to the customer:
//      object         - String    - "coupon" - verifies type of returned object.
//      id             - String    - Coupon ID in Stripe system.
//      livemode       - Boolean   - Account mode in which coupon was created.
//      duration       - String    - Coupon duration. One of "forever", "once", and "repeating".
//                                   Describes how long a customer who applies this coupon
//                                   will get the discount.
//      amount_off     - Number    - Amount (in the currency specified) that will be taken off
//                                   the subtotal of any invoices for this customer.
//      currency       - String    - 3-letter ISO currency code. If amount_off has been set,
//                                   the currency of the amount to take off.
//      duration_in_months - Number- If duration is "repeating", the number of months the coupon
//                                   applies. Undefined - if coupon duration is forever or once.
//      max_redemptions - Number   - Maximum number of times this coupon can be redeemed
//                                   by a customer before it is no longer valid.
//      percent_off    - Number    - Percent that will be taken off the subtotal of any invoices
//                                   for this customer for the duration of the coupon. For example,
//                                   a coupon with percent_off of 50 will make a $100 invoice $50 instead.
//      redeem_by      - Datetime  - Date after which the coupon can no longer be redeemed.
//      times_redeemed - Number    - Number of times this coupon has been applied to a customer.
//     customer        - String    - Customer ID having this discount applied.
//     start           - Datetime  - Date that the coupon was applied.
//     end             - Datetime  - If the coupon has a duration of once or repeating,
//                                   the date that this discount will end.
//                     - Undefined - If the coupon used has a forever duration.
//    email            - String    - The customer's email address. It is displayed alongside
//                                   the customer in the web interface.
//    subscription     - Structure - (optional) Structure describing the current subscription
//                                   on the customer, if there is one. If the customer
//                                   has no current subscription, this will be Undefined.
//     object          - String    - "subscription" - verifies type of returned object.
//     id              - String    - Subscription ID in Stripe system.
//     cancel_at_period_end - Boolean - If the subscription has been canceled with the
//                                   at_period_end flag set to true, cancel_at_period_end
//                                   on the subscription will be true. You can use this attribute
//                                   to determine whether a subscription that has a status of active
//                                   is scheduled to be canceled at the end of the current period.
//     customer        - String    - Customer ID having this subscription applied.
//     plan            - Structure - Structure describing the plan the customer is subscribed to.
//      object         - String    - "plan" - verifies type of returned object.
//      id             - String    - Plan ID in Stripe system.
//      livemode       - Boolean   - Account mode in which plan was created.
//      amount         - Number    - The amount in cents to be charged on the interval specified.
//      currency       - String    - 3-letter ISO currency code. Currency in which subscription
//                                   will be charged.
//      interval       - String    - Interval string: One of "week", "month" or "year".
//                                   The frequency with which a subscription should be billed.
//      interval_count - Number    - Quantity of billing inetervals for the amount to be applied.
//      name           - String    - Display name of the plan.
//      trial_period_days - Number - Number of trial period days granted when subscribing a customer
//                                   to this plan. Undefined if the plan has no trial period.
//     quantity        - Number    - Number of times this subscription has been applied to a customer.
//     start           - Datetime  - Date the subscription started.
//     status          - String    - Possible values are "trialing", "active", "past_due", "canceled",
//                                   or "unpaid". A subscription still in its trial period is trialing
//                                   and moves to active when the trial period is over. When payment
//                                   to renew the subscription fails, the subscription becomes past_due.
//                                   After Stripe has exhausted all payment retry attempts,
//                                   the subscription ends up with a status of either canceled or unpaid
//                                   depending on your retry settings. Note that when a subscription has
//                                   a status of unpaid, any future invoices will not be attempted until
//                                   the customer’s card details are updated.
//     canceled_at     - Datetime  - If the subscription has been canceled, the date of that cancellation.
//                                   If the subscription was canceled with cancel_at_period_end, canceled_at
//                                   will still reflect the date of the initial cancellation request,
//                                   not the end of the subscription period when the subscription is
//                                   automatically moved to a canceled state.
//     current_period_end - Datetime - End of the current period that the subscription has been invoiced for.
//                                   At the end of this period, a new invoice will be created.
//     current_period_start - Datetime - Start of the current period that the subscription has been invoiced for.
//     ended_at        - Datetime  - If the subscription has ended (either because it was canceled or because
//                                   the customer was switched to a subscription to a new plan),
//                                   the date the subscription ended
//     trial_end       - Datetime  - If the subscription has a trial, the end of that trial.
//     trial_start     - Datetime  - If the subscription has a trial, the beginning of that trial.
//   - or              - Undefined - If failed.
//   Description       - String    - Error description if function failed.
//   AdditionalData    - Structure - If failed, contains source data, returned by the Stripe server.
//                                   For example, if customer was deleted, then other object is returned.
//    Code             - Number    - Server result code (if available).
//    Result           - Structure - If server returned object which wasn't expected.
//                     - String    - If server returned string what we didn't expect at all.
//   - or              - Undefined - If succeeded.
//
Function CreateCustomer(CustomerData) Export
	Method = "Post"; Object = "Customers"; RequestObj = "customer";
	
	// Define and fill input data for Stripe API method.
	If CustomerData.Property("customer") Then
		// Fill customer properties.
		InputParameters = New Structure("card, coupon, email, description, account_balance, plan, trial_end, quantity");
		FillPropertyValues(InputParameters, CustomerData.customer);
		
		// Fill customer card properties.
		If CustomerData.Property("card") Then
			InputParameters.Insert("card", New Structure("number, exp_month, exp_year, cvc, name, address_line1, address_line2, address_city, address_zip, address_state, address_country"));
			FillPropertyValues(InputParameters.card, CustomerData.card);
		EndIf;
		
	Else // The input parameters are not specified.
		Return ResultDescription(Undefined, NStr("en = 'Stripe API: Input parameters are not properly defined.'"));
	EndIf;
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = GetStripeApiEndpoint() + GetStripeApiResourcePath(Object);
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection         = ConnectionStructure.Result;
	
	// Convert sending data for POST request.
	InputData          = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	// Open connection and request Stripe API.
	RequestStructure   = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,, InputData,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Handle the execution result and return the object structure.
	Return GetRequestResult(RequestStructure, RequestObj);
	
EndFunction

// Retrieves the details of an existing customer.
//
// Parameters:
//  CustomerData       - String    - ID of existing customer in Stripe system.
//
// Returns:
//  ResultDescription  - Structure with following parameters:
//   Result            - Structure - The Customer object with the following keys and values:
//    object           - String    - "customer" - verifies type of returned object.
//    id               - String    - Customer ID in Stripe system.
//    livemode         - Boolean   - Account mode in which customer was created.
//    cards            - Structure - List of customer cards.
//     object          - String    - "list" - verifies type of returned object.
//     count           - Number    - The total number of items available.
//     data            - Array     - Array of "card" objects (see Stripe: Cards).
//     url             - String    - URL of cards for listing access.
//    created          - Datetime  - Timestamp of created customer record.
//    account_balance  - Number    - Current balance, if any, being stored on the customer’s account.
//                                   If negative, the customer has credit to apply to the next invoice.
//                                   If positive, the customer has an amount owed that will be added to
//                                   the next invoice. The balance does not refer to any unpaid invoices;
//                                   it solely takes into account amounts that have yet to be successfully
//                                   applied to any invoice.
//                                   This balance is only taken into account for recurring charges.
//    default_card     - String    - (optional) ID of default card for the customer.
//                     - Undefined - If default card is not specified.
//    delinquent       - Boolean   - Whether or not the latest charge for the customer’s latest
//                                   invoice has failed.
//    description      - String    - An arbitrary string displayed alongside the customer
//                                   in the web interface.
//    discount         - Structure - (optional) Structure describing the current discount
//                                   active on the customer, if there is one:
//     object          - String    - "discount" - verifies type of returned object.
//     coupon          - Structure - Structure describing the coupon, basing on the discount
//                                   is applied to the customer:
//      object         - String    - "coupon" - verifies type of returned object.
//      id             - String    - Coupon ID in Stripe system.
//      livemode       - Boolean   - Account mode in which coupon was created.
//      duration       - String    - Coupon duration. One of "forever", "once", and "repeating".
//                                   Describes how long a customer who applies this coupon
//                                   will get the discount.
//      amount_off     - Number    - Amount (in the currency specified) that will be taken off
//                                   the subtotal of any invoices for this customer.
//      currency       - String    - 3-letter ISO currency code. If amount_off has been set,
//                                   the currency of the amount to take off.
//      duration_in_months - Number- If duration is "repeating", the number of months the coupon
//                                   applies. Undefined - if coupon duration is forever or once.
//      max_redemptions - Number   - Maximum number of times this coupon can be redeemed
//                                   by a customer before it is no longer valid.
//      percent_off    - Number    - Percent that will be taken off the subtotal of any invoices
//                                   for this customer for the duration of the coupon. For example,
//                                   a coupon with percent_off of 50 will make a $100 invoice $50 instead.
//      redeem_by      - Datetime  - Date after which the coupon can no longer be redeemed.
//      times_redeemed - Number    - Number of times this coupon has been applied to a customer.
//     customer        - String    - Customer ID having this discount applied.
//     start           - Datetime  - Date that the coupon was applied.
//     end             - Datetime  - If the coupon has a duration of once or repeating,
//                                   the date that this discount will end.
//                     - Undefined - If the coupon used has a forever duration.
//    email            - String    - The customer's email address. It is displayed alongside
//                                   the customer in the web interface.
//    subscription     - Structure - (optional) Structure describing the current subscription
//                                   on the customer, if there is one. If the customer
//                                   has no current subscription, this will be Undefined.
//     object          - String    - "subscription" - verifies type of returned object.
//     id              - String    - Subscription ID in Stripe system.
//     cancel_at_period_end - Boolean - If the subscription has been canceled with the
//                                   at_period_end flag set to true, cancel_at_period_end
//                                   on the subscription will be true. You can use this attribute
//                                   to determine whether a subscription that has a status of active
//                                   is scheduled to be canceled at the end of the current period.
//     customer        - String    - Customer ID having this subscription applied.
//     plan            - Structure - Structure describing the plan the customer is subscribed to.
//      object         - String    - "plan" - verifies type of returned object.
//      id             - String    - Plan ID in Stripe system.
//      livemode       - Boolean   - Account mode in which plan was created.
//      amount         - Number    - The amount in cents to be charged on the interval specified.
//      currency       - String    - 3-letter ISO currency code. Currency in which subscription
//                                   will be charged.
//      interval       - String    - Interval string: One of "week", "month" or "year".
//                                   The frequency with which a subscription should be billed.
//      interval_count - Number    - Quantity of billing inetervals for the amount to be applied.
//      name           - String    - Display name of the plan.
//      trial_period_days - Number - Number of trial period days granted when subscribing a customer
//                                   to this plan. Undefined if the plan has no trial period.
//     quantity        - Number    - Number of times this subscription has been applied to a customer.
//     start           - Datetime  - Date the subscription started.
//     status          - String    - Possible values are "trialing", "active", "past_due", "canceled",
//                                   or "unpaid". A subscription still in its trial period is trialing
//                                   and moves to active when the trial period is over. When payment
//                                   to renew the subscription fails, the subscription becomes past_due.
//                                   After Stripe has exhausted all payment retry attempts,
//                                   the subscription ends up with a status of either canceled or unpaid
//                                   depending on your retry settings. Note that when a subscription has
//                                   a status of unpaid, any future invoices will not be attempted until
//                                   the customer’s card details are updated.
//     canceled_at     - Datetime  - If the subscription has been canceled, the date of that cancellation.
//                                   If the subscription was canceled with cancel_at_period_end, canceled_at
//                                   will still reflect the date of the initial cancellation request,
//                                   not the end of the subscription period when the subscription is
//                                   automatically moved to a canceled state.
//     current_period_end - Datetime - End of the current period that the subscription has been invoiced for.
//                                   At the end of this period, a new invoice will be created.
//     current_period_start - Datetime - Start of the current period that the subscription has been invoiced for.
//     ended_at        - Datetime  - If the subscription has ended (either because it was canceled or because
//                                   the customer was switched to a subscription to a new plan),
//                                   the date the subscription ended
//     trial_end       - Datetime  - If the subscription has a trial, the end of that trial.
//     trial_start     - Datetime  - If the subscription has a trial, the beginning of that trial.
//   - or              - Undefined - If failed.
//   Description       - String    - Error description if function failed.
//   AdditionalData    - Structure - If failed, contains source data, returned by the Stripe server.
//                                   For example, if customer was deleted, then other object is returned.
//    Code             - Number    - Server result code (if available).
//    Result           - Structure - If server returned object which wasn't expected.
//                     - String    - If server returned string what we didn't expect at all.
//   - or              - Undefined - If succeeded.
//
Function RetrieveCustomer(CustomerData) Export
	Method = "Get"; Object = "Customer"; RequestObj = "customer";
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = StrReplace(GetStripeApiEndpoint() + GetStripeApiResourcePath(Object), "{CUSTOMER_ID}", TrimAll(CustomerData));
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection         = ConnectionStructure.Result;
	
	// Open connection and request Stripe API.
	RequestStructure   = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,,,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Handle the execution result and return the object structure.
	Return GetRequestResult(RequestStructure, RequestObj);
	
EndFunction

Function UpdateCustomer() Export
	
EndFunction

// Permanently deletes a customer.
// It cannot be undone.
//
// Parameters:
//  CustomerData       - String    - The identifier of the customer to be deleted.
//
// Returns:
//  ResultDescription  - Structure with following parameters:
//   Result            - Structure - The Customer object with the following keys and values:
//    deleted          - Boolean   - "true" - confirms deleting the object.
//    id               - String    - The identifier of the deleted customer.
//   - or              - Undefined - If failed.
//   Description       - String    - Error description if function failed.
//   AdditionalData    - Structure - If failed, contains source data, returned by the Stripe server.
//    Code             - Number    - Server result code (if available).
//    Result           - Structure - If server returned object which wasn't expected.
//                     - String    - If server returned string what we didn't expect at all.
//   - or              - Undefined - If succeeded.
//
Function DeleteCustomer(CustomerData) Export
	Method = "Delete"; Object = "Customer";
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = StrReplace(GetStripeApiEndpoint() + GetStripeApiResourcePath(Object), "{CUSTOMER_ID}", TrimAll(CustomerData));
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection         = ConnectionStructure.Result;
	
	// Open connection and request Stripe API.
	RequestStructure   = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,,,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Handle the execution result and return the object structure.
	Return GetRequestResult(RequestStructure, Undefined);
	
EndFunction

Function ListCustomers() Export
	
EndFunction

#EndRegion

//------------------------------------------------------------------------------
// To be reimplemented.

// Implementation of Stripe "Creating a new charge (charging a credit card)" interface.
Function PostCharges(ChargeData) Export
	Method = "Post"; Object = "Charges"; Charge = Undefined;
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = GetStripeApiEndpoint() + GetStripeApiResourcePath(Object);
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection         = ConnectionStructure.Result;
	
	// Define and fill input data for Stripe API method.
	InputParameters    = New Structure("amount, currency, customer, card, description, capture, application_fee");
	FillPropertyValues(InputParameters, ChargeData);
	
	// Convert sending data for POST request.
	InputData          = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	// Open connection and request Stripe API.
	RequestStructure   = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,,InputData,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Convert resulting data to structure object.
	If TypeOf(RequestStructure.Result) = Type("String") Then
		Charge = InternetConnectionClientServer.DecodeJSON(RequestStructure.Result, New Structure("UseLocalDate", False));
	EndIf;
	
	// Return decoded object.
	Return ResultDescription(Charge);
	
EndFunction

// Implementation of Stripe "Refunding a Charge" interface.
Function PostChargeRefund(ChargeID, ChargeRefundData) Export
	Method = "Post"; Object = "ChargeRefund"; ChargeRefund = Undefined;
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = GetStripeApiEndpoint() + StrReplace(GetStripeApiResourcePath(Object), "{CHARGE_ID}", ChargeID);
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection         = ConnectionStructure.Result;
	
	// Define and fill input data for Stripe API method.
	InputParameters    = New Structure("amount");
	FillPropertyValues(InputParameters, ChargeRefundData);
	
	// Convert sending data for POST request.
	InputData          = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	// Open connection and request Stripe API.
	RequestStructure   = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,,InputData,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Convert resulting data to structure object.
	If TypeOf(RequestStructure.Result) = Type("String") Then
		ChargeRefund = InternetConnectionClientServer.DecodeJSON(RequestStructure.Result, New Structure("UseLocalDate", False));
	EndIf;
	
	// Return decoded object.
	Return ResultDescription(ChargeRefund);
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

// Stripe: API constants
//------------------------------------------------------------------------------
// Standard settings for establishing the connection to Stripe Servers.
//------------------------------------------------------------------------------
#Region Stripe_Constants

// Returns Stripe API endpoint.
//
// Returns:
//  String - Web address of Stripe API server end point.
//
Function GetStripeApiEndpoint()
	
	// Primary Stripe API endpoint for serving client calls.
	Return "https://api.stripe.com";
	
EndFunction

// Returns pathes to Stripe API resources.
//
// Parameters:
//  ResourceName - String - Type of resource, which path is requested.
//
// Returns:
//  String - Path to requested type of resource of Stripe API.
//
Function GetStripeApiResourcePath(ResourceName)
	
	// Case by resource names and their pathes.
	If    ResourceName = "Account" Then
		Return "/v1/account";
		
	ElsIf ResourceName = "Charges" Then
		Return "/v1/charges";
		
	ElsIf ResourceName = "Charge" Then
		Return "/v1/charges/{CHARGE_ID}";
		
	ElsIf ResourceName = "ChargeRefund" Then
		Return "/v1/charges/{CHARGE_ID}/refund";
		
	ElsIf ResourceName = "Coupons" Then
		Return "/v1/coupons";
		
	ElsIf ResourceName = "Coupon" Then
		Return "/v1/coupons/{COUPON_ID}";
		
	ElsIf ResourceName = "Customers" Then
		Return "/v1/customers";
		
	ElsIf ResourceName = "Customer" Then
		Return "/v1/customers/{CUSTOMER_ID}";
		
	ElsIf ResourceName = "Subscriptions" Then
		Return "/v1/customers/{CUSTOMER_ID}/subscription";
		
	ElsIf ResourceName = "Invoices" Then
		Return "/v1/invoices";
		
	ElsIf ResourceName = "Invoice" Then
		Return "/v1/invoices/{INVOICE_ID}";
		
	ElsIf ResourceName = "InvoiceLines" Then
		Return "/v1/invoices/{INVOICE_ID}/lines";
		
	ElsIf ResourceName = "InvoiceItems" Then
		Return "/v1/invoiceitems";
		
	ElsIf ResourceName = "InvoiceItem" Then
		Return "/v1/invoiceitems/{INVOICEITEM_ID}";
		
	ElsIf ResourceName = "Plans" Then
		Return "/v1/plans";
		
	ElsIf ResourceName = "Plan" Then
		Return "/v1/plans/{PLAN_ID}";
		
	ElsIf ResourceName = "Tokens" Then
		Return "/v1/tokens";
		
	ElsIf ResourceName = "Token" Then
		Return "/v1/tokens/{TOKEN_ID}";
		
	ElsIf ResourceName = "Events" Then
		Return "/v1/events";
		
	ElsIf ResourceName = "Event" Then
		Return "/v1/events/{EVENT_ID}";
		
	Else
		Return "";
	EndIf;
	
EndFunction

#EndRegion

// Stripe: Result description
//------------------------------------------------------------------------------
// Functions are used to simplify error codes handling
// and formatting of final request result.
//------------------------------------------------------------------------------
#Region Stripe_Result_Description

// Implementation of Stripe error object, returns error description.
//
// Parameters:
//  ErrorCode - Number - HTTP server status (response) code:
//                       http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html.
//  ErrorJSON - String - JSON object, containing error description.
//   type     - String - The type of error returned:
//                       "invalid_request_error", "api_error", or "card_error".
//   message  - String - A human-readable message giving more details about the error.
//   code     - String - (optional) For card errors, a short string describing
//                                  the kind of card error that occurred.
//   param    - String - (optional) The parameter the error relates to
//                                  if the error is parameter-specific.
//
// Returns:
//  ErrorDescription - A human-readable error description displaying to the user.
//
Function GetErrorDescription(ErrorCode, ErrorJSON = "")
	Var error, type, message, code, param, id, deleted;
	
	// Define error description basing on error code.
	If ErrorCode = 200 Then
		// Everything worked as expected.
		ErrorDescription = NStr("en = 'OK'");
		
	ElsIf ErrorCode = 400 Then
		// Missing a required parameter.
		ErrorDescription = NStr("en = 'Bad request'");
		
	ElsIf ErrorCode = 401 Then
		// No valid API key provided.
		ErrorDescription = NStr("en = 'Unauthorized'");
		
	ElsIf ErrorCode = 402 Then
		// Parameters were valid but request failed.
		ErrorDescription = NStr("en = 'Request failed'");
		
	ElsIf ErrorCode = 404 Then
		// The requested item doesn't exist.
		ErrorDescription = NStr("en = 'Not Found'");
		
	ElsIf ErrorCode = 500
	   Or ErrorCode = 502
	   Or ErrorCode = 503
	   Or ErrorCode = 504
	Then
		// Something went wrong on Stripe's end.
		ErrorDescription = NStr("en = 'Server error'");
	Else
		// Unexpected error ocured.
		ErrorDescription = NStr("en = 'Unknown error'");
	EndIf;
		
	// Decode the error structure.
	ErrorStruct = InternetConnectionClientServer.DecodeJSON(ErrorJSON, New Structure("UseLocalDate", False));
	If TypeOf(ErrorStruct) = Type("Structure") Then
		
		// Check error.
		If ErrorStruct.Property("error", error) Then
			
			// Check error type.
			If error.Property("type", type) Then
				
				// Define error type description.
				If type = "invalid_request_error" Then
					// Invalid request errors arise when your request has invalid parameters.
					ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Invalid request error: %1'"), ErrorDescription);
					
				ElsIf type = "api_error" Then
					// API errors cover any other type of problem (e.g. a temporary problem with Stripe's servers) and should turn up only very infrequently.
					ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Stripe API error: %1'"), ErrorDescription);
				
				ElsIf type = "card_error" Then
					// Card errors are the most common type of error you should expect to handle.
					// They result when the user enters a card that can't be charged for some reason.
					If error.Property("code", code) Then
						If    code = "incorrect_number"     Then CodeDescription = "The card number is incorrect.";
						ElsIf code = "invalid_number"       Then CodeDescription = "The card number is not a valid credit card number.";
						ElsIf code = "invalid_expiry_month" Then CodeDescription = "The card's expiration month is invalid.";
						ElsIf code = "invalid_expiry_year"  Then CodeDescription = "The card's expiration year is invalid.";
						ElsIf code = "invalid_cvc"          Then CodeDescription = "The card's security code is invalid.";
						ElsIf code = "expired_card"         Then CodeDescription = "The card has expired.";
						ElsIf code = "incorrect_cvc"        Then CodeDescription = "The card's security code is incorrect.";
						ElsIf code = "incorrect_zip"        Then CodeDescription = "The card's zip code failed validation.";
						ElsIf code = "card_declined"        Then CodeDescription = "The card was declined.";
						ElsIf code = "missing"              Then CodeDescription = "There is no card on a customer that is being charged.";
						ElsIf code = "processing_error"     Then CodeDescription = "An error occurred while processing the card.";
						Else                                     CodeDescription = ErrorDescription; // Default error code description.
						EndIf;
					EndIf;
					
					// Add extended card error description.
					ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Card error: %1'"), CodeDescription);
				EndIf;
			EndIf;
			
			// Add a human-readable description.
			If error.Property("message", message) Then
				ErrorDescription = ErrorDescription + Chars.LF + message;
			EndIf;
			
		ElsIf ErrorStruct.Property("deleted", deleted) and (deleted = True) Then
			// The requested object is already deleted and operation can not be completed.
			ErrorDescription = NStr("en = 'Invalid request error: Not Found.
			                              |Requested record deleted%1.'");
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(
			                   ErrorDescription, ?(ErrorStruct.Property("id", id), ": " + id, ""));
			
			// Reset the source code 200 OK.
			ErrorCode = 206; // Partial content.
		EndIf;
	EndIf;
	
	// Return error description.
	Return ErrorDescription;
	
EndFunction

// The function implements handling of request result including error decoding
// and messgae processing.
//
// Parameters:
//  RequestStructure - Structure - Structure with the following key and value:
//   Result                      - String - contents of requested data.
//                               - Undefined - if request failed.
//   Description                 - String - if succeded can take on the following values:
//                                "String" - data returned directly in Result parameter.
//                                 or contain an error message in case of failure.
//  RequestedObjectType - String - Description of Stripe object expected.
//
// Returns:
//  ResultDescription - Structure with following parameters:
//   Result           - Structure - expected object,
//                    - Undefined - if request was failed.
//   Description      - String    - user message, containing error description.
//
Function GetRequestResult(RequestStructure, RequestedObjectType = Undefined)
	var objectType, RequestedObject;
	
	// Check additional properties.
	AdditionalData      = Undefined;
	If RequestStructure.Property("AdditionalData", AdditionalData) Then
		// There is the result code of operation.
		StatusCode = AdditionalData.StatusCode;
		
		// Check response code.
		If (StatusCode = 200) And (TypeOf(RequestStructure.Result) = Type("String")) And Left(TrimAll(RequestStructure.Result), 1) = "{" Then
			// Everything worked as expected.
			RequestedObject = InternetConnectionClientServer.DecodeJSON(RequestStructure.Result, New Structure("UseLocalDate", False));
			// Check returned object type.
			If (RequestedObjectType = Undefined) // Do not check object type.
			Or (RequestedObject.Property("object", objectType) And objectType = RequestedObjectType) Then // Object type match.
				Return ResultDescription(RequestedObject);
			EndIf;
		EndIf;
		
		// An error is occured.
		Return ResultDescription(Undefined, GetErrorDescription(StatusCode, RequestStructure.Result), New Structure("Code, Result", StatusCode, RequestedObject));
		
	Else
		// No additional error description/code available.
		
		// Check returning data is JSON object.
		If (TypeOf(RequestStructure.Result) = Type("String")) And Left(TrimAll(RequestStructure.Result), 1) = "{" Then
			// Everything worked as expected.
			RequestedObject = InternetConnectionClientServer.DecodeJSON(RequestStructure.Result, New Structure("UseLocalDate", False));
			// Check returned object type.
			If (RequestedObjectType = Undefined) // Do not check object type.
			Or (RequestedObject.Property("object", objectType) And objectType = RequestedObjectType) Then // Object type match.
				Return ResultDescription(RequestedObject);
			EndIf;
		EndIf;
		
		// An error is occured.
		Return ResultDescription(Undefined, RequestStructure.Description, New Structure("Code, Result", Undefined, RequestedObject));
	EndIf;
	
EndFunction

// Returns the structure with passed parameters.
//
// Parameters:
//  Result             - Arbitrary - Returned function value.
//  Description        - String    - Success string or error description.
//  AdditionalData     - Arbitrary - Additional returning parameters.
//
// Returns:
//  Structure with the passed parameters:
//   Result            - Arbitrary.
//   Description       - String.
//   AdditionalData    - Arbitrary.
//
Function ResultDescription(Result, Description = "", AdditionalData = Undefined)
	
	// Return parameters converted to the structure
	Return New Structure("Result, Description, AdditionalData",
	                      Result, Description, AdditionalData);
	
EndFunction

#EndRegion

#EndRegion
