
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrentDate = CurrentSessionDate();
	
	BeginOfPeriod = BegOfMonth(AddMonth(CurrentDate, -1)); 
	EndOfPeriod = EndOfMonth(AddMonth(CurrentDate, -1)); 
	
	AmountRCBalance = 0.01;
	
	Items.Result.Visible = False;
	
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
	             |	ISNULL(GeneralJournalBalance.AmountRCBalance, 0) AS AmountRCBalance
	             |FROM
	             |	Catalog.Companies AS Companies
	             |		LEFT JOIN AccountingRegister.GeneralJournal.Balance(&EndOfPeriod, , , ExtDimension1.Customer = TRUE) AS GeneralJournalBalance
	             |		ON Companies.Ref = GeneralJournalBalance.ExtDimension1
	             |WHERE
	             |	ISNULL(GeneralJournalBalance.AmountRCBalance, 0) >= &AmountRCBalance
	             |	AND Companies.Customer = TRUE";
				 
	Query.SetParameter("EndOfPeriod", EndOfDay(EndOfPeriod));
	Query.SetParameter("AmountRCBalance", AmountRCBalance);
	
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
			
			DocObject.Date = EndOfPeriod;
			DocObject.BeginOfPeriod = BeginOfPeriod;
			DocObject.Company = Line.Company;
			
			DocObject.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure
