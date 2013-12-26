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
	TabularPartRow.TaxableAmount = 0;
	TabularPartRow.VAT = 0;
	
	Price = GeneralFunctions.RetailPrice(CurrentDate(), TabularPartRow.Product, Object.Company);
	TabularPartRow.Price = Price / Object.ExchangeRate;
		
	TabularPartRow.SalesTaxType = US_FL.GetSalesTaxType(TabularPartRow.Product);
	TabularPartRow.VATCode = CommonUse.GetAttributeValue(TabularPartRow.Product, "SalesVATCode");
	
	RecalcTotal();
	
EndProcedure

&AtClient
// The procedure recalculates a document's sales tax amount
// 
Procedure RecalcSalesTax()
	
	If Object.Company.IsEmpty() Then
		TaxRate = 0;
	Else
		TaxRate = US_FL.GetTaxRate(Object.Company);
	EndIf;
	
	Object.SalesTax = Object.LineItems.Total("TaxableAmount") * TaxRate/100;
	
EndProcedure

&AtClient
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalcTotal()
	
	If Object.PriceIncludesVAT Then
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.SalesTax;
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.SalesTax) * Object.ExchangeRate;		
	Else
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.SalesTax;
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.SalesTax) * Object.ExchangeRate;
	EndIf;	
	Object.VATTotal = Object.LineItems.Total("VAT") * Object.ExchangeRate;
	
EndProcedure

&AtClient
// The procedure recalculates a taxable amount for a line item.
// 
Procedure RecalcTaxableAmount()
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	If TabularPartRow.SalesTaxType = GeneralFunctionsReusable.US_FL_Taxable() Then
		TabularPartRow.TaxableAmount = TabularPartRow.LineTotal;
	Else
		TabularPartRow.TaxableAmount = 0;
	EndIf;
	
EndProcedure

&AtClient
// CustomerOnChange UI event handler.
// Selects default currency for the customer, determines an exchange rate, and
// recalculates the document's sales tax and total amounts.
//  
Procedure CompanyOnChange(Item)
	
	Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ARAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	RecalcSalesTax();
	RecalcTotal();
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
	
	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
	
	RecalcTaxableAmount();
	RecalcSalesTax();
	RecalcTotal();

EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's
// sales tax and total.
//
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	RecalcSalesTax();
	RecalcTotal();
	
EndProcedure

&AtClient
// CurrencyOnChange UI event handler.
// Determines an exchange rate for the new currency, and recalculates the document's
// sales tax and total.
//
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Object.ARAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	RecalcSalesTax();
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsAfterDeleteRow UI event handler.
// 
Procedure LineItemsAfterDeleteRow(Item)
	
	RecalcSalesTax();
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsSalesTaxTypeOnChange UI event handler.
//
Procedure LineItemsSalesTaxTypeOnChange(Item)
	
	RecalcTaxableAmount();
	RecalcSalesTax();
	RecalcTotal();
	
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
	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
	
	RecalcTaxableAmount();
	RecalcSalesTax();
	RecalcTotal();

EndProcedure

&AtServer
// Procedure fills in default values, used mostly when the corresponding functional options are
// turned off.
// The following defaults are filled in - warehouse location, and currency.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//ConstantCreditMemo = Constants.CreditMemoLastNumber.Get();
	//If Object.Ref.IsEmpty() Then		
	//	
	//	Object.Number = Constants.CreditMemoLastNumber.Get();
	//Endif;

	
	Items.LineItemsQuantity.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.LineItemsQuantity.Format = "NFD=" + Constants.QtyPrecision.Get();

	If Object.BegBal = False Then
		Items.DocumentTotalRC.ReadOnly = True;
		Items.DocumentTotal.ReadOnly = True;
	EndIf;
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	
	//Title = "Sales Return " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.Ref.IsEmpty() Then
    	Object.PriceIncludesVAT = GeneralFunctionsReusable.PriceIncludesVAT();
	EndIf;

	If NOT GeneralFunctionsReusable.FunctionalOptionValue("USFinLocalization") Then
		Items.SalesTaxGroup.Visible = False;
	EndIf;
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("VATFinLocalization") Then
		Items.VATGroup.Visible = False;
	EndIf;
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible = False;
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
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + Object.Currency.Symbol;
	Items.VATCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.SalesTaxCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	
EndProcedure

&AtClient
// Calculates a VAT amount for the document line
//
Procedure LineItemsVATCodeOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
    RecalcTotal();

EndProcedure

&AtClient
Procedure BegBalOnChange(Item)
	
	If Object.BegBal = True Then
		Items.DocumentTotalRC.ReadOnly = False;
		Items.DocumentTotal.ReadOnly = False;
	ElsIf Object.BegBal = False Then
		Items.DocumentTotalRC.ReadOnly = True;
		Items.DocumentTotal.ReadOnly = True;
	EndIf;

EndProcedure

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
			datastring = datastring + "<TR height=""20""><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Product +  "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.ProductDescription + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Quantity + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;""> $" + DocumentLine.Price + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;""> $" + DocumentLine.LineTotal + "</TD></TR>";

		EndDo;
		
	    	 
	    MailProfil = New InternetMailProfile; 
	    
	    MailProfil.SMTPServerAddress = "smtp.sendgrid.net";
		//MailProfil.SMTPServerAddress = Constants.MailProfAddress.Get();
	    MailProfil.SMTPUseSSL = True;
		//MailProfil.SMTPUseSSL = Constants.MailProfSSL.Get();
	    MailProfil.SMTPPort = 465; 
	    
	    MailProfil.Timeout = 180; 
	    
		MailProfil.SMTPPassword = "1cusa2012";
	 	  
		MailProfil.SMTPUser = "bnghiem";

		
		//MailProfil.SMTPPassword = "At/XCgOEv2nAyR+Nu7CC0WnhUVvbqndhaz1UkUkmQQTU"; 
		//MailProfil.SMTPPassword = Constants.MailProfPass.Get();
	    
	    //MailProfil.SMTPUser = "AKIAJIZ4ECYUL7N3P3BA"; 
		//MailProfil.SMTPUser = Constants.MailProfUser.Get();
	    
	    
	    send = New InternetMailMessage; 
	    //send.To.Add(object.shipto.Email);
	    send.To.Add(object.EmailTo);
		
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
		  
	   If object.SalesTax = 0 Then
	    	FormatHTML2 = StrReplace(FormatHTML2,"object.salestax","0.00");
	   Else
	 	 	 FormatHTML2 = StrReplace(FormatHTML2,"object.salestax",Format(object.SalesTax,"NFD=2"));
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
		
	Object.EmailTo = Dataset[0].Email;
	
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
	If DocumentPosting.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = DocumentPosting.DocumentWritePermitted(WriteParameters);
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
	If DocumentPosting.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not DocumentPosting.DocumentWritePermitted(WriteParameters);
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
