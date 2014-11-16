
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Date = CurrentSessionDate();
	
EndProcedure

&AtClient
Procedure Create(Command)
	
	If Not ValueIsFilled(Date) Then
		
		UM = New UserMessage;
		UM.Field = "Date";
		UM.Text  = NStr("en = 'Field ""Date of reclass"" is empty'");
		UM.Message();
		
	Else
		
		Form = GetForm("Document.GeneralJournalEntry.ObjectForm");
		GJE = Form.Object;
		FillGJE(GJE);
		CopyFormData(GJE, Form.Object);
		Form.Modified = True;
		Form.Open();
		
		Close();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillGJE(GJE)
	
	GJE.Date         = EndOfDay(Date);
	GJE.Currency     = Constants.DefaultCurrency.Get();
	GJE.ExchangeRate = 1;
	GJE.Memo         = "Reclass (auto-created)";
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	GeneralJournalBalance.Account AS Account,
		|	GeneralJournalBalance.Account.ReclassAccount AS ReclassAccount,
		|	ISNULL(GeneralJournalBalance.AmountRCBalanceDr, 0) AS AmountDr,
		|	ISNULL(GeneralJournalBalance.AmountRCBalanceCr, 0) AS AmountCr
		|FROM
		|	AccountingRegister.GeneralJournal.Balance(&Date, Account.ReclassAccount <> VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef), , ) AS GeneralJournalBalance
		|WHERE
		|	(GeneralJournalBalance.AmountRCBalanceDr <> 0
		|			OR GeneralJournalBalance.AmountRCBalanceCr <> 0)";

	Query.SetParameter("Date", EndOfDay(Date) + 1);

	SDR = Query.Execute().Select();
	
	While SDR.Next() Do
		
		Row = GJE.LineItems.Add();
		Row.Account  = SDR.Account; 
		Row.AmountDr = SDR.AmountCr;
		Row.AmountCr = SDR.AmountDr;
		Row.Memo     = "Reclass (auto-created)";
		
		Row = GJE.LineItems.Add();
		Row.Account  = SDR.ReclassAccount; 
		Row.AmountDr = SDR.AmountDr;
		Row.AmountCr = SDR.AmountCr;
		Row.Memo     = "Reclass (auto-created)";
		
	EndDo;
	
	GJE.DocumentTotal   = GJE.LineItems.Total("AmountDr");
	GJE.DocumentTotalRC = GJE.LineItems.Total("AmountDr") * GJE.ExchangeRate;
	
EndProcedure
