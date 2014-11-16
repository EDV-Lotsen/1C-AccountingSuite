
Function StripeAuth(access_token, spk, livemode)
	
	Constants.secret_temp.Set(access_token);
	Constants.publishable_temp.Set(spk);
	//Constants.access_token.Set(spk);
	//Constants.spk.Set(spk);
	
	Result = ApiStripeProtected.EncodeSecretKey(access_token);
	
	Constants.spk.Set(Result[0]);
	Constants.spk2.Set(Result[1]);
	Constants.spk3.Set(Result[2]);
	
	StripeEmail = ApiStripeRequestorInterface.RetrieveAccount();
	Constants.StripeUser.Set(StripeEmail.Result.Email);
	
	Constants.stripe_display_name.Set(StripeEmail.Result.display_name);
	If StripeEmail.Result.charge_enabled = True Then
		Constants.stripe_live_status.Set("Live");
	Else
		Constants.stripe_live_status.Set("Not Live");
	EndIf;

EndFunction

Function StripeToken(token, company)
	
	// Find company, which the card belongs to.
	CompanyRef = Catalogs.Companies.FindByCode(company);	
	CompanyDescription = CompanyRef.Description;
	
	CustomerData = New Structure("customer", New Structure("description, card", CompanyDescription, token));
	PostResult   = ApiStripeRequestorInterface.CreateCustomer(CustomerData);

	// Save Stripe ID into object.
	CompanyObj = CompanyRef.GetObject();
	CompanyObj.StripeToken = token;
	CompanyObj.StripeID = PostResult.Result.id;
	//CompanyObj.last4 = PostResult.Result.active_card.last4;
	//CompanyObj.exp_month = PostResult.Result.active_card.exp_month;
	//CompanyObj.exp_year = PostResult.Result.active_card.exp_year;
	//CompanyObj.type = PostResult.Result.active_card.type;
	
	CompanyObj.last4 = PostResult.Result.cards.data[0].last4;
	CompanyObj.exp_month = PostResult.Result.cards.data[0].exp_month;
	CompanyObj.exp_year = PostResult.Result.cards.data[0].exp_year;
	CompanyObj.type = PostResult.Result.cards.data[0].type;

	CompanyObj.Write();
										
	// Request customer creating.
	
	
EndFunction
