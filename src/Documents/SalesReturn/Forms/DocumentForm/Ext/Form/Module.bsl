&AtClient
Var SalesTaxRateInactive, AgenciesRatesInactive;//Cache for storing inactive rates previously used in the document

&AtClient
// ProductOnChange UI event handler.
// The procedure clears quantities, line total, and taxable amount in the line item,
// selects price for the new product from the price-list, divides the price by the document
// exchange rate, selects a default unit of measure for the product, and
// selects a product's sales tax type.
// 
Procedure LineItemsProductOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.ProductDescription = CommonUse.GetAttributeValue(TabularPartRow.Product, "Description");
	TabularPartRow.Quantity = 0;
	TabularPartRow.LineTotal = 0;
	TabularPartRow.Price = 0;
	//TabularPartRow.TaxableAmount = 0;
	//TabularPartRow.VAT = 0;
	
	Price = GeneralFunctions.RetailPrice(CurrentDate(), TabularPartRow.Product, Object.Company);
	TabularPartRow.Price = Price / Object.ExchangeRate;
		
	TabularPartRow.Taxable = CommonUse.GetAttributeValue(TabularPartRow.Product, "Taxable");
	//TabularPartRow.VATCode = CommonUse.GetAttributeValue(TabularPartRow.Product, "SalesVATCode");
	
	RecalculateTotals();
	
EndProcedure

&AtClient
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalculateTotals()
	
	RecalculateTotalsNoContext(Object);
	//return;
	//
	//Object.LineSubtotal = Object.LineItems.Total("LineTotal");
	//Object.SubTotal = Object.LineItems.Total("LineTotal"); // + Object.DiscountRC;
	//
	//// Recalculate the discount and it's percent.
	//Object.Discount     = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
	//If Object.Discount < -Object.LineSubtotal Then
	//	Object.Discount = -Object.LineSubtotal;
	//EndIf;
	//If Object.LineSubtotal > 0 Then
	//	Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	//EndIf;

	////Calculate sales tax
	//TaxableSubtotal = 0;
	//For Each LineItem In Object.LineItems Do
	//	TaxableSubtotal = TaxableSubtotal + ?(LineItem.Taxable, LineItem.LineTotal, 0);
	//EndDo;
	//If Object.DiscountIsTaxable Then
	//	Object.TaxableSubtotal = TaxableSubtotal;
	//Else
	//	Object.TaxableSubtotal = TaxableSubtotal + Round(-1 * TaxableSubtotal * Object.DiscountPercent/100, 2);
	//EndIf;
	//CurrentAgenciesRates = Undefined;
	//If Object.SalesTaxAcrossAgencies.Count() > 0 Then
	//	CurrentAgenciesRates = New Array();
	//	For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
	//		CurrentAgenciesRates.Add(New Structure("Agency, Rate", AgencyRate.Agency, AgencyRate.Rate));
	//	EndDo;
	//EndIf;
	//SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
	//Object.SalesTaxAcrossAgencies.Clear();
	//For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
	//	NewRow = Object.SalesTaxAcrossAgencies.Add();
	//	FillPropertyValues(NewRow, STAcrossAgencies);
	//EndDo;
	//Object.SalesTaxRC = Object.SalesTaxAcrossAgencies.Total("Amount");

	//// Calculate the rest of the totals.
	//Object.SubTotal         = Object.LineSubtotal + Object.Discount;
	//Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTaxRC;
	//Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);

EndProcedure

&AtClientAtServerNoContext
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalculateTotalsNoContext(Object)
	
	Object.LineSubtotal = Object.LineItems.Total("LineTotal");
	Object.SubTotal = Object.LineItems.Total("LineTotal"); // + Object.DiscountRC;
	
	// Recalculate the discount and it's percent.
	Object.Discount     = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = -Object.LineSubtotal;
	EndIf;
	If Object.LineSubtotal > 0 Then
		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	EndIf;

	//Calculate sales tax
	TaxableSubtotal = 0;
	For Each LineItem In Object.LineItems Do
		TaxableSubtotal = TaxableSubtotal + ?(LineItem.Taxable, LineItem.LineTotal, 0);
	EndDo;
	If Object.DiscountIsTaxable Then
		Object.TaxableSubtotal = TaxableSubtotal;
	Else
		Object.TaxableSubtotal = TaxableSubtotal + Round(-1 * TaxableSubtotal * Object.DiscountPercent/100, 2);
	EndIf;
	CurrentAgenciesRates = Undefined;
	If Object.SalesTaxAcrossAgencies.Count() > 0 Then
		CurrentAgenciesRates = New Array();
		For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
			CurrentAgenciesRates.Add(New Structure("Agency, Rate", AgencyRate.Agency, AgencyRate.Rate));
		EndDo;
	EndIf;
	
#If AtClient Then
	SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);	
#Else		
	SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
#EndIf

	Object.SalesTaxAcrossAgencies.Clear();
	For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
		NewRow = Object.SalesTaxAcrossAgencies.Add();
		FillPropertyValues(NewRow, STAcrossAgencies);
	EndDo;
	Object.SalesTaxRC = Object.SalesTaxAcrossAgencies.Total("Amount");

	// Calculate the rest of the totals.
	Object.SubTotal         = Object.LineSubtotal + Object.Discount;
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTaxRC;
	Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);

EndProcedure

&AtClient
// CustomerOnChange UI event handler.
// Selects default currency for the customer, determines an exchange rate, and
// recalculates the document's sales tax and total amounts.
//  
Procedure CompanyOnChange(Item)
	
	//Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ARAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	
	//RecalcSalesTax();
	If Not ValueIsFilled(Object.ParentDocument) Then
		SalesTaxRate = SalesTax.GetDefaultSalesTaxRate(Object.Company);
		SetSalesTaxRate(SalesTaxRate);
	EndIf;
	
	RecalculateTotals();
	EmailSet();
	
EndProcedure

&AtClient
// PriceOnChange UI event handler.
// Calculates line total by multiplying a price by a quantity in either the selected
// unit of measure (U/M) or in the base U/M, and recalculates the line's taxable amount and total.
//  
Procedure LineItemsPriceOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	
	//TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
	
	//RecalcTaxableAmount();
	//RecalcSalesTax();
	//RecalculateTotals();
	RecalculateTotalsNoContext(Object);

EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's
// sales tax and total.
//
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	//RecalcSalesTax();
	RecalculateTotals();
	
EndProcedure

&AtClient
// CurrencyOnChange UI event handler.
// Determines an exchange rate for the new currency, and recalculates the document's
// sales tax and total.
//
Procedure CurrencyOnChange(Item)
	
	DisplayCurrencySimbols(ThisForm, Object.Currency);
	RecalculateTotals();
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayCurrencySimbols(Form, ObjectCurrency)
	
	DefaultCurrencySymbol = GeneralFunctionsReusable.DefaultCurrencySymbol();
	DocumentCurrencySymbol = CommonUse.GetAttributeValue(ObjectCurrency, "Symbol");
	
	Form.Items.ExchangeRate.Title = DefaultCurrencySymbol + "/1" + DocumentCurrencySymbol;
	Form.Items.RCCurrency.Title = DefaultCurrencySymbol;
	
	Form.Items.SalesTaxCurrency.Title = DocumentCurrencySymbol;
	Form.Items.TaxableSubtotalCurrency.Title = DocumentCurrencySymbol;
	Form.Items.DiscountCurrency.Title = DocumentCurrencySymbol;
	Form.Items.ShippingCurrency.Title = DocumentCurrencySymbol;
	Form.Items.SubtotalCurrency.Title = DocumentCurrencySymbol;
	Form.Items.FCYCurrency.Title = DocumentCurrencySymbol;
	
EndProcedure

&AtClient
// LineItemsAfterDeleteRow UI event handler.
// 
Procedure LineItemsAfterDeleteRow(Item)
	
	//RecalcSalesTax();
	RecalculateTotals();
	
EndProcedure

&AtClient
// LineItemsQuantityOnChange UI event handler.
// This procedure is used when the units of measure (U/M) functional option is turned off
// and base quantities are used instead of U/M quantities.
// The procedure recalculates line total, line taxable amount, and a document's sales tax and total.
//  
Procedure LineItemsQuantityOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	//TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
	
	//RecalcTaxableAmount();
	//RecalcSalesTax();
	RecalculateTotals();

EndProcedure

&AtServer
// Procedure fills in default values, used mostly when the corresponding functional options are
// turned off.
// The following defaults are filled in - warehouse location, and currency.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Company") And Parameters.Company.Customer Then
		Object.Company = Parameters.Company;
	EndIf;

	//ConstantCreditMemo = Constants.CreditMemoLastNumber.Get();
	//If Object.Ref.IsEmpty() Then		
	//	
	//	Object.Number = Constants.CreditMemoLastNumber.Get();
	//Endif;

	
	Items.LineItemsQuantity.EditFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.Format = GeneralFunctionsReusable.DefaultQuantityFormat();
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	
	//Title = "Sales Return " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	//If Object.Ref.IsEmpty() Then
	//	Object.PriceIncludesVAT = GeneralFunctionsReusable.PriceIncludesVAT();
	//EndIf;
	
	// Request tax rate for US sales tax calculation.
	If GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") Then
		//Fill the list of available tax rates
		ListOfAvailableTaxRates = SalesTax.GetSalesTaxRatesList();
		For Each TaxRateItem In ListOfAvailableTaxRates Do
			Items.SalesTaxRate.ChoiceList.Add(TaxRateItem.Value, TaxRateItem.Presentation);
		EndDo;
		If Object.Ref.IsEmpty() Then
			If Not ValueIsFilled(Parameters.Basis) Then
				Object.DiscountIsTaxable = True;
			Else //If filled on the basis of Sales Order
				RecalculateTotalsNoContext(Object);
			EndIf;
			//If filled on the basis of Sales Order set current value
			SalesTaxRate = Object.SalesTaxRate;
		Else
			TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
			SalesTaxRateText = "Sales tax rate: " + String(TaxRate) + "%";
			Items.SalesTaxPercentDecoration.Title = SalesTaxRateText;
			//Determine if document's sales tax rate is inactive (has been changed)
			AgenciesRates = New Array();
			For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
				AgenciesRates.Add(New Structure("Agency, Rate", AgencyRate.Agency, AgencyRate.Rate));
			EndDo;
			If SalesTax.DocumentSalesTaxRateIsInactive(Object.SalesTaxRate, AgenciesRates) Then
				SalesTaxRate = 0;
				Representation = SalesTax.GetSalesTaxRatePresentation(Object.SalesTaxRate.Description, TaxRate) + " - Inactive";
				Items.SalesTaxRate.ChoiceList.Add(0, Representation);
			Else
				SalesTaxRate = Object.SalesTaxRate;
			EndIf;
		EndIf;
	Else
		Items.SalesTaxPercentDecoration.Title = "";
		Items.SalesTaxPercentDecoration.Border = New Border(ControlBorderType.WithoutBorder);
		Items.TotalsColumn3.Visible = False;
		Items.SalesTaxRate.Visible = False;
	EndIf;
				
	//If GeneralFunctionsReusable.FunctionalOptionValue("MultiLocation") Then
	//Else
		If Object.Location.IsEmpty() Then
			Object.Location = Catalogs.Locations.MainWarehouse;
		EndIf;
	//EndIf;

	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.ARAccount = Object.Currency.DefaultARAccount;
		Object.ExchangeRate = 1;	
	Else
	EndIf; 
	
	DisplayCurrencySimbols(ThisForm, Object.Currency);
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		//Items.FCYCurrency.Visible = False;
		//Items.RCCurrency.Visible = False;
		Items.RCCurrency.Title = "";
	EndIf;

	//DefaultCurrencySymbol = GeneralFunctionsReusable.DefaultCurrencySymbol();
	//DocumentCurrencySymbol = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	//
	//Items.ExchangeRate.Title = DefaultCurrencySymbol + "/1" + Object.Currency.Symbol;
	////Items.VATCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	//Items.RCCurrency.Title = DefaultCurrencySymbol;
	//Items.SalesTaxCurrency.Title = DefaultCurrencySymbol;
	//Items.TaxableSubtotalCurrency.Title = DefaultCurrencySymbol;
	//
	//Items.DiscountCurrency.Title = DocumentCurrencySymbol;
	//Items.ShippingCurrency.Title = DocumentCurrencySymbol;
	//Items.SubtotalCurrency.Title = DocumentCurrencySymbol;
	//Items.FCYCurrency.Title = DocumentCurrencySymbol;
	
	
EndProcedure

//&AtClient
// Calculates a VAT amount for the document line
//
//Procedure LineItemsVATCodeOnChange(Item)
//	
//	TabularPartRow = Items.LineItems.CurrentData;
//	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
//	RecalculateTotals();

//EndProcedure


&AtClient
Procedure SendEmail(Command)
	SendEmailAtServer();
EndProcedure

&AtServer
Procedure SendEmailAtServer()
	
If Object.Ref.IsEmpty() Then
		Message("An email cannot be sent until the invoice is posted or written");
	Else
		
	If Object.EmailTo <> "" Then
		
	// 	//imagelogo = Base64String(GeneralFunctions.GetLogo());
	 	If constants.logoURL.Get() = "" Then
			 imagelogo = "http://www.accountingsuite.com/images/logo-a.png";
	 	else
			 imagelogo = Constants.logoURL.Get();  
	 	Endif;
	 	
		
		
		datastring = "";
		TotalAmount = 0;
		TotalCredits = 0;
		For Each DocumentLine in Object.LineItems Do
			
			TotalAmount = TotalAmount + DocumentLine.LineTotal;
			datastring = datastring + "<TR height=""20""><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Product +  "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.ProductDescription + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Quantity + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Price + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.LineTotal + "</TD></TR>";

		EndDo;
		
	    	 
	    MailProfil = New InternetMailProfile; 
	    
	    MailProfil.SMTPServerAddress = ServiceParameters.SMTPServer(); 
		//MailProfil.SMTPServerAddress = Constants.MailProfAddress.Get();
	    MailProfil.SMTPUseSSL = ServiceParameters.SMTPUseSSL();
		//MailProfil.SMTPUseSSL = Constants.MailProfSSL.Get();
	    MailProfil.SMTPPort = 465;  
	    
	    MailProfil.Timeout = 180; 
	    
		MailProfil.SMTPPassword = ServiceParameters.SendGridPassword();
	 	  
		MailProfil.SMTPUser = ServiceParameters.SendGridUserName();

	    
	    send = New InternetMailMessage; 
	    //send.To.Add(object.shipto.Email);
	    //send.To.Add(object.EmailTo);
		
		If Object.EmailTo <> "" Then
			EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Object.EmailTo, ",");
			For Each EmailAddress in EAddresses Do
				send.To.Add(EmailAddress);
			EndDo;
		Endif;
		
		If Object.EmailCC <> "" Then
			EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Object.EmailCC, ",");
			For Each EmailAddress in EAddresses Do
				send.CC.Add(EmailAddress);
			EndDo;
		Endif;
		
		
	    send.From.Address = Constants.Email.Get();
	    send.From.DisplayName = "AccountingSuite";
	    send.Subject = Constants.SystemTitle.Get() + " - Credit Memo " + Object.Number + " from " + Format(Object.Date,"DLF=D") + " - $" + Format(Object.DocumentTotalRC,"NFD=2");
	    
	    FormatHTML = FormAttributeToValue("Object").GetTemplate("Template").GetText();
	 	  
	 	 
		FormatHTML2 = StrReplace(FormatHTML,"object.number",object.RefNum);
		
		FormatHTML2 = StrReplace(FormatHTML2,"imagelogo",imagelogo);
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(object.Date,"DLF=D"));
	 	  //BillTo
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.company",object.Company);

		  Query = New Query("SELECT
		                  |	Addresses.FirstName,
		                  |	Addresses.MiddleName,
		                  |	Addresses.LastName,
		                  |	Addresses.Phone,
		                  |	Addresses.Fax,
		                  |	Addresses.Email,
		                  |	Addresses.AddressLine1,
		                  |	Addresses.AddressLine2,
		                  |	Addresses.City,
		                  |	Addresses.State.Code AS State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP,
		                  |	Addresses.RemitTo
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultBilling = TRUE");
		Query.SetParameter("Company", object.company);
			QueryResult = Query.Execute();	
		Dataset = QueryResult.Unload();

		  
		  
		  FormatHTML2 = StrReplace(FormatHTML2,"object.shipto1",Dataset[0].AddressLine1);
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.shipto2",Dataset[0].AddressLine2);
	 	 CityStateZip = Dataset[0].City + Dataset[0].State + Dataset[0].ZIP;
	 	 
	 	 If CityStateZip = "" Then
	 	 	FormatHTML2 = StrReplace(FormatHTML2,"object.city object.state object.zip","");
	 	 Else
	 	  	FormatHTML2 = StrReplace(FormatHTML2,"object.city object.state object.zip",Dataset[0].City + ", " + Dataset[0].State + " " + Dataset[0].ZIP);
	 	 Endif;
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.country",Dataset[0].Country);
	 	  //lineitems
	 	  FormatHTML2 = StrReplace(FormatHTML2,"lineitems",datastring);
 	   
	 	  //User's company info
	 	  FormatHTML2 = StrReplace(FormatHTML2,"mycompany",Constants.SystemTitle.Get()); 
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myaddress1",Constants.AddressLine1.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myaddress2",Constants.AddressLine2.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"mycity mystate myzip",Constants.City.Get() + ", " + Constants.State.Get() + " " + Constants.ZIP.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myphone",Constants.Phone.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myemail",Constants.Email.Get());
	 	  
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.subtotal",Format(Object.DocumentTotalRC,"NFD=2"));
		  
	   If object.SalesTaxRC = 0 Then
	    	FormatHTML2 = StrReplace(FormatHTML2,"object.salestax","0.00");
	   Else
	 	 	 FormatHTML2 = StrReplace(FormatHTML2,"object.salestax",Format(object.SalesTaxRC,"NFD=2"));
	   Endif;
  
		  
	   If TotalAmount = 0 Then
	 	   FormatHTML2 = StrReplace(FormatHTML2,"object.total","0.00");
	   Else
	  		 FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(TotalAmount,"NFD=2"));
	   Endif;

	   //Note
	   FormatHTML2 = StrReplace(FormatHTML2,"object.note",Object.EmailNote);
	  
		send.Texts.Add(FormatHTML2,InternetMailTextType.HTML);
			
		Posta = New InternetMail; 
		Posta.Logon(MailProfil); 
		Posta.Send(send); 
		Posta.Logoff();
		
		Message("Credit Memo email has been sent");
		
		SentEmail = True;

		Else
	 		 Message("The recipient email has not been specified");
	    Endif;
	 	
	Endif;
	

 EndProcedure
 
  &AtServer
