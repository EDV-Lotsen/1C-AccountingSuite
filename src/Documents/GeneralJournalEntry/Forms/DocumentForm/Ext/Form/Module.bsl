
&AtClient
// The procedure calculates TotalDr and TotalCr for the transaction, and prevents
// saving an unbalanced transaction.
//
Procedure BeforeWrite(Cancel, WriteParameters)
	
	TotalDr = Object.LineItems.Total("AmountDr");
	TotalCr = Object.LineItems.Total("AmountCr"); 
	
	Object.DocumentTotal = TotalDr;
	Object.DocumentTotalRC = TotalDr * Object.ExchangeRate;
	
	If Not GeneralFunctions.FunctionalOptionValue("UnbalancedGLEntryPosting") Then
		
		If TotalDr <> TotalCr Then
			Message = New UserMessage();
			Message.Text = NStr("en='Balance The Transaction'");
			Message.Message();
			Cancel = True;
            Return;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
// LineItemsAmountDrOnChange UI event handler.
// The procedure clears Cr amount in the line if Dr amount is entered. A transaction can only have
// either Dr or Cr amount in one line (but not both).
// 
Procedure LineItemsAmountDrOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.AmountCr = 0;
	
EndProcedure

&AtClient
// LineItemsAmountCrOnChange UI event handler.
// The procedure clears Dr amount in the line if Cr amount is entered. A transaction can only have
// either Dr or Cr amount in one line (but not both).
// 
Procedure LineItemsAmountCrOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.AmountDr = 0;
	
EndProcedure

&AtClient
// Fills in the account description
//
Procedure LineItemsAccountOnChange(Item)
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.AccountDescription = GeneralFunctions.GetAttributeValue
		(TabularPartRow.Account, "Description");
	EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Title = "GL entry " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.ExchangeRate = 1;
	Else
	EndIf;

EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(), Object.Currency);

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(), Object.Currency);
	
EndProcedure
