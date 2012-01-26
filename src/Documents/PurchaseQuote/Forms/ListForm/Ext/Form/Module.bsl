
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
EndProcedure

&AtClient
Procedure CreateQuote(Command)
	
	Rows = Items.List.SelectedRows;
	NoOfRows = Rows.Count();
	
	If NoOfRows = 0 Then
    	DoMessageBox("Select at least one line");
		Return;
	EndIf;
	
	Customer = GeneralFunctions.GetCustomerFromPurchaseQuote(Rows[0]);
	Bank = GeneralFunctions.GetBankFromPurchaseQuote(Rows[0]);
	
	Quote = GeneralFunctions.GenerateQuote(Rows, Customer, Bank);
	
	If Quote.IsEmpty() Then
		DoMessageBox("Quote generation failed");
	Else		
		DoMessageBox("Success");
	EndIf;
	
EndProcedure



