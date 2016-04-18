
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrentDate = CurrentSessionDate();
	
	BeginOfPeriod = BegOfMonth(AddMonth(CurrentDate, -1)); 
	EndOfPeriod = EndOfMonth(AddMonth(CurrentDate, -1)); 
	
	AmountBalance = 0.01;
	
	Items.Result.Visible = False;
	
	Items.ListCurrency.Visible = Constants.MultiCurrency.Get();
	
EndProcedure

&AtClient
Procedure ShowList(Command)
	
	ShowListAtServer();
	
	Items.Result.Visible = True;
	
EndProcedure

&AtServer
Procedure ShowListAtServer()
	
	Query = New Query;
	Query.Text = "SELECT
	             |	TRUE AS Choice,
	             |	Companies.Ref AS Company,
	             |	ISNULL(GeneralJournalBalance.AmountBalance, 0) AS AmountBalance,
	             |	ISNULL(GeneralJournalBalance.Currency, Companies.DefaultCurrency) AS Currency,
	             |	Addresses.Ref AS Address
	             |FROM
	             |	Catalog.Companies AS Companies
	             |		LEFT JOIN AccountingRegister.GeneralJournal.Balance(&EndOfPeriod, , , ExtDimension1.Customer = TRUE) AS GeneralJournalBalance
	             |		ON Companies.Ref = GeneralJournalBalance.ExtDimension1
	             |		LEFT JOIN Catalog.Addresses AS Addresses
	             |		ON Companies.Ref = Addresses.Owner
	             |			AND (Addresses.DefaultBilling)
	             |WHERE
	             |	ISNULL(GeneralJournalBalance.AmountBalance, 0) >= &AmountBalance
	             |	AND Companies.Customer = TRUE";
				 
	Query.SetParameter("EndOfPeriod", EndOfDay(EndOfPeriod) + 1);
	Query.SetParameter("AmountBalance", AmountBalance);
	
	ValueToFormData(Query.Execute().Unload(), List);
	
EndProcedure

&AtClient
Procedure SelectAllCompanies(Command)
	
	For Each Line In List Do
		Line.Choice = True;	
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllCompanies(Command)
	
	For Each Line In List Do
		Line.Choice = False;	
	EndDo;
	
EndProcedure

&AtClient
Procedure GenerateStatements(Command)
	
	GenerateStatementsAtServer();
	
	Notify("UpdateStatements");
	
	ThisForm.Close();
	
EndProcedure

&AtServer
Procedure GenerateStatementsAtServer()
	
	For Each Line In List Do
		
		If Line.Choice Then
			DocObject = Documents.Statement.CreateDocument();
			
			DocObject.Date           = EndOfPeriod;
			DocObject.BeginOfPeriod  = BeginOfPeriod;
			DocObject.Company        = Line.Company;
			DocObject.Currency       = Line.Currency;
			DocObject.MailingAddress = Line.Address;
			
			DocObject.Write();
		EndIf;
		
	EndDo;
	
EndProcedure