Procedure EmailSet()
	Query = New Query("SELECT
		                  |	Addresses.FirstName,
		                  |	Addresses.MiddleName,
		                  |	Addresses.LastName,
		                  |	Addresses.Phone,
		                  |	Addresses.Fax,
		                  |	Addresses.Email,
		                  |	Addresses.AddressLine1,
		                  |	Addresses.AddressLine2,
		                  |	Addresses.City,
		                  |	Addresses.State.Code AS State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP,
		                  |	Addresses.RemitTo
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultBilling = TRUE");
		Query.SetParameter("Company", object.company);
			QueryResult = Query.Execute();	
		Dataset = QueryResult.Unload();
		
	If Dataset.Count() > 0 Then	
		Object.EmailTo = Dataset[0].Email;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	OnCloseAtServer();
EndProcedure

&AtServer
Procedure OnCloseAtServer()

	If SentEmail = True Then
		
		DocObject = object.ref.GetObject();
		DocObject.EmailTo = Object.EmailTo;
		DocObject.LastEmail = "Last email on " + Format(CurrentDate(),"DLF=DT") + " to " + Object.EmailTo;
		DocObject.Write();
	Endif;

EndProcedure

&AtServer
Function Increment(NumberToInc)
	
	//Last = Constants.SalesInvoiceLastNumber.Get();
	Last = NumberToInc;
	//Last = "AAAAA";
	LastCount = StrLen(Last);
	Digits = new Array();
	For i = 1 to LastCount Do	
		Digits.Add(Mid(Last,i,1));

	EndDo;
	
	NumPos = 9999;
	lengthcount = 0;
	firstnum = false;
	j = 0;
	While j < LastCount Do
		If NumCheck(Digits[LastCount - 1 - j]) Then
			if firstnum = false then //first number encountered, remember position
				firstnum = true;
				NumPos = LastCount - 1 - j;
				lengthcount = lengthcount + 1;
			Else
				If firstnum = true Then
					If NumCheck(Digits[LastCount - j]) Then //if the previous char is a number
						lengthcount = lengthcount + 1;  //next numbers, add to length.
					Else
						break;
					Endif;
				Endif;
			Endif;
						
		Endif;
		j = j + 1;
	EndDo;
	
	NewString = "";
	
	If lengthcount > 0 Then //if there are numbers in the string
		changenumber = Mid(Last,(NumPos - lengthcount + 2),lengthcount);
		NumVal = Number(changenumber);
		NumVal = NumVal + 1;
		StringVal = String(NumVal);
		StringVal = StrReplace(StringVal,",","");
		
		StringValLen = StrLen(StringVal);
		changenumberlen = StrLen(changenumber);
		LeadingZeros = Left(changenumber,(changenumberlen - StringValLen));

		LeftSide = Left(Last,(NumPos - lengthcount + 1));
		RightSide = Right(Last,(LastCount - NumPos - 1));
		NewString = LeftSide + LeadingZeros + StringVal + RightSide; //left side + incremented number + right side
		
	Endif;
	
	Next = NewString;

	return NewString;
	
EndFunction

&AtServer
Function NumCheck(CheckValue)
	 
	For i = 0 to  9 Do
		If CheckValue = String(i) Then
			Return True;
		Endif;
	EndDo;
		
	Return False;
		
EndFunction

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;

	
	If Object.LineItems.Count() = 0  Then
		Message("Cannot post with no line items.");
		Cancel = True;
	EndIf;

	
	//If Object.Ref.IsEmpty() Then
	//
	//	MatchVal = Increment(Constants.CreditMemoLastNumber.Get());
	//	If Object.Number = MatchVal Then
	//		Constants.CreditMemoLastNumber.Set(MatchVal);
	//	Else
	//		If Increment(Object.Number) = "" Then
	//		Else
	//			If StrLen(Increment(Object.Number)) > 20 Then
	//				 Constants.CreditMemoLastNumber.Set("");
	//			Else
	//				Constants.CreditMemoLastNumber.Set(Increment(Object.Number));
	//			Endif;

	//		Endif;
	//	Endif;
	//Endif;

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
	If PeriodClosingServerCall.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		If Cancel Then
			If WriteParameters.Property("PeriodClosingPassword") And WriteParameters.Property("Password") Then
				If WriteParameters.Password = TRUE Then //Writing the document requires a password
					ShowMessageBox(, "Invalid password!",, "Closed period notification");
				EndIf;
			Else
				Notify = New NotifyDescription("ProcessUserResponseOnDocumentPeriodClosed", ThisObject, WriteParameters);
				Password = "";
				OpenForm("CommonForm.ClosedPeriodNotification", New Structure, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
			return;
		EndIf;
	EndIf;

EndProcedure

//Closing period
&AtClient
Procedure ProcessUserResponseOnDocumentPeriodClosed(Result, Parameters) Export
	If (TypeOf(Result) = Type("String")) Then //Inserted password
		Parameters.Insert("PeriodClosingPassword", Result);
		Parameters.Insert("Password", TRUE);
		Write(Parameters);
	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then //Yes, No or Cancel
		If Result = DialogReturnCode.Yes Then
			Parameters.Insert("PeriodClosingPassword", "Yes");
			Parameters.Insert("Password", FALSE);
			Write(Parameters);
		EndIf;
	EndIf;	
EndProcedure

&AtClient
Procedure SalesTaxOnChange(Item)
	SalesTaxOnChangeAtServer();
	RecalculateTotals();
EndProcedure

&AtServer
Procedure SalesTaxOnChangeAtServer()
	// Insert handler contents.
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AfterOpen", 0.1, True);	
	
EndProcedure

&AtClient
Procedure AfterOpen()
	
	ThisForm.Activate();
	
	If ThisForm.IsInputAvailable() Then
		///////////////////////////////////////////////
		DetachIdleHandler("AfterOpen");
		
		If  Object.Ref.IsEmpty() And ValueIsFilled(Object.Company) Then
			CompanyOnChange(Items.Company);	
		EndIf;	
		///////////////////////////////////////////////
	Else
		AttachIdleHandler("AfterOpen", 0.1, True);	
	EndIf;		
	
EndProcedure

&AtClient
Procedure SetSalesTaxRate(NewSalesTaxRate)
	//Cache inactive sales tax rates
	If ValueIsFilled(Object.SalesTaxRate) Then
		AgenciesRates = New Array();
		For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
			AgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
		EndDo;
		If SalesTax.DocumentSalesTaxRateIsInactive(Object.SalesTaxRate, AgenciesRates) Then
			SalesTaxRateInactive = Object.SalesTaxRate;
			AgenciesRatesInactive = AgenciesRates;
		EndIf;
	EndIf;
	//Restore inactive sales tax rates
	If TypeOf(NewSalesTaxRate) = Type("Number") Then //user returned inactive sales tax rate
		Object.SalesTaxRate = SalesTaxRateInactive;
		Object.SalesTaxAcrossAgencies.Clear();
		For Each AgencyRateInactive In AgenciesRatesInactive Do
			FillPropertyValues(Object.SalesTaxAcrossAgencies.Add(), AgencyRateInactive);
		EndDo;
	Else
		Object.SalesTaxRate = NewSalesTaxRate;
		Object.SalesTaxAcrossAgencies.Clear();
	EndIf;
	ShowSalesTaxRate();
	RecalculateTotals();
EndProcedure

&AtClient
Procedure ShowSalesTaxRate()
	If Object.SalesTaxAcrossAgencies.Count() = 0 Then
		SalesTaxRateAttr = CommonUse.GetAttributeValues(Object.SalesTaxRate, "Rate");
		TaxRate = SalesTaxRateAttr.Rate;
	Else
		TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
	EndIf;
	SalesTaxRateText = "Sales tax rate: " + String(TaxRate) + " %";
	Items.SalesTaxPercentDecoration.Title = SalesTaxRateText;
EndProcedure

&AtClient
Procedure DiscountIsTaxableOnChange(Item)
	RecalculateTotals();
EndProcedure

&AtClient
Procedure SalesTaxRateOnChange(Item)
	SetSalesTaxRate(SalesTaxRate);
EndProcedure

&AtClient
Procedure DiscountPercentOnChange(Item)
	
	Object.Discount = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure DiscountOnChange(Item)
	
	// Discount can not override the total.
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = - Object.LineSubtotal;
	EndIf;
	
	// Recalculate discount value by it's percent.
	If Object.LineSubtotal > 0 Then
		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	EndIf;
	
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ShippingOnChange(Item)
	
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure LineItemsTaxableOnChange(Item)
	RecalculateTotals();
EndProcedure

&AtClient
Procedure ExchangeRateOnChange(Item)
	RecalculateTotals();
EndProcedure



