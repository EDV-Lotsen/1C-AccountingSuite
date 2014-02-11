
////////////////////////////////////////////////////////////////////////////////
// Stripe API: Settings, overridable
//------------------------------------------------------------------------------
// Available on:
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

// Returns Stripe API authorization data.
//
// The function can be overriden in particular configurations
// depending on the storage used for holding key data.
//
// Returns:
//  FixedArray - Encoded key data for authorization:
//  - [0] PublicHeader - String - Public header of saved key & secret body length,
//  - [1] HUID - UUID  - Encoded key data,
//  - [2] LUID - UUID  - Encoded key data,
//  Undefined  - if failed.
//
Function GetStripeAPIAuthorizationKey() Export
	
	// Request user authorization key.
	AuthorizationKey = CommonUseServerCall.GetValueByDefault("StripeAPIAuthorizationKey");
	
#Region AccountingSuite_Override
	
	// Requesting authorization key from default account.
	If AuthorizationKey = Undefined Then
		
		// Request key data from constants.
		AuthorizationConstSet = Constants.CreateSet("spk, spk2, spk3");
		AuthorizationConstSet.Read();
		If Not IsBlankString(AuthorizationConstSet.spk)
		   And ValueIsFilled(AuthorizationConstSet.spk2)
		   And ValueIsFilled(AuthorizationConstSet.spk3)
		Then
			// Fill in the authorization key data.
			AuthorizationKeyData    = New Array(3);
			AuthorizationKeyData[0] = AuthorizationConstSet.spk;
			AuthorizationKeyData[1] = AuthorizationConstSet.spk2;
			AuthorizationKeyData[2] = AuthorizationConstSet.spk3;
			AuthorizationKey        = New FixedArray(AuthorizationKeyData);
			
			// Save the data for the future use.
			SetStripeAPIAuthorizationKey(AuthorizationKey);
		EndIf;
	EndIf;
	
#EndRegion
	
	Return AuthorizationKey;
	
EndFunction

// Assign Stripe API authorization data.
//
// The function can be overriden in particular configurations
// depending on the storage used for holding key data.
//
// Parameters:
//  AuthorizationKey  - FixedArray - Encoded key data for authorization:
//  - [0] PublicHeader - String     - Public header of saved key & secret body length,
//  - [1] HUID         - UUID       - Encoded key data,
//  - [2] LUID         - UUID       - Encoded key data.
//
Procedure SetStripeAPIAuthorizationKey(AuthorizationKey) Export
	
	// Check incoming value.
	If AuthorizationKey = Undefined Then
		// Clear the authorization data.
		CommonUseServerCall.SetValueAsDefault("StripeAPIAuthorizationKey", Undefined);
		
	ElsIf TypeOf(AuthorizationKey)    = Type("FixedArray")
	  And AuthorizationKey.Count()    = 3
	  And TypeOf(AuthorizationKey[0]) = Type("String")
	  And TypeOf(AuthorizationKey[1]) = Type("UUID")
	  And TypeOf(AuthorizationKey[2]) = Type("UUID")
	Then
		// Set passed value by default.
		CommonUseServerCall.SetValueAsDefault("StripeAPIAuthorizationKey", AuthorizationKey);
		
	Else
		// Wrong data passed.
		Raise NStr("en = 'Wrong authorization key data passed.'");
	EndIf;
	
EndProcedure

#EndRegion
